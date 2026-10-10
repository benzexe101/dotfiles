> **Sanitized portfolio copy:** Original personal runbook preserved separately. Values such as `192.0.2.x`, example users, and camera IDs are fictitious; replace them when testing in your own authorized environment. This file has not been executed or fully verified on the current software versions.

###  UEFI Secure Boot Configuration — Windows 11 / Linux Dual Boot

Overview

This project documents my experience configuring UEFI Secure Boot on a Windows 11 and Linux dual-boot system using sbctl and custom Secure Boot keys.

Both operating systems are installed on separate NVMe drives, each with its own EFI System Partition (ESP).

The objective was to enable Secure Boot while maintaining the ability to boot both operating systems, without relying on a distribution-provided signed shim for Linux.

Technologies Used

Windows 11 and Garuda Linux (Arch-based)

UEFI Secure Boot

GRUB bootloader

sbctl

Custom Platform Key (PK), Key Exchange Key (KEK), and signature database (db)

Microsoft certificates for Windows compatibility
# Secure Boot — Manual Re-Signing & Recovery

Companion to `secure-boot-sbctl-runbook.md`. This one is for when the automatic hook doesn't fire and you're staring at a boot loop after an update.

**Read this first:** you are not locked out. BIOS → Boot → Secure Boot → **OS Type → Other OS** → F10. Everything boots, all keys stay enrolled. Fix it from a working desktop, then flip back to **Windows UEFI mode**.

---

## Why this happens

The sbctl package ships a hook that re-signs every file in its database after a package transaction. If the file isn't *in* the database, the hook skips it — silently.

Anything signed **without `-s`** is a one-time signature. The next kernel update overwrites `/boot/vmlinuz-*` with an unsigned binary, firmware refuses it, and you get:

```
error: loader/efi/linux.c:grub_arch_efi_linux_boot_image:227:cannot load image.
```

Other ways it breaks:

| Cause | What happened |
|---|---|
| Signed without `-s` | File never entered the database; hook has nothing to do |
| New kernel installed (`linux-lts`, `linux-hardened`) | New path, not in database, never signed |
| `grub-install` re-run | Fresh unsigned `grubx64.efi` overwrites the signed one |
| Hook didn't run | Interrupted transaction, `NoExtract` in `pacman.conf`, or hook removed |
| `/var/lib/sbctl` lost | Restored from a snapshot that predates key creation, or wiped |
| Distro reinstall / migration | New system, keys still enrolled in firmware but no signing keys locally |

---

## Diagnosis (2 minutes)

Boot with **OS Type → Other OS**, then:

```bash
# 1. What does sbctl think it's managing?
sudo sbctl list-files

# 2. Does the enrollment still exist?
sudo sbctl status

# 3. What kernels actually exist on disk?
ls -la /boot/vmlinuz-*

# 4. What EFI binaries exist?
sudo find /boot/efi -name '*.efi'
```

Compare 1 against 3 and 4. **Anything present on disk but missing from `list-files` is unsigned and will fail.**

Check a specific file directly:

```bash
sudo sbctl verify                          # /boot/efi only
sudo sbverify --list /boot/vmlinuz-linux-zen   # any file, from sbsigntools
```

`sbverify` printing "No signature table present" is your confirmation.

---

## Fix

### Re-sign everything already in the database

```bash
sudo sbctl sign-all
```

Fastest fix when the hook simply didn't run. Won't help if the file was never registered.

### Add missing files to the database

```bash
sudo sbctl sign -s /boot/vmlinuz-linux-zen
sudo sbctl sign -s /boot/efi/EFI/Garuda/grubx64.efi
sudo sbctl sign -s /boot/efi/EFI/BOOT/BOOTX64.EFI
```

Adjust paths for your distro. Then confirm:

```bash
sudo sbctl list-files
```

Every file must read `✓ Signed`. Reboot, set **OS Type → Windows UEFI mode**, F10.

> **fish shell gotcha:** run `sudo` commands **one at a time**. Pasting a multi-line block makes fish feed the whole thing to stdin, sudo eats line 2 as your password, and the command dies with `sudo: a password is required` — which is easy to miss when it scrolls past. This exact thing cost time during the original setup.

---

## Catching new kernels automatically

The hook re-signs what's in the database. It does not discover new files. If you install a second kernel, register it at install time:

```bash
sudo pacman -S linux-lts linux-lts-headers
sudo sbctl sign -s /boot/vmlinuz-linux-lts
```

To make this self-maintaining, add a pacman hook that registers any kernel sbctl isn't already tracking:

**`/etc/pacman.d/hooks/95-sbctl-register-kernels.hook`**

