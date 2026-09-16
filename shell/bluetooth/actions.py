#!/usr/bin/python3
"""BlueZ actions and an application-local pairing agent; JSON lines on stdio.

Device observations stay in Quickshell.Bluetooth. Registering this agent (never
as default) makes only pairing initiated by this connection use our prompts.
"""
import json
import os
import re
import sys
from gi.repository import Gio, GLib

AGENT_PATH = '/org/pond/BluetoothAgent'
DEVICE_PATH = re.compile(r'^/org/bluez/hci\d+/dev_(?:[0-9A-Fa-f]{2}_){5}[0-9A-Fa-f]{2}$')
ADAPTER_PATH = re.compile(r'^/org/bluez/hci\d+$')
AGENT_XML = '''<node><interface name="org.bluez.Agent1">
<method name="Release"/><method name="Cancel"/>
<method name="RequestPinCode"><arg type="o" direction="in"/><arg type="s" direction="out"/></method>
<method name="RequestPasskey"><arg type="o" direction="in"/><arg type="u" direction="out"/></method>
<method name="DisplayPinCode"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
<method name="DisplayPasskey"><arg type="o" direction="in"/><arg type="u" direction="in"/><arg type="q" direction="in"/></method>
<method name="RequestConfirmation"><arg type="o" direction="in"/><arg type="u" direction="in"/></method>
<method name="RequestAuthorization"><arg type="o" direction="in"/></method>
<method name="AuthorizeService"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
</interface></node>'''


def emit(**message):
    print(json.dumps(message), flush=True)


