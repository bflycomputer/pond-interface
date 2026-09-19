#!/usr/bin/env python3
"""Small JSON bridge for the Appearance panel's hardware and saved settings."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
SCALES = (1, 1.25, 1.5, 2)


def run(*args, timeout=12):
    result = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or f"{args[0]} failed")
    return result.stdout


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


def brightness_device(output, cached=""):
    device = json.loads(cached) if cached else None
    # Match brightness control to the selected connector, not detection order.
    if not device and not output.startswith(("eDP", "LVDS", "DSI")):
        # The targeted brightness read below also checks DDC support.
        detected = run("ddcutil", "detect", "--brief", "--skip-ddc-checks")
        for block in re.split(r"(?=Display \d+)", detected):
            connector = re.search(r"DRM connector:\s+\S*card\d+-(\S+)", block)
            bus = re.search(r"I2C bus:\s+/dev/i2c-(\d+)", block)
            if connector and bus and connector[1] == output:
                device = {"kind": "ddc", "device": bus[1]}
                break
    elif not device:
        devices = sorted(Path("/sys/class/backlight").glob("*"))
        if devices:
            device = {"kind": "backlight", "device": devices[0].name}
    try:
        if device and device["kind"] == "ddc":
            value = run("ddcutil", "-b", device["device"], "getvcp", "10", "--brief",
                        *(["--skip-ddc-checks"] if cached else []))
            match = re.search(r"VCP 10 C (\d+) (\d+)", value)
            if match and int(match[2]) > 0:
                return dict(device, current=int(match[1]), max=int(match[2]))
        elif device:
            path = Path("/sys/class/backlight") / device["device"]
            return dict(device, current=int((path / "brightness").read_text()),
                        max=int((path / "max_brightness").read_text()))
    except (RuntimeError, OSError, subprocess.TimeoutExpired):
        if not cached:
            raise
    if cached:
        return brightness_device(output)
    raise RuntimeError("Brightness control is unavailable for this display")


def status(output, cached=""):
    outputs = json.loads(run("niri", "msg", "-j", "outputs"))
    monitor = outputs.get(output)
    result = {"output": output, "connected": bool(monitor and monitor.get("logical")),
              "brightness": None, "brightnessDevice": None, "brightnessError": ""}
    if result["connected"]:
        mode = monitor["modes"][monitor["current_mode"]]
        result.update(width=mode["width"], height=mode["height"], scale=monitor["logical"]["scale"])
        try:
            device = brightness_device(output, cached)
            result["brightness"] = device["current"] / device["max"]
            result["brightnessDevice"] = device
        except (RuntimeError, OSError, subprocess.TimeoutExpired) as error:
            result["brightnessError"] = str(error)
    return result


def set_brightness(output, value, cached=""):
    value = max(0.01, min(1, float(value)))
    device = json.loads(cached) if cached else brightness_device(output)
    if device["kind"] == "ddc":
        run("ddcutil", "-b", device["device"], "--noverify", "--enable-dynamic-sleep",
            "--sleep-multiplier=0.05", "setvcp", "10", str(round(value * device["max"])))
    else:
        run("brightnessctl", "-d", device["device"], "set", f"{round(value * 100)}%")
    return {"brightness": value}


def step_brightness(output, delta):
    device = brightness_device(output)
    value = device["current"] / device["max"] + float(delta)
    return set_brightness(output, value, json.dumps(device))


def scaled_config(text, output, scale):
    """Replace only the target output's direct scale node, preserving other KDL."""
    # Token positions preserve comments/formatting. Strings and comments cannot
    # accidentally contribute braces or nodes to the structural scan.
    token_re = re.compile(r'//[^\n]*|/\*.*?\*/|"(?:\\.|[^"\\])*"|[{};\n]|[^\s{};"/]+', re.S)
    tokens = [(m[0], m.start(), m.end()) for m in token_re.finditer(text)
              if not m[0].startswith(("//", "/*"))]
    for index, (token, _, _) in enumerate(tokens):
        if token != "output" or index + 2 >= len(tokens):
            continue
        name, _, _ = tokens[index + 1]
        if not name.startswith('"') or json.loads(name) != output or tokens[index + 2][0] != "{":
            continue
        depth = 1
        cursor = index + 3
        while cursor < len(tokens):
            token, start, end = tokens[cursor]
            if token == "{":
                depth += 1
            elif token == "}":
                depth -= 1
                if depth == 0:
                    return text[:start] + f"    scale {scale:g}\n" + text[start:]
            elif token == "scale" and depth == 1:
                _, value_start, value_end = tokens[cursor + 1]
                return text[:value_start] + f"{scale:g}" + text[value_end:]
            cursor += 1
        raise ValueError("Unclosed output configuration")
    return text.rstrip() + f'\n\noutput {json.dumps(output)} {{\n    scale {scale:g}\n}}\n'


def set_scale(output, value):
    scale = float(value)
    if scale not in SCALES:
        raise ValueError("Unsupported display scale")
    outputs = json.loads(run("niri", "msg", "-j", "outputs"))
    if output not in outputs or not outputs[output].get("logical"):
        raise ValueError("Display is no longer connected")
    path = CONFIG / "niri/cfg/display.kdl"
    previous = path.read_text()
    updated = scaled_config(previous, output, scale)
    # Keep a recovery copy and roll back if the compositor rejects the config.
    atomic_write(path.with_suffix(".kdl.appearance-backup"), previous)
    atomic_write(path, updated)
    try:
        run("niri", "validate")
        run("niri", "msg", "output", output, "scale", str(scale))
    except Exception:
        atomic_write(path, previous)
        raise
    return {"scale": scale}


def wallpaper(mode, path=""):
    state = {"mode": mode, "path": "", "url": ""}
    if mode == "custom":
        import gi
        gi.require_version("GdkPixbuf", "2.0")
        from gi.repository import GdkPixbuf
        image = Path(path).expanduser().resolve(strict=True)
        if not image.is_file() or GdkPixbuf.Pixbuf.get_file_info(str(image))[0] is None:
            raise ValueError("Choose a readable image file")
        state.update(path=str(image), url=image.as_uri())
    elif mode != "dynamic":
        raise ValueError("Unknown wallpaper mode")
    atomic_write(CONFIG / "pond-interface/wallpaper.json", json.dumps(state) + "\n")
    return state


def pick_wallpaper():
    result = subprocess.run(["zenity", "--file-selection", "--title=Choose a wallpaper",
                             f"--filename={Path.home() / 'Pictures/Wallpapers'}/",
                             "--file-filter=Images | *.png *.jpg *.jpeg *.webp *.avif *.bmp *.gif *.svg *.PNG *.JPG *.JPEG",
                             "--file-filter=All files | *"], capture_output=True, text=True)
    if result.returncode == 1:
        return {"cancelled": True}
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "Could not open the image picker")
    return wallpaper("custom", result.stdout.rstrip("\n"))


def theme(name):
    if name not in ("daylight", "unthemed"):
        raise ValueError("Unknown theme")
    atomic_write(CONFIG / "pond-interface/theme.json", json.dumps({"theme": name}) + "\n")
    return {"theme": name}


def main():
    try:
        action, *args = sys.argv[1:]
        commands = {"status": status, "brightness": set_brightness, "brightness-step": step_brightness, "scale": set_scale,
                    "wallpaper": wallpaper, "pick-wallpaper": pick_wallpaper, "theme": theme}
        print(json.dumps(commands[action](*args)))
    except Exception as error:
        print(json.dumps({"error": str(error)}))
        sys.exit(1)


if __name__ == "__main__":
    main()
