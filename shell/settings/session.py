#!/usr/bin/env python3
"""Run session actions, using Pond's confirmed session lock before suspend."""
from pathlib import Path
import subprocess
import sys
import time


def run(action):
    if action in ('reboot', 'shutdown'):
        subprocess.run(['systemctl', 'reboot' if action == 'reboot' else 'poweroff'], check=True)
        return
    if action not in ('lock', 'suspend'):
        raise ValueError('Unsupported session action')
    method = 'lock' if action == 'lock' else 'lockAndSuspend'
    installed = Path('/usr/share/pond-interface/lockscreen')
    local = Path(__file__).resolve().parents[2] / 'lockscreen'
    # Reuse an existing installed or source instance before starting one.
    paths = list(dict.fromkeys((installed, local)))
    for path in paths:
        result = subprocess.run(['qs', '-p', str(path), 'ipc', 'call', 'lockscreen', method],
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if result.returncode == 0:
            return
    path = installed if installed.is_dir() else local
    subprocess.run(['qs', '-d', '-p', str(path)], check=True)
    if action == 'lock':
        return
    for _ in range(30):
        result = subprocess.run(['qs', '-p', str(path), 'ipc', 'call', 'lockscreen', method],
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if result.returncode == 0:
            return
        time.sleep(0.1)
    raise RuntimeError('Pond lockscreen did not start; refusing to suspend')


if __name__ == '__main__':
    run(sys.argv[1])
