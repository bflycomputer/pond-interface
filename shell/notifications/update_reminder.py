import os
from datetime import datetime
from pathlib import Path
import subprocess
import time

DAY = 24 * 60 * 60


def main():
    now = time.time()
    state = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state") / "pond-interface/update-reminder"
    try:
        if 0 <= now - state.stat().st_mtime < 4 * DAY:
            return
    except FileNotFoundError:
        state.parent.mkdir(parents=True, exist_ok=True)
        state.touch()
        return

    last_upgrade = None
    full_upgrade = False
    with open("/var/log/pacman.log", errors="replace") as log:
        for line in log:
            timestamp, _, message = line.rstrip().partition("] ")
            if message.startswith("[PACMAN] Running "):
                full_upgrade = False
            elif message == "[PACMAN] starting full system upgrade":
                full_upgrade = True
            elif full_upgrade and message == "[ALPM] transaction completed":
                last_upgrade = timestamp[1:]

    if not last_upgrade or now - datetime.fromisoformat(last_upgrade).timestamp() >= 3 * DAY:
        subprocess.run([
            "busctl", "--user", "--timeout=5", "--", "call", "org.freedesktop.Notifications",
            "/org/freedesktop/Notifications", "org.freedesktop.Notifications", "Notify",
            "susssasa{sv}i", "Pond", "0", "system-software-update", "Update Pond",
            "Open a terminal and run:\nsudo pacman -Syu", "0", "0", "-1",
        ], check=True, stdout=subprocess.DEVNULL)
    state.touch()


if __name__ == "__main__":
    main()