```ini
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Target = usr/lib/modules/*/vmlinuz
Target = boot/vmlinuz-*

[Action]
Description = Registering new kernels with sbctl...
When = PostTransaction
Exec = /bin/sh -c 'for k in /boot/vmlinuz-*; do sbctl list-files | grep -qF "$k" || sbctl sign -s "$k"; done'
```

This runs *before* sbctl's own signing hook alphabetically (95 < 99), so newly registered kernels get signed in the same transaction.

**Debian/Ubuntu equivalent** — `/etc/kernel/postinst.d/zz-sbctl`:

```bash
#!/bin/sh
set -e
for k in /boot/vmlinuz-*; do
    sbctl list-files | grep -qF "$k" || sbctl sign -s "$k"
done
sbctl sign-all
```

`chmod +x` it.

**Fedora** — `/etc/kernel/install.d/99-sbctl.install`, same idea, driven by `kernel-install`.

---

## Verify before you reboot

Habit worth building: check signatures *before* rebooting into enforcement, not after.

```bash
#!/usr/bin/env bash
# ~/.local/bin/sb-check
echo "=== Enrollment ==="
sudo sbctl status

echo -e "\n=== Database ==="
sudo sbctl list-files

echo -e "\n=== Kernels on disk ==="
for k in /boot/vmlinuz-*; do
    if sudo sbverify --list "$k" &>/dev/null; then
        echo "  ✓ $k"
    else
        echo "  ✗ $k  <-- UNSIGNED, WILL NOT BOOT"
    fi
done

echo -e "\n=== EFI binaries ==="
sudo sbctl verify
```

Run it after any kernel update, any `grub-install`, any big `-Syu`. If anything shows `✗`, fix it before rebooting.

Optional: wire it into a systemd unit that warns at shutdown, or just make it a fish abbreviation you fire out of habit.

---

## Escalating failures

### Fixed the signatures, still won't boot

The problem isn't signing. Work the diagnostics from the main runbook: `e` at the GRUB entry → `Ctrl+X` to hold errors on screen, strip `quiet loglevel=3`, add `systemd.unit=multi-user.target`.

Read the error rather than assuming. `sparse file not allowed` and the `grub-probe` device-type warning are both cosmetic and both appear on healthy systems.

### `sbctl status` shows Setup Mode enabled again

Firmware keys were cleared — CMOS battery, BIOS update, or a "load optimized defaults." Your local keys in `/var/lib/sbctl/` are fine; they just aren't enrolled anymore.

```bash
sudo sbctl enroll-keys --microsoft
```

No need to regenerate. Re-enroll and reboot.

### `/var/lib/sbctl` is gone

You've lost the private keys. Firmware still trusts the old public keys, but nothing can sign with them anymore.

If you have the backup:

```bash
sudo tar xzf sbctl-keys-backup.tar.gz -C /
sudo sbctl status
sudo sbctl sign-all
```

If you don't: clear Secure Boot keys in BIOS (back to Setup Mode), `sbctl create-keys`, `sbctl enroll-keys --microsoft`, re-sign everything. Twenty minutes and one BIOS trip.

**Make the backup now if you haven't:**

```bash
sudo tar czf ~/sbctl-keys-backup-$(date +%F).tar.gz /var/lib/sbctl/
```

Store it off the machine in encrypted storage with restricted access; do not commit the archive or signing keys to Git. These keys sign your bootloader; treat them like an SSH private key. Anyone holding them can sign a bootloader your firmware will trust.

### Snapper rollback broke it

Rolling back `/` to a snapshot from before key creation restores an old `/var/lib/sbctl`. Meanwhile `/boot/efi` is a separate vfat partition and doesn't roll back, so the signed binaries and the signing database now disagree.

Restore the key backup over the rolled-back state, then `sbctl sign-all`.

Worth noting: snapshots are not a substitute for the tar backup, precisely because of this mismatch.

### Windows stopped booting after key changes

You enrolled without `--microsoft`. Windows Boot Manager is signed by Microsoft's CA, which is no longer in your db.

```bash
sudo sbctl enroll-keys --microsoft
```

Also relevant: some GPUs and add-in cards carry option ROMs signed by the Microsoft UEFI CA. Without it enrolled you can lose display output entirely — which is a much worse afternoon. Always enroll with `--microsoft` on a dual-boot machine with discrete graphics.

---

## Quick reference

```bash
sudo sbctl status                # enrolled? enforcing?
sudo sbctl list-files            # what's tracked
sudo sbctl sign-all              # re-sign tracked files
sudo sbctl sign -s <path>        # track + sign (always use -s)
sudo sbverify --list <path>      # check any file's signature
```

**Escape hatch:** BIOS → Boot → Secure Boot → OS Type → **Other OS** → F10
**Re-enable:** same path → **Windows UEFI mode** → F10

**Rule that prevents most of this:** every EFI binary and every kernel gets `sbctl sign -s`. Never plain `sign`. Never signed once and forgotten.
