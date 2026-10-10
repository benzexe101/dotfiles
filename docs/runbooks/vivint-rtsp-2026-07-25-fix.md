> **Sanitized portfolio copy:** Original personal runbook preserved separately. Values such as `192.0.2.x`, example users, and camera IDs are fictitious; replace them when testing in your own authorized environment. This file has not been executed or fully verified on the current software versions.

> **Public-copy notice:** All `192.0.2.x` addresses, camera names, and stream IDs below are illustrative, not real endpoints. Examples embedding passwords in RTSP URLs document the original troubleshooting workflow but are **not safe production credential-handling instructions**: process arguments and command history may disclose secrets. Use a vetted client and secret-storage mechanism, and test against your own authorized devices.

# Vivint RTSP — Fix Log, 2026-07-25

Addendum to `vivint-rtsp-setup.md`. Two unrelated failures stacked on top of each other.

---

## Symptom

```
mpv rtsp://user:PANEL_PASSWORD@192.0.2.53:8554/Video-01
[ffmpeg] tcp: Connection to tcp://192.0.2.53:8554 failed: Connection refused
```

Plus `dump_cameras.py` dying on `ModuleNotFoundError`.

---

## Root Cause 1 — Panel IP drifted

**The panel moved from `192.0.2.53` to `192.0.2.50`.** DHCP reassigned it; nothing was
listening at `.53`, hence connection refused. This was flagged as a risk in the original
writeup and it happened.

Confirmed by re-running `dump_cameras.py`, which returns stream URLs live from the cloud API —
those URLs are authoritative and always reflect the panel's current address.

### Fix

```fish
# Update every hardcoded reference
sed -i 's/192\.0\.2\.53/192.0.2.50/g' \
  ~/vivint-tools/vivint-rtsp-setup.md \
  ~/vivint-tools/vivint-rtsp-troubleshooting.md \
  ~/.config/fish/functions/cam.fish

# Verify nothing was missed
grep -rn "192.0.2.53" ~/vivint-tools/ ~/.config/fish/
```

Only the IP octet changes. Port `8554`, the `Video-NN` paths, the `_SD` suffixes, and the
`user` username are all tied to the cameras/panel, not the network.

### Permanent fix — DHCP reservation

```fish
ip neigh | grep 192.0.2.50
# 192.0.2.50 dev eno1 lladdr 02:00:00:00:00:01 STALE
```

| Field | Value |
|-------|-------|
| Panel MAC | `02:00:00:00:00:01` |
| Reserved IP | `192.0.2.50` |
| Router | TP-Link Deco (app → More → Advanced → Address Reservation) |

Reserved to the address it already held, so no reboot needed — and rebooting a monitored alarm
panel can trigger a tamper/comms-failure event, so avoid it without reason.

---

## Root Cause 2 — Incomplete dependency tree on Python 3.14

`vivintpy` was installed without its deps resolved, so every run failed on the *next* missing
import: `httpx` → `jwt` → etc.

### Safer reproduction of the dependency fix (not the historical commands)

The original incident used an installation override on system Python. For a reproducible portfolio example, prefer a separate virtual environment:

```fish
sudo pacman -S python-pip   # needed on original machine
python3 -m venv .venv
source .venv/bin/activate
python -m pip install httpx pyjwt protobuf h2
```

`protobuf` pulled a `cp310-abi3` wheel, so no source build — 3.14 was not actually the problem
here. Cleaner equivalent for next time:

```fish
python -m pip install --force-reinstall vivintpy
```

**Note:** `pip check` output on the original environment mentioned `displaycal` missing `build` / `PyChromecast`. Unrelated
to this stack — ignore.

---

## Historical state (addresses replaced with non-routable examples)

Panel: `192.0.2.50:8554` · Username: `user` · Password: rotating secret (never store in a public file)

The stream identifiers and IP addresses below are anonymized examples. They do not represent the actual configuration of the devices.


| Camera | HD | SD |
|--------|----|----|
| Camera A | `rtsp://192.0.2.50:8554/Video-01` | `.../Video-01_SD` |
| Camera B | `rtsp://192.0.2.50:8554/Video-02` | `.../Video-02_SD` |
| Camera C | `rtsp://192.0.2.50:8554/Video-03` | `.../Video-03_SD` |
| Camera D | `rtsp://192.0.2.50:8554/Video-04` | `.../Video-04_SD` |

Quote the URL in fish — the panel password format can contain characters the shell will try to
interpret:

```fish
mpv "rtsp://user:<PASSWORD_REDACTED>@192.0.2.50:8554/Video-01"  # illustrative; do NOT pass real credentials this way
```

---

## Diagnostic Order (for next time)

1. `nc -zv <panel-ip> 8554` — refused means nothing is listening, not a bad password
2. `ping -c3 <panel-ip>` — no reply can mean a moved IP, filtering, outage, or an unresponsive device; investigate further
3. `python3 ~/vivint-tools/dump_cameras.py` — check the current address and authentication state without logging secrets
4. 401 errors, not refused? Creds rotated. Re-run step 3.

---

## Open Items

- [ ] Replace the credential-handling path with a vetted secret store; never print or log the panel password
- [ ] Evaluate secure session persistence using the supported API and protected secret storage; avoid plaintext token caches
- [ ] Reserve NAS `192.0.2.59` and Pi-hole `192.0.2.58` in Deco — Pi-hole drifting
      would take DNS down network-wide
- [ ] `await account.disconnect()` at end of `main()` to silence the aiohttp
      "Unclosed client session" warnings
