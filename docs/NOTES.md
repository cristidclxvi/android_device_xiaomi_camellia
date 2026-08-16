# Why this tree looks the way it does

Notes on the non-obvious parts. Everything here was measured on hardware or read
out of the shipped build, not inferred.

Device: Redmi Note 10 5G / Redmi Note 10T 5G / POCO M3 Pro 5G, MediaTek MT6833
(Dimensity 700). Kernel 4.14.357-openela: MiCode's 4.14.186 drop merged up to
the OpenELA stable tag.

## Android 16 on a 4.14 kernel

Android 16 (SDK 36) hard-requires kernel 4.19+ in several places. Left alone
that produces a silent boot loop with no crash record anywhere, because the
failure is an *orderly init-requested reboot*, not a panic. Nothing is written
to pstore, ramoops or expdb.

Android 14 ROMs for this device are unaffected: they are SDK 34 and the checks
are gated on `isAtLeastV`. Same kernel, different outcome, purely on the SDK
axis.

The fix lives in [`../patches/connectivity_android16_on_kernel414.patch`](../patches),
against `packages/modules/Connectivity`:

| File | Change | Why |
|---|---|---|
| `bpf/loader/NetBpfLoad.cpp` | V/4.19 and 25Q2/5.4 gates `return 5`/`return 6` -> `ALOGW` | fatal exit + `reboot_on_failure` = boot loop before zygote |
| `bpf/loader/NetBpfLoad.cpp` | drop `isAtLeastT` from the pre-4.20 BPF-UAPI degradation path | AOSP already implements this fallback for the "Xiaomi S 4.14.180 kernel uapi bug" but gates it to Android S |
| `bpf/loader/netbpfload.35rc` | comment out `reboot_on_failure` | AOSP's own documented procedure, written in that file under "How to debug bootloops caused by 'bpfloader-failed'" |
| `bpf/netd/BpfHandler.cpp` | same two gates -> `ALOGW` | `netd` aborted in `libnetd_updatable_init`, respawning every 5s forever |
| `staticlibs/.../SingleWriterBpfMap.java` | tolerate `ENOTSUPP` when priming the cache; override `clear()` and `forEach()` to use the cache | see below |

LineageOS already applies exactly this treatment to the 25Q4/5.10 gate in
`NetBpfLoad.cpp`, so the first two changes extend an established in-tree
pattern.

### The LPM_TRIE problem

`local_net_access_map` is a `BPF_MAP_TYPE_LPM_TRIE`. The kernel only implemented
`trie_get_next_key` in **4.20**; before that `BPF_MAP_GET_NEXT_KEY` returns the
kernel-internal `ENOTSUPP` (errno 524). Any code that walks the map therefore
fails, which crashed `system_server` during `NetworkStatsService` startup:

```
IllegalStateException: Failed to initialize local_net_access map
Caused by: ErrnoException: nativeGetNextMapKey failed: errno 524
```

`SingleWriterBpfMap` holds an exclusive lock and a write-through cache, and is
by construction the **sole writer** — it already serves `containsKey()` and
`getValue()` from that cache. The patch extends the same reasoning to the three
paths that would otherwise ask the kernel to enumerate: constructor cache
priming, `clear()` and `forEach()`. No behaviour change on kernels that can
iterate.

`local_net_access_map` is the only LPM_TRIE in the module; every other map
`BpfNetMaps` opens is HASH or ARRAY, which 4.14 iterates fine.

### Consequence

Per-app firewall and Data Saver work. The earlier claim here that cgroup BPF
does not load on 4.14 was wrong: the cgroupskb programs are pinned and
restrict-background is enforced, verified on device. Ordinary networking,
including mobile data, is validated end to end.

The bump to 4.14.357-openela has since been done, and it did **not** remove the
need for these patches. Every check the Connectivity patch relaxes tests for
4.19, 4.20 or 5.4, so no 4.14 sublevel can satisfy them, and `kernel/bpf/btf.c`
is still absent. `PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false`
likewise stays: the remaining blockers are `HAVE_MOVE_PMD` and `HAVE_MOVE_PUD`,
which do not exist anywhere in 4.14.

## Wi-Fi

MiCode never published `vendor/mediatek/kernel_modules`, so the sources come
from a fork of OnePlus's MT6833 modules tree, which is the same SoC. Wi-Fi,
Bluetooth, GPS, FM and the WMT/FEM support modules are all built from source
now rather than extracted from the device as prebuilts.

The note below is kept because it still explains why the prebuilts worked at
the time, and why vermagic is not something to worry about here.
`same_magic()` discards the release string when a module carries a `__versions`
section, and all 947 modversion CRCs match, so vermagic is a non-issue. Do
**not** create `.scmversion`.

Load order is orchestrated by the already-shipped `init.connfem.rc` /
`init.wmt_drv.rc` / `init.bt_drv.rc` against `vendor.connsys.driver.ready`. Do
**not** add them to a `modules.load`; that would insmod before CONNSYS is
powered.

Bluetooth, GPS and FM work from the modules alone.

### The actual root cause

