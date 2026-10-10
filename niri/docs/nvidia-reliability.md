# NVIDIA boot reliability fix — 2026-10-10

The fix is installed and passed a full reboot. Niri initialized the NVIDIA RTX 4070 SUPER and the LG ultrawide at 3440x1440 / 160 Hz with Secure Boot enabled.

## What failed

A driver update installed NVIDIA userspace/firmware `615.78.08`, but the initramfs still contained open kernel module `615.71.09`. That module requested removed version-specific GSP firmware and failed GPU initialization. NVIDIA's render node disappeared, and niri's hardcoded `/dev/dri/renderD129` could not open.

This was a system NVIDIA driver/firmware mismatch. GNOME's ability to run did not establish that NVIDIA was healthy; a compositor can use the Intel GPU. Niri was explicitly pinned to NVIDIA.

The local dracut `add_drivers` override had forced NVIDIA into the image despite RPM Fusion's omission policy. A userspace/firmware update did not refresh that embedded copy. The older installed kernel also had stale on-disk modules, so it needed repair.

## Installed changes

| Repository file | Purpose |
| --- | --- |
| `system/etc/dracut.conf.d/nvidia.conf` | Remove NVIDIA `add_drivers`; explicitly omit NVIDIA and preserve nouveau omission |
| `system/etc/modprobe.d/90-nvidia-managed-load.conf` | Suppress premature alias loading until matching modules are ready; explicit loading remains allowed |
| `system/etc/systemd/system/nvidia-boot-ready.service` | Wait for akmods, verify/repair and load NVIDIA, then wait for its render node |
| `system/etc/systemd/system/gdm.service.d/20-nvidia-ready.conf` | Make GDM wait for preparation with `Wants` and `After`; a helper failure does not become a hard GDM dependency failure |
| `system/usr/local/libexec/nvidia-reliability/nvidia_ready.py` | Check installed package versions, open-module selection, kernel compatibility, existing signing certificate serial, firmware, modesetting, and the GPU render node |
| `home/.config/niri/config.kdl` | Select `/dev/dri/by-path/pci-0000:01:00.0-render` so a numbered-node change does not select a different GPU |

Both normal installed-kernel images were rebuilt with NVIDIA absent and NVMe/btrfs support verified. Kernel `7.2.8`'s stale modules were rebuilt using the existing signing key. Both kernel builds now match `615.78.08`.

Boot order is: root filesystem mounted → packaged akmods → NVIDIA checks/repair → explicit DRM load and render-node readiness → GDM → niri. PCI coldplug is deferred so an old on-disk module cannot win the race before the build finishes. The helper never hot-unloads a running GPU.

## After dnf or yum updates

Continue using normal `sudo dnf update` or `sudo yum update`. For ordinary NVIDIA driver updates, no manual initramfs rebuild is needed to refresh NVIDIA: it is no longer embedded. The helper derives the required version from installed packages each boot rather than hardcoding `615.78.08`.

The custom integration is stored under `/etc` and `/usr/local`, so ordinary package updates do not replace it. For a new kernel, the helper waits for packaged akmods and checks the actual build, repairing a stale/missing open build once when possible. A successful akmods exit alone is not accepted as proof that the modules are ready.

A module build still needs compatible sources, kernel development files, and working build tools. Future incompatible kernel/driver releases, missing packages, hardware faults, or a changed signing key are not guaranteed recoverable. This is a custom integration with tests and a verified boot, not a promise that every future update is safe.

An NVIDIA userspace update during an active session may still require a normal reboot. Early boot may briefly show a blank or incorrectly sized firmware framebuffer; a boot that must compile modules may take several minutes.

## What stayed protected

Secure Boot remains enabled; the existing enrolled akmods key is used. No key was generated or enrolled. Windows disks/EFI and the Windows GRUB entry were not changed, and protected GRUB files retained their hashes. Open-module preference and existing modesetting/nouveau/nova_core command-line settings remain in place.

Bindings, output layout, desktop packages, and the active desktop were not restarted by the installer. The special rescue image was not rebuilt.

## Restore and rollback

Read the [included installer instructions](../maintenance/nvidia-reliability/README.md). Restore all related policy/helper/service files together; alias blacklists alone can leave NVIDIA unloaded. Copying dracut configuration alone does not repair existing boot images. From the repository root, on this same machine:

```sh
sudo ./niri/maintenance/nvidia-reliability/install.sh
```

The successful original installation saved rollback data at:

```text
/var/lib/nvidia-reliability/backups/20261010T053734.815264Z
```

To restore those originals on this machine:

```sh
sudo ./niri/maintenance/nvidia-reliability/install.sh --rollback /var/lib/nvidia-reliability/backups/20261010T053734.815264Z
```

Backups and signing keys remain on the machine and are not in Git. A later installation prints a new backup directory. Rollback restores configuration/images and retains package-managed module repairs.

## Verification

The 29 safety tests passed. Host installation verified both kernel builds and candidate images, SELinux labeling, the systemd dependency configuration, and unchanged protected GRUB hashes.

A full reboot on `7.2.9-300.fc45.x86_64` passed: akmods finished at 11:52:38 IST, the helper reported `NVIDIA ready` at 11:52:39, GDM started at 11:52:42, and niri initialized NVIDIA/the ultrawide at 11:52:49. Secure Boot was enabled, and the earlier API-mismatch, missing-GSP-image, and adapter-initialization errors were absent.

The older kernel's build/image passed installation checks but has not been boot-tested. A later NVIDIA version bump has not yet been observed. Read the [boot verification record](../maintenance/nvidia-reliability/verification/first-boot.md) and [primary-source research](../maintenance/nvidia-reliability/RESEARCH.md).
