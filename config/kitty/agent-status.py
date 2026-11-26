import os
import subprocess
import time

URGENCY = ('idle', 'done', 'error', 'working', 'blocked')
DOTS = ('read', 'working', 'unread', 'blocked')
states = {}
unread = set()


def dot(window_id):
    state = states[window_id]
    return state if state in ('working', 'blocked') else 'unread' if window_id in unread else 'read'


def report(window, state):
    if state:
        if states.get(window.id) == 'working' and state != 'working' and not window.is_focused:
            unread.add(window.id)
        states[window.id] = state
    else:
        states.pop(window.id, None)
        unread.discard(window.id)
    subprocess.Popen(
        ['qs', '-c', 'pond-shell', 'ipc', 'call', 'agents', 'status',
         str(os.getpid()), max(map(dot, states), key=DOTS.index, default=''), repr(time.monotonic())],
        stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def on_program_status_change(boss, window, data):
    reported = [r['state'] for r in data['program_status']]
    last = states.get(window.id, '')
    report(window, max(reported, key=URGENCY.index) if reported else last if last in ('done', 'error') else '')


def on_focus_change(boss, window, data):
    if data['focused'] and window.id in unread:
        unread.discard(window.id)
        report(window, states[window.id])


def on_cmd_startstop(boss, window, data):
    if not data['is_start'] and window.id in states:
        report(window, '')


def on_close(boss, window, data):
    if window.id in states:
        report(window, '')
