# Install LineageOS 23.2 on camellia

Redmi Note 10 5G / Redmi Note 10T 5G / POCO M3 Pro 5G

> **WARNING:** The provided instructions are for LineageOS 23.2. These will only
> work if you follow every section and step precisely.
> **Do not continue after something fails!**

---

## Basic requirements

1. Read through the instructions at least once before actually following them, so
   as to avoid any problems due to any missed steps!
2. Make sure your computer has `adb` and `fastboot`.
3. Enable **USB debugging** on your device.
4. Make sure that your model number is one of the following (exact match
   required!):

   | Model | Device | Status |
   |---|---|---|
   | `M2103K19C` | Redmi Note 10 5G (China) | **tested** |
   | `M2103K19G` | Redmi Note 10 5G (Global) | untested |
   | `M2103K19I` | Redmi Note 10T 5G (India) | untested |
   | `M2103K19PG` | POCO M3 Pro 5G (Global) | untested |
   | `M2103K19PI` | POCO M3 Pro 5G (India) | untested |

> **WARNING:** This ROM has only ever been installed and run on **`M2103K19C`**,
> by one person, on one unit. The other four models are **expected** to work and
> nothing is known to be wrong with them — one build serves all five, because
> every variant's drivers and firmware ship together and the correct ones are
> chosen at runtime from the hardware IDs. But "expected to work" is not the same
> as "tested", and no one has verified them.
>
> If you have one of the untested models, please treat this as a first run and be
> prepared to return to stock. Reports are very welcome — the most useful thing
> you can post is the output of:
> ```
> cat /proc/cmdline
> getprop | grep -E "sku|rsc|hwc|marketname|ro.product.model"
> ```
> plus whether NFC, the fingerprint reader, the cameras and mobile data work.
5. Your bootloader must already be unlocked. Unlocking is Xiaomi's own process
   via Mi Unlock, including their waiting period, and is out of scope here.
6. Boot your device with the stock OS at least once and check every
   functionality.

> **WARNING:** Make sure that you can send and receive SMS and place and receive
> calls (also via WiFi and LTE, if available), otherwise it won't work on
> LineageOS either!

7. Remove all Google accounts from your device to avoid "Factory reset
   protection".
8. LineageOS is provided as-is with no warranty. This is an **unofficial** build.
   While we attempt to verify everything works, you are installing this at your
   own risk!

> **WARNING: Never relock your bootloader while this ROM is installed.**
> `boot` and `vbmeta` are signed with a test key, so a locked bootloader will
> refuse to verify them and the device will only be recoverable via BROM. If you
> want to relock, flash the full stock fastboot ROM first.

---

## Checking the correct firmware

Installation on your device requires a specific firmware version to be installed
before you continue.

- Firmware refers to a device-specific set of images that are included in, and
  updated by, the stock OS — on camellia that means `lk`, `tee`, `scp`, `sspm`,
  `md1img` and others.
- LineageOS builds for this device require a **MIUI 14 (Android 13)** version of
  the stock OS, specifically **V14.0.x**, to be installed prior to following the
  installation guide.
- Please ensure that you are checking the **Android** version, and not the MIUI
  version.
- Being on another custom ROM, including unofficial builds of the same version of
  LineageOS, does not ensure that this requirement has been fulfilled.
- Please re-read this section as many times as necessary to fully understand the
  requirements.

> **NOTE:** If you are unsure what firmware version you are currently on, we
> strongly recommend returning to stock MIUI 14 before following the installation
> guide. camellia has no anti-rollback, so downgrading from a newer MIUI or from
> a HyperOS port is safe.

Failing to install the correct firmware version prior to installation may result
in failure to install LineageOS, or unexpected crashes post-installation. The
vendor blobs in this ROM come from V14.0.6.0, and a mismatched `tee` or `scp`
typically presents as a broken lockscreen, fingerprint or DRM rather than as a
clean failure.

---

## Installing LineageOS recovery using fastboot

> **NOTE:** camellia has **no recovery partition**. The recovery is contained
> inside `boot.img` together with the kernel, so you flash `boot`, not
> `recovery`.

> **IMPORTANT:** Other recoveries will not work for installation or updates.
> TWRP and OrangeFox **cannot** be used on this device — installing one replaces
> the LineageOS kernel, and this package format contains no installer script for
> them to execute. We strongly recommend using only the recovery included in
> `boot.img`.

1. Download `boot.img` for the build you intend to install.
2. Power off the device, and boot it into fastboot mode:
   - With the device powered off, hold **Volume Down + Power**.
3. Once the device is in fastboot mode, verify your PC finds it by typing:
   ```
   fastboot devices
   ```
4. Flash boot onto your device:
   ```
   fastboot flash boot boot.img
   ```

