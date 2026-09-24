#!/usr/bin/env python3
"""Niri display settings: advertised modes, persistent changes and draft layouts.

No custom modes. Validate under a lock, atomically save, reload and verify.
A failed transaction restores both the saved configuration and live outputs.
"""
import copy
import fcntl
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

CONFIG = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config')) / 'niri'
SCALES = (1, 1.25, 1.5, 1.75, 2)


def run(*args):
    p = subprocess.run(args, capture_output=True, text=True, timeout=15)
    if p.returncode:
        raise RuntimeError(p.stderr.strip() or p.stdout.strip() or 'Display command failed')
    return p.stdout


def outputs():
    active = {k: v for k, v in json.loads(run('niri', 'msg', '-j', 'outputs')).items() if v.get('logical')}
    for name, monitor in active.items():
        if monitor.get('current_mode') is None:
            raise ValueError(f'Cannot edit displays: the current mode for {name} is unavailable')
    return active


def mode_id(m):
    return f'{m["width"]}x{m["height"]}@{m["refresh_rate"] / 1000:.3f}'


def current_mode(m):
    return m['modes'][m['current_mode']]


def advertised_modes(m):
    return [(i, mode) for i, mode in enumerate(m['modes'])
            if not (m.get('is_custom_mode') and i == m['current_mode'])]


def logical_size(m):
    mode, logical = current_mode(m), m['logical']
    w, h = mode['width'] / logical['scale'], mode['height'] / logical['scale']
    if str(logical['transform']).lower() in ('90', '270', 'flipped90', 'flipped270'): w, h = h, w
    return w, h


def placement(m):
    # IPC sizes truncate fractions; placement must cover the entire output.
    w, h = map(math.ceil, logical_size(m))
    return dict(m['logical'], width=w, height=h)


def identity(m):
    return ' '.join(m.get(k) or 'Unknown' for k in ('make', 'model', 'serial'))


def geometry(data):
    return [{"name": k, "identity": identity(v), **placement(v)} for k, v in sorted(data.items())]


def status(data=None):
    data = outputs() if data is None else data
    monitors = []
    for name, monitor in sorted(data.items()):
        mode = current_mode(monitor)
        modes = [m for _, m in advertised_modes(monitor)]
        resolutions = sorted({(m['width'], m['height']) for m in modes},
                             key=lambda s: (-s[0] * s[1], -s[0]))
        rates = sorted({m['refresh_rate'] for m in modes
                        if (m['width'], m['height']) == (mode['width'], mode['height'])}, reverse=True)
        # Fractional scaling is a compositor capability, not an EDID mode list.
        scales = sorted(set(SCALES) | {monitor['logical']['scale']})
        monitors.append(dict(name=name, label=monitor.get('model') or monitor.get('make') or name,
            identity=identity(monitor), logical=placement(monitor), mode=mode_id(mode),
            width=mode['width'], height=mode['height'], refresh=mode['refresh_rate'],
            scale=monitor['logical']['scale'], scales=scales,
            resolutions=[dict(label=f'{w} x {h}', value=f'{w}x{h}') for w, h in resolutions],
            rates=[dict(label=f'{rate / 1000:.3f}'.rstrip('0').rstrip('.') + ' Hz', value=str(rate)) for rate in rates],
            vrrSupported=bool(monitor.get('vrr_supported')), vrrEnabled=bool(monitor.get('vrr_enabled'))))
    labels = [m['label'] for m in monitors]
    for m in monitors:
        if labels.count(m['label']) > 1: m['label'] += ' (' + m['name'] + ')'
    return dict(monitors=monitors, geometry=geometry(data))


def overlaps(a, b):
    return (a['x'] < b['x'] + b['width'] and b['x'] < a['x'] + a['width']
            and a['y'] < b['y'] + b['height'] and b['y'] < a['y'] + a['height'])


def adjacent(a, b):
    return (((a['x'] + a['width'] == b['x'] or b['x'] + b['width'] == a['x'])
             and min(a['y'] + a['height'], b['y'] + b['height']) > max(a['y'], b['y']))
            or ((a['y'] + a['height'] == b['y'] or b['y'] + b['height'] == a['y'])
                and min(a['x'] + a['width'], b['x'] + b['width']) > max(a['x'], b['x'])))


