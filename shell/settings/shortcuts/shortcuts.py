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
# niri has no unbind: a chord moved away from a read-only Pond default is
# parked on a no-op that the hotkey overlay and this page both hide.
PARKED = 'spawn-sh "true";'


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
    return [bind for bind in binds.values() if bind["action"] != PARKED]


def check_free(key, ignore=""):
    if not canonical(key):
        raise ValueError(f"'{key}' is not a valid niri chord.")
    for bind in active_binds():
        identity = canonical(bind["key"])
        if identity == canonical(key) and identity != canonical(ignore):
            verb = bind["action"].rstrip(";").split(" ")[0]
            label = bind["title"] or " ".join(word.capitalize() for word in verb.split("-"))
            raise ValueError(f"{key} is already used by {label or 'another shortcut'}.")


def user_text():
    return USER_KEYBINDS.read_text() if USER_KEYBINDS.is_file() else DEFAULT_USER_KEYBINDS


def user_chords(text):
    # (chord node, line start, line end) for every bind in the personal file.
    tokens = kdl.tokens(text)
    for first, _, opening, closing in kdl.nodes(tokens):
        if tokens[first][0] != "binds" or opening is None or closing is None:
            continue
        for chord_first, chord_last, _, _ in kdl.nodes(tokens, opening + 1, closing):
            start = text.rfind("\n", 0, tokens[chord_first][1]) + 1
            end = text.find("\n", tokens[chord_last - 1][2])
            yield tokens[chord_first], start, len(text) if end < 0 else end + 1


def drop_line(text, key):
    for token, start, end in user_chords(text):
        if canonical(token[0]) == canonical(key):
            text = text[:start] + text[end:]
            # The managed header goes once its section is empty.
            return text.replace(MANAGED_COMMENT + "\n}", "}"), True
    return text, False


def append_line(text, line):
    tokens = kdl.tokens(text)
    closing = next((tokens[closing][1] for first, _, opening, closing in kdl.nodes(tokens)
                    if tokens[first][0] == "binds" and opening is not None and closing is not None), None)
    if closing is None:
        raise ValueError("No binds block in " + str(USER_KEYBINDS) + ".")
    insert = "" if MANAGED_COMMENT in text else MANAGED_COMMENT + "\n"
    head = "\n" if closing > 0 and text[closing - 1] != "\n" else ""
    return text[:closing] + head + insert + line + "\n" + text[closing:]


def write_user(text):
    USER_KEYBINDS.parent.mkdir(parents=True, exist_ok=True)
    kdl.atomic_write(USER_KEYBINDS, text)


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
    check_free(key)
    entry = {"key": key, "title": title, "flags": flags or {"repeat": False}, "action": action}
    text, _ = drop_line(user_text(), key)  # a parked chord is free to reuse
    write_user(append_line(text, format_bind(**entry)))
    stored = [value for value in custom_binds() if canonical(value["key"]) != canonical(key)]
    stored.append(entry)
    store_binds(stored)
    return entry


def remove(key):
    text, found = drop_line(user_text(), key)
    if not found:
        raise ValueError(f"'{key}' has no custom shortcut to remove.")
    write_user(text)
    store_binds([entry for entry in custom_binds() if canonical(entry["key"]) != canonical(key)])
    return {}


def rebind(old, new):
    # Moves any active bind to a new chord, keeping its action and flags.
    bind = next((bind for bind in active_binds() if canonical(bind["key"]) == canonical(old)), None)
    if bind is None:
        raise ValueError(f"'{old}' is not bound.")
    if canonical(new) == canonical(old):
        return bind
    check_free(new, old)
    text, _ = drop_line(user_text(), new)
    if bind["personal"]:
        # Rewrite the chord in place so hand-written lines keep their spot.
        token = next(token for token, _, _ in user_chords(text) if canonical(token[0]) == canonical(old))
        text = text[:token[1]] + new + text[token[2]:]
    else:
        text = append_line(text, format_bind(new, bind["title"], bind["flags"], bind["action"]))
    write_user(text)
    # A read-only default (or one the personal line was shadowing) would
    # take the old chord back; park it.
    if any(canonical(other["key"]) == canonical(old) for other in active_binds()):
        write_user(append_line(user_text(), "    " + old + " hotkey-overlay-title=null { " + PARKED + " }"))
    stored = custom_binds()
    for entry in stored:
        if canonical(entry["key"]) == canonical(old):
            entry["key"] = new
    store_binds(stored)
    return bind | {"key": new}


def transaction(change):
    # Every write restores both files if any step is refused, so a rejected
    # edit never loses the existing bind.
    snapshots = {path: path.read_text() if path.is_file() else None for path in (USER_KEYBINDS, META)}
    try:
        return change()
    except Exception:
        for path, text in snapshots.items():
            if text is None:
                path.unlink(missing_ok=True)
            else:
                kdl.atomic_write(path, text)
        raise


def save(original, request):
    if original:
        try:
            remove(original)
        except (OSError, ValueError):
            pass
    return add(request["key"], request.get("title", ""),
               request.get("flags", {}), request.get("action", ""))


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
            print(json.dumps(transaction(lambda: save(sys.argv[2], json.loads(sys.argv[3])))))
        elif command == "rebind":
            print(json.dumps(transaction(lambda: rebind(sys.argv[2], sys.argv[3]))))
        elif command == "remove":
            print(json.dumps(transaction(lambda: remove(sys.argv[2]))))
        else:
            raise ValueError("Unknown command: " + command)
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
