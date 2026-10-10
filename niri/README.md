# Niri desktop (Fedora)

Daily session on the desktop PC. GNOME stays installed as the recovery login. This is not the Hyprland laptop and not the Mac.

| | |
|---|---|
| Machine | i5-14600K, 32 GB, RTX 4070 SUPER, LG ultrawide on `DP-5` |
| OS | Fedora 45 (the identity package says Budgie Prerelease; the session is niri) |
| Account | `som` |
| WM | niri 26.04, from Fedora's repo |
| Shell | Noctalia 5.2.1, from Fedora's repo. Not `noctalia-shell`, Quickshell, or Dank Material Shell |
| Terminal | Kitty 0.48.2, login shell zsh |
| GPU | RPM Fusion open module `615.78.08`, existing Secure Boot MOK enrolled; boot verified 2026-10-10 |
| Kernels | `7.2.9-300` running and boot-tested; `7.2.8-300` also installed with matching signed open modules. `installonly_limit=2` |

`home/` mirrors `$HOME`. `system/` mirrors paths from `/`.

The NVIDIA boot reliability fix was installed and reboot-tested on 2026-10-10. Read [the NVIDIA maintenance note](docs/nvidia-reliability.md) for the failure, installed changes, update behavior, and verification. The tested installer is included under `maintenance/nvidia-reliability/`.

## What is in here

