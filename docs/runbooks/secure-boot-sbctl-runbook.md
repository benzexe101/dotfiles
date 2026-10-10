> **Sanitized portfolio copy:** Original personal runbook preserved separately. Values such as `192.0.2.x`, example users, and camera IDs are fictitious; replace them when testing in your own authorized environment. This file has not been executed or fully verified on the current software versions.

# Secure Boot with Custom Keys (sbctl) — Runbook

**Machine:** Consumer desktop (exact motherboard, firmware version, CPU, and GPU details omitted)
**Layout:** Windows 11 + Linux dual-boot, separate ESPs on separate NVMe drives
**Completed:** 2026-07-29
**Goal:** Enable UEFI Secure Boot so game anti-cheat (Valorant, BF6, COD BO7) passes, without giving up a self-managed Linux install.

---

## The core concept

Secure Boot is a signature chain enforced by firmware. Firmware holds four EFI variables:

| Variable | Role |
|---|---|
| **PK** (Platform Key) | Root of trust. Controls who may modify KEK. One key. |
| **KEK** (Key Exchange Key) | Controls who may modify db/dbx. |
| **db** (Signature Database) | Allow-list. Binaries signed by a key in here may execute. |
| **dbx** (Forbidden Signatures) | Deny-list. Revoked/compromised binaries, checked first. |

The normal consumer path is: Microsoft owns the PK, ships `shim` signed by their CA, shim validates your distro's GRUB, GRUB validates the kernel. Distros pay Microsoft to sign shim.

**The path this runbook takes instead:** clear the factory keys, generate your own PK/KEK/db, re-enroll Microsoft's certs alongside yours (so Windows still boots), and sign your own bootloader and kernel. You become the root of trust for your own machine. No shim, no Microsoft dependency on the Linux side.

This provides more direct control over trusted boot binaries, but is not automatically more secure: key custody, firmware revocation state, update automation, and recovery become your responsibility.

---

## The thing that cost the most time

> **Both GRUB *and* the kernel must be signed. Signing only GRUB produces a boot loop.**

Why: GRUB 2.12+ on EFI doesn't parse and jump to the kernel itself. It calls the firmware's `LoadImage()` boot service. Firmware then validates the kernel against db *regardless of what GRUB thinks*. So:

- `--disable-shim-lock` disables GRUB's **internal** verifier (the `shim_lock` module)
- It does **nothing** about the firmware's LoadImage check

Result if you sign GRUB but not the kernel: GRUB's menu draws fine (firmware validated it), you pick your entry, and you get:

```
error: loader/efi/linux.c:grub_arch_efi_linux_boot_image:227:cannot load image.
```

...followed by a reset. From the menu it flashes past too fast to read, which is why it looks like an unexplained loop.

**Sign the kernel. `sudo sbctl sign -s /boot/vmlinuz-<flavor>`.**

The initramfs does **not** need signing — GRUB loads that into memory directly, never through LoadImage.

---

## Diagnostic technique (reusable)

When a boot loops too fast to read, don't guess. Force GRUB to hold on error.

**1. Read the error instead of losing it.** At the GRUB menu, highlight the entry, press `e`, then `Ctrl+X`. Booting from the editor makes GRUB print failures and wait for a keypress rather than resetting.

**2. Unhide kernel output.** In that same editor, delete `quiet` and `loglevel=3` from the `linux` line before `Ctrl+X`.

**3. Skip the graphical session.** Append `systemd.unit=multi-user.target` to the `linux` line. Boots to a text console — invaluable when you suspect GPU driver problems, since you get a usable shell instead of a black screen.

**4. Check what GRUB actually loaded.** Press `c` at the menu for a GRUB shell:
```
set pager=1
lsmod
```
If `shim_lock` appears, `--disable-shim-lock` didn't take. If it doesn't appear and you're still failing, the problem is downstream of GRUB — i.e. the firmware LoadImage check.

**5. Verify the entry's own config.** In the `e` editor, confirm `root=UUID=...` matches the `search --set=root` UUID above it, and that btrfs installs carry `rootflags=subvol=@`. NVMe device names (`nvme0n1` vs `nvme1n1`) can reshuffle between boots — that's normal and harmless because GRUB uses UUIDs, but it's worth ruling out.

### Red herrings seen on this system

| Message | Meaning |
|---|---|
| `commands/loadenv.c:check_blocklists:289:sparse file not allowed` | GRUB can't write `grubenv` on btrfs. Cosmetic. Predates Secure Boot. Ignore. |
| `grub-probe: warning: unknown device type nvmeXn1` | Cosmetic. Ignore. |
| `sbctl verify` doesn't list the kernel | Expected. `verify` only walks `/boot/efi`. Use `sbctl list-files`. |

---

## Escape hatch

