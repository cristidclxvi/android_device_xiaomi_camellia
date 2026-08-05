# Install LineageOS 23.2 on camellia

Redmi Note 10 5G / Redmi Note 10T 5G / POCO M3 Pro 5G

> **WARNING:** These instructions are for LineageOS 23.2. They will only work if
> you follow every section and step precisely.
> **Do not continue after something fails.**

---

## 1. Basic requirements

1. Read through these instructions at least once before following them, so you
   don't get caught out by a missed step.
2. Make sure your computer has `adb` and `fastboot`.
3. Enable **USB debugging** on your device.
4. Make sure your model number is one of the following (exact match required):
   - `M2103K19C` — Redmi Note 10 5G (China)
   - `M2103K19G` — Redmi Note 10 5G (Global)
   - `M2103K19I` — Redmi Note 10T 5G (India)
   - `M2103K19PG` — POCO M3 Pro 5G (Global)
   - `M2103K19PI` — POCO M3 Pro 5G (India)
5. Your bootloader must already be unlocked. Unlocking is Xiaomi's process, done
   through Mi Unlock with the associated waiting period, and is out of scope
   here.
6. Boot the stock OS at least once and check every function works.

> **WARNING:** Make sure you can send and receive SMS, and place and receive
> calls (including over WiFi and LTE if you use them). If something doesn't work
> on stock, it won't work on LineageOS either.

7. Remove all Google accounts from your device to avoid Factory Reset
   Protection.
8. LineageOS is provided as-is with no warranty. This is an **unofficial**
   build. You are installing it at your own risk.

> **WARNING: Never relock your bootloader with this ROM installed.**
> `boot` and `vbmeta` are signed with a test key. A locked bootloader will refuse
> to verify them and the device will only be recoverable through BROM. If you
> want to relock, flash the full stock fastboot ROM first.

---

## 2. Checking the correct firmware

Installation requires a specific firmware version to already be present.

- Firmware means the device-specific images included in, and updated by, the
  stock OS — on camellia that's `lk`, `tee`, `scp`, `sspm`, `md1img` and others.
- LineageOS builds for this device require **MIUI 14 (Android 13)**, version
  **V14.0.x**, to be installed beforehand.
- Check the **Android version**, not the MIUI version.
- Being on another custom ROM — including a different unofficial LineageOS
  build — does **not** mean this requirement is met.

> **NOTE:** If you are unsure which firmware you're on, return to stock MIUI 14
> before following this guide. camellia has no anti-rollback, so downgrading from
> a newer MIUI or a HyperOS port is safe.

Firmware older than MIUI 14 is a real risk on this device: the vendor blobs in
this ROM come from V14.0.6.0, and a mismatched `tee` or `scp` typically shows up
as a broken lockscreen, fingerprint or DRM rather than a clean failure.

---

## 3. Installing LineageOS recovery

> **NOTE:** camellia has **no recovery partition**. The recovery lives inside
> `boot.img` along with the kernel, so you flash `boot`, not `recovery`.
> This also means TWRP and OrangeFox **cannot** be used — installing one would
> replace the LineageOS kernel, and this ROM's package format has no installer
> script for them to run.

1. Download `boot.img` for the build you intend to install.
2. Power off the device and boot into fastboot mode:
   - With the device powered off, hold **Volume Down + Power** until the
     fastboot screen appears.
3. Verify your computer sees the device:
   ```
   fastboot devices
   ```
4. Flash it:
   ```
   fastboot flash boot boot.img
   ```
5. Reboot straight into recovery — **do not boot the system yet**:
   ```
   fastboot reboot recovery
   ```
   You can also reach recovery from a powered-off device by holding
   **Volume Up + Power**.

> **NOTE:** LineageOS recovery is navigated with the **Volume** buttons to move
> and the **Power** button to select. It has no touch interface. This is normal
> and not a fault.

---

## 4. Installing LineageOS from recovery

1. Download the LineageOS `.zip` you want to install.
2. Select **Factory Reset**, then **Format data / factory reset**, and continue
   through the formatting process.

> **WARNING:** Do not skip the format. Installing over MIUI's data leaves you
> running LineageOS on top of MIUI's `/data` — you will see Xiaomi apps, the MIUI
> wallpaper, your old WiFi networks, and `android.process.media` crashing
> repeatedly. If you see those symptoms, come back here and format.

> **NOTE:** `fastboot -w` does **not** work on camellia. It reports
> `Erase successful, but not automatically formatting` and leaves userdata
> unformatted, which bootloops. Always format from recovery.

3. Return to the main menu.
4. Select **Apply update**, then **Apply from ADB**.
5. On your computer:
   ```
   adb -d sideload lineage-23.2-<date>-UNOFFICIAL-camellia.zip
   ```

> **NOTE:** Recovery will warn that the package *"will downgrade your system"*.
> **Accept it.** That check compares the package timestamp against
> `ro.build.date.utc`, which is unset in recovery and defaults to its maximum
> value, so the warning appears for every package — official LineageOS included.

> **TIP:** `adb` normally reports `Total xfer: 1.00x`. It may instead stop at
> around 47% and print `adb: failed to read command: Success`. That is also fine.

6. When the install finishes, recovery offers to reboot to recovery to install
   add-ons. Choose **Yes** if you want GApps (next section), otherwise **No**.

---

## 5. Installing GApps (optional)

GApps must be installed **before** you first boot the system, otherwise Play
Services has no initialised profile and you'll need to format again.

1. Download **MindTheGapps** for **arm64, Android 16**.
2. From the recovery main menu, select **Apply update**, then **Apply from ADB**.
3. On your computer:
   ```
   adb -d sideload MindTheGapps-16.0.0-arm64-<date>.zip
   ```
4. Reboot to system.

---

## 6. First boot

Select **Reboot system now**. The first boot after a format takes several
minutes — this is normal.

---

## Updating later

Reboot to recovery and sideload the newer `.zip`. No format, and no need to
reflash `boot`. The update installs to the unused slot and switches to it, so
your data is preserved.

---

## Notes specific to camellia

- **NFC** is only fitted on `camellian` and `camellianp` units (Global / POCO
  Global). On `camellia` the hardware is absent and its absence is correct.
- **Recovery has no touch input.** Use the volume keys.
- The ROM ships every variant's drivers and firmware and selects at runtime, so
  one build covers all five model numbers.
