> **Sanitized portfolio copy:** Original personal runbook preserved separately. Values such as `192.0.2.x`, example users, and camera IDs are fictitious; replace them when testing in your own authorized environment. This file has not been executed or fully verified on the current software versions.

# Runbook: Nextcloud Unreachable on One Client — DNS + Expired TLS Cert

**Environment:** Homelab — TrueNAS SCALE (Docker apps), Tailscale mesh VPN with MagicDNS, Nextcloud behind Tailscale's built-in Let's Encrypt cert issuance, Garuda Linux (Arch-based) client with NetworkManager.

**Symptom:** Nextcloud (`https://<tailnet-host>.<tailnet-domain>:30027`) was reachable from a laptop on the same tailnet, but unreachable from a desktop PC on the same network. Desktop client showed a "behind a captive portal, or being redirected" error in the Nextcloud desktop app.

> Screenshot referenced in original documentation; not included in the supplied attachments or reviewed for disclosure.

---

## 1. Triage

Started by ruling out the server, since a second client (laptop) could reach it fine — this pointed at something client-specific to the desktop rather than a Nextcloud or network-wide outage.

Checked the VPN mesh layer first, since Nextcloud is only exposed over Tailscale, not the public internet:

```fish
systemctl status tailscaled
tailscale status
```

Result: `tailscaled` was healthy, and the peer list showed the NAS as `active; direct <ip>:<port>` — a live, direct (non-relayed) connection. This made a broad Tailscale connectivity failure less likely, though it did not prove application-port reachability.

## 2. Isolating the layer

With VPN peer connectivity appearing healthy (not proof of application-port reachability), tested the actual HTTPS path directly, bypassing the browser and desktop client entirely:

```fish
curl -vk https://<tailnet-host>.<tailnet-domain>:30027
```

Result: `curl: (6) Could not resolve host`. At that point, name resolution was the immediate blocker; routing, TLS, and application behavior could only be tested after the hostname resolved.

## 3. Root cause #1 — DNS resolver not wired up

Checked the resolver stack:

```fish
resolvectl status
cat /etc/resolv.conf
```

Findings:
- `resolvectl status` failed outright — `systemd-resolved` wasn't running on this machine.
- `/etc/resolv.conf` was being written directly by NetworkManager, pointing only at the LAN's local DNS server (Pi-hole) — no Tailscale MagicDNS resolver (`100.100.100.100`) in the chain at all.

Confirmed MagicDNS was actually enabled tailnet-side:

```fish
tailscale status --json | grep -A5 '"MagicDNSSuffix"'
```

→ `MagicDNSEnabled: true`. So the tailnet was correctly configured; this client just wasn't hooked into it. On systems using `systemd-resolved`, Tailscale registers a split-DNS domain for its `.ts.net` suffix automatically. Without `systemd-resolved` running and NetworkManager configured to defer to it, that registration has nowhere to land — Tailscale falls back to trying to manage `/etc/resolv.conf` directly, but NetworkManager keeps overwriting it back to the LAN-only config.

**Fix:**

