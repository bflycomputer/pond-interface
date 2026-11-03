#!/usr/bin/env python3
"""Manage wallpaper discovery and saved selection through a JSON command interface."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
INCLUDED_WALLPAPERS = Path(__file__).resolve().parent / "included"


def atomic_write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as file:
        temporary = Path(file.name)
        file.write(text)
    try:
        if path.exists():
            temporary.chmod(path.stat().st_mode)
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def wallpaper_folder():
    from PyQt6.QtCore import QStandardPaths
    return Path(QStandardPaths.writableLocation(QStandardPaths.StandardLocation.PicturesLocation)) / "Wallpapers"


def wallpaper_state():
    try:
        saved = json.loads((CONFIG / "pond-interface/wallpaper.json").read_text())
    except FileNotFoundError:
        saved = {}
    state = {"mode": "dynamic", "path": "", "url": "", "imports": [], **saved}
    if not isinstance(state["imports"], list) or not all(isinstance(p, str) for p in state["imports"]):
        raise ValueError("Invalid wallpaper imports")
    return state


def wallpaper_entry(path, title=None, subtitle=None):
    from PyQt6.QtGui import QImageReader
    try:
        image = Path(path).expanduser().resolve(strict=True)
        if not image.is_file() or not QImageReader(str(image)).canRead():
            return None
        folder = str(image.parent)
        if image.is_relative_to(Path.home()):
            folder = "~/" + str(image.parent.relative_to(Path.home()))
        return {"path": str(image), "url": f"{image.as_uri()}?{image.stat().st_mtime_ns}",
                "title": image.name if title is None else title,
                "subtitle": folder if subtitle is None else subtitle}
    except OSError:
        return None


def wallpapers():
    state = wallpaper_state()
    original = json.dumps(state)
    catalog_path = INCLUDED_WALLPAPERS.parent / "catalog.json"
    catalog = json.loads(catalog_path.read_text()) if catalog_path.exists() else []
    included = [entry for item in catalog
                if (entry := wallpaper_entry(INCLUDED_WALLPAPERS / item["file"], item["title"], item["author"]))]
    included_paths = {entry["path"] for entry in included}
    discovered = {}
    for path in sorted(wallpaper_folder().glob("*"), key=lambda p: p.name.casefold()):
        if (entry := wallpaper_entry(path)) and entry["path"] not in included_paths:
            discovered[entry["path"]] = entry
    known = included_paths | discovered.keys()
    imported = {}
    # Preserve the previously selected image when upgrading from a single-path setting.
    paths = state["imports"] + ([state["path"]] if state["mode"] == "custom" and state["path"] else [])
    for path in paths:
        if (entry := wallpaper_entry(path)) and entry["path"] not in known:
            imported[entry["path"]] = entry
    state["imports"] = list(imported)
    if state["mode"] == "custom":
        selected = wallpaper_entry(state["path"])
        if selected:
            state.update(path=selected["path"], url=selected["url"])
        else:
            state.update(mode="dynamic", path="", url="")
    if json.dumps(state) != original:
        atomic_write(CONFIG / "pond-interface/wallpaper.json", json.dumps(state) + "\n")
    dynamic = {"dynamic": True, "title": "Daylight (dynamic)", "subtitle": "Changes through the day"}
    return dict(state, wallpapers=list(imported.values()) + list(discovered.values()) + [dynamic] + included)


def wallpaper(mode, path=""):
    state = wallpaper_state()
    if mode == "custom":
        selected = wallpaper_entry(path)
        if not selected:
            raise ValueError("Choose a readable image file")
        state.update(mode=mode, path=selected["path"], url=selected["url"])
        if selected["path"] not in state["imports"]:
            state["imports"].insert(0, selected["path"])
    elif mode == "dynamic":
        state.update(mode=mode, path="", url="")
    else:
        raise ValueError("Unknown wallpaper mode")
    atomic_write(CONFIG / "pond-interface/wallpaper.json", json.dumps(state) + "\n")
    return wallpapers()


def pick_wallpaper():
    result = subprocess.run(["zenity", "--file-selection", "--title=Choose a wallpaper",
                             f"--filename={wallpaper_folder()}/",
                             "--file-filter=Images | *.png *.jpg *.jpeg *.webp *.avif *.bmp *.gif *.svg *.PNG *.JPG *.JPEG",
                             "--file-filter=All files | *"], capture_output=True, text=True)
    if result.returncode == 1:
        return {"cancelled": True}
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "Could not open the image picker")
    return wallpaper("custom", result.stdout.rstrip("\n"))


def main():
    try:
        action, *args = sys.argv[1:]
        commands = {"list": wallpapers, "set": wallpaper, "pick": pick_wallpaper}
        print(json.dumps(commands[action](*args)))
    except Exception as error:
        print(json.dumps({"error": str(error)}))
        sys.exit(1)


if __name__ == "__main__":
    main()
