# Patches to shared LineageOS repositories

These are **not** part of the device tree. They modify repositories the
LineageOS manifest already provides, so a buildbot build from the stock manifest
will not have them. Apply before building.

This is the complete set. Verified against the tree that produced the shipped
release: exactly three repositories are modified, and they are these three.
Kernel changes are not here — they are commits in
[android_kernel_xiaomi_camellia](https://github.com/cristidclxvi/android_kernel_xiaomi_camellia).

| Patch | Repository | Why |
|---|---|---|
| `connectivity_android16_on_kernel414.patch` | `packages/modules/Connectivity` | Android 16 hard-requires kernel 4.19+ in the BPF loader. On 4.14 the loader exits fatally and `reboot_on_failure` turns that into a silent boot loop with no crash record. Also tolerates `ENOTSUPP` (524) from `BPF_MAP_GET_NEXT_KEY`, which 4.14 returns for LPM_TRIE maps because `trie_get_next_key` only landed in 4.20. |
| `wifi_mtk_configurechip_quirk.patch` | `packages/modules/Wifi` | The Android-13-era MTK vendor HAL configures the chip correctly but reports failure, because Android 16's newer AIDL chip queries return empty on it. `HalDeviceManager` aborted on that. |
| `livedisplay_sysfs_se_value.patch` | `hardware/lineage/interfaces` | Adds a configurable enable value to the sysfs SunlightEnhancement HAL. camellia's panel needs `2` or `3` written to `mtk_fb_hbm`; `1` is the normal operating current and looks like a no-op. |

## Upstreaming status

`livedisplay_sysfs_se_value.patch` is genuinely upstreamable once the
device-specific hardcoded cflags are replaced by soong config values set from
`device.mk`.

`wifi_mtk_configurechip_quirk.patch` is at the wrong layer. It belongs in
`hardware/mediatek/libwifi-hal-wrapper`, which already carries soong knobs for
MTK ABI divergence, rather than in the framework where it affects every device.

`connectivity_android16_on_kernel414.patch` is the hard case: it relaxes checks
Google added deliberately. Note that LineageOS already ships an equivalent
relaxation for the 25Q4/5.10 gate in the same file, and that `davinci` runs
official LineageOS 23.2 on 4.14.357-openela with an unmodified Connectivity
module. That strongly suggests most of this patch is a symptom of our stale
4.14.186 base rather than of 4.14 itself, and that an openela stable bump would
remove the need for it. Revert and retest after that bump before proposing
anything upstream.