def validate_layout(rects):
    if not rects:
        raise ValueError('No connected displays')
    for i, a in enumerate(rects):
        for k in ('x', 'y', 'width', 'height'):
            if type(a[k]) is not int or abs(a[k]) > 1000000:
                raise ValueError('Invalid display coordinates')
        if a['width'] <= 0 or a['height'] <= 0:
            raise ValueError('Invalid display size')
        if any(overlaps(a, b) for b in rects[i + 1:]):
            raise ValueError('Displays cannot overlap')
    reached = {0}
    while True:
        more = {i for i, a in enumerate(rects) if any(adjacent(a, rects[j]) for j in reached)} - reached
        if not more:
            break
        reached |= more
    if len(reached) != len(rects):
        raise ValueError('Display edges must touch so the cursor can move between them')


def normalize(rects):
    minx, miny = min(r['x'] for r in rects), min(r['y'] for r in rects)
    return [dict(r, x=r['x'] - minx, y=r['y'] - miny) for r in rects]


def reflow(before, after):
    """Keep edge relationships when mode/scale changes logical display sizes."""
    old = {r['name']: r for r in geometry(before)}
    pending = geometry(after)
    placed = [pending.pop(0)]
    while pending:
        # Prefer a neighbour in the original topology (also handles 3+ outputs).
        pick = next(((i, p) for i, r in enumerate(pending) for p in placed
                     if adjacent(old[r['name']], old[p['name']])), (0, placed[0]))
        i, anchor = pick
        r = pending.pop(i)
        a, b = old[r['name']], old[anchor['name']]
        x, y = anchor['x'] + a['x'] - b['x'], anchor['y'] + a['y'] - b['y']
        if a['x'] == b['x'] + b['width']: x = anchor['x'] + anchor['width']
        elif a['x'] + a['width'] == b['x']: x = anchor['x'] - r['width']
        if a['y'] == b['y'] + b['height']: y = anchor['y'] + anchor['height']
        elif a['y'] + a['height'] == b['y']: y = anchor['y'] - r['height']
        candidates = [dict(r, x=x, y=y)]
        for p in placed:
            cy = max(p['y'] - r['height'] + 1, min(y, p['y'] + p['height'] - 1))
            cx = max(p['x'] - r['width'] + 1, min(x, p['x'] + p['width'] - 1))
            candidates += [dict(r, x=p['x'] - r['width'], y=cy), dict(r, x=p['x'] + p['width'], y=cy),
                           dict(r, x=cx, y=p['y'] - r['height']), dict(r, x=cx, y=p['y'] + p['height'])]
        valid = [c for c in candidates if not any(overlaps(c, p) for p in placed)
                 and any(adjacent(c, p) for p in placed)]
        placed.append(min(valid, key=lambda c: (c['x'] - x)**2 + (c['y'] - y)**2))
    return normalize(placed)


# A position-preserving KDL scanner. Comments/quoted strings are opaque; /-
# nodes are skipped. Only direct children of an active output are modified.
def tokens(text):
    result, i = [], 0
    while i < len(text):
        if text.startswith('//', i):
            end = text.find('\n', i); i = len(text) if end < 0 else end
        elif text.startswith('/*', i):
            depth = 1; i += 2
            while depth and i < len(text):
                if text.startswith('/*', i): depth += 1; i += 2
                elif text.startswith('*/', i): depth -= 1; i += 2
                else: i += 1
            if depth: raise ValueError('Unclosed KDL comment')
        elif text[i] in ' \t\r': i += 1
        else:
            start = i
            if text.startswith('/-', i): i += 2
            elif text[i] == '"':
                i += 1
                while i < len(text):
                    if text[i] == '\\': i += 2
                    elif text[i] == '"': i += 1; break
                    else: i += 1
            elif text[i] in '{};\n': i += 1
            else:
                while i < len(text) and not text[i].isspace() and text[i] not in '{};"': i += 1
            result.append((text[start:i], start, i))
    return result


def nodes(ts, start=0, end=None):
    end = len(ts) if end is None else end
    i = start
    while i < end:
        if ts[i][0] in ('\n', ';'): i += 1; continue
        disabled = ts[i][0] == '/-'
        if disabled: i += 1
        first = i; depth = 0; opening = closing = None
        while i < end:
            t = ts[i][0]
            if depth == 0 and t in ('\n', ';', '}'): break
            if t == '{':
                if depth == 0: opening = i
                depth += 1
            elif t == '}':
                depth -= 1
                if depth == 0: closing = i; i += 1; break
            i += 1
        if i == first: raise ValueError('Unexpected KDL token')
        if not disabled: yield first, i, opening, closing
        if i < end and ts[i][0] in ('\n', ';'): i += 1


