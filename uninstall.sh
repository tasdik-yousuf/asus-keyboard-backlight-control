#!/usr/bin/env bash
# Removes kbd-backlight-idle. Run with sudo.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run this with sudo: sudo ./uninstall.sh" >&2
    exit 1
fi

systemctl disable --now kbd-backlight-idle 2>/dev/null || true
rm -f /etc/systemd/system/kbd-backlight-idle.service
systemctl daemon-reload

rm -f /usr/local/bin/kbd-backlight-idle
rm -rf /run/kbd-backlight-idle

read -r -p "Also remove /etc/kbd-backlight-idle.conf? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    rm -f /etc/kbd-backlight-idle.conf
fi

echo "Uninstalled."
