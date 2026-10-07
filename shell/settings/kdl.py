import json
import os
from pathlib import Path
import tempfile
import textwrap


# A position-preserving KDL scanner. Comments/quoted strings are opaque; /-
# nodes are skipped.
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


def atomic_write(path, text):
    with tempfile.NamedTemporaryFile(mode='w', dir=path.parent, delete=False) as f:
        temporary = Path(f.name); f.write(text); f.flush(); os.fsync(f.fileno())
    try:
        if path.exists(): temporary.chmod(path.stat().st_mode)
        os.replace(temporary, path)
    finally: temporary.unlink(missing_ok=True)


def insert_child(text, brace, body):
    if brace is None: return text.rstrip() + '\n\n' + body if text.strip() else body
    line = text.rfind('\n', 0, brace) + 1
    indent = text[line:brace]
    if indent.strip(): return text[:brace] + '\n' + textwrap.indent(body, '    ') + text[brace:]
    return text[:line] + textwrap.indent(body, indent + '    ') + text[line:]


def set_properties(text, path, properties):
    ts, opening, closing = tokens(text), -1, None
    for depth, name in enumerate(path):
        block = next((n for n in nodes(ts, opening + 1, closing) if ts[n[0]][0] == name and n[2] is not None), None)
        if block is None:
            body = ''.join(f'{key} {json.dumps(value)}\n' for key, value in properties.items())
            for parent in reversed(path[depth:]): body = f'{parent} {{\n{textwrap.indent(body, "    ")}}}\n'
            return insert_child(text, None if closing is None else ts[closing][1], body)
        _, _, opening, closing = block
    children = [(first, last) for first, last, _, _ in nodes(ts, opening + 1, closing) if ts[first][0] in properties]
    found = {ts[first][0] for first, _ in children}
    body = ''.join(f'{key} {json.dumps(value)}\n' for key, value in properties.items() if key not in found)
    if body: text = insert_child(text, ts[closing][1], body)
    for first, last in reversed(children):
        key = ts[first][0]
        text = text[:ts[first][1]] + f'{key} {json.dumps(properties[key])}' + text[ts[last - 1][2]:]
    return text
