# Xiaomi Redmi Note 10 5G (camellia)

Device configuration for the Xiaomi Redmi Note 10 5G. The Redmi Note 10T 5G and
the POCO M3 Pro 5G are the same hardware under different names and are covered
by this tree.

```
#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
```

## Specifications

| | |
|---|---|
| SoC | MediaTek MT6833 Dimensity 700 |
| CPU | 2x2.2 GHz Cortex-A76 + 6x2.0 GHz Cortex-A55 |
| GPU | Mali-G57 MC2 |
| Memory | 4/6/8 GB LPDDR4X |
| Storage | 64/128 GB UFS 2.2, microSD |
| Display | 6.5" 1080x2400 IPS LCD, 90 Hz |
| Battery | 5000 mAh |
| Rear camera | 48 MP wide + 2 MP depth + 2 MP macro |
| Front camera | 8 MP |
| Shipped with | Android 11, MIUI 12 |

## Models covered

| Model | Name | SKU |
|---|---|---|
| M2103K19C | Redmi Note 10 5G | `camellia` |
| M2103K19I | Redmi Note 10T 5G | `camellia` |
| M2103K19G | Redmi Note 10 5G | `camellian` |
| M2103K19PI | POCO M3 Pro 5G | `camelliap` |
| M2103K19PG | POCO M3 Pro 5G | `camellianp` |

One build serves all five. Both touchscreen controllers, both fingerprint
readers, both backlight ICs, all five display panels and every camera module
combination are compiled in and selected at boot from the bootloader's hardware
IDs.

## Unofficial LineageOS 23.2

This tree is not part of official LineageOS, and no official build exists for
this device.

- Downloads and checksums: [Releases](../../releases)
- Installing: [docs/INSTALL.md](docs/INSTALL.md)
- Why the tree looks the way it does: [docs/NOTES.md](docs/NOTES.md)

### Status

| | |
|---|---|
| Boot, telephony, 5G, VoLTE, mobile data | works |
| Wi-Fi 2.4/5 GHz, Bluetooth, GPS, FM radio | works |
| Cameras, main and front | works |
| Depth and macro sensors | auxiliary, not app-visible, same as stock |
| Audio, sensors, fingerprint, IR blaster | works |
| 90 Hz display, touch, auto-brightness | works |
| LiveDisplay including Outdoor mode | works |
| NFC (`camellian` / `camellianp` only) | untested; hardware absent on other SKUs |
| Per-app firewall, Data Saver | untested; cgroup BPF does not load on 4.14 |

Built `userdebug`, but not a debuggable build: `ro.debuggable=0`, `ro.secure=1`,
`ro.build.tags=release-keys`. `boot` and `vbmeta` are signed with a test key, so
**never relock the bootloader while this is installed**.

Tested on one M2103K19C by one person. The other four models are expected to
work and nothing is known to be wrong with them, but none has been verified.

## Building

The kernel is not in the LineageOS organisation, so it needs a local manifest.
Save this as `.repo/local_manifests/camellia.xml` in a `lineage-23.2` tree:

```xml
<manifest>
  <project name="cristidclxvi/android_device_xiaomi_camellia"
           path="device/xiaomi/camellia" remote="github" revision="lineage-23.2" />
  <project name="cristidclxvi/android_kernel_xiaomi_camellia"
           path="kernel/xiaomi/camellia" remote="github" revision="lineage-23.2" />
  <project name="LineageOS/android_device_mediatek_sepolicy_vndr"
           path="device/mediatek/sepolicy_vndr" remote="github" />
  <project name="LineageOS/android_hardware_mediatek"
           path="hardware/mediatek" remote="github" />
  <project name="LineageOS/android_hardware_xiaomi"
           path="hardware/xiaomi" remote="github" />

  <!-- Kernel toolchain. LineageOS ships clang r547379 and newer; this 4.14
       tree needs r383902, which AOSP keeps only on its Android 12 branches. -->
  <project name="platform/prebuilts/clang/host/linux-x86"
           path="prebuilts/clang/host/linux-x86-r383902"
           remote="aosp" revision="refs/tags/android-12.1.0_r27"
           clone-depth="1" />
</manifest>
```

That branch of the toolchain also carries an `Android.mk` which the current
build system refuses to see under `prebuilts/`, and which would pull in test
binaries this tree does not ship. Nothing in it is meant to be built, so mark
the directory once after syncing:

```
touch prebuilts/clang/host/linux-x86-r383902/.find-ignore
```

Apply the patches in [`patches/`](patches). They change repositories the
LineageOS manifest already provides and they are not optional. Then:

```
source build/envsetup.sh
lunch lineage_camellia-bp4a-userdebug
mka bacon
```

Proprietary blobs are not included. Extract them from a device running stock
MIUI 14 V14.0.6.0 with `./extract-files.py`.

A build from these repositories is functionally identical to a release but not
bit-identical. `CONFIG_LTO_CLANG` and `CONFIG_CFI_CLANG` make the kernel
non-deterministic, the build date and version strings are baked into the system
properties, and released images are signed with a private release key that is
not published, so your own build gets whichever keys you sign it with.

## Related

- Kernel: [android_kernel_xiaomi_camellia](https://github.com/cristidclxvi/android_kernel_xiaomi_camellia) — 4.14.186, branch `lineage-23.2`

The kernel branch is based directly on MiCode's `camellian-t-oss` commit, so the
MediaTek and Xiaomi history is intact and
`git diff f4e416aea06c..lineage-23.2` shows every change made for this device —
ten files.

## License

Apache-2.0, see [LICENSE](LICENSE). Two files under `prebuilt/` are not covered
by it:

- `prebuilt/dtbo.img` is Xiaomi's factory device tree overlay, shipped byte for
  byte because the published kernel sources do not contain what it is built
  from.
- `prebuilt/dtb/camellia.dtb` is GPL-2.0-only, compiled from the kernel device
  tree sources published in the kernel repository above.

Configuration files taken from the stock vendor image — the audio, media,
thermal and regional property files under `configs/` — remain the property of
Xiaomi and MediaTek and are redistributed unmodified.
