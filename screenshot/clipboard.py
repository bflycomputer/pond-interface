"""Transfer Niri's completed PNG to/from the screenshot preview."""

import base64
from pathlib import Path
import subprocess
import sys


def main():
    action = sys.argv[1]
    if action == "read":
        path = sys.argv[2] if len(sys.argv) > 2 else ""
        png = Path(path).read_bytes() if path else subprocess.run(
            ["wl-paste", "--no-newline", "--type", "image/png"],
            check=True, capture_output=True, timeout=5,
        ).stdout
    elif action == "copy":
        png = base64.b64decode(sys.stdin.buffer.read(), validate=True)
    else:
        raise ValueError("Unknown clipboard action")

    if not png.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("Screenshot is not a PNG")
    if action == "read":
        print(base64.b64encode(png).decode("ascii"))
    else:
        subprocess.run(["wl-copy", "--type", "image/png"], input=png,
                       check=True, timeout=5)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"Screenshot preview: {error}", file=sys.stderr)
        sys.exit(1)