> **NOTE:** If you are facing an error similar to `No such file or directory`
> when executing any `fastboot flash` command, it is because fastboot doesn't
> know where exactly your file is located. Either pass the full path to it, or
> type the first three parts of the command (e.g. `fastboot flash boot `,
> including a space at the end) and then drag and drop the file into the console.

5. Now reboot into recovery to verify the installation:
   ```
   fastboot reboot recovery
   ```
   You can also boot into recovery via a key combination: with the device
   powered off, hold **Volume Up + Power**.

> **NOTE:** You'll need to use the **Volume Buttons** to cycle onscreen options
> and the **Power Button** to select. LineageOS recovery has no touch interface;
> this is normal and not a fault.

> **NOTE:** If your recovery does not show the LineageOS logo, you accidentally
> booted into the wrong recovery. Please start at the top of this section!

---

## Installing LineageOS from recovery

1. Download the LineageOS zip file that you would like to install, or build the
   package yourself.
2. Now select **Factory Reset**, then **Format data / factory reset** and
   continue with the formatting process. This will remove encryption and delete
   all files stored in the internal storage.

> **WARNING:** Do not skip the format. Installing over MIUI's data leaves you
> running LineageOS on top of MIUI's `/data`: you will see Xiaomi apps, the MIUI
> wallpaper, your previous WiFi networks, and `android.process.media` crashing
> repeatedly. If you see those symptoms, return here and format.

> **NOTE:** `fastboot -w` does **not** work on camellia. It reports
> `Erase successful, but not automatically formatting` and leaves userdata
> unformatted, which bootloops. Always format from recovery.

3. Return to the main menu.
4. **Sideload the LineageOS .zip package, but do not reboot to system before you
   have read and followed the rest of the instructions!**
   - On the device, select **Apply update**, then **Apply from ADB** to begin
     sideload.
   - On the host machine, sideload the package using:
     ```
     adb -d sideload /path/to/lineage-23.2-<date>-UNOFFICIAL-camellia.zip
     ```

> **NOTE:** Recovery will warn that the package *"will downgrade your system"*.
> **Accept it.** That check compares the package timestamp against
> `ro.build.date.utc`, which is unset in recovery and therefore defaults to its
> maximum value, so the prompt appears for every package — including official
> LineageOS builds.

> **TIP:** After the package is installed, recovery will inform you that a reboot
> to recovery is required to install add-ons. If you want to install Google Apps,
> select **Yes**, otherwise **No**.

> **TIP:** Normally, adb reports `Total xfer: 1.00x`, but in some cases, even if
> the process succeeds, the output may stop at 47% and show
> `adb: failed to read command: Success`, which is also fine.

---

## Installing Add-Ons

> **NOTE:** If you don't want to install any add-on (such as Google Apps), you
> can skip this whole section!

> **WARNING:** If you want to install the Google Apps add-on package, use
> **MindTheGapps** for the **arm64** architecture and **Android 16**. This add-on
> needs to be installed **before booting into LineageOS for the first time!**

1. Click **Apply update**, then **Apply from ADB**, then run for each of those
   packages in sequence:
   ```
   adb -d sideload /path/to/MindTheGapps-16.0.0-arm64-<date>.zip
   ```

   When presented with a screen that says `Signature verification failed`, click
   **Yes**. It is expected, as add-ons aren't signed with LineageOS's key.

> **NOTE:** If you boot the system before installing GApps, Play Services will
> have no initialised profile. You will need to return to recovery, format data
> again, re-sideload the add-on, and only then boot.

---

## All set!

Once you have installed everything successfully, you can now reboot your device
into the OS for the first time!

Click the back arrow in the top left of the screen, then **Reboot system now**.

> **NOTE:** The first boot after a format usually takes no longer than 15
> minutes. If it takes longer, you may have missed a step.

---

## Updating later

Reboot to recovery and sideload the newer `.zip`. There is no need to format, and
no need to reflash `boot`. The update installs to the unused slot and switches to
it, so your data is preserved.

---

## Notes specific to camellia

- **NFC** is only fitted on `camellian` and `camellianp` units (Global and POCO
  Global). On `camellia` the hardware is absent, and its absence is correct
  rather than a fault. The NFC stack ships and is gated on the SKU exactly as
  stock does it, but since no NFC-equipped unit was available it has never
  actually run.
- **Recovery has no touch input.** Use the volume keys to move and power to
  select.
- One build covers all five model numbers. Both touchscreen controllers, both
  fingerprint readers, both backlight ICs, all five display panels and all nine
  camera sensor combinations are compiled in and selected at runtime from the
  bootloader's hardware IDs. On the tested unit that means NVT touch, FPC
  fingerprint, TI backlight and a Tianma panel; the alternates are shipped but
  have never been exercised.
- **Auto-brightness** is calibrated against the one panel present on the tested
  unit. The other four panels may read slightly differently.
- Device identity (brand, model, market name) is resolved per variant at boot, so
  a POCO should report as a POCO. This works on the tested unit but, like
  everything else above, has not been confirmed on the others.
