#!/usr/bin/env python3
# Backend for the Shortcuts settings page: lists niri key bindings, tracks
# custom ones created through the page, and edits the personal keybinds file.
# Custom binds are appended to ~/.config/niri/cfg/keybinds.kdl, which niri
# auto-reloads, so entries show up in the hotkey overlay immediately.
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import kdl

USER_CONFIG = Path.home() / ".config/niri/config.kdl"
USER_KEYBINDS = Path.home() / ".config/niri/cfg/keybinds.kdl"
META = Path.home() / ".config/pond-interface/shortcuts.json"
MANAGED_COMMENT = "    // ─── Pond shortcuts (managed by Settings → Keyboard shortcuts) ───"
MODS = ["MOD", "SHIFT", "CTRL", "ALT", "SUPER"]


def config_files():
    # Every file contributing binds, in niri include order. A real Pond install
    # keeps the whole config in ~/.config/niri; the /usr/share layout is the
    # packaged default and the checkout-relative path is for development.
    defaults = [Path("/usr/share/pond-interface/config/niri/config.kdl"),
                Path(__file__).resolve().parents[3] / "config/niri/config.kdl"]
    root = next((path for path in [USER_CONFIG, *defaults] if path.is_file()), None)
    files, seen = [], set()

    def visit(path, depth=0):
        resolved = path.resolve()
        if depth > 12 or resolved in seen or not resolved.is_file():
            return
        seen.add(resolved)
        files.append(resolved)
        try:
            text = resolved.read_text()
        except OSError:
            return
        tokens = kdl.tokens(text)
        for first, _, opening, _ in kdl.nodes(tokens):
            if tokens[first][0] != "include" or opening is not None:
                continue
            for index in range(first + 1, len(tokens)):
                token = tokens[index][0]
                if token in ("\n", ";", "{"):
                    break
                target = Path(token.strip('"'))
                if not target.is_absolute():
                    target = resolved.parent / target
                visit(target, depth + 1)

    visit(root)
    return files


def scan_binds(text):
    # A bind is one node per chord: `Mod+Q flags... { action; }`. Bare KDL
    # comments are invisible to the scanner, so commented-out defaults are
    # naturally skipped; `/-`-disabled nodes are skipped inside nodes().
    tokens = kdl.tokens(text)
    result = []
    for first, _, opening, closing in kdl.nodes(tokens):
        if tokens[first][0] != "binds" or opening is None or closing is None:
            continue
        for chord_first, chord_last, _, chord_closing in kdl.nodes(tokens, opening + 1, closing):
            chord, title, flags = "", "", {}
            argument = chord_first
            while argument < chord_closing:
                token = tokens[argument][0]
                # `hotkey-overlay-title="..."` splits into a bare `k=v` token
                # followed by a quoted-string token; plain values stay in one.
                if token.endswith("=") and argument + 1 < chord_closing:
                    value_token = tokens[argument + 1][0]
                    token += value_token
                    argument += 1
                if "=" in token:
                    key, _, value = token.partition("=")
                    try:
                        value = json.loads(value)
                    except ValueError:
                        value = value.strip('"')
                    if key == "hotkey-overlay-title":
                        title = value
                    elif key in ("repeat", "allow-when-locked"):
                        flags[key] = value
                elif not chord:
                    chord = token
                argument += 1
            if chord:
                action = clean_action(text, tokens, chord_closing)
                result.append({"key": chord, "title": title, "flags": flags, "action": action})
    return result


def clean_action(text, tokens, closing):
    # Everything between this node's `{` and its closing `}`.
    opening = closing
    while tokens[opening][0] != "{":
        opening -= 1
    body = text[tokens[opening + 1][1]:tokens[closing][1]] if opening + 1 < closing else ""
    lines = []
    for line in body.splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith("//"):
            lines.append(" ".join(line.split()))
    return " ".join(lines).strip()


def canonical(chord):
    # niri parses modifiers and keysyms case-insensitively.
    mods, key = [], ""
    for part in chord.split("+"):
        upper = part.upper()
        if upper in MODS:
            mods.append(upper.title() if upper != "MOD" else "Mod")
        elif key:
            return ""
        else:
            key = part.lower()
    return "+".join(sorted(set(mods), key=lambda mod: MODS.index(mod.upper())) + [key])


def active_binds():
    # niri merges binds across includes and a later file's chord replaces an
    # earlier one, so the last sighting wins (in its first position).
    binds = {}
    for path in config_files():
        try:
            text = path.read_text()
        except OSError:
            continue
        for bind in scan_binds(text):
            identity = canonical(bind["key"])
            if identity:
                binds[identity] = bind | {"file": str(path), "personal": path == USER_KEYBINDS}
    return list(binds.values())


