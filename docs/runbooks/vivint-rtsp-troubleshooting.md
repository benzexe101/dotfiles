> **Sanitized portfolio copy:** Original personal runbook preserved separately. Values such as `192.0.2.x`, example users, and camera IDs are fictitious; replace them when testing in your own authorized environment. This file has not been executed or fully verified on the current software versions.

> **Public-copy notice:** All `192.0.2.x` addresses, camera names, and stream IDs below are illustrative, not real endpoints. Examples embedding passwords in RTSP URLs document the original troubleshooting workflow but are **not safe production credential-handling instructions**: process arguments and command history may disclose secrets. Use a vetted client and secret-storage mechanism, and test against your own authorized devices.

# Vivint RTSP on Linux — Instructions & Troubleshooting Guide

---

## Quick Reference

| Thing | Value |
|-------|-------|
| Panel IP | `192.0.2.53` |
| RTSP Port | `8554` |
| Username | `user` (all cameras) |
| Password | Rotates — re-run script to refresh |
| Script location | `~/vivint-tools/dump_cameras.py` |

### Stream URLs

```
Camera A:     rtsp://user:PASSWORD@192.0.2.53:8554/Video-01
              rtsp://user:PASSWORD@192.0.2.53:8554/Video-01_SD

Camera B:   rtsp://user:PASSWORD@192.0.2.53:8554/Video-02
              rtsp://user:PASSWORD@192.0.2.53:8554/Video-02_SD

Camera C:     rtsp://user:PASSWORD@192.0.2.53:8554/Video-03
              rtsp://user:PASSWORD@192.0.2.53:8554/Video-03_SD

Camera D:  rtsp://user:PASSWORD@192.0.2.53:8554/Video-04
              rtsp://user:PASSWORD@192.0.2.53:8554/Video-04_SD
```

---

## Normal Usage

### Watch a camera (recommended — use the `cam` function)

```bash
cam camera_b       # Camera B SD
cam camera_a    # Camera A SD
cam camera_c        # Camera C SD
cam camera_d      # Camera D SD
cam all         # All cameras SD
cam hd camera_b    # Camera B HD
cam stop        # Kill all streams
```

Streams run fully detached — closing the terminal won't stop them.

### Watch a camera (manual mpv)

```bash
# HD
mpv rtsp://user:PASSWORD@192.0.2.53:8554/Video-02

# SD (lower latency, less CPU)
mpv rtsp://user:PASSWORD@192.0.2.53:8554/Video-02_SD
```

### Refresh credentials (do this when streams stop working)

```bash
cd ~/vivint-tools
python3 dump_cameras.py
```

Enter the MFA code if prompted; handle the returned credential privately and never paste it into a public document.

### Record a stream to a file

```bash
ffmpeg -rtsp_transport tcp -i "rtsp://user:PASSWORD@192.0.2.53:8554/Video-02" \
  -c copy -t 60 ~/Videos/camera_b-$(date +%Y%m%d-%H%M%S).mp4
```

Change `-t 60` to however many seconds you want to record.

### Watch multiple cameras at once

```bash
mpv rtsp://user:PASSWORD@192.0.2.53:8554/Video-01_SD &
mpv rtsp://user:PASSWORD@192.0.2.53:8554/Video-02_SD &
mpv rtsp://user:PASSWORD@192.0.2.53:8554/Video-03_SD &
mpv rtsp://user:PASSWORD@192.0.2.53:8554/Video-04_SD &
```

---

## What-If Scenarios

---

### "My stream suddenly stopped working with a 401 Unauthorized error"

**What happened:** The RTSP panel credentials rotated. This happens automatically on Vivint's schedule — nothing you did caused it.

**Fix:**
1. Re-run the credentials script:
   ```bash
   cd ~/vivint-tools
   python3 dump_cameras.py
   ```
2. Enter your SMS code
3. Retrieve the password through a private authenticated workflow; avoid logging it
4. Use a tested, secret-safe mechanism to authenticate your streaming client

