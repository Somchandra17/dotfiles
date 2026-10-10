#!/usr/bin/python3
"""Load this machine's NVIDIA GPU only after matching akmods are available."""
import argparse
import os
from pathlib import Path
import re
import stat
import subprocess
import sys

PCI = "0000:01:00.0"
RENDER = Path(f"/dev/dri/by-path/pci-{PCI}-render")
CERT = Path("/etc/pki/akmods/certs/public_key.der")
PRIVATE_KEY = Path("/etc/pki/akmods/private/private_key.priv")
MODULES = ("nvidia", "nvidia_modeset", "nvidia_drm", "nvidia_uvm")


class DriverError(RuntimeError):
    pass


def command_result(args, *, timeout=60):
    try:
        return subprocess.run(args, text=True, capture_output=True, timeout=timeout,
                              env={**os.environ, "LC_ALL": "C"})
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise DriverError(f"{args[0]}: {exc}") from exc


def run(args, *, timeout=60, check=True):
    result = command_result(args, timeout=timeout)
    if check and result.returncode:
        detail = (result.stderr or result.stdout).strip()[-2000:]
        raise DriverError(f"{' '.join(args)} failed: {detail}")
    return result.stdout.strip()


def expected_version():
    versions = run([
        "rpm", "-q", "--qf", "%{VERSION}\n",
        "xorg-x11-drv-nvidia", "xorg-x11-drv-nvidia-libs", "akmod-nvidia-open",
    ]).splitlines()
    if not versions or len(set(versions)) != 1 or not re.fullmatch(r"[0-9.]+", versions[0]):
        raise DriverError("NVIDIA userspace and akmod package versions do not agree")
    return versions[0]


def enrolled_key():
    # Never create a key or enroll anything. Refuse repairs if the existing key is absent.
    if not CERT.is_file() or not PRIVATE_KEY.is_file():
        raise DriverError("The existing akmods certificate or signing key is missing")
    if run(["mokutil", "--sb-state"]).splitlines() != ["SecureBoot enabled"]:
        raise DriverError("Secure Boot is not enabled; no security settings will be changed")
    result = command_result(["mokutil", "--test-key", str(CERT)])
    output = "\n".join(part.strip() for part in (result.stdout, result.stderr) if part.strip())
    # Some packaged mokutil builds return nonzero for an already-enrolled key.
    # Require the exact positive outcome, never just an exit code or a substring:
    # pending enrollment and blacklist outcomes can also return zero upstream.
    if output not in (f"{CERT} is already enrolled", f"{CERT} is already in db"):
        raise DriverError(f"The existing akmods key was not confirmed enrolled: {output[-2000:]}")
    serial = run([
        "openssl", "x509", "-inform", "DER", "-in", str(CERT),
        "-noout", "-serial",
    ])
    # kmod's PKCS#7 parser exposes the signer's certificate serial as sig_key,
    # not its subjectKeyIdentifier extension. Compare the same identifier.
    match = re.fullmatch(r"serial=([0-9A-Fa-f]+)", serial)
    if not match:
        raise DriverError("Cannot identify the existing akmods signing certificate")
    return match[1].lower().lstrip("0") or "0"


def metadata(kernel, module):
    fields = {}
    for line in run(["modinfo", "-k", kernel, module]).splitlines():
        name, separator, value = line.partition(":")
        if separator:
            fields.setdefault(name, []).append(value.strip())
    return fields


def verify_disk(kernel, version, key=None):
    for module in MODULES:
        fields = metadata(kernel, module)

        def first(name):
            return fields.get(name, [""])[0]

        filename = str(Path(first("filename")).resolve())
        prefix = f"/usr/lib/modules/{kernel}/extra/nvidia-open/"
        alternate = f"/lib/modules/{kernel}/extra/nvidia-open/"
        if not filename.startswith((prefix, alternate)):
            raise DriverError(f"{kernel}: {module} does not select the open module")
        if first("version") != version:
            raise DriverError(f"{kernel}: {module} is {first('version')}, expected {version}")
        if first("vermagic").split()[:1] != [kernel]:
            raise DriverError(f"{kernel}: {module} was built for a different kernel")
        sig_key = first("sig_key").replace(":", "").lower()
        normalized = sig_key.lstrip("0") or "0"
        if (first("sig_id") != "PKCS#7" or not first("signer") or not sig_key
                or (key is not None and normalized != (key.lstrip("0") or "0"))):
            raise DriverError(f"{kernel}: {module} does not have the expected signature metadata")
        for firmware in fields.get("firmware", []):
            path = Path(firmware)
            if path.is_absolute() or ".." in path.parts:
                raise DriverError(f"Unexpected firmware path: {firmware}")
            if not any(Path(f"/usr/lib/firmware/{firmware}{suffix}").is_file()
                       for suffix in ("", ".xz", ".zst")):
                raise DriverError(f"{kernel}: required firmware is missing: {firmware}")


def ensure_disk(kernel, key):
    version = expected_version()
    try:
        verify_disk(kernel, version, key)
    except DriverError as exc:
        print(f"NVIDIA: {exc}; building with the existing akmods key", flush=True)
        run(["akmods", "--force", "--kernels", kernel, "--akmod", "nvidia-open"], timeout=900)
        run(["depmod", "-a", kernel])
        # akmods can return success despite an individual failed build. Check the result.
        version = expected_version()
        verify_disk(kernel, version, key)
    return version


def verify_running(version):
    if Path("/sys/module/nvidia/version").read_text().strip() != version:
        raise DriverError("The running NVIDIA module does not match the installed driver")
    if Path("/sys/module/nvidia_drm/parameters/modeset").read_text().strip() != "Y":
        raise DriverError("NVIDIA DRM modesetting is disabled")
    if not RENDER.exists() or not stat.S_ISCHR(RENDER.stat().st_mode):
        raise DriverError(f"The NVIDIA render node is missing: {RENDER}")
    node = RENDER.resolve().name
    device = Path(f"/sys/class/drm/{node}/device").resolve()
    if device != Path(f"/sys/bus/pci/devices/{PCI}").resolve():
        raise DriverError("The render-node symlink points at a different GPU")


def boot():
    if os.geteuid() != 0:
        raise DriverError("Boot preparation must run as root")
    kernel = os.uname().release
    version = ensure_disk(kernel, enrolled_key())
    loaded = Path("/sys/module/nvidia/version")
    if loaded.exists() and loaded.read_text().strip() != version:
        # Never unload a GPU that may already be in use, and never restart the desktop.
        raise DriverError("An older NVIDIA module is already loaded; refusing to unload it")
    # Explicit loading bypasses alias blacklists. The kernel still verifies signatures.
    run(["modprobe", "nvidia_drm"])
    run(["udevadm", "wait", "--timeout=20", "--initialized=yes", str(RENDER)], timeout=30)
    verify_running(version)
    print(f"NVIDIA ready: open {version}, kernel {kernel}, GPU {PCI}", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("boot", "audit", "check"))
    parser.add_argument("--kernel", default=os.uname().release)
    args = parser.parse_args()
    try:
        if args.mode == "boot":
            boot()
        else:
            key = enrolled_key() if args.mode == "check" else None
            version = expected_version()
            verify_disk(args.kernel, version, key)
            print(f"On-disk open modules and firmware match {version} for {args.kernel}")
            if args.mode == "audit":
                print("Read-only audit: certificate enrollment and cryptographic load were not tested")
    except (DriverError, OSError) as exc:
        print(f"NVIDIA preparation failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
