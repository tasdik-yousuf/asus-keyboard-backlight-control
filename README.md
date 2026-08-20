# kbd-backlight-idle

Turns off the ASUS keyboard backlight after a period of inactivity, and
restores it to whatever level was last set (not a fixed brightness) the
moment you press a key — or click, move, or scroll the mouse, if one is
detected.

## How it works

- Watches the keyboard's raw input events via `evtest` (works under X11,
  Wayland, or a bare TTY, since it reads the kernel device directly).
- If a mouse is also auto-detected, it's watched the same way in a
  separate background listener — movement, clicks, and scroll all count
  as activity too. If none is found, the script just runs on keyboard
  activity alone; nothing else changes.
- After `IDLE_TIMEOUT` seconds with no activity from either, it
  remembers the current backlight level and sets it to 0.
- On the next keypress (or mouse activity), it restores that remembered
  level — so if you had it at 30% before it idled out, it comes back at
  30%, not some hardcoded default.

## Requirements

- `brightnessctl`
- `evtest`
- `libinput`

```bash
sudo apt update
sudo apt install brightnessctl evtest libinput-tools
```

## Install

1. **Unzip and enter the project**

   ```bash
   unzip kbd-backlight-idle.zip
   cd kbd-backlight-idle
   ```

2. **Install dependencies**

   ```bash
   sudo apt update
   sudo apt install brightnessctl evtest libinput-tools
   ```

3. **Run the installer**

   ```bash
   sudo ./install.sh
   ```

   This copies:

   - `bin/kbd-backlight-idle` → `/usr/local/bin/kbd-backlight-idle`
   - `config/kbd-backlight-idle.conf` → `/etc/kbd-backlight-idle.conf` (only if it doesn't already exist)
   - `systemd/kbd-backlight-idle.service` → `/etc/systemd/system/kbd-backlight-idle.service`

   and runs `systemctl daemon-reload`. It does **not** enable or start the service — that's a separate step below, so you can test in the foreground first.

## Configure

Edit `/etc/kbd-backlight-idle.conf`:

```bash
sudo nano /etc/kbd-backlight-idle.conf
```

```bash
DEVICE="asus::kbd_backlight"   # confirm with: brightnessctl -l
IDLE_TIMEOUT=10                # seconds before turning off
FALLBACK_LEVEL="50%"           # only used if backlight is already off at startup
```

`DEVICE` is the one worth double-checking — run `brightnessctl -l` and make sure it matches exactly what's listed under class `leds`.

## Test

Run these in order — foreground first, service last — so config problems surface before they're hidden behind systemd.

1. **Confirm the device name**

   ```bash
   brightnessctl -l
   ```

   Look for a `leds` class device matching `DEVICE` in the config.

2. **Sanity-check device detection**

   ```bash
   sudo libinput list-devices
   ```

   Confirm a device with "Keyboard" in its name shows a `Kernel:` line like `/dev/input/event5`. If you also want mouse activity to count, check for a device with "Mouse" in its name too — this is optional, the script runs fine on keyboard alone if none is found.

3. **Run in the foreground**

   ```bash
   sudo kbd-backlight-idle
   ```

   It should print the detected device and confirm the idle/restore behavior, then sit listening. Leave this terminal open to catch errors. Ctrl+C to stop.

4. **Watch brightness live in a second terminal**

   ```bash
   watch -n1 brightnessctl --device="asus::kbd_backlight" get
   ```

   (swap in your `DEVICE`). Shows the raw value updating every second.

5. **Test the idle timeout**

   Stop touching the keyboard. After `IDLE_TIMEOUT` seconds the value should drop to 0 and the physical backlight should turn off.

6. **Test wake-on-keypress and level memory**

   Press any key — the value should jump back to whatever it was before idling out. To confirm it's not a fixed level: manually set a different level (`brightnessctl --device="asus::kbd_backlight" set 30%`), let it idle out, then press a key — it should restore to 30%, not the original level.

7. **Switch to the systemd service**

   Once foreground testing looks right:

   ```bash
   sudo systemctl enable --now kbd-backlight-idle
   ```

   `enable` starts it on every future boot, `--now` also starts it immediately. Confirm it's active:

   ```bash
   systemctl status kbd-backlight-idle
   ```

   Repeat steps 5–6 — behavior should be identical.

8. **Check logs if anything's off**

   ```bash
   journalctl -u kbd-backlight-idle -f
   ```

   Common issues here are a wrong `DEVICE` name (brightnessctl errors) or evtest failing to grab the device (permissions or wrong event number) — both show up in this log.

## Uninstall

```bash
sudo ./uninstall.sh
```

## License

MIT
