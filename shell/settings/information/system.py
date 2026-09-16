#!/usr/bin/env python3
"""Read-only system facts for the Information dialog (no privileged queries)."""
import json
import os
from pathlib import Path
import platform
import re
import shlex
import socket
import subprocess
import sys


def read(path):
    try:
        return Path(path).read_text().strip()
    except OSError:
        return ""


def os_name():
    values = {}
    for line in (read("/etc/os-release") or read("/usr/lib/os-release")).splitlines():
        if "=" in line and not line.startswith("#"):
            key, value = line.split("=", 1)
            try:
                values[key] = " ".join(shlex.split(value))
            except ValueError:
                pass
    return values.get("PRETTY_NAME") or values.get("NAME") or platform.system()


def cpu_name(text):
    models = re.findall(r"^(?:model name|Hardware)\s*:\s*(.+)$", text, re.M)
    model = models[0] if models else platform.machine()
    model = re.sub(r"\s+\d+-Core Processor$", "", model)
    threads = len(re.findall(r"^processor\s*:", text, re.M)) or os.cpu_count() or 1
    return f"{model} ({threads} {'Thread' if threads == 1 else 'Threads'})"


def gpu_names(pci):
    names = []
    for line in pci.splitlines():
        try:
            fields = shlex.split(line)
        except ValueError:
            continue
        if len(fields) < 4 or fields[1] not in ("VGA compatible controller", "3D controller", "Display controller"):
            continue
        # PCI databases put the marketed model in brackets after the chip name.
        model = re.findall(r"\[([^]]+)\]", fields[3])
        name = model[-1] if model else fields[3]
        if name not in names:
            names.append(name)
    return names


def gpus():
    try:
        result = subprocess.run(["lspci", "-mm"], capture_output=True, text=True, timeout=4)
        names = gpu_names(result.stdout)
        if names:
            return ", ".join(names)
    except (OSError, subprocess.TimeoutExpired):
        pass
    ids = []
    for card in sorted(Path("/sys/class/drm").glob("card[0-9]*")):
        if re.fullmatch(r"card\d+", card.name):
            vendor, device = read(card / "device/vendor"), read(card / "device/device")
            if vendor and device:
                ids.append(f"{vendor}:{device}")
    return ", ".join(dict.fromkeys(ids)) or "Unavailable"


def memory_usage(text):
    values = {key: int(value) * 1024 for key, value in re.findall(r"^(\w+):\s+(\d+)\s+kB", text, re.M)}
    total = values.get("MemTotal", 0)
    available = values.get("MemAvailable", values.get("MemFree", 0) + values.get("Buffers", 0)
                           + values.get("Cached", 0) + values.get("SReclaimable", 0) - values.get("Shmem", 0))
    if not total:
        return "Unavailable"
    used = max(0, min(total, total - available))
    return f"{used / 2**30:.1f} GiB / {total / 2**30:.1f} GiB"


def usage():
    try:
        fs = os.statvfs("/")
        total = fs.f_blocks * fs.f_frsize
        used = (fs.f_blocks - fs.f_bfree) * fs.f_frsize
        disk = f"{used / 2**30:.1f} GiB / {total / 2**30:.1f} GiB"
    except OSError:
        disk = "Unavailable"
    return {"memory": memory_usage(read("/proc/meminfo")), "disk": disk}


def snapshot():
    return {"os": os_name(), "host": socket.gethostname(),
            "board": read("/sys/class/dmi/id/board_name") or "Unavailable",
            "cpu": cpu_name(read("/proc/cpuinfo")), "gpu": gpus(), **usage()}


if __name__ == "__main__":
    print(json.dumps(usage() if sys.argv[1:] == ["--usage"] else snapshot()))
