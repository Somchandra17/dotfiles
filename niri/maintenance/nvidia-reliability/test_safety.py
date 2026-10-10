"""Exercise update failures and transactional boot-image replacement without root."""
import os
from contextlib import ExitStack
from pathlib import Path
import tempfile
import subprocess
import unittest
from unittest.mock import patch

import install as installer
import nvidia_ready as driver

KERNEL = "9.9.9-300.fc45.x86_64"
VERSION = "615.78.08"
KEY = "37b742e07ff3f05332cb806db699a393908bc9d3"


def info(module, *, version=VERSION, flavor="nvidia-open", key=KEY):
    return {
        "filename": [f"/usr/lib/modules/{KERNEL}/extra/{flavor}/{module.replace('_', '-')}.ko.xz"],
        "version": [version], "vermagic": [KERNEL + " SMP"],
        "signer": ["existing-akmods-key"], "sig_key": [key], "sig_id": ["PKCS#7"],
    }


class UpdateSafety(unittest.TestCase):
    def check_enrollment_result(self, result):
        with patch.object(Path, "is_file", return_value=True), \
             patch.object(driver, "run", side_effect=["SecureBoot enabled", f"serial={KEY.upper()}"]), \
             patch.object(driver, "command_result", return_value=result):
            return driver.enrolled_key()

    def test_enrolled_key_with_nonzero_exit_is_accepted(self):
        for status in (1, 255):
            for stream in ("stdout", "stderr"):
                with self.subTest(status=status, stream=stream):
                    output = {"stdout": "", "stderr": ""}
                    output[stream] = f"{driver.CERT} is already enrolled\n"
                    result = subprocess.CompletedProcess([], status, **output)
                    self.assertEqual(self.check_enrollment_result(result), KEY)

    def test_enrolled_key_with_zero_exit_is_accepted(self):
        result = subprocess.CompletedProcess([], 0, f"{driver.CERT} is already enrolled\n", "")
        self.assertEqual(self.check_enrollment_result(result), KEY)

    def test_firmware_db_key_is_accepted(self):
        result = subprocess.CompletedProcess([], 0, f"{driver.CERT} is already in db\n", "")
        self.assertEqual(self.check_enrollment_result(result), KEY)

    def test_pending_blocked_missing_and_unreadable_keys_are_rejected_even_with_zero_exit(self):
        for message in ("is not enrolled", "is already in the enrollment request",
                        "is blocked in dbx", "is blocked in MokListX"):
            with self.subTest(message=message):
                result = subprocess.CompletedProcess([], 0, f"{driver.CERT} {message}\n", "")
                with self.assertRaisesRegex(driver.DriverError, "not confirmed enrolled"):
                    self.check_enrollment_result(result)
        result = subprocess.CompletedProcess([], 255, "", f"Failed to open {driver.CERT}\n")
        with self.assertRaisesRegex(driver.DriverError, "not confirmed enrolled"):
            self.check_enrollment_result(result)

    def test_enrollment_message_with_additional_error_is_rejected(self):
        result = subprocess.CompletedProcess([], 1, f"{driver.CERT} is already enrolled\n",
                                             "Failed to read firmware variables\n")
        with self.assertRaisesRegex(driver.DriverError, "not confirmed enrolled"):
            self.check_enrollment_result(result)

    def test_secure_boot_with_disabled_shim_validation_is_rejected(self):
        with patch.object(Path, "is_file", return_value=True), \
             patch.object(driver, "run", return_value="SecureBoot enabled\nSecureBoot validation is disabled in shim"), \
             patch.object(driver, "command_result") as command:
            with self.assertRaisesRegex(driver.DriverError, "Secure Boot"):
                driver.enrolled_key()
            command.assert_not_called()

    def test_certificate_serial_is_used_instead_of_subject_key_identifier(self):
        def command(args, **kwargs):
            if args == ["mokutil", "--sb-state"]:
                return "SecureBoot enabled"
            self.assertEqual(args[-2:], ["-noout", "-serial"])
            return f"serial={KEY.upper()}"
        result = subprocess.CompletedProcess([], 1, f"{driver.CERT} is already enrolled\n", "")
        with patch.object(Path, "is_file", return_value=True), \
             patch.object(driver, "run", side_effect=command), \
             patch.object(driver, "command_result", return_value=result):
            self.assertEqual(driver.enrolled_key(), KEY)

    def test_signature_serial_leading_zero_padding_is_normalized(self):
        with patch.object(driver, "metadata", side_effect=lambda k, m: info(m, key="00" + KEY)):
            driver.verify_disk(KERNEL, VERSION, KEY)

    def test_unsupported_signature_identifier_is_rejected(self):
        fields = info("nvidia")
        fields["sig_id"] = ["X509"]
        with patch.object(driver, "metadata", return_value=fields):
            with self.assertRaisesRegex(driver.DriverError, "signature"):
                driver.verify_disk(KERNEL, VERSION, KEY)

    def test_matching_open_modules_need_no_build(self):
        with patch.object(driver, "metadata", side_effect=lambda k, m: info(m)):
            driver.verify_disk(KERNEL, VERSION, KEY)

    def test_stale_module_is_rejected(self):
        with patch.object(driver, "metadata", side_effect=lambda k, m: info(m, version="615.71.09")):
            with self.assertRaisesRegex(driver.DriverError, "expected"):
                driver.verify_disk(KERNEL, VERSION, KEY)

    def test_wrong_signing_key_is_rejected(self):
        with patch.object(driver, "metadata", side_effect=lambda k, m: info(m, key="deadbeef")):
            with self.assertRaisesRegex(driver.DriverError, "signature"):
                driver.verify_disk(KERNEL, VERSION, KEY)

    def test_proprietary_precedence_is_rejected(self):
        with patch.object(driver, "metadata", side_effect=lambda k, m: info(m, flavor="nvidia")):
            with self.assertRaisesRegex(driver.DriverError, "open module"):
                driver.verify_disk(KERNEL, VERSION, KEY)

    def test_missing_firmware_is_rejected(self):
        fields = info("nvidia")
        fields["firmware"] = ["nvidia/does-not-exist/gsp_ga10x.bin"]
        with patch.object(driver, "metadata", return_value=fields):
            with self.assertRaisesRegex(driver.DriverError, "firmware is missing"):
                driver.verify_disk(KERNEL, VERSION, KEY)

    def test_missing_or_stale_build_is_repaired_and_rechecked(self):
        with patch.object(driver, "expected_version", return_value=VERSION), \
             patch.object(driver, "verify_disk", side_effect=[driver.DriverError("missing"), None]) as verify, \
             patch.object(driver, "run") as command:
            self.assertEqual(driver.ensure_disk(KERNEL, KEY), VERSION)
            self.assertEqual(command.call_args_list[0].args[0],
                             ["akmods", "--force", "--kernels", KERNEL, "--akmod", "nvidia-open"])
            self.assertEqual(verify.call_count, 2)

    def test_akmods_success_exit_does_not_hide_a_failed_build(self):
        with patch.object(driver, "expected_version", return_value=VERSION), \
             patch.object(driver, "verify_disk", side_effect=driver.DriverError("still stale")), \
             patch.object(driver, "run", return_value=""):
            with self.assertRaisesRegex(driver.DriverError, "still stale"):
                driver.ensure_disk(KERNEL, KEY)

    def test_boot_never_unloads_an_already_loaded_old_gpu(self):
        with patch.object(driver.os, "geteuid", return_value=0), \
             patch.object(driver, "enrolled_key", return_value=KEY), \
             patch.object(driver, "ensure_disk", return_value=VERSION), \
             patch.object(Path, "exists", return_value=True), \
             patch.object(Path, "read_text", return_value="615.71.09"), \
             patch.object(driver, "run") as command:
            with self.assertRaisesRegex(driver.DriverError, "refusing to unload"):
                driver.boot()
            command.assert_not_called()

    def test_boot_loads_explicitly_then_waits_for_render_node(self):
        with patch.object(driver.os, "geteuid", return_value=0), \
             patch.object(driver, "enrolled_key", return_value=KEY), \
             patch.object(driver, "ensure_disk", return_value=VERSION), \
             patch.object(Path, "exists", return_value=True), \
             patch.object(Path, "read_text", return_value=VERSION), \
             patch.object(driver, "verify_running") as verify, \
             patch.object(driver, "run") as command:
            driver.boot()
            self.assertEqual(command.call_args_list[0].args[0], ["modprobe", "nvidia_drm"])
            self.assertIn("--initialized=yes", command.call_args_list[1].args[0])
            verify.assert_called_once_with(VERSION)

    def test_mixed_userspace_package_versions_are_rejected(self):
        with patch.object(driver, "run", return_value="615.78.08\n615.71.09\n615.78.08"):
            with self.assertRaisesRegex(driver.DriverError, "do not agree"):
                driver.expected_version()


