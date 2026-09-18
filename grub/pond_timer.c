/* SPDX-License-Identifier: GPL-3.0-or-later */
#include <grub/bitmap.h>
#include <grub/dl.h>
#include <grub/env.h>
#include <grub/file.h>
#include <grub/gui.h>
#include <grub/menu_viewer.h>
#include <grub/misc.h>
#include <grub/mm.h>
#include <grub/time.h>
#include <grub/video.h>

GRUB_MOD_LICENSE ("GPLv3+");

static grub_err_t (*previous_try) (int, grub_menu_t, int);
static void (*previous_poll) (int);
static grub_gui_component_t timer_component;
static struct grub_gui_component_ops *original_ops;
static struct grub_gui_component_ops timer_ops;
static struct grub_video_bitmap *overlay, *selected_arrow;
static grub_uint64_t start_ms, duration_ms, last_paint;
static unsigned screen_width, screen_height;
static int active, complete, default_row, double_repaint, busy;

static void
timer_paint (void *self, const grub_video_rect_t *region)
{
  grub_video_rect_t bounds, saved;
  grub_uint64_t elapsed;
  int fill;

  if (!active || !overlay || !selected_arrow)
    return;

  original_ops->get_bounds (self, &bounds);
  if (!grub_video_have_common_points (region, &bounds))
    return;

  grub_gui_set_viewport (&bounds, &saved);
  grub_video_fill_rect (grub_video_map_rgb (28, 9, 25),
                        0, 0, bounds.width, bounds.height);
  if (complete)
    grub_video_blit_bitmap (selected_arrow, GRUB_VIDEO_BLIT_BLEND,
                           0, 0, 0, 0, bounds.width, bounds.height);
  else
    {
      elapsed = grub_get_time_ms () - start_ms;
      elapsed = grub_min (elapsed, duration_ms);
      fill = duration_ms
        ? grub_divmod64 (bounds.height * elapsed, duration_ms, 0)
        : bounds.height;
      grub_video_fill_rect (grub_video_map_rgb (203, 226, 91),
                           0, 0, bounds.width, fill);
      grub_video_blit_bitmap (overlay, GRUB_VIDEO_BLIT_BLEND,
                             0, 0, 0, 0, bounds.width, bounds.height);
    }
  grub_gui_restore_viewport (&saved);
}

static void
repaint_timer (void)
{
  grub_video_rect_t bounds, saved;
  struct grub_video_render_target *target;
  grub_video_area_status_t area;
  int pass;

  if (!active || !timer_component || busy)
    return;

  busy = 1;
  timer_component->ops->get_bounds (timer_component, &bounds);
  grub_video_get_active_render_target (&target);
  grub_video_set_active_render_target (GRUB_VIDEO_RENDER_TARGET_DISPLAY);
  grub_gui_save_viewport (&saved);
  grub_video_get_area_status (&area);
  grub_video_set_area_status (GRUB_VIDEO_AREA_DISABLED);
  grub_video_set_viewport (0, 0, screen_width, screen_height);
  for (pass = 0; pass < (double_repaint ? 2 : 1); pass++)
    {
      timer_paint (timer_component, &bounds);
      if (pass == 0)
        grub_video_swap_buffers ();
    }
  grub_gui_restore_viewport (&saved);
  grub_video_set_area_status (area);
  grub_video_set_active_render_target (target);
  busy = 0;
}

static void
poll_timer (int wait)
{
  grub_uint64_t now;

  if (previous_poll)
    previous_poll (wait);
  if (!active || busy)
    return;

  now = grub_get_time_ms ();
  if (now - last_paint >= 50)
    {
      last_paint = now;
      repaint_timer ();
    }
}

static void
clear_timer (void *data __attribute__ ((unused)))
{
  complete = 1;
  repaint_timer ();
  active = 0;
}

static void
set_choice (int entry, void *data __attribute__ ((unused)))
{
  if (entry != default_row)
    clear_timer (0);
}

static void
notify_timeout (int seconds, void *data __attribute__ ((unused)))
{
  if (seconds <= 0)
    {
      clear_timer (0);
      return;
    }
  if (!active && timer_component)
    {
      duration_ms = (grub_uint64_t) seconds * 1000;
      start_ms = grub_get_time_ms ();
      last_paint = 0;
      complete = 0;
      active = 1;
    }
}

static void
finish_timer (void *data __attribute__ ((unused)))
{
  active = 0;
  if (timer_component)
    timer_component->ops = original_ops;
  timer_component = 0;
  grub_video_bitmap_destroy (overlay);
  grub_video_bitmap_destroy (selected_arrow);
  overlay = selected_arrow = 0;
}

