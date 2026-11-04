#!/usr/bin/env python3
"""Manage wallpaper selection and thumbnail discovery through a JSON CLI.

`list` returns original wallpaper URLs plus existing thumbnail URLs without decoding
the originals. `thumbnail PATH` creates a 552x310, alpha-preserving preview under
$XDG_CACHE_HOME/pond-interface/wallpaper-thumbnails (default ~/.cache).
Bundled and custom wallpapers share this runtime cache; generated images never
need to be shipped in the repository. Cache keys include the canonical path,
mtime, size, and thumbnail version.
Only picker previews are resized; saved wallpaper selections use the originals.
"""
import json
import hashlib
import os
from pathlib import Path
import subprocess
import sys
import tempfile

CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
INCLUDED_WALLPAPERS = Path(__file__).resolve().parent / "included"
THUMBNAIL_VERSION = "1"
THUMBNAIL_WIDTH = 552
THUMBNAIL_HEIGHT = 310


def thumbnail_path(image):
    """Return the versioned cache path for a canonical image."""
    stat = image.stat()
    key = f"{THUMBNAIL_VERSION}\0{image}\0{stat.st_mtime_ns}\0{stat.st_size}"
    digest = hashlib.sha256(key.encode("utf-8")).hexdigest()
    cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    return cache / "pond-interface" / "wallpaper-thumbnails" / f"{digest}.png"


def render_thumbnail(source, destination):
    """Decode only as much as needed, orient, and center-crop a preview."""
    from PyQt6.QtCore import QSize, Qt
    from PyQt6.QtGui import QImageReader

    reader = QImageReader(str(source))
    reader.setAutoTransform(True)
    size = reader.size()
    if not size.isValid():
        raise ValueError(f"Could not read image {source}: {reader.errorString()}")
    # QImageReader's scaled size is in the source's coordinates, before EXIF rotation.
    rotated = bool(reader.transformation().value & 4)
    target = QSize(THUMBNAIL_HEIGHT, THUMBNAIL_WIDTH) if rotated else QSize(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT)
    reader.setScaledSize(size.scaled(target, Qt.AspectRatioMode.KeepAspectRatioByExpanding))
    image = reader.read()
    if image.isNull():
        raise ValueError(f"Could not read image {source}: {reader.errorString()}")
    image = image.scaled(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT,
                         Qt.AspectRatioMode.KeepAspectRatioByExpanding,
                         Qt.TransformationMode.SmoothTransformation)
    image = image.copy((image.width() - THUMBNAIL_WIDTH) // 2,
                       (image.height() - THUMBNAIL_HEIGHT) // 2,
                       THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT)
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=destination.parent, delete=False) as file:
        temporary = Path(file.name)
    try:
        if not image.save(str(temporary), "PNG"):
            raise OSError(f"Could not write thumbnail {destination}")
        os.replace(temporary, destination)
    finally:
        temporary.unlink(missing_ok=True)


def thumbnail(path):
    image = Path(path).expanduser().resolve(strict=True)
    if not image.is_file():
        raise ValueError("Choose a readable image file")
    destination = thumbnail_path(image)
    if not destination.is_file():
        render_thumbnail(image, destination)
    return {"thumbnail": destination.as_uri()}


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
        preview = thumbnail_path(image)
        return {"path": str(image), "url": f"{image.as_uri()}?{image.stat().st_mtime_ns}",
                "thumbnail": preview.as_uri() if preview.is_file() else "",
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
                             "--file-filter=Images | *.png *.jpg *.jpeg *.webp *.bmp *.gif *.svg *.PNG *.JPG *.JPEG",
                             "--file-filter=All files | *"], capture_output=True, text=True)
    if result.returncode == 1:
        return {"cancelled": True}
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "Could not open the image picker")
    return wallpaper("custom", result.stdout.rstrip("\n"))


def main():
    try:
        action, *args = sys.argv[1:]
        commands = {"list": wallpapers, "set": wallpaper, "pick": pick_wallpaper,
                    "thumbnail": thumbnail}
        print(json.dumps(commands[action](*args)))
    except Exception as error:
        print(json.dumps({"error": str(error)}))
        sys.exit(1)


if __name__ == "__main__":
    main()
