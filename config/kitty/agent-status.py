import os
import subprocess
import time

URGENCY = ('idle', 'working', 'done', 'error', 'blocked')
states = {}


def report(window, state):
    if state:
        states[window.id] = state
    else:
        states.pop(window.id, None)
    subprocess.Popen(
        ['qs', '-c', 'pond-shell', 'ipc', 'call', 'agents', 'status',
         str(os.getpid()), max(states.values(), key=URGENCY.index, default=''), repr(time.monotonic())],
        stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def on_program_status_change(boss, window, data):
    reported = [r['state'] for r in data['program_status']]
    last = states.get(window.id, '')
    report(window, max(reported, key=URGENCY.index) if reported else last if last in ('done', 'error') else '')


def on_cmd_startstop(boss, window, data):
    if not data['is_start'] and window.id in states:
        report(window, '')


def on_close(boss, window, data):
    if window.id in states:
        report(window, '')
