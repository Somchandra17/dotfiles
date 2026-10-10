# First full boot verification

Verified by read-only inspection on 2026-10-10 immediately after the user's normal reboot.

- Boot ID: `d3695bee-94d9-4ec6-8067-a9371e5749c1`, different from the pre-installation boot.
- Boot estimate: 11:52:28 IST. Uptime at first inspection: approximately 50 seconds.
- Kernel: `7.2.9-300.fc45.x86_64`.
- Running NVIDIA module: open `615.78.08`.
- NVIDIA DRM modesetting: `Y`.
- NVIDIA driver, both installed userspace-library architectures, and open akmod package: `615.78.08`.
- Secure Boot: enabled.

Observed host system journal sequence:

| Time (IST) | Event |
| --- | --- |
| 11:52:37 | Packaged akmods service started |
| 11:52:38 | Akmods confirmed current-kernel modules and finished |
| 11:52:38 | Custom NVIDIA preparation service started |
| 11:52:39 | Helper reported `NVIDIA ready: open 615.78.08, kernel 7.2.9-300.fc45.x86_64, GPU 0000:01:00.0` and service finished |
| 11:52:42 | GDM started |
| 11:52:49 | Niri initialized NVIDIA and connected the LG ultrawide |

Niri opened `/dev/dri/by-path/pci-0000:01:00.0-render`, resolved it to `/dev/dri/renderD129`, initialized that primary renderer, and connected `DP-5` with mode `3440x1440` at `160 Hz`.

The NVIDIA render node maps to PCI device `0000:01:00.0`; Intel remains on its own render node. The current kernel journal contains none of the earlier NVIDIA API-mismatch, missing-GSP-image, or adapter-initialization error messages.

The system bus remains inaccessible to this tool sandbox, so service completion/order was established from the host journal rather than `systemctl show`. The older kernel build/image passed installation checks but has not been boot-tested. A future package-version update has not yet been observed; failure cases were exercised by the automated tests. This is evidence that the installed boot path works, not a guarantee against future incompatible upstream releases.