---

### "I changed my Vivint account password"

**What happened:** Two separate things are affected:

1. **The Python script will fail** — it uses your login password to authenticate. Update it:
   ```bash
   nvim ~/vivint-tools/dump_cameras.py
   ```
   Use interactive input or an OS secret store; never write the password into a script tracked by Git.

2. **Active streams will keep working** — the RTSP panel password is separate from your account password and won't change just because you updated your login.

---

### "The script asks for an SMS code every single time"

**What happened:** `vivintpy` doesn't cache your session between runs, so it re-authenticates each time.

**Security-aware follow-up:** The original experiment stored a refresh token in a plaintext home-directory file and embedded an account email in code. Those examples have been removed from this shareable copy. A refresh token is effectively a credential: if persistence is truly necessary, use an OS keyring or dedicated secrets service, restrict access, set an expiration/revocation process, and verify current `vivintpy` API support. Do not commit tokens, email addresses, or account passwords to Git.

---

### "mpv can't connect at all — no 401, just connection refused or timeout"

**What happened:** One of a few things:
- The panel rebooted and got a new IP
- Your router reassigned the IP to a different device
- The panel's RTSP service is temporarily down

**Fix — find the panel's current IP:**
```bash
nmap -p 8554 --open 192.0.2.0/24
```

Look for the host with port 8554 open. Update your stream URLs with the new IP.

**Permanent fix — set a DHCP reservation:** Log into your router, find the Vivint panel's MAC address, and assign it a permanent IP so it never changes. The panel's MAC was visible in the nmap scan output.

---

### "I can connect but the video is choppy or laggy"

**What happened:** HD streams are heavy — the panel is encoding and your network or CPU may be struggling.

**Fix options:**

1. Use SD instead of HD:
   ```bash
   # Change Video-02 to Video-02_SD
   mpv rtsp://user:PASSWORD@192.0.2.53:8554/Video-02_SD
   ```

2. Force TCP transport (more reliable than UDP on local networks):
   ```bash
   mpv --rtsp-transport=tcp rtsp://user:PASSWORD@192.0.2.53:8554/Video-02
   ```

3. Reduce mpv buffering for lower latency:
   ```bash
   mpv --no-cache --untimed rtsp://user:PASSWORD@192.0.2.53:8554/Video-02_SD
   ```

---

### "I cancelled my Vivint subscription"

**What happened:** Your Vivint cloud account loses access, so the Python script can no longer authenticate and fetch credentials. However, the panel hardware still exists on your LAN.

**What may still work (unverified):**
- The local panel remains on the network, though the example address is fictional
- Any access after cancellation depends on actual authorization, service behavior, and credentials

**What breaks:**
- The Python auth script — no cloud account, no credentials
- Credential refresh — you can't get new ones without an account

**Security note:** Do not publish or archive working credentials as a workaround. Verify your product access and licensing terms before relying on any continued streaming functionality.

---

### "I got a new Vivint panel / the panel was replaced"

**What happened:** New panel = new device IDs. The `Video-01`, `Video-02` etc. numbers are tied to the panel, not the cameras themselves.

**Fix:** Re-run the full discovery script to get new stream paths:
```bash
cd ~/vivint-tools
python3 dump_cameras.py
```

The output will show updated stream URLs with the new video IDs.

---

### "I added a new camera to my Vivint system"

**Fix:** Re-run the discovery script — it lists all cameras currently registered to your panel:
```bash
cd ~/vivint-tools
python3 dump_cameras.py
```

The new camera will appear with its own `Video-XX` path.

---

### "I want to access cameras remotely (outside my home network)"

The `ciu`/`cius` fields are LAN (private) URLs. The `cetu`/`cetus` fields in the API response are the cloud/public relay URLs.