| Path | Live location | What it is |
|---|---|---|
| `home/.config/niri/` | `~/.config/niri/` | Compositor config: output, binds, animations, window rules. `profiles/not final.kdl` is an unused draft |
| `system/etc/sysctl.d/99-disable-ipv6.conf` | `/etc/sysctl.d/` | IPv6 is off. This network has no IPv6 route, and Antigravity account setup fails when DNS returns an AAAA record |
| `home/.zshrc`, `home/.zprofile` | `~/` | Lean zsh. No Oh My Zsh. Grok's bin is on `PATH` |
| `home/.local/bin/cx-knob-columns` | same | CX keyboard knob focuses the column left/right |
| `home/.config/autostart/gnome-keyring-*.desktop` | `~/.config/autostart/` | Secret storage, PKCS#11, and the SSH agent. Fedora's copies are GNOME-only; these start them under niri |
| `home/.config/environment.d/99-ssh-auth-sock.conf` | `~/.config/environment.d/` | Points `SSH_AUTH_SOCK` at the keyring socket for the next login |
| `home/.config/systemd/user/cx-knob-columns.service` | same | User service for that knob |
| `home/.config/systemd/user/graphical-session.target.wants/cx-knob-columns.service` | same | Enables that service in the graphical session |
| `home/.var/app/org.mozilla.firefox/.../user.js` | same | Middle-click autoscroll on. Not the rest of the Firefox profile |
| `home/.local/share/fonts/fantasque-sans-mono.regular.otf` | same | The regular face. Not a Nerd Font |
| `home/.local/state/noctalia/settings.toml` | same | Bar, dock pins, panels, 12-hour clock, Wallhaven widget, niri ribbon, wallpaper |
| `home/.local/share/noctalia/plugins/niri-ribbon/` | same | Noctalia 5 bar widget for columns scrolled off the ultrawide. The upstream QML ribbon does not load on this shell |
| `home/.config/nirinit/config.toml` | `~/.config/nirinit/` | Session restore. Skips Noctalia and Flameshot. Maps Flatpak and app launchers |
| `home/.local/bin/niri-ror` | same | Wrapper for [niri-ror](https://github.com/boomskats/niri-ror) at `60fbab4`. The clone itself is not stored |
| `home/.config/kitty/` | `~/.config/kitty/` | Fantasque Sans Mono 14, opacity 0.9, OneDark, splits, Ctrl+Shift+arrows move between panes |
| `home/.local/state/noctalia/state.toml` | same | Small Noctalia state |
| `home/.local/state/noctalia/plugins/materialized/official/wallhaven/` | same | Installed Wallhaven plugin snapshot |
| `home/Pictures/wallhaven-96j6px.jpg` | `~/Pictures/` | Wallpaper the bar and monitors point at |
| `system/etc/default/grub` | `/etc/default/grub` | 4 second gfxterm menu, 3440x1440, bsol theme, BLS off |
| `system/boot/grub2/themes/bsol/` | `/boot/grub2/themes/bsol/` | GRUB theme from [harishnkr/bsol](https://github.com/harishnkr/bsol) |
| `system/usr/local/sbin/reorder-grub-menu` | same | Puts Windows before the rescue entry after `grub2-mkconfig` |
| `system/etc/kernel/install.d/99-zz-reorder-grub.install` | same | Runs that reorder on kernel install |
| `system/usr/local/sbin/boot-to-windows` | same | One-shot firmware boot into Windows |
| `system/etc/modprobe.d/` | same | nouveau blacklist and NVIDIA modeset / suspend options |
| `system/etc/dracut.conf.d/nvidia.conf` | same | Omit NVIDIA and nouveau from the initramfs; load NVIDIA from root after akmods |
| `system/etc/modprobe.d/90-nvidia-managed-load.conf` | same | Defer NVIDIA alias loading until boot preparation finishes |
| `system/etc/systemd/system/nvidia-boot-ready.service` | same | Verify/repair signed open modules and initialize NVIDIA before GDM |
| `system/etc/systemd/system/gdm.service.d/20-nvidia-ready.conf` | same | Wait for NVIDIA preparation while retaining recovery login if it fails |
| `system/usr/local/libexec/nvidia-reliability/nvidia_ready.py` | same | Boot helper using the existing enrolled key and installed package version |
| `maintenance/nvidia-reliability/` | maintenance tools | Tested installer, rollback support, safety tests, research, and reboot verification |
| `system/etc/depmod.d/nvidia-open.conf` | same | Prefer `extra/nvidia-open` over the other NVIDIA build |
| `system/etc/nvidia/...json` | same | niri VRAM profile (`GLVidHeapReuseRatio` 0) |
| `system/etc/dnf/dnf.conf` | same | `installonly_limit=2` |
| `system/etc/dnf/libdnf5.conf.d/99-speed.conf` | same | Parallel downloads and fastest mirror |
| `system/etc/udev/rules.d/65-cx-knob.rules` | same | Lets the session read the knob device |
| `system/etc/NetworkManager/.../Wired connection 1.nmconnection` | same | Ethernet DNS `1.1.1.1,8.8.8.8`, IPv6 off. No password in the file |
| `packages/installed.txt` | note only | Kernel, NVIDIA, niri, Noctalia, Flatpak IDs, plugin git pins |

## Left out on purpose

- Kernel images, initramfs, and `.ko` files. The package names are in `packages/installed.txt`.
- `/etc/sudoers.d/som-nopasswd`. It grants passwordless sudo. It stays on the machine and is not in this backup.
- Wi-Fi profiles `KANDAM` and `Trash X300`. Both contain a PSK.
- Noctalia clipboard history, notification history, usage counts, and `instance.id`.
- The 19 MB official and community plugin git clones. They are upstream checkouts, not edits. Pins: `noctalia-dev/official-plugins` `2337829`, `noctalia-dev/community-plugins` `a1b7827`.
- The `niri-ror` and `nirinit` source trees. Pins are `niri/home/.local/src/niri-ror.pin` (`60fbab4`) and `nirinit.pin` (0.2.2, built locally because the GitHub binary is Nix-only).
- Community theme-template cache under `~/.local/state/noctalia/community-templates`.

## Binds worth remembering

Mod is Super. The Paneru fn key maps to Super.

- Mod+D launcher, Mod+Return opens Kitty, Mod+Shift+Return focuses an open Kitty
- Mod+B focuses or opens Firefox. Mod+Shift+C focuses or opens VS Code
- Mod+Up/Down switch workspace. Mod+Page Up/Down do the same
- Mod+Shift+S region screenshot in Flameshot. Print takes the full screen
- Mod+Left/Right focus columns. The keyboard knob does the same thing
- Ctrl+Shift+D vertical Kitty split, Ctrl+Shift+E horizontal Kitty split. Ctrl+Shift+arrows move between those panes
- Mod+Shift+Q is unbound. In niri that chord quits the session

`center-focused-column` is `never`, so two half-width windows sit side by side. Variable refresh is off.

## Keyring

Fedora ships `gnome-keyring-secrets.desktop`, `gnome-keyring-pkcs11.desktop`, and `gnome-keyring-ssh.desktop` with `OnlyShowIn=GNOME;Unity;MATE;`. A niri login skips them, so `gh auth login` can finish in the browser and then fail to save the token. The copies in `home/.config/autostart/` drop that line. GDM still unlocks the keyring through `pam_gnome_keyring.so` in `/usr/lib/pam.d/gdm-password`.

Other `OnlyShowIn=GNOME` autostart entries are left skipped on purpose: Orca, localsearch, the disk-utility notifier, and the AT-SPI bus. The polkit agent is `OnlyShowIn=MATE`, so it is started from `spawn-at-startup` in the niri config instead.

`SSH_AUTH_SOCK` is `${XDG_RUNTIME_DIR}/keyring/ssh`. `home/.config/environment.d/99-ssh-auth-sock.conf` sets it for the next login. `home/.zshrc` sets it for a terminal opened before that.

## Restoring

Copy `home/` onto a user that already has niri and Noctalia installed from Fedora. Log out and back into the niri session so Noctalia rereads `settings.toml`.

System files need root and a reboot to matter. After restoring GRUB files, run `grub2-mkconfig -o /boot/grub2/grub.cfg` and then `/usr/local/sbin/reorder-grub-menu`. Check `efibootmgr` still lists Fedora before Windows.

NVIDIA stays on the real root filesystem and is built and signed by akmods. Do not restore `add_drivers` for NVIDIA: an embedded driver can become stale after a package update. Niri selects `/dev/dri/by-path/pci-0000:01:00.0-render` instead of a numbered render node.

Restore the NVIDIA preparation service, GDM drop-in, helper, alias blacklist, and dracut omission together. Copying configuration alone does not rebuild existing boot images. On this same Fedora desktop, run the included installer from the repo root:

```sh
sudo ./niri/maintenance/nvidia-reliability/install.sh
```

It verifies the existing Secure Boot key, repairs signed open modules for each installed normal kernel if necessary, builds and inspects replacement images before installation, and backs up the original files. It preserves Windows and GRUB and does not hot-unload the GPU or reboot. The first verified boot used kernel `7.2.9-300.fc45.x86_64`; the older kernel's build and image passed installation checks but have not been boot-tested.

The rescue entry is not a second copy of this desktop and is not rebuilt by this installer. The GRUB restoration commands above are only for restoring GRUB files; they are not required by the NVIDIA fix. See [the maintenance note](docs/nvidia-reliability.md) for rollback and remaining limits.
