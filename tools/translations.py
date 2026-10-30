#!/usr/bin/env python3
"""Validate Pond's editable JSON translation catalogs (Python standard library)."""
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
CATALOGS = ROOT / 'translations'
MESSAGE_ID = re.compile(r'''["']((?:pond|wifi|localization|hardware|settings|time|notifications|displays)\.[a-z0-9_]+)["']''')
PLACEHOLDER = re.compile(r'%(?:L?n|L?\d+)')


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f'duplicate key: {key}')
        result[key] = value
    return result


def validate():
    catalogs = {}
    errors = []
    for path in sorted(CATALOGS.glob('*.json')):
        try:
            catalog = json.loads(path.read_text(encoding='utf-8'), object_pairs_hook=unique_object)
            if not isinstance(catalog, dict):
                raise ValueError('catalog must be an object of message IDs')
            catalogs[path.stem] = catalog
        except (ValueError, OSError) as error:
            errors.append(f'{path.name}: {error}')
    for language in ('en', 'fr'):
        if language not in catalogs:
            errors.append(f'Missing readable {language}.json catalog')

    english = catalogs.get('en', {})
    sources = set()
    for directory in ('shell', 'screenshot', 'lockscreen', 'localization'):
        for path in (ROOT / directory).rglob('*'):
            if path.suffix in ('.qml', '.py', '.cpp', '.h'):
                sources.update(key for key in MESSAGE_ID.findall(path.read_text(encoding='utf-8'))
                               if not key.endswith(('.svg', '.qml', '.py')))
    for key in sorted(sources - english.keys()):
        errors.append(f'Missing English message: {key}')

    for language, catalog in catalogs.items():
        if language in ('en', 'fr'):
            for key in sorted(english.keys() - catalog.keys()):
                errors.append(f'{language}: missing message: {key}')
        for key, value in catalog.items():
            if not re.fullmatch(r'[a-z][a-z0-9_]*(?:\.[a-z0-9_]+)+', key):
                errors.append(f'{language}: invalid message ID: {key}')
            if key not in english:
                errors.append(f'{language}: unknown message: {key}')
            source = english.get(key)
            if isinstance(value, str):
                forms = [value]
            elif isinstance(value, dict) and set(value) == {'one', 'other'}:
                forms = list(value.values())
            else:
                errors.append(f'{language}: {key}: use a string or one/other strings')
                continue
            if isinstance(source, dict) != isinstance(value, dict):
                errors.append(f'{language}: {key}: plural shape differs from English')
            reference = source.get('other') if isinstance(source, dict) else source
            tokens = set(PLACEHOLDER.findall(reference)) if isinstance(reference, str) else set()
            for text in forms:
                if not isinstance(text, str) or not text:
                    errors.append(f'{language}: {key}: text must be a nonempty string')
                elif set(PLACEHOLDER.findall(text)) != tokens:
                    errors.append(f'{language}: {key}: mismatched placeholders')
            if isinstance(value, dict) and not ({'%n', '%Ln'} & tokens):
                errors.append(f'{language}: {key}: plural message needs %n or %Ln')
    if errors:
        raise SystemExit('\n'.join(errors))
    print(f'Validated {len(catalogs)} catalogs and {len(sources)} referenced message IDs')


if __name__ == '__main__':
    validate()