def patch_output(text, names, changes):
    ts = tokens(text)
    matches = []
    for first, end, op, cl in nodes(ts):
        if ts[first][0] != 'output' or op is None: continue
        try: name = json.loads(ts[first + 1][0])
        except (ValueError, IndexError): continue
        if name.lower() in [n.lower() for n in names]: matches.append((op, cl))
    if len(matches) > 1: raise ValueError('Multiple matching output blocks; consolidate them before changing this display')
    if not matches:
        body = '\n'.join('    ' + v for v in changes.values() if v is not None)
        return text.rstrip() + '\n\noutput ' + json.dumps(names[0]) + ' {\n' + body + '\n}\n'
    op, cl = matches[0]
    edits, found = [], set()
    for first, end, _, _ in nodes(ts, op + 1, cl):
        key = ts[first][0]
        if key not in changes: continue
        if key in found: raise ValueError('Duplicate display setting: ' + key)
        found.add(key)
        start, stop = ts[first][1], ts[end - 1][2]
        if changes[key] is None:
            if end < cl and ts[end][0] == ';': stop = ts[end][2]
            line_start = text.rfind('\n', 0, start) + 1
            line_end = text.find('\n', stop)
            if line_end < 0: line_end = len(text)
            # Remove an otherwise empty line, but preserve trailing comments.
            if not text[line_start:start].strip() and not text[stop:line_end].strip():
                start, stop = line_start, min(line_end + 1, len(text))
        edits.append((start, stop, changes[key] or ''))
    missing = ['    ' + value + '\n' for key, value in changes.items() if key not in found and value is not None]
    if missing:
        closing = ts[cl][1]
        line_start = text.rfind('\n', 0, closing) + 1
        standalone = not text[line_start:closing].strip()
        insertion = line_start if standalone else closing
        edits.append((insertion, insertion, ('' if standalone else '\n') + ''.join(missing)))
    for start, end, value in sorted(edits, reverse=True): text = text[:start] + value + text[end:]
    return text


def atomic_write(path, text):
    with tempfile.NamedTemporaryFile(mode='w', dir=path.parent, delete=False) as f:
        temporary = Path(f.name); f.write(text); f.flush(); os.fsync(f.fileno())
    try:
        if path.exists(): temporary.chmod(path.stat().st_mode)
        os.replace(temporary, path)
    finally: temporary.unlink(missing_ok=True)


def validate_config(text):
    with tempfile.TemporaryDirectory(prefix='pond-display-validate-') as directory:
        stage = Path(directory) / 'niri'
        shutil.copytree(CONFIG, stage)
        (stage / 'cfg/display.kdl').write_text(text)
        run('niri', 'validate', '-c', str(stage / 'config.kdl'))


def command(name, *args):
    # JSON output also catches Niri's OutputWasMissing result (exit status 0).
    response = json.loads(run('niri', 'msg', '-j', 'output', name, *args))
    if 'OutputWasMissing' in json.dumps(response): raise RuntimeError('Display disconnected before the change was applied')


def same_settings(actual, wanted):
    if set(actual) != set(wanted): return False
    for name, m in wanted.items():
        a = actual[name]
        if identity(a) != identity(m) or mode_id(current_mode(a)) != mode_id(current_mode(m)): return False
        if a.get('vrr_enabled') != m.get('vrr_enabled'): return False
        if any(a['logical'][k] != m['logical'][k] for k in ('x', 'y', 'width', 'height', 'scale', 'transform')): return False
    return True


def wait_for(wanted):
    for _ in range(30):
        actual = outputs()
        if same_settings(actual, wanted): return actual
        time.sleep(.1)
    raise RuntimeError('The compositor did not accept the requested display settings')


def set_positions(rects):
    # First move outputs apart to avoid Niri's overlap fallback during a swap.
    for i, r in enumerate(rects): command(r['name'], 'position', 'set', str(100000 + i * 20000), '100000')
    for r in rects: command(r['name'], 'position', 'set', '--', str(r['x']), str(r['y']))


def reload_config():
    run("niri", "msg", "action", "load-config-file")


def restore(before):
    live = outputs()
    if same_settings(live, before): return
    for name, m in before.items():
        if name not in live or identity(live[name]) != identity(m): continue
        if mode_id(current_mode(live[name])) != mode_id(current_mode(m)): command(name, 'mode', mode_id(current_mode(m)))
        if live[name]['logical']['scale'] != m['logical']['scale']: command(name, 'scale', str(m['logical']['scale']))
        if live[name].get('vrr_enabled') != m.get('vrr_enabled'): command(name, 'vrr', 'on' if m.get('vrr_enabled') else 'off')
    rects = [r for r in geometry(before) if r['name'] in live and r['identity'] == identity(live[r['name']])]
    if rects: set_positions(rects)