class InstallationSafety(unittest.TestCase):
    def test_non_root_installer_stops_before_inspecting_or_changing_files(self):
        with patch.object(installer.os, "geteuid", return_value=1000), \
             patch.object(driver, "run") as command:
            with self.assertRaisesRegex(driver.DriverError, "no changes"):
                installer.preflight()
            command.assert_not_called()

    def test_remove_nvidia_preserves_unrelated_early_drivers(self):
        original = 'add_drivers+=" nvme nvidia nvidia-drm btrfs "\nomit_drivers+=" nouveau "\n'
        changed = installer.rewrite_dracut(original)
        self.assertIn('add_drivers+=" nvme btrfs "', changed)
        self.assertNotIn('add_drivers+=" nvme nvidia', changed)
        self.assertEqual(installer.rewrite_dracut(changed), changed)

    def test_dynamic_nvidia_assignment_is_not_overwritten(self):
        with self.assertRaisesRegex(driver.DriverError, "dynamic"):
            installer.rewrite_dracut("add_drivers+=${nvidia_extra}\n")

    def test_niri_change_is_limited_to_gpu_path(self):
        original = 'output "DP-5" { scale 1; }\ndebug {\n    render-drm-device "/dev/dri/renderD129"\n}\n'
        changed = installer.rewrite_niri(original)
        self.assertEqual(changed, original.replace("/dev/dri/renderD129", str(driver.RENDER)))

    def test_embedded_nvidia_module_is_detected(self):
        listing = f"usr/lib/modules/{KERNEL}/extra/nvidia-open/nvidia-drm.ko.xz\n"
        with patch.object(driver, "run", return_value=listing):
            with self.assertRaisesRegex(driver.DriverError, "remain"):
                installer.verify_image(Path("candidate.img"), KERNEL)

    def test_login_is_a_weak_dependency_not_a_hard_failure(self):
        dropin = (installer.BUNDLE / "files/20-nvidia-ready.conf").read_text()
        self.assertIn("Wants=nvidia-boot-ready.service", dropin)
        self.assertIn("After=nvidia-boot-ready.service", dropin)
        self.assertNotIn("Requires=", dropin)
        unit = (installer.BUNDLE / "files/nvidia-boot-ready.service").read_text()
        self.assertIn("After=akmods.service", unit)
        self.assertIn("nvidia-fallback.service", unit)

    def test_backup_restores_original_and_removes_new_file(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            original, added = root / "original", root / "added"
            original.write_text("working image")
            original.chmod(0o600)
            with patch.object(installer, "STATE", root / "backups"):
                backup, manifest = installer.snapshot([original, added])
            original.write_text("replacement")
            added.write_text("new policy")
            with patch.object(driver, "run"):
                installer.restore(backup, manifest)
            self.assertEqual(original.read_text(), "working image")
            self.assertEqual(original.stat().st_mode & 0o777, 0o600)
            self.assertFalse(added.exists())

    def test_second_bad_candidate_leaves_live_files_untouched(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            dracut = root / "conf.d/nvidia.conf"
            dracut.parent.mkdir()
            dracut.write_text('add_drivers+=" nvidia "\nomit_drivers+=" nouveau "\n')
            niri = root / "live.kdl"
            niri.write_text('debug {\n render-drm-device "/dev/dri/renderD129"\n}\n')
            original_dracut, original_niri = dracut.read_bytes(), niri.read_bytes()

            def fake_command(args, **kwargs):
                if args[0] == "dracut":
                    Path(args[-2]).write_bytes(b"candidate")
                return ""

            with patch.object(installer, "preflight", return_value=(KEY, [KERNEL, "9.9.8-300.fc45.x86_64"])), \
                 patch.object(installer, "protected_hashes", return_value={}), \
                 patch.object(installer, "DRACUT", dracut), patch.object(installer, "NIRI", niri), \
                 patch.object(installer, "STAGING", root), \
                 patch.object(driver, "ensure_disk"), patch.object(driver, "run", side_effect=fake_command), \
                 patch.object(installer, "verify_image", side_effect=[None, driver.DriverError("stale image")]), \
                 patch.object(installer, "snapshot") as snapshot:
                with self.assertRaisesRegex(driver.DriverError, "stale image"):
                    installer.install()
                snapshot.assert_not_called()
            self.assertEqual(dracut.read_bytes(), original_dracut)
            self.assertEqual(niri.read_bytes(), original_niri)

    def test_copy_failure_rolls_back_both_images_and_configuration(self):
        self.exercise_transaction(fail_copy=True)

    def test_successful_transaction_installs_both_inspected_images(self):
        self.exercise_transaction(fail_copy=False)

    def exercise_transaction(self, fail_copy):
        with tempfile.TemporaryDirectory() as temporary, ExitStack() as stack:
            root = Path(temporary)
            kernels = [KERNEL, "9.9.8-300.fc45.x86_64"]
            paths = {
                "BOOT": root / "boot", "STATE": root / "backups", "STAGING": root,
                "DRACUT": root / "etc/dracut.conf.d/nvidia.conf",
                "NIRI": root / "home/config.kdl", "RUNTIME": root / "local/nvidia_ready.py",
                "UNIT": root / "etc/systemd/system/nvidia-boot-ready.service",
                "GDM": root / "etc/systemd/system/gdm.service.d/20-nvidia-ready.conf",
                "MODPROBE": root / "etc/modprobe.d/90-nvidia-managed-load.conf",
            }
            for name, value in paths.items():
                stack.enter_context(patch.object(installer, name, value))
            paths["BOOT"].mkdir()
            paths["DRACUT"].parent.mkdir(parents=True)
            paths["NIRI"].parent.mkdir(parents=True)
            paths["DRACUT"].write_text('add_drivers+=" nvidia "\nomit_drivers+=" nouveau "\n')
            paths["NIRI"].write_text('debug {\n render-drm-device "/dev/dri/renderD129"\n}\n')
            images = [paths["BOOT"] / f"initramfs-{kernel}.img" for kernel in kernels]
            for image in images:
                image.write_bytes(b"original image")
            originals = {path: path.read_bytes() for path in [paths["DRACUT"], paths["NIRI"], *images]}

            def fake_command(args, **kwargs):
                if args[0] == "dracut":
                    Path(args[-2]).write_bytes(b"inspected candidate")
                if args[:3] == ["systemctl", "show", "gdm.service"]:
                    return "Wants=nvidia-boot-ready.service\nAfter=nvidia-boot-ready.service"
                return ""

            real_copy = installer.atomic_copy
            failed_once = False

            def copy(source, destination, record, **kwargs):
                nonlocal failed_once
                if fail_copy and destination == images[1] and not failed_once:
                    failed_once = True
                    raise driver.DriverError("simulated second-image copy failure")
                return real_copy(source, destination, record, **kwargs)

            stack.enter_context(patch.object(installer, "preflight", return_value=(KEY, kernels)))
            stack.enter_context(patch.object(installer, "protected_hashes", return_value={}))
            stack.enter_context(patch.object(driver, "ensure_disk"))
            stack.enter_context(patch.object(driver, "verify_disk"))
            stack.enter_context(patch.object(driver, "expected_version", return_value=VERSION))
            stack.enter_context(patch.object(driver, "run", side_effect=fake_command))
            stack.enter_context(patch.object(installer, "verify_image"))
            stack.enter_context(patch.object(installer, "atomic_copy", side_effect=copy))
            # Newly created production files belong to root; test files remain in the temp fixture.
            stack.enter_context(patch.object(installer.os, "fchown"))
            if fail_copy:
                with self.assertRaisesRegex(driver.DriverError, "second-image"):
                    installer.install()
                for path, content in originals.items():
                    self.assertEqual(path.read_bytes(), content)
                for name in ("UNIT", "RUNTIME", "MODPROBE", "GDM"):
                    self.assertFalse(paths[name].exists())
            else:
                installer.install()
                for image in images:
                    self.assertEqual(image.read_bytes(), b"inspected candidate")
                self.assertIn(str(driver.RENDER), paths["NIRI"].read_text())
                self.assertIn("blacklist nvidia", paths["MODPROBE"].read_text())


if __name__ == "__main__":
    unittest.main(verbosity=2)
