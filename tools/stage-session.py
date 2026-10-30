#!/usr/bin/env python3
"""Install a build into a user prefix and configure its Quickshell module search path."""
import argparse
from pathlib import Path
import shutil
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('build', type=Path)
parser.add_argument('prefix', type=Path)
args = parser.parse_args()
prefix = args.prefix.resolve()
if prefix == Path('/usr') or prefix == Path('/'):
    parser.error('For system installation use cmake --install directly')
if prefix.exists() and any(prefix.iterdir()):
    parser.error('Choose a new, empty release directory to preserve rollback')
cmake = shutil.which('cmake')
if not cmake:
    parser.error('cmake must be on PATH')
subprocess.run([cmake, '--install', str(args.build.resolve()), '--prefix', str(prefix)], check=True)
module_path = str(prefix / 'lib/qt6/qml')
for relative in ['shell/shell.qml', 'lockscreen/shell.qml']:
    path = prefix / 'share/pond-interface' / relative
    path.write_text('//@ pragma Env QML_IMPORT_PATH = ' + module_path + '\n' + path.read_text())
print(f'Staged: {prefix}')
print(f'Test shell: qs -p {prefix / "share/pond-interface/shell"}')
print('The active configuration has not been changed.')