**One line in `device.mk`:**

```make
$(call soong_config_set_bool,mediatek_wifi_hal,use_pre_u_qpr2_struct,true)
```

LineageOS ships `hardware/mediatek/libwifi-hal-wrapper` specifically to
translate MediaTek's older `wifi_hal_fn` layout to the one AOSP compiles
against. Its `Android.bp` selects the older layout from the soong config
`mediatek_wifi_hal.use_pre_u_qpr2_struct` — and nothing in the tree ever set it.
The wrapper therefore compiled its "legacy" struct at the Android 16 layout,
identical to the destination, and the translation degenerated into an identity
copy that translated nothing.

The blob writes Android-12-era offsets. The drift is piecewise-uniform: +0 slots
for struct indices 0-26, +2 for 27-28, +4 for 29-106, +12 from 107. Matching the
blob's 66 written slots against the struct compiled WITH the flag gives 44/44
symbol matches; without it, 11/44 — exactly the members below the first
divergence, which is why interface enumeration worked while everything past it
failed.

Verifiable before flashing, no device needed. `llvm-objdump` the built wrapper:
the `calloc` in `init_wifi_vendor_hal_func_table` must read `#1088` (136x8), not
`#1192` (149x8), and the max `ldr` immediate `#1080`, not `#1184`.

Do **not** also set `use_pre_baklava_qpr0_struct`; its `#ifndef` nests inside the
QPR2 guard, so the single flag already yields the right layout.

`"Can not initialize the vendor function pointer table"` is a **red herring**.
It comes from `wifi_legacy_hal_factory.cpp:112` on the first statically-linked
attempt, before the factory falls back to the XML path that loads the wrapper
successfully. It still appears after the fix, and other working ROMs log it too.

### patchelf version matters

`libwifi-hal-mtk.so` is stock's `libwifi-hal.so` with the soname corrected. The
patchelf version used to do that changes the outcome:

| patchelf | size | ifaces enumerated |
|---|---|---|
| unpatched | 201064 | 3 |
| 0_9 | 215808 | 3 |
| 0_18 | 280177 | **0** |

`0_18` restructures the binary enough to break `wifi_get_ifaces()`, and it is
the extract-utils default. The `FIX_SONAME` flag in `proprietary-files.txt`
always uses that default, so the fix is done in `extract-files.py` instead with
an explicit `.patchelf_version('0_9')`.

### Three further defects, all real but downstream of the above

1. **`android.hardware.wifi.aware.xml` and `android.hardware.wifi.rtt.xml` must
   not be declared.** Stock's vendor ships only `wifi.xml`, `wifi.direct.xml`
   and `wifi.passpoint.xml`. This chipset supports neither NAN nor 802.11mc
   ranging; declaring them made the framework allocate a NAN iface, fail, and
   tear down the whole Wi-Fi stack (`Failed to allocate new Nan iface` ->
   `Wifi HAL stopped`).
2. **`configureChip()` reports failure despite succeeding** — see
   [`../patches/wifi_mtk_configurechip_quirk.patch`](../patches). The vendor HAL
   configures the chip correctly (wlan0/wlan1/p2p0 handles appear immediately
   after) but returns false, because Android 16's newer AIDL chip queries return
   empty on this Android-13-era blob (`chipCapabilities={}`,
   `radioCombinations=null`). `HalDeviceManager` aborted on that. Made
   non-fatal.
3. **Both connsys firmware ASIC-ECO sets must ship.** Stock
   `/vendor/firmware` carries `soc2_2_ram_{bt,wifi,mcu}_1_1_hdr.bin` *and*
   `…_1a_1_hdr.bin`, plus both `WIFI_RAM_CODE_soc2_2_*`. The wlan driver builds
   the filename at runtime from the detected ECO revision, so shipping only one
   set leaves some units with no Wi-Fi and no Bluetooth.

## Camera

`drivers/misc/mediatek/imgsensor/src/Makefile` gated the sensor table on
`$(TARGET_PRODUCT)`, an Android build variable that never reaches the kernel
build — so the gate never matched and the sensor list compiled **empty**. The
camera service enumerated 0 devices while `camerahalserver` ran happily and all
492 camera libs were present. Defining `-DTARGET_PRODUCT_CAMELLIA`
unconditionally restores all 9 sensors, giving 4 camera devices. Fixed in the
kernel repository.

Only 2 of the 4 are app-visible (`normal camera devices: 2`); the depth and
macro sensors are auxiliary by design, exactly as stock does it.

## Display

- Manual brightness is byte-identical to stock (`display_id_0.xml`, 400 nit
  ceiling, backlight 2047/2047). Nothing to fix.
- **Auto-brightness was broken.** `mBrightnessLevelsNits` was empty, so the
  framework fell back to `config_autoBrightnessLcdBacklightValues`, which it
  reads on the legacy **0-255** scale while ours is written for **0-4095**.
  Everything past the 5th entry clamped to 1.0, pinning the screen to maximum
  above roughly 10 lux. Fixed by shipping
  `config_autoBrightnessDisplayValuesNits`.
