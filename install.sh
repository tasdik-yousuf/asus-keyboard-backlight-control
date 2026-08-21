#!/usr/bin/env bash

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run this with sudo: sudo ./install.sh" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Checking dependencies..."
for dep in brightnessctl evtest libinput; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "Missing dependency: $dep (install with your package manager, e.g. sudo apt install $dep)" >&2
        exit 1
    fi
done

install -Dm755 "$SCRIPT_DIR/bin/kbd-backlight-idle" /usr/local/bin/kbd-backlight-idle

if [[ -f /etc/kbd-backlight-idle.conf ]]; then
    echo "Existing /etc/kbd-backlight-idle.conf found, leaving it as-is."
else
    install -Dm644 "$SCRIPT_DIR/config/kbd-backlight-idle.conf" /etc/kbd-backlight-idle.conf
    echo "Installed config to /etc/kbd-backlight-idle.conf"
fi

install -Dm644 "$SCRIPT_DIR/systemd/kbd-backlight-idle.service" /etc/systemd/system/kbd-backlight-idle.service
systemctl daemon-reload

echo
echo "Installed. Check /etc/kbd-backlight-idle.conf (DEVICE especially — verify with 'brightnessctl -l')."
echo
echo "Run once in the foreground to test:"
echo "  sudo kbd-backlight-idle"
echo
echo "Or run persistently via systemd:"
echo "  sudo systemctl enable --now kbd-backlight-idle"