def custom_binds():
    try:
        data = json.loads(META.read_text())
        return data if isinstance(data, list) else []
    except (OSError, ValueError):
        return []


def store_binds(entries):
    META.parent.mkdir(parents=True, exist_ok=True)
    kdl.atomic_write(META, json.dumps(entries, indent=2) + "\n")


def format_bind(key, title, flags, action):
    line = "    " + key
    if flags.get("repeat") is False:
        line += " repeat=false"
    if flags.get("allow-when-locked"):
        line += " allow-when-locked=true"
    if title:
        line += " hotkey-overlay-title=" + json.dumps(title)
    return line + " { " + action.strip() + " }"


def add(key, title, flags, action):
    key, title, action = key.strip(), str(title), (action or "").strip()
    if not key or not action:
        raise ValueError("A chord and an action are required.")
    if not canonical(key):
        raise ValueError(f"'{key}' is not a valid niri chord.")
    conflict = next((bind for bind in active_binds() if canonical(bind["key"]) == canonical(key)), None)
    if conflict:
        label = conflict["title"] or conflict["action"] or "an existing shortcut"
        raise ValueError(f"'{key}' is already bound: {label}.")
    text = USER_KEYBINDS.read_text() if USER_KEYBINDS.is_file() else DEFAULT_USER_KEYBINDS
    tokens = kdl.tokens(text)
    closing = next((tokens[closing][1] for first, _, opening, closing in kdl.nodes(tokens)
                    if tokens[first][0] == "binds" and opening is not None and closing is not None), None)
    if closing is None:
        raise ValueError("No binds block in " + str(USER_KEYBINDS) + ".")
    USER_KEYBINDS.parent.mkdir(parents=True, exist_ok=True)
    entry = {"key": key, "title": title, "flags": flags or {"repeat": False}, "action": action}
    insert = "" if MANAGED_COMMENT in text else MANAGED_COMMENT + "\n"
    head = "\n" if closing > 0 and text[closing - 1] != "\n" else ""
    text = text[:closing] + head + insert + format_bind(**entry) + "\n" + text[closing:]
    kdl.atomic_write(USER_KEYBINDS, text)
    stored = [value for value in custom_binds() if canonical(value["key"]) != canonical(key)]
    stored.append(entry)
    store_binds(stored)
    return entry


def remove(key):
    text = USER_KEYBINDS.read_text()
    tokens = kdl.tokens(text)
    for first, _, opening, closing in kdl.nodes(tokens):
        if tokens[first][0] != "binds" or opening is None or closing is None:
            continue
        for chord_first, chord_last, _, chord_closing in kdl.nodes(tokens, opening + 1, closing):
            if canonical(tokens[chord_first][0]) != canonical(key):
                continue
            start = text.rfind("\n", 0, tokens[chord_first][1]) + 1
            end = text.find("\n", tokens[chord_last - 1][2])
            text = text[:start] + text[len(text) if end < 0 else end + 1:]
            stored = [entry for entry in custom_binds() if canonical(entry["key"]) != canonical(key)]
            if not stored:
                text = text.replace(MANAGED_COMMENT + "\n", "")
            kdl.atomic_write(USER_KEYBINDS, text)
            store_binds(stored)
            return {}
    raise ValueError(f"'{key}' has no custom shortcut to remove.")


def save(original, request):
    # Editing is remove + add; restore both files if the add is refused so a
    # rejected edit never loses the existing bind.
    snapshots = {path: path.read_text() if path.is_file() else None for path in (USER_KEYBINDS, META)}
    try:
        if original:
            try:
                remove(original)
            except (OSError, ValueError):
                pass
        return add(request["key"], request.get("title", ""),
                   request.get("flags", {}), request.get("action", ""))
    except Exception:
        for path, text in snapshots.items():
            if text is None:
                path.unlink(missing_ok=True)
            else:
                kdl.atomic_write(path, text)
        raise


DEFAULT_USER_KEYBINDS = """\
// Personal key bindings.
// Anything here applies on top of the Pond defaults in
// /usr/share/pond-interface/config/niri. This file is safe to edit by hand.

binds {
}
"""


def main():
    try:
        command = sys.argv[1]
        if command == "list":
            custom = custom_binds()
            identities = {canonical(entry["key"]) for entry in custom}
            binds = [bind | {"custom": canonical(bind["key"]) in identities} for bind in active_binds()]
            print(json.dumps({"binds": binds, "custom": custom}))
        elif command == "save":
            print(json.dumps(save(sys.argv[2], json.loads(sys.argv[3]))))
        elif command == "remove":
            print(json.dumps(remove(sys.argv[2])))
        else:
            raise ValueError("Unknown command: " + command)
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