```fish
sudo systemctl enable --now systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

Edited `/etc/NetworkManager/NetworkManager.conf`:

```ini
[main]
dns=systemd-resolved
```

(Note: the `[main]` header was initially left commented out during editing — `dns=` on its own outside any section is silently ignored by NetworkManager. Worth double-checking the section header isn't commented when editing this file.)

```fish
sudo systemctl restart systemd-resolved
sudo systemctl restart NetworkManager
```

NetworkManager briefly hit a `start-limit-hit` crash loop on the first restart attempt (config file was mid-edit at the time / `[main]` still commented). Confirmed via:

```fish
systemctl status NetworkManager.service
journalctl -xeu NetworkManager.service --no-pager | tail -40
```

Fixed the config and restarted cleanly. Verified the fix with:

```fish
resolvectl status
```

`tailscale0` still showed no DNS scope even after NetworkManager came back healthy — Tailscale hadn't yet pushed its resolver config to the now-working resolved stack. Forced it:

```fish
sudo tailscale set --accept-dns=true
resolvectl status
```

`tailscale0` now showed `Current DNS Server: 100.100.100.100` with the full `<tailnet-domain>` split-DNS zone registered. Confirmed resolution:

```fish
resolvectl query <tailnet-host>.<tailnet-domain>
```

→ resolved correctly to the NAS's Tailscale IP.

## 4. Root cause #2 — expired TLS certificate

With DNS fixed, re-ran the original curl test (`-k` is diagnostic only and disables certificate verification; the later test without `-k` is the actual TLS validation):

```fish
curl -vk https://<tailnet-host>.<tailnet-domain>:30027
```

Connection succeeded, but `OpenSSL verify result: 14` (expired certificate). Cert details confirmed it:

```
start date: Mar 24 2026 GMT
expire date: Jun 22 2026 GMT
```

The Tailscale-issued Let's Encrypt cert had lapsed roughly two weeks earlier and had not been renewed — this was a known outstanding item that had been missed. This explains the "captive portal" error surfaced by the Nextcloud desktop client: some clients misreport expired-cert TLS failures as connectivity/portal issues rather than a clear certificate warning. Firefox's own HSTS-pinned error (`SEC_ERROR_EXPIRED_CERTIFICATE`) on the same host confirmed the same root cause independently, and — because of the HSTS pin — blocked the usual "click through the warning" workaround entirely.

> Screenshot omitted from this shareable copy; original not supplied for independent privacy review.

**Fix — renewed the cert from inside the Tailscale container on the NAS:**

SSH'd into the TrueNAS host directly (bypassing the web UI, which was itself behind the expired cert):

```fish
ssh admin@<nas-ip>
sudo docker ps | grep -i tailscale
sudo docker exec -it <tailscale-container> tailscale cert <tailnet-host>.<tailnet-domain>
```

Located and copied the renewed cert/key out of the container:

```fish
sudo docker exec <tailscale-container> find / -name "<tailnet-host>.<tailnet-domain>.*" 2>/dev/null
sudo docker cp <tailscale-container>:/<tailnet-host>.<tailnet-domain>.crt ./
# Sensitive operation: transfer the private key only to a protected destination; verify file permissions.
sudo docker cp <tailscale-container>:/<tailnet-host>.<tailnet-domain>.key ./
cat <tailnet-host>.<tailnet-domain>.crt
# NEVER print or paste the private key into a terminal transcript.
# Verify ownership and permissions without displaying secret contents:
sudo ls -l <tailnet-host>.<tailnet-domain>.key
```

> Screenshot omitted from this shareable copy; original not supplied for independent privacy review.

> Screenshot omitted from this shareable copy; original not supplied for independent privacy review.

Imported the new cert pair via **TrueNAS Web UI → Credentials → Certificates → Add → Import Certificate** (left "Add to trusted store" unchecked — this is a standard LE-issued leaf cert, not a CA/root cert, so it doesn't need to be added as a trust anchor).

> Screenshot omitted from this shareable copy; original not supplied for independent privacy review.

Reassigned the new cert in two places:
- **System → General → GUI SSL Certificate**
- **Apps → Nextcloud → Edit** (app-level TLS cert setting)

## 5. Verification

```fish
curl -v https://<tailnet-host>.<tailnet-domain>:30027
```

```
* SSL certificate verified via OpenSSL.
< HTTP/2 302
< location: https://<tailnet-host>.<tailnet-domain>:30027/login
```

`OpenSSL verify result: 0`, SAN match confirmed, clean redirect to Nextcloud's login page with no `-k` flag needed. Confirmed working in Firefox on the previously-affected desktop as well.

---

## Root causes (two, independent)

1. **NetworkManager was not configured to hand DNS resolution off to `systemd-resolved`**, which meant Tailscale's MagicDNS resolver never got registered on this client — breaking `.ts.net` hostname resolution specifically on this machine, while other clients (already correctly configured) were unaffected.
2. **The Tailscale-issued Let's Encrypt certificate had expired** and had not been renewed on schedule, which was masked as a DNS/connectivity issue until DNS was fixed and the TLS failure became visible.

## Prevention / follow-up

- Add a systemd timer to auto-renew the Tailscale certificate ~2 weeks before its 90-day expiry, re-import into TrueNAS Credentials, and reassign to affected apps automatically (or at minimum alert when renewal is needed) — this was a known gap prior to this incident.
- Standardize DNS backend configuration (`systemd-resolved` + NetworkManager integration) across all client machines on the tailnet at initial setup, rather than per-client defaults, to avoid this exact single-client failure mode recurring on a new machine.