**If Linux won't boot, you are never stuck.** BIOS → Boot → Secure Boot → **OS Type → Other OS** → F10. Enforcement off, everything boots, all enrolled keys preserved. Flip back to **Windows UEFI mode** when you want enforcement again.

("Windows UEFI mode" is ASUS's confusing label for *enforcing*, not *Windows-only*. Other vendors just call it Enabled/Disabled.)

---

> **Safety note for readers:** This is a historical case study, not a ready-to-run setup script. The full procedure includes destructive disk formatting and firmware trust changes; verify device names, backups, recovery access, and machine-specific requirements before running anything.

## Full procedure (distro-agnostic)

### Phase 0 — Pre-flight

**Windows (run PowerShell as Administrator):**

```powershell
# Confirm no BitLocker — Secure Boot changes alter PCR values and can trigger recovery
manage-bde -status
(Get-BitLockerVolume -MountPoint "C:").KeyProtector

# Confirm UEFI boot. Returns False (a boolean, not an error) = UEFI, Secure Boot off
Confirm-SecureBootUEFI

# Disable Fast Startup — it hibernates the kernel and skips firmware re-init
powercfg /h off
```

If BitLocker is on, either suspend it or **save your recovery key** first. This is the one step that can actually cost you data.

Also: if you've ever queued a TPM clear via PPI, cancel it. Clearing the TPM while BitLocker is active is how people lose drives.

**Linux:**

```bash
# Confirm UEFI (not BIOS/CSM)
ls /sys/firmware/efi

# Identify ESP and bootloader
findmnt /boot/efi
ls /boot/efi/EFI/

# Check kernel lockdown policy — determines whether DKMS modules need signing
cat /sys/kernel/security/lockdown
zgrep -E 'LOCK_DOWN|MODULE_SIG' /proc/config.gz   # if available
```

`lockdown` reading `[none]` with `CONFIG_LOCK_DOWN_KERNEL_FORCE_NONE=y` means unsigned DKMS modules (NVIDIA) will still load under Secure Boot. If instead you see `CONFIG_LOCK_DOWN_IN_EFI_SECURE_BOOT=y`, lockdown activates *only* when Secure Boot is on, and you'll need to sign kernel modules separately (see Appendix A).

### Phase 1 — Back up firmware state

Non-negotiable. You're about to erase the factory keys.

1. Format a USB stick as **FAT32** (UEFI can't read ext4/btrfs/exFAT reliably).

   ```bash
   sudo wipefs -a /dev/sdX
   sudo sgdisk --zap-all /dev/sdX
   sudo sgdisk --new=1:0:0 --typecode=1:0700 /dev/sdX
   sudo mkfs.vfat -F32 -n BIOSKEYS /dev/sdX1
   ```

   *(fish shell note: use `/dev/sdX[0-9]*` in globs, not `/dev/sdX?*` — fish dropped `?` as a glob character.)*

2. **Save your BIOS profile** — every overclock, fan curve, and boot setting. On ASUS: Tool → ASUS User Profile → save to an internal slot *and* export a `.CMO` to the USB. Do both; internal slots survive most things, the file survives a CMOS clear.

3. **Export the factory Secure Boot keys.** Boot → Secure Boot → Key Management → Save all Secure Boot variables → target the USB.

Keep this stick. Restoring factory keys is Key Management → restore defaults, but having the export means you can put back the exact original set.

### Phase 2 — Firmware into Setup Mode

BIOS → Boot → Secure Boot:

1. **Secure Boot Mode: Standard → Custom** (exposes Key Management)
2. **Key Management → Clear Secure Boot Keys**
3. Confirm PK/KEK/db/dbx all read **0 keys / No Keys**, Secure Boot State: **Setup**
4. F10 to save

Setup Mode means firmware will accept new keys written from the OS without physical-presence confirmation. That's the window you need.

### Phase 3 — Generate and enroll keys

Install sbctl (`pacman -S sbctl`, `dnf install sbctl`, `apt install sbctl`, or build from source — it's a single Go binary).

```bash
sudo sbctl status          # should show Setup Mode: Enabled
sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft
```

**`--microsoft` is important.** It enrolls Microsoft's Windows Production CA and UEFI CA alongside your own keys. Without it:
- Windows Boot Manager won't validate → Windows won't boot
- Option ROMs on add-in cards (GPU, NIC, HBA) signed by the UEFI CA won't run → possible no display output

Verify the variables were written:

```bash
sudo sbctl status
efivar -l | grep -iE 'PK|KEK|db'
```

You want PK: 1 key, KEK: 3 keys, db: ~6 keys, all "Modified."

> **Note:** `sbctl status` may report Setup Mode still enabled during the same session that enrolled the keys — that's a stale runtime cache. The BIOS is authoritative. Reboot into firmware and confirm there.

### Phase 4 — Sign everything in the chain

**This is the step that matters most.** Every binary the firmware executes via LoadImage needs a signature.

```bash
# Bootloader
sudo sbctl sign -s /boot/efi/EFI/<distro-id>/grubx64.efi

# Fallback bootloader (if present — worth installing, see below)
sudo sbctl sign -s /boot/efi/EFI/BOOT/BOOTX64.EFI

# THE KERNEL — the step everyone misses
sudo sbctl sign -s /boot/vmlinuz-<flavor>

# Verify
sudo sbctl list-files
```

Every entry must read `✓ Signed`.

**The `-s` flag is what makes this survive updates.** It adds the file to sbctl's database (`/var/lib/sbctl/files.json`), and the distro's sbctl package hook re-signs everything in that database automatically after each `pacman`/`dnf`/`apt` transaction. Sign without `-s` and your next kernel update strands you in exactly the failure this runbook describes.

**Install a fallback bootloader** while you're here — it's the removable-media path (`/EFI/BOOT/BOOTX64.EFI`) firmware uses when NVRAM entries get wiped, which happens after a CMOS clear:

```bash
sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable
sudo sbctl sign -s /boot/efi/EFI/BOOT/BOOTX64.EFI
```

### Phase 5 — Enable enforcement

BIOS → Boot → Secure Boot → **OS Type: Windows UEFI mode** → F10.

### Phase 6 — Verify

**Linux:**
```bash
sbctl status      # Setup Mode: ✓ Disabled, Secure Boot: ✓ Enabled
nvidia-smi        # GPU still loading
bootctl status    # alternative check
```

**Windows:**
```powershell
Confirm-SecureBootUEFI   # True
manage-bde -status C:    # confirm nothing auto-encrypted during the key churn
```

Then launch whatever anti-cheat game motivated this.

---

## Per-distro / per-bootloader differences

The key management is identical everywhere. Only the paths and which binaries exist change.

### GRUB (Arch, Garuda, Fedora, Debian, Ubuntu, openSUSE)

Sign: `grubx64.efi` + `vmlinuz-*` + (optional) `BOOTX64.EFI`

```bash
sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi \
    --bootloader-id=<name> --modules="tpm" --disable-shim-lock
sudo grub-mkconfig -o /boot/grub/grub.cfg   # Fedora/openSUSE: /boot/grub2/grub.cfg
```

`--disable-shim-lock` prevents GRUB's internal verifier from demanding a shim that isn't there. It does not replace signing the kernel.

**Fedora/RHEL note:** ships with shim + Microsoft-signed GRUB by default. You can either keep that (skip custom keys entirely — it just works) or go custom as above. Mixing them causes confusion; pick one.

**Debian/Ubuntu note:** `grub-install` may re-add shim. Check `/boot/efi/EFI/<distro>/` for `shimx64.efi` after install and remove/ignore it if going custom.

### systemd-boot (any distro that uses it)

Cleaner for this purpose — fewer moving parts.

```bash
sudo bootctl install
sudo sbctl sign -s /boot/efi/EFI/systemd/systemd-bootx64.efi
sudo sbctl sign -s /boot/efi/EFI/BOOT/BOOTX64.EFI
sudo sbctl sign -s /boot/vmlinuz-<flavor>
```

### Unified Kernel Image (UKI) — the endgame

A UKI bundles kernel + initramfs + cmdline + stub into **one signed EFI binary**. Firmware validates the whole thing as a unit.

This closes the gap left by the GRUB approach: with GRUB, the initramfs and kernel cmdline are unverified, so someone with disk access could inject an initramfs hook or add `init=/bin/sh`. With a UKI, tampering with any component breaks the signature.

```bash
# Arch: configure /etc/mkinitcpio.d/<preset>.preset for UKI output, then
sudo mkinitcpio -P
sudo sbctl sign -s /boot/efi/EFI/Linux/arch-linux.efi

# systemd-native
sudo ukify build --linux=/boot/vmlinuz-linux --initrd=/boot/initramfs-linux.img \
    --cmdline="root=UUID=... rw rootflags=subvol=@" --output=/boot/efi/EFI/Linux/linux.efi
sudo sbctl sign -s /boot/efi/EFI/Linux/linux.efi
```

Boot it directly via a firmware NVRAM entry or systemd-boot's auto-discovery of `/EFI/Linux/*.efi`. Drop GRUB entirely.

**Trade-off:** UKIs mean regenerating and re-signing the whole image on every kernel *and* initramfs change, and editing the cmdline requires a rebuild. That's the price of a verified chain. Worth it once the setup stabilizes; annoying while you're still tinkering.

---

## Moving to a different distro later

Your keys live in **two** places: firmware NVRAM (the enrolled PK/KEK/db) and `/var/lib/sbctl/` (the private keys used to sign).

**Back up `/var/lib/sbctl/` before wiping anything.**

```bash
sudo tar czf sbctl-keys-backup.tar.gz /var/lib/sbctl/
# Store somewhere off the machine. These keys sign your bootloader —
# treat them the way you'd treat an SSH private key.
```

### Path A — keep your existing keys (recommended)

1. Set **OS Type → Other OS** so the installer can boot
2. Install the new distro normally
3. Install sbctl, restore your backup:
   ```bash
   sudo tar xzf sbctl-keys-backup.tar.gz -C /
   sudo sbctl status   # should recognize existing keys
   ```
4. Sign the new distro's bootloader + kernel with `-s`
5. **OS Type → Windows UEFI mode**

No firmware changes needed. Your enrolled db already trusts these keys — you're just signing new binaries with them.

### Path B — start clean

Repeat Phases 1–5 from scratch. Necessary if you lost the key backup, or if you want fresh keys after any suspicion of compromise.

### If you lose the private keys and can't boot

Not a disaster: **OS Type → Other OS**, boot in, generate new keys, put firmware in Setup Mode, re-enroll, re-sign. The only permanent loss would be losing keys *and* having no way to reach Setup Mode — which is why the BIOS profile export from Phase 1 matters.

---

## Appendix A — signing kernel modules (only if lockdown is active)

If `cat /sys/kernel/security/lockdown` shows `[integrity]` or `[confidentiality]` when Secure Boot is on, unsigned DKMS modules (NVIDIA, VirtualBox, ZFS) will be refused. Symptom: no GPU acceleration, session fails to start, `dmesg` shows module signature errors.

This is a **separate mechanism** from EFI binary signing — different key format, different tool.

> **Procedure withheld pending validation:** The original appendix mixed Machine Owner Key (MOK), firmware `db` enrollment, and kernel module trust; it also used an sbctl flag not verified for this configuration. Those operations are not interchangeable. Verify your boot chain, kernel lockdown mode, module-signing workflow, certificate trust path, and current tool syntax before using any enrollment/signing commands.

Arch/Garuda: configure DKMS to auto-sign via `/etc/dkms/framework.conf` (`mok_signing_key`, `mok_certificate`) so rebuilds stay signed.

**On the system this runbook was written for, this was not needed** — `CONFIG_LOCK_DOWN_KERNEL_FORCE_NONE=y` in the linux-zen kernel means lockdown stays off, and `nvidia-open-dkms` loaded fine under Secure Boot.

---

## Appendix B — dbx (revocation list)

`sbctl enroll-keys --microsoft` does **not** populate dbx. An empty dbx means known-compromised bootloaders — including the BlackLotus-era GRUB binaries and revoked vendor shims — would still validate against your db if they're signed by a trusted CA.

**Correction:** `sbctl enroll-keys --microsoft --firmware-builtin` does **not** install a UEFI dbx revocation update. A dbx update is a separate firmware trust operation. Do not copy speculative commands for revocation updates; consult current firmware-vendor or authoritative dbx-update documentation, back up the relevant state, and test the boot paths before proceeding.

**Status:** dbx management was documented as an open issue in the original project, not a completed remediation.

---

## Appendix C — command reference

```bash
sbctl status                  # enrollment + enforcement state
sbctl list-files              # everything in the signing database
sbctl verify                  # walks /boot/efi only (NOT /boot)
sbctl sign -s <path>          # sign + add to database (use -s always)
sbctl sign-all                # re-sign everything in the database
sbctl create-keys             # generate PK/KEK/db
sbctl enroll-keys --microsoft # write keys to firmware + MS certs
sbctl reset                   # restore factory keys (needs Setup Mode)
```

```powershell
Confirm-SecureBootUEFI        # enforcement state
Get-SecureBootPolicy          # policy details
manage-bde -status            # BitLocker per volume
powercfg /a                   # available sleep states / hibernation
```

---

## Outcome log — 2026-07-29

| Item | Result |
|---|---|
| Factory keys exported | ✓ BIOSKEYS USB |
| BIOS profile saved | ✓ internal slot 1 + `8.3-ish.CMO` |
| Custom PK/KEK/db enrolled | ✓ owner GUID `<REDACTED-OWNER-GUID>` |
| Microsoft certs included | ✓ |
| `grubx64.efi` signed | ✓ |
| `BOOTX64.EFI` signed | ✓ |
| `vmlinuz-linux-zen` signed | ✓ (the fix) |
| Secure Boot | ✓ Enabled |
| Setup Mode | ✓ Disabled |
| RTX 4080 under Hyprland | ✓ working, unsigned DKMS loading fine |
| dbx | ✗ empty — open item |

**Time sink:** roughly 90 minutes, almost all of it on the kernel-signing step, because the error was invisible from the GRUB menu. The `e` → `Ctrl+X` trick surfaced it in under a minute once tried.