- **HBM / LiveDisplay Outdoor mode.** Write **2** or **3** to
  `/sys/devices/platform/14000000.dispsys_config/mtk_fb_hbm`. Level **1 is the
  normal operating current** (21.8 mA) and looks like a no-op; 2 = 25 mA,
  3 = 27.4 mA. Wired up via
  [`../patches/livedisplay_sysfs_se_value.patch`](../patches), which adds a
  configurable enable value to the sysfs SunlightEnhancement HAL.

## Audio — one speaker, and why it looks like two

camellia is **mono**: one bottom loudspeaker driven by a single external smart
amplifier. Bottom-only playback is correct, and matches stock. This gets
re-investigated because several things in the tree look like evidence of stereo.
They are not:

- **Two amplifiers are declared** on i2c6 — `aw87559_pa_58@58` (Awinic) and
  `fs16xx@34` (FourSemi FS1815). They are second-source alternates for one
  footprint, not a stereo pair. Both carry the **same reset GPIO 139**, with
  contradictory polarity flags (`<&pio 139 0>` vs `<&pio 139 1>`); two
  independently controlled amps cannot share a reset line. Only one probes —
  `/sys/class/huaqin/interface/hw_info/audio_PA` reports which. Xiaomi's
  changelog comment "bring up second PA" means second *vendor*.
- **`cust_foursemi.dtsi` declares four amps** with `fsm,position` =
  `LTOP`/`LBTM`/`RTOP`/`RBTM`. That is a genuine stereo reference layout and it
  is dead code — no DTS includes it.
- **The MTK HAL blob contains `dual_speaker_output`** and
  `headphoneDualSpeaker_output`. Also dead: `audio_device.xml` never defines
  those paths, so the code has no mixer path to drive. Stock had the same blob
  and the same absence.
- **`two_in_one_speaker_output` exists in `audio_device.xml`** with *empty*
  turnon and turnoff bodies. In MTK terminology "2-in-1 speaker" is one
  transducer serving as both earpiece and loudspeaker — the opposite of stereo —
  and here it is a no-op.
- **The Speaker port declares `AUDIO_CHANNEL_OUT_STEREO`.** That only means the
  HAL accepts a 2-channel stream. `fs1815n/fsm_core.c:1038` sets `chs12 = 3`
  (sum L+R) when `dev_count == 1`, so the amp downmixes into its single
  transducer.

The decisive evidence is upstream of all of it: MT6359 has one loudspeaker
output, `LINEOUT L`, and no `LINEOUT R` widget exists. `mt6833-mt6359.c` has
exactly one speaker DAPM widget fed only from `LINEOUT L`, and one
`Ext_Speaker_Amp Switch`. The earpiece cannot carry media either — `RCV Mux`
offers only `{Open, Mute, Voice Playback, Test Mode}`.

Routing config is byte-identical to stock (`audio_device.xml`, `audio_em.xml`,
`audio_policy_volumes.xml`). The DSP layer deliberately differs: Xiaomi's
`misound` is replaced by `mtk_bessound` and `misoundfx` is dropped, which
changes tuning, not routing.

## Multi-variant

LK reads a board-ID ADC and emits `pcba_config`, `androidboot.rsc`,
`androidboot.hwc` and `androidboot.product.hardware.sku`. The model is a
function of **(sku, rsc)**, not sku alone — `sku=camellia` covers both
M2103K19C and M2103K19I. `libinit/` resolves identity from that pair and
includes a catch-all entry so an unrecognised unit gets sane defaults rather
than silently reporting the wrong device.

Selection of the actual hardware is runtime and happens below us: panels and
touch on `LCM_name=`, backlight on `:bklic=`, cameras by I2C ID, and both
fingerprint drivers self-gate on SPI chip-ID reads with cross-driver exclusion.

NFC is fitted only on `camellian` and `camellianp`. On `camellia` the hardware
is absent and its absence is correct rather than a fault; the stack ships and is
gated on the SKU exactly as stock does it.

## Prebuilts

`prebuilt/dtbo.img` and `prebuilt/dtb/camellia.dtb` are byte-identical to
factory (dtbo md5 `69f38af3796c4b8512eef0aa8910eaeb`; base DTB
`1d21abde9944861d7dd2fb2d66b24d5d`, taken from the factory boot.img at offset
34424832). Both are single-entry, so `dtb_idx=0`/`dtbo_idx=0` are the only
possible values and LK hardcodes `androidboot.dtb_idx=0`. The `.dts` sources for
the overlay were never published, which is why the binary ships.

## Build notes

```
lunch lineage_camellia-bp4a-userdebug
mka bacon
```

`WITH_ADB_INSECURE=true` is useful while debugging: LineageOS forces
`ro.debuggable=0` even on userdebug, so without it adb is unavailable until the
setup wizard completes — which is impossible if the device does not finish
booting. The shipped release does **not** set it.

Updates are recovery-sideload only. In-system OTA does not fit: VABC is off and
an uncompressed COW needs roughly 4.84 GB against 4.28 GB free. Recovery
sideload survives because it sets `delete_source = true`.