class Actions:
    def __init__(self, bus):
        self.bus = bus
        self.registered = False
        self.bluez_owner = ""
        self.pair_job = None
        self.prompt = None
        self.prompt_serial = 0
        self.buffer = b''
        self.loop = GLib.MainLoop()
        self.registration = bus.register_object(
            AGENT_PATH, Gio.DBusNodeInfo.new_for_xml(AGENT_XML).interfaces[0],
            self.agent_call, None, None)

    def bluez_appeared(self, connection, name, owner):
        self.bluez_owner = owner

    def bluez_vanished(self, connection, name):
        self.bluez_owner = ""
        self.registered = False
        if self.pair_job:
            self.result(self.pair_job, 'Bluetooth service stopped')

    def call(self, path, interface, method, args, done, timeout=45000):
        def finished(connection, result):
            try:
                value = connection.call_finish(result)
            except GLib.Error as error:
                done(None, error)
            else:
                done(value.unpack() if value else (), None)
        self.bus.call('org.bluez', path, interface, method, args, None,
                      Gio.DBusCallFlags.NONE, timeout, None, finished)

    def result(self, job, error=None):
        if self.pair_job is job:
            self.clear_prompt()
            self.pair_job = None
        emit(event='result', id=job['id'], path=job['path'], action=job['action'],
             success=error is None, error=str(error or ''))

    def clear_prompt(self):
        if self.prompt:
            self.prompt[2].return_dbus_error('org.bluez.Error.Canceled', 'Pairing canceled')
            self.prompt = None
        emit(event='prompt', kind='')

    def agent_call(self, connection, sender, path, interface, method, parameters, invocation):
        if not self.bluez_owner or sender != self.bluez_owner:
            invocation.return_dbus_error('org.bluez.Error.Rejected', 'Only BlueZ may request pairing')
            return
        args = parameters.unpack()
        if method in ('Release', 'Cancel'):
            if method == 'Release':
                self.registered = False
            self.clear_prompt()
            invocation.return_value(None)
            return
        if not self.pair_job or args[0] != self.pair_job['path']:
            invocation.return_dbus_error('org.bluez.Error.Rejected', 'No matching pairing request')
            return
        if method == 'AuthorizeService':
            # Only the device explicitly selected in this pending pairing flow.
            invocation.return_value(None)
            return
        self.clear_prompt()
        self.prompt_serial += 1
        kind = {'RequestPinCode': 'pin', 'RequestPasskey': 'passkey',
                'DisplayPinCode': 'display', 'DisplayPasskey': 'display',
                'RequestConfirmation': 'confirm', 'RequestAuthorization': 'authorize'}[method]
        code = str(args[1]).zfill(6) if len(args) > 1 else ''
        if method in ('DisplayPinCode', 'DisplayPasskey'):
            invocation.return_value(None)
        else:
            self.prompt = (self.prompt_serial, kind, invocation)
        emit(event='prompt', id=self.prompt_serial, kind=kind,
             path=args[0], code=code, entered=int(args[2]) if len(args) > 2 else 0)

    def answer(self, message):
        if not self.prompt or message.get('promptId') != self.prompt[0]:
            return
        serial, kind, invocation = self.prompt
        value = str(message.get('value', ''))
        if message.get('accept'):
            if kind == 'passkey' and not re.fullmatch(r'\d{1,6}', value):
                return
            if kind == 'pin' and not 1 <= len(value) <= 16:
                return
        self.prompt = None
        if not message.get('accept'):
            invocation.return_dbus_error('org.bluez.Error.Rejected', 'Pairing rejected')
        elif kind == 'pin':
            invocation.return_value(GLib.Variant('(s)', (value,)))
        elif kind == 'passkey':
            invocation.return_value(GLib.Variant('(u)', (int(value),)))
        else:
            invocation.return_value(None)
        emit(event='prompt', kind='')

    def pair(self, job):
        if self.pair_job:
            self.result(job, 'Another device is already pairing')
            return
        self.pair_job = job
        def paired(value, error):
            if self.pair_job is not job:
                return
            if error and 'AlreadyExists' not in str(error):
                self.result(job, error)
                return
            self.clear_prompt()
            self.call(job['path'], 'org.freedesktop.DBus.Properties', 'Set',
                      GLib.Variant('(ssv)', ('org.bluez.Device1', 'Trusted', GLib.Variant('b', True))),
                      lambda value, error: self.result(job, error) if error else self.connect(job))
        def registered(value, error):
            if self.pair_job is not job:
                return
            if error and 'AlreadyExists' not in str(error):
                self.result(job, error)
                return
            self.registered = True
            self.call(job['path'], 'org.bluez.Device1', 'Pair', None, paired, 90000)
        if self.registered:
            registered(None, None)
        else:
            self.call('/org/bluez', 'org.bluez.AgentManager1', 'RegisterAgent',
                      GLib.Variant('(os)', (AGENT_PATH, 'KeyboardDisplay')), registered)

    def connect(self, job):
        self.call(job['path'], 'org.bluez.Device1', 'Connect', None,
                  lambda value, error: self.result(job, error))

    def command(self, job):
        action = job.get('action')
        if action == 'answer':
            self.answer(job)
            return
        if action == 'cancel':
            if self.pair_job:
                pending = self.pair_job
                self.clear_prompt()
                self.pair_job = None
                self.call(pending['path'], 'org.bluez.Device1', 'CancelPairing', None,
                          lambda value, error: None)
                self.result(pending, 'Pairing canceled')
            return
        path = job.get('path', '')
        if not isinstance(job.get('id'), int):
            return
        if action in ('power', 'scan-start', 'scan-stop'):
            if not ADAPTER_PATH.fullmatch(path):
                self.result(job, 'Bluetooth adapter unavailable')
                return
            if action == 'power':
                self.call(path, 'org.freedesktop.DBus.Properties', 'Set',
                          GLib.Variant('(ssv)', ('org.bluez.Adapter1', 'Powered',
                                               GLib.Variant('b', bool(job.get('enabled'))))),
                          lambda value, error: self.result(job, error))
            else:
                self.call(path, 'org.bluez.Adapter1',
                          'StartDiscovery' if action == 'scan-start' else 'StopDiscovery', None,
                          lambda value, error: self.result(job, error))
        elif not DEVICE_PATH.fullmatch(path):
            self.result(job, 'Bluetooth device unavailable')
        elif action == 'pair':
            self.pair(job)
        elif action == 'connect':
            self.connect(job)
        elif action == 'disconnect':
            self.call(path, 'org.bluez.Device1', 'Disconnect', None,
                      lambda value, error: self.result(job, error))
        elif action == 'forget':
            self.call(path.rsplit('/', 1)[0], 'org.bluez.Adapter1', 'RemoveDevice',
                      GLib.Variant('(o)', (path,)), lambda value, error: self.result(job, error))
        else:
            self.result(job, 'Unsupported Bluetooth action')

    def read_input(self, fd, condition):
        data = os.read(fd, 65536)
        if not data:
            self.command({'action': 'cancel'})
            self.loop.quit()
            return False
        self.buffer += data
        while b'\n' in self.buffer:
            line, self.buffer = self.buffer.split(b'\n', 1)
            try:
                self.command(json.loads(line))
            except (ValueError, TypeError, KeyError) as error:
                emit(event='error', error=str(error))
        return True

    def run(self):
        Gio.bus_watch_name_on_connection(self.bus, 'org.bluez', Gio.BusNameWatcherFlags.NONE,
                                        self.bluez_appeared, self.bluez_vanished)
        GLib.io_add_watch(sys.stdin.fileno(), GLib.IO_IN | GLib.IO_HUP, self.read_input)
        emit(event='ready')
        self.loop.run()


if __name__ == '__main__':
    Actions(Gio.bus_get_sync(Gio.BusType.SYSTEM, None)).run()
