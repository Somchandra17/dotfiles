#!/usr/bin/python3
"""Transactional, machine-specific installer; run from the host with sudo."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import sys
import tempfile

import nvidia_ready as driver

BUNDLE = Path(__file__).resolve().parent
BOOT = Path("/boot")
STATE = Path("/var/lib/nvidia-reliability/backups")
STAGING = Path("/var/tmp")
NIRI = Path("/home/som/.config/niri/config.kdl")
DRACUT = Path("/etc/dracut.conf.d/nvidia.conf")
RUNTIME = Path("/usr/local/libexec/nvidia-reliability/nvidia_ready.py")
UNIT = Path("/etc/systemd/system/nvidia-boot-ready.service")
GDM = Path("/etc/systemd/system/gdm.service.d/20-nvidia-ready.conf")
MODPROBE = Path("/etc/modprobe.d/90-nvidia-managed-load.conf")
PROTECTED = (Path("/etc/default/grub"), Path("/boot/grub2/grub.cfg"), Path("/boot/grub2/grubenv"))
NVIDIA_NAMES = {"nvidia", "nvidia_modeset", "nvidia_drm", "nvidia_uvm", "nvidia_peermem"}
KERNEL_RE = re.compile(r"[0-9][A-Za-z0-9._+-]*\.fc[0-9]+\.x86_64")


def rewrite_dracut(text):
    lines = []
    assignment = re.compile(r"^(\s*(?:add_drivers|force_drivers)\s*\+?=\s*)([\"'])(.*)\2(\s*(?:#.*)?)$")
    for line in text.splitlines():
        match = assignment.match(line)
        if match:
            tokens = match[3].split()
            remaining = [item for item in tokens if item.replace("-", "_") not in NVIDIA_NAMES]
            if remaining:
                lines.append(f"{match[1]}{match[2]} {' '.join(remaining)} {match[2]}{match[4]}")
        elif "nvidia" in line and re.match(r"\s*(?:add_drivers|force_drivers)\b", line):
            raise driver.DriverError("Cannot safely rewrite a dynamic NVIDIA dracut assignment")
        else:
            lines.append(line)
    marker = '# Load NVIDIA from root after akmods; never embed a versioned copy.'
    policy = 'omit_drivers+=" nvidia nvidia_modeset nvidia_drm nvidia_uvm nvidia_peermem "'
    if policy not in lines:
        lines.extend([marker, policy])
    # The existing nouveau omission is preserved, and added if absent.
    if not any(re.match(r"\s*omit_drivers\s*\+?=.*\bnouveau\b", line) for line in lines):
        lines.append('omit_drivers+=" nouveau "')
    return "\n".join(lines) + "\n"


def rewrite_niri(text):
    pattern = re.compile(r'(?m)^(\s*render-drm-device\s+)"([^"]+)"')
    matches = list(pattern.finditer(text))
    if len(matches) != 1 or matches[0][2] not in ("/dev/dri/renderD129", str(driver.RENDER)):
        raise driver.DriverError("The niri GPU selection changed; refusing to overwrite it blindly")
    return pattern.sub(lambda match: f'{match[1]}"{driver.RENDER}"', text)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def protected_hashes():
    return {str(path): sha256(path) for path in PROTECTED if path.is_file()}


def installed_kernels():
    kernels = driver.run(["rpm", "-q", "--qf", "%{VERSION}-%{RELEASE}.%{ARCH}\n", "kernel-core"]).splitlines()
    kernels = sorted(set(kernels))
    if not kernels or any(not KERNEL_RE.fullmatch(kernel) for kernel in kernels):
        raise driver.DriverError("Unexpected installed Fedora kernel identifiers")
    if os.uname().release not in kernels:
        raise driver.DriverError("The running kernel is not in the installed kernel-core packages")
    for kernel in kernels:
        image = BOOT / f"initramfs-{kernel}.img"
        if not image.is_file() or image.is_symlink():
            raise driver.DriverError(f"Expected a normal Fedora initramfs: {image}")
    return kernels


def preflight():
    if os.geteuid() != 0:
        raise driver.DriverError("Run this installer with sudo from a host terminal; no changes were made")
    if not re.search(r"(?m)^ID=['\"]?fedora['\"]?$", Path("/etc/os-release").read_text()):
        raise driver.DriverError("This installer is for this Fedora machine only")
    gpu = Path(f"/sys/bus/pci/devices/{driver.PCI}")
    if gpu.joinpath("vendor").read_text().strip() != "0x10de" or gpu.joinpath("device").read_text().strip() != "0x2783":
        raise driver.DriverError("The expected RTX 4070 SUPER was not found")
    # Explicitly identify the Linux boot partition; never write to an ESP.
    mount = driver.run(["findmnt", "-n", "-o", "SOURCE,FSTYPE", "--target", str(BOOT)]).split()
    if mount != ["/dev/nvme1n1p2", "ext4"]:
        raise driver.DriverError(f"Linux /boot partition changed: {' '.join(mount)}")
    if os.statvfs(BOOT).f_flag & os.ST_RDONLY:
        raise driver.DriverError("/boot is read-only in this execution environment")
    if NIRI.is_symlink() or DRACUT.is_symlink():
        raise driver.DriverError("A target configuration is a symlink; review its target first")
    key = driver.enrolled_key()
    driver.expected_version()
    kernels = installed_kernels()
    size = sum((BOOT / f"initramfs-{kernel}.img").stat().st_size for kernel in kernels)
    if shutil.disk_usage(STAGING).free < 2 * size + 256 * 1024**2:
        raise driver.DriverError("Insufficient space for staged images and rollback backups")
    if shutil.disk_usage(BOOT).free < max((BOOT / f"initramfs-{k}.img").stat().st_size for k in kernels):
        raise driver.DriverError("Insufficient /boot space for atomic image replacement")
    return key, kernels


def verify_image(image, kernel):
    listing = driver.run(["lsinitrd", str(image)], timeout=120)
    if re.search(r"/(?:nvidia(?:[-_](?:drm|modeset|uvm|peermem))?)\.ko(?:\.[A-Za-z0-9]+)?(?:\s|$)", listing):
        raise driver.DriverError(f"NVIDIA kernel modules remain in {image}")
    builtin_path = Path(f"/usr/lib/modules/{kernel}/modules.builtin")
    builtin = builtin_path.read_text() if builtin_path.is_file() else ""
    for name in ("nvme", "nvme-core", "btrfs"):
        if not re.search(rf"/{re.escape(name)}\.ko(?:\.[A-Za-z0-9]+)?(?:\s|$)", listing + "\n" + builtin):
            raise driver.DriverError(f"Root-storage driver {name} was not found in {image} or the built-in list")


def snapshot(destinations):
    backup = STATE / datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    backup.mkdir(parents=True, mode=0o700)
    manifest = {}
    for destination in destinations:
        if destination.is_symlink():
            raise driver.DriverError(f"Refusing to replace symlink {destination}")
        record = {"exists": destination.exists()}
        if destination.exists():
            info = destination.stat()
            record.update(uid=info.st_uid, gid=info.st_gid, mode=stat.S_IMODE(info.st_mode), sha256=sha256(destination))
            copy = backup / str(destination).lstrip("/")
            copy.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(destination, copy)
        manifest[str(destination)] = record
    (backup / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return backup, manifest


def atomic_copy(source, destination, record, *, executable=False):
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.is_symlink():
        raise driver.DriverError(f"Refusing to replace symlink {destination}")
    fd, temporary = tempfile.mkstemp(prefix=".nvidia-reliability-", dir=destination.parent)
    try:
        with os.fdopen(fd, "wb") as stream, source.open("rb") as origin:
            shutil.copyfileobj(origin, stream)
            mode = record.get("mode", 0o755 if executable else 0o644)
            os.fchmod(stream.fileno(), mode)
            os.fchown(stream.fileno(), record.get("uid", 0), record.get("gid", 0))
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, destination)
        directory = os.open(destination.parent, os.O_DIRECTORY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def restore(backup, manifest):
    for name, record in manifest.items():
        destination = Path(name)
        if record["exists"]:
            atomic_copy(backup / name.lstrip("/"), destination, record)
        elif destination.exists():
            destination.unlink()
    driver.run(["systemctl", "daemon-reload"])


def install():
    key, kernels = preflight()
    protected = protected_hashes()
    dracut_text = rewrite_dracut(DRACUT.read_text())
    niri_text = rewrite_niri(NIRI.read_text())
    # Bring both normal boot choices up to date. This never unloads a running module.
    for kernel in kernels:
        print(f"Checking signed on-disk open modules for {kernel}", flush=True)
        driver.ensure_disk(kernel, key)
    with tempfile.TemporaryDirectory(prefix="nvidia-reliability-", dir=STAGING) as temporary:
        stage = Path(temporary)
        confdir = stage / "dracut.conf.d"
        confdir.mkdir()
        for source in DRACUT.parent.glob("*.conf"):
            shutil.copy2(source, confdir / source.name)
        (confdir / DRACUT.name).write_text(dracut_text)
        niri_candidate = stage / "config.kdl"
        niri_candidate.write_text(niri_text)
        driver.run(["niri", "validate", "-c", str(niri_candidate)])
        candidates = {}
        for kernel in kernels:
            print(f"Building and inspecting a candidate initramfs for {kernel}", flush=True)
            candidate = stage / f"initramfs-{kernel}.img"
            driver.run([
                "dracut", "--force", "--no-uefi", "--no-ukify", "--confdir", str(confdir),
                "--include", str(BUNDLE / "files/90-nvidia-managed-load.conf"), str(MODPROBE),
                str(candidate), kernel,
            ], timeout=600)
            verify_image(candidate, kernel)
            candidates[BOOT / f"initramfs-{kernel}.img"] = candidate
        dracut_candidate = stage / "nvidia.conf"
        dracut_candidate.write_text(dracut_text)
        files = {
            DRACUT: dracut_candidate,
            MODPROBE: BUNDLE / "files/90-nvidia-managed-load.conf",
            RUNTIME: BUNDLE / "nvidia_ready.py",
            UNIT: BUNDLE / "files/nvidia-boot-ready.service",
            GDM: BUNDLE / "files/20-nvidia-ready.conf",
            NIRI: niri_candidate,
            **candidates,
        }
        # All candidates pass before any active boot image or configuration is replaced.
        backup, manifest = snapshot(files)
        try:
            for destination, source in files.items():
                atomic_copy(source, destination, manifest[str(destination)], executable=destination == RUNTIME)
            driver.run(["restorecon", str(DRACUT), str(MODPROBE), str(RUNTIME), str(UNIT), str(GDM), str(NIRI),
                        *(str(destination) for destination in candidates)])
            driver.run(["systemd-analyze", "verify", str(UNIT)], timeout=120)
            driver.run(["systemctl", "daemon-reload"])
            dependencies = driver.run(["systemctl", "show", "gdm.service", "-p", "Wants", "-p", "After"])
            if sum("nvidia-boot-ready.service" in line for line in dependencies.splitlines()) != 2:
                raise driver.DriverError("GDM did not acquire the preparation dependency")
            for kernel in kernels:
                driver.verify_disk(kernel, driver.expected_version(), key)
            if protected_hashes() != protected:
                raise driver.DriverError("A protected GRUB file changed during installation; investigate before rebooting")
            driver.run(["sync", "--file-system", str(BOOT)])
        except BaseException:
            print(f"Installation failed; restoring configuration and boot images from {backup}", file=sys.stderr)
            restore(backup, manifest)
            raise
        print(f"Installed and verified. Rollback backup: {backup}")
        print("The current desktop was not restarted or unloaded. The new loading order takes effect next boot.")


def rollback(path):
    if os.geteuid() != 0:
        raise driver.DriverError("Rollback requires sudo from a host terminal")
    backup = Path(path).resolve()
    if backup.parent != STATE.resolve():
        raise driver.DriverError("Rollback must use this installer's own backup directory")
    manifest = json.loads((backup / "manifest.json").read_text())
    allowed = {DRACUT, MODPROBE, RUNTIME, UNIT, GDM, NIRI}
    for name in manifest:
        destination = Path(name)
        if destination not in allowed and not re.fullmatch(r"/boot/initramfs-" + KERNEL_RE.pattern + r"\.img", name):
            raise driver.DriverError(f"Unexpected rollback destination: {destination}")
    for name, record in manifest.items():
        if record["exists"] and sha256(backup / name.lstrip("/")) != record["sha256"]:
            raise driver.DriverError(f"Rollback backup checksum failed: {name}")
    restore(backup, manifest)
    print("Original configuration and images restored. No desktop restart or reboot was performed.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rollback", metavar="BACKUP_DIRECTORY")
    args = parser.parse_args()
    try:
        rollback(args.rollback) if args.rollback else install()
    except (driver.DriverError, OSError, ValueError) as exc:
        print(f"Not installed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
