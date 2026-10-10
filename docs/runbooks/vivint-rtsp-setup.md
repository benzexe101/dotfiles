> **Sanitized portfolio copy:** Original personal runbook preserved separately. Values such as `192.0.2.x`, example users, and camera IDs are fictitious; replace them when testing in your own authorized environment. This file has not been executed or fully verified on the current software versions.

> **Public-copy notice:** All `192.0.2.x` addresses, camera names, and stream IDs below are illustrative, not real endpoints. Examples embedding passwords in RTSP URLs document the original troubleshooting workflow but are **not safe production credential-handling instructions**: process arguments and command history may disclose secrets. Use a vetted client and secret-storage mechanism, and test against your own authorized devices.

# Vivint Camera RTSP Access on Linux

A complete walkthrough of getting live Vivint camera streams working on Garuda Linux using RTSP.

---

## Overview

Vivint cameras route through Vivint's cloud by default, but the Smart Hub panel also runs a local RTSP server on your LAN. With the right credentials, you can stream any camera directly using mpv, VLC, ffmpeg, or any other RTSP-capable tool — no Vivint app required.

---

## What We Did

### Step 1 — Find the Panel on the Network

Used nmap to scan the local network for port 8554 (Vivint's RTSP port):

```bash
nmap -p 8554 --open 192.0.2.0/24
```

Found the Vivint Smart Hub at `192.0.2.53`. Confirmed it was the panel with a deeper scan:

```bash
nmap -sV -p 8554,80,443,8080,8443 192.0.2.53
```

Key findings:
- Port 8554: RTSP server (camera streams)
- Port 443: Vivint panel API (`realm="vivint.panel"`, digest auth required)
- Port 8443: Local panel API (`aiohttp 3.6.2`)
- Port 80: OpenWrt uHTTPd (panel web interface)

### Step 2 — Authenticate via Vivint Cloud API

The RTSP server requires credentials that come from Vivint's cloud API. The old `Riebart/vivint.py` library no longer works because Vivint migrated their login to OAuth PKCE.

Installed the actively maintained `vivintpy` library instead:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install vivintpy
```

### Step 3 — Handle MFA and Pull Credentials

Vivint accounts require SMS MFA. The original project used a Python script for the MFA flow and RTSP credentials. The sanitized example below uses interactive input rather than hardcoded credentials (API compatibility has not been re-tested):

```python
import asyncio
import os
from getpass import getpass
from vivintpy.account import Account
from vivintpy.exceptions import VivintSkyApiMfaRequiredError

async def main():
    account = Account(
        username=os.environ['VIVINT_EMAIL'],
        password=getpass('Vivint account password: '),
    )

    try:
        await account.connect(load_devices=True)
    except VivintSkyApiMfaRequiredError:
        code = input('SMS code: ').strip()
        await account.api.verify_mfa(code)
        await account.connect(load_devices=True)

    # Get panel-level RTSP credentials
    panel_id = account.systems[0].data['system']['panid']
    creds = await account.api.get_panel_credentials(panel_id)
    # Credential object retained only in memory; never print or log it.
    print('RTSP credentials retrieved (values intentionally hidden).')

    # List all cameras and their stream URLs
    for d in account.systems[0].data['system']['par'][0]['d']:
        if d.get('t') == 'camera_device':
            print("--- Authorized camera discovered (name withheld)")
            print("  Stream URL available in API response (not printed: may contain credentials).")

asyncio.run(main())
```

### Step 4 — Stream with mpv

The panel-level credentials (from `get_panel_credentials`) work for all cameras:

```bash
mpv rtsp://user:PANEL_PASSWORD@192.0.2.53:8554/Video-01
```
Security note: This command uses fictional addresses and placeholder credentials for demonstration. Embedding real passwords directly in command-line arguments is discouraged because they may be exposed through shell history or process inspection.
---

## Camera Stream URLs

The stream identifiers and IP addresses below are anonymized examples. They do not represent the actual configuration of the devices.

| Camera | HD Stream | SD Stream |
|--------|-----------|-----------|
| Camera A | `rtsp://192.0.2.53:8554/Video-01` | `rtsp://192.0.2.53:8554/Video-01_SD` |
| Camera B | `rtsp://192.0.2.53:8554/Video-02` | `rtsp://192.0.2.53:8554/Video-02_SD` |
| Camera C | `rtsp://192.0.2.53:8554/Video-03` | `rtsp://192.0.2.53:8554/Video-03_SD` |
| Camera D | `rtsp://192.0.2.53:8554/Video-04` | `rtsp://192.0.2.53:8554/Video-04_SD` |

Username for all streams: `user`
Password: retrieved from `get_panel_credentials()` — rotates periodically.

---

## What Happens If You Change Your Vivint Password?

Changing your Vivint account password affects things at two separate levels:

### 1. Cloud authentication (your login password)

The Python script uses your Vivint account email and password to log into `vivintsky.com` and get a session token. If you change your Vivint password:

- The password you provide interactively must match the current account password
- The script will throw a 401 error on next run
- **Fix:** Re-run the script and enter the current password at the secure prompt

### 2. RTSP credentials (the panel password)

The RTSP stream password (e.g. `<PANEL_PASSWORD>`) is **separate** from your account login password. It is:

- Generated by Vivint's backend, not set by you
- Tied to the panel hardware, not your account password
- Rotated periodically by Vivint regardless of whether you change your login password

This means:
- Changing your Vivint account password does **not** immediately invalidate your RTSP stream credentials
- Your active mpv streams will keep working until the RTSP credentials naturally rotate
- When the RTSP creds rotate (could be hours, days, or longer), mpv will start throwing 401 errors again

### 3. What to do when streams stop working

Re-run the credentials script to get fresh ones:

```bash
python3 ~/vivint-tools/dump_cameras.py
```

Then provide the new credential through a tested private authentication workflow. The original RTSP paths could also change if the panel IP or device IDs changed.

---

## Automating Credential Refresh — design note

The private prototype used a fish script that fetched rotating credentials and passed them in an RTSP URL to `mpv`. The runnable example is omitted from this publication copy because passwords in command-line arguments can be exposed to other processes and logs. A secure replacement must use supported client secret handling and test the token lifecycle; **no secure automation is claimed as implemented**.

**Before using the Python example above:** supply an account identifier through `VIVINT_EMAIL` in your local environment, enter the password interactively, and avoid logging API responses that may include credentials. The `vivintpy` API may change across versions.

## Tools Used

| Tool | Purpose |
|------|---------|
| `nmap` | Discovered panel IP and open ports |
| `vivintpy` | Python library for Vivint cloud API (supports OAuth PKCE + MFA) |
| `mpv` / `vlc` | RTSP stream playback |
| `python3` | Auth scripting and credential extraction |

---

## Notes

- The `Riebart/vivint.py` library is outdated — it predates Vivint's OAuth PKCE migration and will fail at login
- Per-camera `pswd` fields in the API response are **not** the RTSP password — use the panel-level credentials from `get_panel_credentials()`
- The panel IP (`192.0.2.53`) could change if your router reassigns it — consider setting a DHCP reservation for the panel's MAC address to keep it stable
- Streams are LAN-only by default; the `cetu`/`cetus` fields in the API contain public/cloud relay URLs if you need remote access