static unsigned
select_layout (const char *root, const struct grub_video_mode_info *mode)
{
  static const struct { unsigned width, height, font; } profiles[] = {
    { 640, 360, 12 }, { 1024, 576, 17 }, { 1280, 720, 21 },
    { 1920, 1080, 32 }, { 2560, 1440, 43 }, { 3840, 2160, 64 }
  };
  unsigned i, font = 12;
  char *path;
  grub_file_t file;

  for (i = 0; i < ARRAY_SIZE (profiles); i++)
    if (mode->width >= profiles[i].width && mode->height >= profiles[i].height)
      font = profiles[i].font;

  path = grub_xasprintf ("%s/theme-%u.txt", root, font);
  file = path ? grub_file_open (path, GRUB_FILE_TYPE_CONFIG) : 0;
  if (file)
    {
      grub_env_set ("theme", path);
      grub_file_close (file);
    }
  grub_free (path);
  grub_errno = GRUB_ERR_NONE;
  return file ? font : 0;
}

static void
find_menu (grub_gui_component_t component, void *data)
{
  if (component->ops->is_instance (component, "list"))
    *(grub_gui_component_t *) data = component;
}

static grub_err_t
try_menu (int entry, grub_menu_t menu, int nested)
{
  const char *root = grub_env_get ("pond_theme_root");
  struct grub_video_mode_info mode;
  struct grub_gfxmenu_timeout_notify *notification;
  struct grub_menu_viewer *viewer;
  grub_gui_component_t component, menu_component = 0;
  grub_gui_container_t parent;
  grub_video_rect_t bounds;
  grub_err_t err;
  char *path;
  unsigned font = 0;

  finish_timer (0);
  if (root && !grub_video_get_info (&mode))
    font = select_layout (root, &mode);
  err = previous_try (entry, menu, nested);
  if (err || !font)
    return err;
  screen_width = mode.width;
  screen_height = mode.height;

  notification = grub_gfxmenu_timeout_notifications;
  if (!notification)
    return GRUB_ERR_NONE;
  component = notification->self;
  parent = component->ops->get_parent (component);
  if (!parent)
    return GRUB_ERR_NONE;
  grub_gui_find_by_id (&parent->component, "pond_menu", find_menu, &menu_component);
  if (!menu_component || !grub_gui_list_get_selected_bounds (menu_component, &bounds))
    return GRUB_ERR_NONE;

  path = grub_xasprintf ("%s/assets/%u/arrow-overlay.png", root, font);
  err = path ? grub_video_bitmap_load (&overlay, path) : GRUB_ERR_OUT_OF_MEMORY;
  grub_free (path);
  if (err)
    goto fail;
  path = grub_xasprintf ("%s/assets/%u/selected_w.png", root, font);
  err = path ? grub_video_bitmap_load (&selected_arrow, path) : GRUB_ERR_OUT_OF_MEMORY;
  grub_free (path);
  if (err || overlay->mode_info.width != bounds.width ||
      overlay->mode_info.height != bounds.height ||
      selected_arrow->mode_info.width != bounds.width ||
      selected_arrow->mode_info.height != bounds.height)
    goto fail;

  viewer = grub_zalloc (sizeof (*viewer));
  if (!viewer)
    goto fail;

  component->x = bounds.x;
  component->y = bounds.y;
  component->w = bounds.width;
  component->h = bounds.height;
  component->xfrac = component->yfrac = component->wfrac = component->hfrac = 0;
  component->ops->set_bounds (component, &bounds);
  timer_component = component;
  original_ops = component->ops;
  timer_ops = *original_ops;
  timer_ops.paint = timer_paint;
  timer_ops.get_minimal_size = 0;
  component->ops = &timer_ops;
  default_row = entry;
  double_repaint = (mode.mode_type & GRUB_VIDEO_MODE_TYPE_DOUBLE_BUFFERED)
    && !(mode.mode_type & GRUB_VIDEO_MODE_TYPE_UPDATING_SWAP);
  viewer->set_chosen_entry = set_choice;
  viewer->print_timeout = notify_timeout;
  viewer->clear_timeout = clear_timer;
  viewer->fini = finish_timer;
  grub_menu_register_viewer (viewer);
  return GRUB_ERR_NONE;

fail:
  finish_timer (0);
  grub_errno = GRUB_ERR_NONE;
  return GRUB_ERR_NONE;
}

GRUB_MOD_INIT (pond_timer)
{
  previous_try = grub_gfxmenu_try_hook;
  previous_poll = grub_term_poll_usb;
  grub_gfxmenu_try_hook = try_menu;
  grub_term_poll_usb = poll_timer;
  grub_env_set ("pond_timer_loaded", "1");
  grub_env_export ("pond_timer_loaded");
  grub_dl_ref (mod);
}

GRUB_MOD_FINI (pond_timer)
{
  grub_env_unset ("pond_timer_loaded");
  finish_timer (0);
  if (grub_gfxmenu_try_hook == try_menu)
    grub_gfxmenu_try_hook = previous_try;
  if (grub_term_poll_usb == poll_timer)
    grub_term_poll_usb = previous_poll;
}
