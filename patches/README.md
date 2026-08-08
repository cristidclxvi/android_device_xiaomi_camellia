# Patches to shared LineageOS repositories

These are **not** part of the device tree. They modify repositories the
LineageOS manifest already provides, so a buildbot build from the stock manifest
will not have them. Apply before building.

Kernel changes are not here — they are commits in
[android_kernel_xiaomi_camellia](https://github.com/cristidclxvi/android_kernel_xiaomi_camellia).

| Patch | Repository | Why |
|---|---|---|
| `connectivity_android16_on_kernel414.patch` | `packages/modules/Connectivity` | Android 16 hard-requires kernel 4.19+ in the BPF loader. On 4.14 the loader exits fatally and `reboot_on_failure` turns that into a silent boot loop with no crash record. Also tolerates `ENOTSUPP` (524) from `BPF_MAP_GET_NEXT_KEY`, which 4.14 returns for LPM_TRIE maps because `trie_get_next_key` only landed in 4.20. |
| `wifi_mtk_configurechip_quirk.patch` | `packages/modules/Wifi` | The Android-13-era MTK vendor HAL configures the chip correctly but reports failure, because Android 16's newer AIDL chip queries return empty on it. `HalDeviceManager` aborted on that. |
| `wifi_countrycode_chip_fallback.patch` | `packages/modules/Wifi` | Wi-Fi is weak at range because the country code never reaches the radio, so gen4m runs the worldwide row of its TX power table. `WifiCountryCode` only ever pushes the country through `ConcreteClientModeManager`, i.e. wpa_supplicant, which delivers it as a vendor `driver_cmd`. We build without `BOARD_WPA_SUPPLICANT_PRIVATE_LIB`, so soong compiles with `-DANDROID_LIB_STUB` and `.driver_cmd` is left out of `wpa_driver_nl80211_ops` entirely — every driver command fails with an empty `ServiceSpecificException`, deterministically, forever. A private lib would not help: the stock `wlan_drv_gen4m.ko` has no `COUNTRY` handler. It does export `mtk_cfg80211_vendor_set_country_code`, reached by the chip-level vendor HAL, which SoftAP start already uses successfully — kernel log shows `Set country code: ID` and the scan then reports `Country Code = ID`. This falls back to that path for client mode. |
| `livedisplay_sysfs_se_value.patch` | `hardware/lineage/interfaces` | Adds a configurable enable value to the sysfs SunlightEnhancement HAL. camellia's panel needs `2` or `3` written to `mtk_fb_hbm`; `1` is the normal operating current and looks like a no-op. |
| `tethering_dns_forwarder_nonfatal.patch` | `packages/modules/Connectivity` | The Wi-Fi hotspot dies the instant mobile data is switched on. netd's legacy `dnsmasq` DNS proxy never actually starts here — `posix_spawn` reports success because the fork succeeded, and the exec failure in the child is silent, so netd holds a pipe with no reader. The first write lands in the pipe buffer and appears to succeed; nothing writes again until an upstream appears, at which point `setDnsForwarders` gets `EREMOTEIO` and `Tethering` transitions to `SetDnsForwardersErrorState`, which calls `tetherStop()` and `ipfwdDisableForwarding()` and drops the AP. This makes the failure non-fatal, matching what the IPv6 path in `IpServer` already does. |
| `bluetooth_mtk_sniff_subrating.patch` | `packages/modules/Bluetooth` | The connsys controller advertises sniff-subrating support, then answers `HCI_Sniff_Subrating` (0x0811) with a Command Status event carrying `COMMAND_DISALLOWED` instead of the Command Complete the spec requires. AOSP asserts on the response *form* and aborts (`system/gd/hci/hci_layer.cc:278`), so `com.android.bluetooth` crash-loops and any audio link drops. Reproduced with AirPods Pro 3: crash within seconds of pressing play. Affects every sniff-subrating-capable headset, not one vendor. |

## Upstreaming status

`bluetooth_mtk_sniff_subrating.patch` is not upstreamable as written — it hard
disables the feature for everyone. The upstreamable version gates it on a
soong config or a `bluetooth.core.classic.*` sysprop set from `device.mk`,
matching the existing knobs in `btm_inq.cc`. Arguably AOSP should also not
abort here: the controller returned a valid error, only in the wrong event
form, and `hci_layer.cc` already has a `WaitingFor::STATUS_OR_COMPLETE` mode
that tolerates both. There is a second AOSP bug visible in the same trace —
`acl_peer_supports_sniff_subrating()` is queried before the remote feature read
completes, and logs "remote feature read is incomplete".

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