**Option 1 — Tailscale:**
Tailscale on the remote client alone does not provide access to every LAN device. Reaching a camera panel on its private LAN IP requires an authorized subnet router (or another approved route/proxy) and appropriate access rules.

**Option 2 — use the public relay URLs:**
These go through Vivint's cloud servers and require the same credentials. Pull them with:
```python
cetu = d.get('cetu', [None])[0]   # HD public
cetus = d.get('cetus', [None])[0]  # SD public
```

---

### "I want to pipe streams into Frigate for motion detection and recording"

Frigate is an NVR that accepts RTSP streams. Add your cameras to `frigate.yml`:

```yaml
cameras:
  Camera A:
    ffmpeg:
      inputs:
        - path: rtsp://user:PASSWORD@192.0.2.53:8554/Video-01
          roles:
            - detect
            - record
  camera_b:
    ffmpeg:
      inputs:
        - path: rtsp://user:PASSWORD@192.0.2.53:8554/Video-02
          roles:
            - detect
            - record
```

Security note: this YAML snippet is only a schematic illustration. Do not put live credentials directly in a Git-tracked `frigate.yml`; use supported secret handling for your deployment.

---

### "The script fails with 'MFA required' but I never receive an SMS"

**What happened:** Vivint's SMS delivery can be slow or fail if your carrier has issues.

**Try:**
1. Wait 60 seconds and check again — SMS can be delayed
2. Check if Vivint has your correct phone number on file in the app
3. Run the script again to trigger a new SMS code — old codes expire quickly
4. Log into `vivint.com` in your browser and complete MFA there to confirm your number works

---

### "I want to avoid re-entering credentials every time I open a stream"

The original `cam` fish function used shortcuts similar to these (examples only; implementation omitted):

```bash
cam camera_b
cam camera_a
cam all
cam stop
cam hd camera_b
```

---

## Setting Up the `cam` Fish Function

This is how the original setup launched streams. It runs mpv fully detached from the terminal using `nohup` + `disown`, so closing the terminal won't kill the stream.

### Implementation note

The complete executable function was intentionally omitted from this public-copy document. The original script prompted for or stored an RTSP password and then placed it in a URL passed to `mpv`, which may expose the credential in process listings. It also used `pkill -f "rtsp://user"`, which could terminate unrelated streams.

For a production implementation, identify whether your RTSP client supports a documented credential input or secret-store mechanism that avoids shell history and exposed process arguments; then handle process lifecycles using specific PIDs rather than a broad pattern. These controls were **not implemented or tested** as part of this redaction.

### Usage

| Command | What it does |
|---------|-------------|
| `cam camera_a` | Stream Camera A in SD |
| `cam camera_b` | Stream Camera B in SD |
| `cam camera_c` | Stream Camera C in SD |
| `cam camera_d` | Stream Camera D in SD |
| `cam all` | Stream all cameras in SD |
| `cam hd camera_b` | Stream Camera B in HD |
| `cam stop` | Kill all running streams |

### When credentials rotate

Reauthenticate through the authorized account workflow, and do not store working tokens or passwords in a public repo. The original URL-based function was omitted from this public copy because the invocation was not hardened.

---

## Key Things to Remember

1. **Two separate passwords exist:** Your Vivint login password (for the app/website) and the RTSP panel password (for streams). They are independent.

2. **RTSP credentials rotate** on Vivint's schedule — not predictably. When streams break with 401, just re-run the script.

3. **The panel IP can change** if your router reassigns it. If you can't connect at all, re-scan with nmap to find it.

4. **Per-camera `pswd` fields in the API are not RTSP passwords** — always use the panel-level credentials from `get_panel_credentials()`.

5. **SD streams are more reliable** than HD for casual viewing — less bandwidth and CPU.

6. **Store credentials safely** — don't leave passwords in plain text scripts if others have access to your machine. Prefer an OS keyring or dedicated secrets store; `.env` files also contain plaintext secrets and must be excluded from Git and protected by filesystem permissions.
