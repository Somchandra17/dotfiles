# NVIDIA maintenance installer

This is the tested, machine-specific installer for som's Fedora desktop. The running boot helper and service/policy files also have mirror copies under `../../system/`; keep those copies identical when updating the maintenance bundle.

The fix was installed on 2026-10-10 and passed a full reboot on kernel `7.2.9-300.fc45.x86_64`. Read [the maintenance note](../../docs/nvidia-reliability.md), [research](RESEARCH.md), and [boot verification](verification/first-boot.md).

## Restore this fix on the same machine

Read `install.sh`, `install.py`, and `nvidia_ready.py` first. From the repository root:

```sh
sudo ./niri/maintenance/nvidia-reliability/install.sh
```

The installer checks Fedora, the RTX 4070 SUPER at `0000:01:00.0`, Linux `/boot` on `/dev/nvme1n1p2` (ext4), the existing enrolled akmods key, and package/module/firmware versions. Its niri configuration path is `/home/som/.config/niri/config.kdl`. Review these assumptions if the machine changes.

It builds and inspects all normal installed-kernel initramfs candidates before replacing active images, checks NVMe/btrfs support, saves checksum/mode/ownership backups, labels installed files, checks systemd ordering, and verifies protected GRUB file hashes. Installation errors restore configuration and images. Akmods package-managed module repairs are retained.

It preserves Secure Boot, the existing key, Windows/EFI, and GRUB. It does not restart the desktop, unload an active GPU, or reboot. Kernel/initramfs files and signing keys are not stored in this repository.

## Verify a boot

```sh
sudo journalctl -b -u nvidia-boot-ready.service --no-pager
niri msg outputs
mokutil --sb-state
```

Expect `NVIDIA ready`, the LG ultrawide connected, and `SecureBoot enabled`.

## Rollback

Use the exact backup directory printed by the installer:

```sh
sudo ./niri/maintenance/nvidia-reliability/install.sh --rollback /var/lib/nvidia-reliability/backups/TIMESTAMP
```

Rollback checks backup checksums and restores configuration and boot images. It does not downgrade packages or hot-unload the GPU.

## Safety tests

```sh
cd niri/maintenance/nvidia-reliability
python3 -B -m unittest -v test_safety
```

The 29 tests exercise stale/missing builds, wrong signing metadata, missing firmware, mixed versions, misleading akmods success, enrollment outcomes, PKCS#7 certificate-serial comparison, refusal to unload an old running module, dependency behavior, and installation rollback. They use temporary fixtures and do not modify the live system.
