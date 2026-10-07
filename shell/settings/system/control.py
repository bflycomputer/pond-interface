#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

from PyQt6.QtCore import QDateTime, QLocale, QTimeZone

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from kdl import atomic_write, set_properties

INPUT = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config')) / 'niri/cfg/input.kdl'
ENGLISH = QLocale('en_US')


def run(*args, timeout=15):
    p = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    if p.returncode: raise RuntimeError(p.stderr.strip() or 'Could not change system settings')
    return p.stdout


def languages():
    result = []
    for layout in ET.parse('/usr/share/X11/xkb/rules/evdev.xml').iterfind('layoutList/layout'):
        name = layout.findtext('configItem/name')
        if name == 'custom': continue
        result.append({'id': name, 'label': layout.findtext('configItem/description')})
    return sorted(result, key=lambda item: item['label'].casefold())


def keyboard():
    return json.loads(run('niri', 'msg', '-j', 'keyboard-layouts'))


def zone(identifier, now):
    tz = QTimeZone(identifier.encode())
    offset = tz.offsetFromUtc(now)
    label = tz.displayName(now, QTimeZone.NameType.LongName, ENGLISH)
    return {'id': identifier, 'label': label, 'minutes': offset // 60,
            'offset': f'GMT{"-" if offset < 0 else "+"}{abs(offset) // 3600:02}:{abs(offset) // 60 % 60:02}',
            'search': label + ' ' + tz.abbreviation(now)}


def timezones(current):
    with open('/usr/share/zoneinfo/zone.tab') as table:
        identifiers = sorted(line.split('\t')[2].strip() for line in table if not line.startswith('#'))
    now = QDateTime.currentDateTimeUtc()
    groups = {}
    for i in [current, 'UTC', *identifiers]:
        z = zone(i, now)
        groups.setdefault((z['label'], z['minutes'], QTimeZone(i.encode()).offsetFromUtc(now.addMonths(6))), z)
    labels = [z['label'] for z in groups.values()]
    for z in groups.values():
        if labels.count(z['label']) > 1: z['label'] += ' – ' + z['id'].rpartition('/')[2].replace('_', ' ')
    return sorted(groups.values(), key=lambda z: (z['minutes'], z['label']))


def status():
    ids = {item['label']: item['id'] for item in languages()}
    names = keyboard()['names']
    timezone = bytes(QTimeZone.systemTimeZoneId()).decode()
    return {'selectedLanguages': [ids.get(name, name) for name in names], 'languageNames': names,
            'timezone': timezone, 'timezoneLabel': zone(timezone, QDateTime.currentDateTimeUtc())['label']}


def load():
    result = status()
    return dict(result, languages=languages(), timezones=timezones(result['timezone']))


def apply_languages(text, names):
    atomic_write(INPUT, text)
    run('niri', 'msg', 'action', 'load-config-file')
    for _ in range(30):
        if keyboard()['names'] == names: return
        time.sleep(.1)
    raise RuntimeError('Niri did not apply the keyboard languages')


def toggle_language(identifier):
    catalog = languages()
    labels = {item['id']: item['label'] for item in catalog}
    ids = {item['label']: item['id'] for item in catalog}
    current = keyboard()
    unknown = [name for name in current['names'] if name not in ids]
    if unknown: raise ValueError('Unknown keyboard language: ' + unknown[0])
    if identifier not in labels: raise ValueError('Unknown keyboard language')
    chosen = [ids[name] for name in current['names']]
    if identifier in chosen: chosen.remove(identifier)
    else: chosen.append(identifier)
    if not chosen: raise ValueError('Keep at least one keyboard language')
    names = [labels[value] for value in chosen]
    previous = INPUT.read_text()
    try: apply_languages(set_properties(previous, ('input', 'keyboard', 'xkb'),
                                        {'layout': ','.join(chosen), 'variant': ',' * (len(chosen) - 1)}), names)
    except Exception:
        apply_languages(previous, current['names'])
        raise
    active = current['names'][current['current_idx']]
    if active in names: run('niri', 'msg', 'action', 'switch-layout', str(names.index(active)))
    return status()


def set_timezone(identifier):
    run('sudo', '-n', '/usr/bin/timedatectl', 'set-timezone', identifier)
    return status()


if __name__ == '__main__':
    try:
        action, *args = sys.argv[1:]
        print(json.dumps({'load': load, 'keyboard': toggle_language, 'timezone': set_timezone}[action](*args)))
    except Exception as error:
        print(json.dumps({'error': str(error)}))
        sys.exit(1)