def apply(action, name='', value='', expected_identity=''):
    path = CONFIG / 'cfg/display.kdl'
    with (CONFIG / '.pond-display.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        before = outputs()
        wanted = copy.deepcopy(before)
        changes = {}
        if action == 'arrange':
            request = json.loads(name)
            if request['baseline'] != geometry(before): raise ValueError('Displays changed. Reopen Arrange and try again.')
            positions = request['positions']
            if len(positions) != len(before) or {p['name'] for p in positions} != set(before): raise ValueError('Displays changed. Reopen Arrange and try again.')
            rects = [dict(r, x=next(p['x'] for p in positions if p['name'] == r['name']),
                          y=next(p['y'] for p in positions if p['name'] == r['name'])) for r in geometry(before)]
            rects = normalize(rects)
        else:
            if name not in before: raise ValueError('Display is no longer connected')
            if expected_identity and identity(before[name]) != expected_identity: raise ValueError('The selected display changed. Please select it again.')
            m = wanted[name]
            if action == 'scale':
                scale = float(value)
                if not math.isfinite(scale) or scale not in set(SCALES) | {m['logical']['scale']}: raise ValueError('Unsupported display scale')
                m['logical']['scale'] = scale
                changes[name] = {'scale': f'scale {scale:g}'}
            elif action in ('resolution', 'refresh'):
                mode = current_mode(m)
                candidates = [(i, x) for i, x in advertised_modes(m) if (f'{x["width"]}x{x["height"]}' == value if action == 'resolution'
                              else x['width'] == mode['width'] and x['height'] == mode['height'] and str(x['refresh_rate']) == value)]
                if not candidates: raise ValueError('This display does not advertise that mode')
                index, selected = min(candidates, key=lambda entry: abs(entry[1]['refresh_rate'] - mode['refresh_rate']))
                m['current_mode'] = index
                m['is_custom_mode'] = False
                changes[name] = {'mode': 'mode ' + json.dumps(mode_id(selected)), 'modeline': None}
            elif action == 'vrr':
                if not m.get('vrr_supported') or value not in ('on', 'off'): raise ValueError('Adaptive sync is unavailable on this display')
                m['vrr_enabled'] = value == 'on'
                changes[name] = {'variable-refresh-rate': 'variable-refresh-rate' if value == 'on' else None}
            else: raise ValueError('Unknown display action')
            w, h = map(int, logical_size(m))
            m['logical'].update(width=w, height=h)
            rects = reflow(before, wanted) if action in ('scale', 'resolution') else geometry(before)
        if action not in ('refresh', 'vrr'): validate_layout(rects)
        for r in rects:
            wanted[r['name']]['logical'].update(x=r['x'], y=r['y'])
            changes.setdefault(r['name'], {})['position'] = f'position x={r["x"]} y={r["y"]}'
        previous = path.read_text()
        updated = previous
        for output, props in changes.items(): updated = patch_output(updated, [output, identity(before[output])], props)
        validate_config(updated)
        # Validation and EDID discovery precede every live mutation.
        if geometry(outputs()) != geometry(before): raise ValueError('Displays changed. Please try again.')
        saved = False
        try:
            if path.read_text() != previous: raise RuntimeError('Display configuration changed elsewhere. Please try again.')
            atomic_write(path, updated); saved = True
            # Niri's explicit reload applies the whole layout together. Saving
            # before reload also prevents a delayed watcher event from reverting
            # a newer IPC-only mode change to the previous saved mode.
            reload_config()
            result = wait_for(wanted)
            return status(result)
        except Exception as error:
            try:
                if saved and path.read_text() == updated:
                    atomic_write(path, previous)
                    reload_config()
                    time.sleep(.2)
                    restore(before)
                    wait_for(before)
            except Exception as rollback: raise RuntimeError(f'{error}; could not fully restore displays: {rollback}') from error
            raise



def main():
    try:
        action, *args = sys.argv[1:]
        result = status() if action == 'status' else apply(action, *args)
        print(json.dumps(result))
    except Exception as error:
        print(json.dumps({'error': str(error)})); sys.exit(1)


if __name__ == '__main__': main()
