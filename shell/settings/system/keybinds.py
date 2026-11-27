#!/usr/bin/env python3
import ctypes
import json
import os
from pathlib import Path
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from control import keyboard, layouts, run
from kdl import atomic_write, nodes, tokens

BINDS = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config')) / 'niri/cfg/keybinds.kdl'
DEFAULTS = Path('/etc/skel/.config/niri/cfg/keybinds.kdl')
NAVIGATION = {'focus-column-left', 'focus-column-right', 'focus-window-or-workspace-up', 'focus-window-or-workspace-down',
              'move-column-left', 'move-column-right', 'move-window-up-or-to-workspace-up', 'move-window-down-or-to-workspace-down',
              'move-column-to-monitor-left', 'move-column-to-monitor-right', 'move-column-to-monitor-up', 'move-column-to-monitor-down',
              'focus-monitor-left', 'focus-monitor-right', 'focus-monitor-up', 'focus-monitor-down',
              'focus-workspace', 'move-column-to-workspace'}
MODIFIERS = {'mod': 'Mod', 'super': 'Mod', 'win': 'Mod', 'ctrl': 'Ctrl', 'control': 'Ctrl', 'shift': 'Shift', 'alt': 'Alt'}


class RuleNames(ctypes.Structure):
    _fields_ = [(name, ctypes.c_char_p) for name in ('rules', 'model', 'layout', 'variant', 'options')]


def key_names():
    ids = {item['label']: item['id'] for item in layouts()}
    state = keyboard()
    chosen = [ids.get(name, 'us') for name in state['names']]
    layout, variant = zip(*(value.rstrip(')').partition('(')[::2] for value in chosen))
    xkb = ctypes.CDLL('libxkbcommon.so.0')
    xkb.xkb_context_new.restype = xkb.xkb_keymap_new_from_names.restype = ctypes.c_void_p
    xkb.xkb_keymap_new_from_names.argtypes = [ctypes.c_void_p, ctypes.POINTER(RuleNames), ctypes.c_int]
    symbols = ctypes.POINTER(ctypes.c_uint32)
    xkb.xkb_keymap_key_get_syms_by_level.argtypes = [ctypes.c_void_p] + [ctypes.c_uint32] * 3 + [ctypes.POINTER(symbols)]
    rules = RuleNames(layout=','.join(layout).encode(), variant=','.join(variant).encode())
    keymap = xkb.xkb_keymap_new_from_names(xkb.xkb_context_new(0), ctypes.byref(rules), 0)
    if not keymap: raise RuntimeError('Could not read the keyboard layout')
    current = state['current_idx']
    result = {}
    for code in range(8, 256):
        found = []
        for index in [current] + [i for i in range(len(chosen)) if i != current]:
            pointer = symbols()
            if xkb.xkb_keymap_key_get_syms_by_level(keymap, code, index, 0, ctypes.byref(pointer)) == 1: found.append(pointer[0])
        if not found: continue
        buffer = ctypes.create_string_buffer(64)
        xkb.xkb_keysym_get_name(next((s for s in found if 0x20 < s < 0x7f), found[0]), buffer, 64)
        name = buffer.value.decode()
        side = name[:-2].lower() if name.endswith(('_L', '_R')) else ''
        result[code] = MODIFIERS.get(side, name.upper() if len(name) == 1 else name)
    return result


def parse(text):
    ts = tokens(text)
    block = next((n for n in nodes(ts) if ts[n[0]][0] == 'binds' and n[2] is not None), None)
    if block is None: return ts, []
    headings = [(m.start(), m.group(1)) for m in re.finditer(r'^[ \t]*// ─{3} (.+?) ─{3}[ \t]*$', text, re.M)]
    result = []
    for first, _, opening, closing in nodes(ts, block[2] + 1, block[3], skipped=True):
        if opening is None: continue
        *modifiers, trigger = ts[first][0].split('+')
        if re.match('wheel|mouse|touchpad', trigger, re.I): continue
        title = next((json.loads(ts[i + 1][0]) for i in range(first, opening) if ts[i][0] == 'hotkey-overlay-title='), None)
        action = [t[0].strip('"') for t in ts[opening + 1:closing] if t[0] not in (';', '\n')]
        if not action: continue
        section = next((name for start, name in reversed(headings) if start < ts[first][1]), None)
        bound = ts[first - 1][0] != '/-'
        result.append({'id': len(result), 'first': first, 'section': section,
                       'listed': section is not None and action[0] not in NAVIGATION,
                       'label': title or ' '.join([action[0].replace('-', ' ').capitalize()] + action[1:]),
                       'keys': [MODIFIERS.get(m.lower(), m) for m in modifiers] + [trigger] if bound else []})
    return ts, result


def signature(keys):
    return frozenset(key.lower() for key in keys[:-1]), keys[-1].lower()


def save(text):
    previous = BINDS.read_text()
    atomic_write(BINDS, text)
    try: run('niri', 'validate')
    except Exception:
        atomic_write(BINDS, previous)
        raise RuntimeError('Niri rejected the keybinds')
    run('niri', 'msg', 'action', 'load-config-file')


def load():
    binds = parse(BINDS.read_text())[1]
    return {'binds': [{key: bind[key] for key in ('id', 'section', 'label', 'keys')} for bind in binds if bind['listed']], 'names': key_names()}


def bind(identifier, combo, force=''):
    if not re.fullmatch(r'(\w+\+)*\w+', combo): raise ValueError('Invalid shortcut')
    text = BINDS.read_text()
    ts, binds = parse(text)
    target = binds[int(identifier)]
    keys = combo.split('+')
    other = next((b for b in binds if b is not target and b['keys'] and signature(b['keys']) == signature(keys)), None)
    if other and not force: return {'conflict': other['label']}
    edits = [(target, combo)] + ([(other, '/- ' + ts[other['first']][0])] if other else [])
    for item, value in sorted(edits, key=lambda edit: -edit[0]['first']):
        first = item['first']
        start = ts[first - 1][1] if ts[first - 1][0] == '/-' else ts[first][1]
        end = ts[first + 1][1]
        text = text[:start] + value.ljust(end - start - 1) + ' ' + text[end:]
    save(text)
    return load()


def reset():
    save(DEFAULTS.read_text())
    return load()


if __name__ == '__main__':
    try:
        action, *args = sys.argv[1:]
        print(json.dumps({'load': load, 'bind': bind, 'reset': reset}[action](*args)))
    except Exception as error:
        print(json.dumps({'error': str(error)}))
        sys.exit(1)
