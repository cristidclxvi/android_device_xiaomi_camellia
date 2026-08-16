#
# Copyright (C) 2026 The LineageOS Project
# Copyright (C) 2026 cristidclxvi
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/camellia

BUILD_BROKEN_DUP_RULES := true


# A/B (matches stock partition layout — boot/system/vendor/product all have slots)
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS := \
    boot \
    product \
    system \
    system_ext \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor \
    vendor

# Architecture (MT6833 = Cortex-A76 perf cluster + Cortex-A55 efficiency)
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a76

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-2a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a55

# Dynamic 64/32 media stack. With ro.zygote=zygote64_32 the dynamic
# mediaserver/drmserver importers select the 32-bit variants, as stock does.
#
# ZYGOTE_FORCE_64 must stay unset: it would force ro.zygote=zygote64 and
# publish an empty abilist32, which is exactly the 32-bit lockout being
# removed here.
TARGET_DYNAMIC_64_32_MEDIASERVER := true
TARGET_DYNAMIC_64_32_DRMSERVER := true

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := camellia
TARGET_NO_BOOTLOADER := true

# Display (Tianma NT36672C FHD+ 1080x2400 90Hz, 440dpi from stock build.prop)
TARGET_SCREEN_DENSITY := 440

# HIDL (MTK common + Xiaomi common matrices added by their VINTF packages)
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += \
    hardware/mediatek/vintf/mediatek_framework_compatibility_matrix.xml \
    hardware/xiaomi/vintf/xiaomi_framework_compatibility_matrix.xml
DEVICE_MANIFEST_FILE := $(DEVICE_PATH)/manifest.xml
DEVICE_MATRIX_FILE := $(DEVICE_PATH)/compatibility_matrix.xml

# Boot image geometry. The kernel itself is built from source, see
# TARGET_KERNEL_SOURCE below (4.14.357-openela, MiCode camellian-t-oss merged
# up to the OpenELA stable tag).
BOARD_DTB_OFFSET := 0x07c80000
BOARD_KERNEL_BASE := 0x40000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_TAGS_OFFSET := 0x07c80000
BOARD_RAMDISK_OFFSET := 0x11100000

BOARD_BOOT_HEADER_VERSION := 2
BOARD_KERNEL_IMAGE_NAME := Image.gz
BOARD_INCLUDE_DTB_IN_BOOTIMG := true

# Stock cmdline from /proc/cmdline captured on device (essential bootopt + AVB settings)
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2

BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/prebuilt/dtb

BOARD_MKBOOTIMG_ARGS := --base $(BOARD_KERNEL_BASE)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)

# OTA assert device names: covers Redmi N10 5G CN/GL/IN + POCO M3 Pro 5G GL/IN (all share camellia codename)
TARGET_OTA_ASSERT_DEVICE := camellia,camellian

# Partitions (sizes from stock fstab.mt6833 + super partition layout)
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_DTBOIMG_PARTITION_SIZE := 8388608

# Ship the stock dtbo (byte-identical to factory images/dtbo.img,
# md5 69f38af3796c4b8512eef0aa8910eaeb). MTK dt_table, dt_entry_count=1,
# selected by androidboot.dtbo_idx=0. We previously produced no dtbo at all and
# never flashed the partition, so the device ran our kernel against whatever
# dtbo happened to be resident -- that is why shipping stock dtbo is correct.
#
# NFC note (verified 2026-08-03, do not re-investigate): the overlay DOES
# apply. /fragment@37/__overlay__/nfc@08 ("mediatek,nfc", reg 0x08, status
# okay) is live under /sys/firmware/devicetree/base/i2c7@11e02000/ and i2c
# client 7-0008 is instantiated. (`find /proc/device-tree` without -L is a
# false negative -- it is a symlink.) NFC is absent because this unit is
# sku=camellia (CN, M2103K19C): Xiaomi's st21nfc_dev_init() returns -EPERM
# ("not nfc phone!") unless the kernel cmdline has
# androidboot.product.hardware.sku=camellian or camellianp. Stock gates NFC on
# the same two SKUs in odm/etc/permissions/sku_*, the HAL init rc, and
# build_$(sku).prop. device.mk and rootdir/etc/init.stnfc.rc already mirror
# that gating. The camellia SKU has no NFC; nothing here is broken.
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/dtbo.img
BOARD_SUPER_PARTITION_SIZE := 9126805504

BOARD_SUPER_PARTITION_GROUPS := mediatek_dynamic_partitions
BOARD_MEDIATEK_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext vendor product
BOARD_MEDIATEK_DYNAMIC_PARTITIONS_SIZE := 9122611200

BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4

# Let vendor/lineage pick the reserved size. It defaults this to true for
# PRODUCT_VIRTUAL_AB_OTA devices (we are one: misc_info virtual_ab=true), which
# reserves 1188036608 instead of 1957691392 and returns ~734 MB to super.
# Overriding it to false here also defeated the `?=` in that file.
-include vendor/lineage/config/BoardConfigReservedSize.mk

TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_VENDOR := vendor

BOARD_USES_METADATA_PARTITION := true

# Platform (MT6833 = Dimensity 700)
TARGET_BOARD_PLATFORM := mt6833

# Properties
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Recovery (boot.img IS the recovery image — A/B device)
BOARD_USES_RECOVERY_AS_BOOT := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.mt6833
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# RIL (MTK fusion RIL handles dual-SIM + VoLTE/VoNR)
ENABLE_VENDOR_RIL_SERVICE := true

# SELinux (inherit common MTK vendor policies + our device-specific rules)
include device/mediatek/sepolicy_vndr/SEPolicy.mk
BOARD_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor

# Security patch - must match the SPL of the shipped vendor blobs, which come
# from stock MIUI 14 V14.0.6.0.TKSMIXM (ro.vendor.build.security_patch=2023-09-01).
# Do not raise this to the platform SPL: the blobs are what it describes.
VENDOR_SECURITY_PATCH := 2023-09-01

# Verified Boot (AVB v2 with hashtree disabled for custom ROM flashing)
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --set_hashtree_disabled_flag
BOARD_AVB_BOOT_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_BOOT_ALGORITHM := SHA256_RSA2048
BOARD_AVB_BOOT_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_BOOT_ROLLBACK_INDEX_LOCATION := 1
BOARD_AVB_VBMETA_SYSTEM := product system system_ext
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2
BOARD_AVB_VBMETA_VENDOR := vendor
BOARD_AVB_VBMETA_VENDOR_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_VENDOR_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX_LOCATION := 3

# Wi-Fi (MTK MT6631 connectivity chip via /dev/wmtWifi)
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_DRIVER := NL80211

# Do not set BOARD_WLAN_DEVICE here. hostapd's built-in ACS needs
# dump_survey, which gen4m does not implement; hotspot channel selection
# only works because the driver registers the QCA DO_ACS vendor command and
# hostapd is built with CONFIG_DRIVER_NL80211_QCA, which soong enables only
# while BOARD_WLAN_DEVICE is unset. Setting it silently breaks ACS.
#
# BOARD_WPA_SUPPLICANT_PRIVATE_LIB is also deliberately unset - see
# patches/wifi_countrycode_chip_fallback.patch. lib_driver_cmd_fallback
# would make every driver_cmd return success without doing anything, which
# is worse than the honest failure we handle in the framework.
WIFI_DRIVER_FW_PATH_PARAM := "/dev/wmtWifi"
WIFI_DRIVER_FW_PATH_STA := "STA"
WIFI_DRIVER_FW_PATH_AP := "AP"

# Inherit vendor blob makefile (generated by extract-files.py)
include vendor/xiaomi/camellia/BoardConfigVendor.mk

# Kernel build directives (LOS will build kernel from source in kernel/xiaomi/camellia)
TARGET_KERNEL_SOURCE := kernel/xiaomi/camellia
TARGET_KERNEL_CONFIG := camellian_gl_defconfig
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_KERNEL_CLANG_COMPILE := true

# Pin the kernel toolchain to clang r383902, the version this 4.14 tree was
# written against. LineageOS's manifest only carries r547379 and newer, which
# this tree does not build with, so the toolchain is fetched separately from
# AOSP's Android 12 branch. See the local manifest in README.md. This checkout
# is used for the kernel only; the platform still builds with LineageOS clang.
TARGET_KERNEL_CLANG_VERSION := r383902
TARGET_KERNEL_CLANG_PATH := $(abspath prebuilts/clang/host/linux-x86-r383902/clang-r383902)

# Connectivity drivers are built from source rather than shipped as prebuilt
# .ko. Entries are relative to TARGET_KERNEL_EXT_MODULE_ROOT and are built in
# list order, which matters: gen4m, bt, gps and fmradio all import symbols from
# wmt_drv (connectivity/common), and gen4m additionally from wmt_chrdev_wifi
# (wlan/adaptor). ":kbuild" selects make-kbuild-module-target, i.e. a plain
# "make -C $(KERNEL_SRC) M=<dir>" - these modules have no standalone toolchain.
TARGET_KERNEL_EXT_MODULE_ROOT := kernel/xiaomi/vendor/mediatek/kernel_modules/connectivity
TARGET_KERNEL_EXT_MODULES := \
    common:kbuild \
    connfem:kbuild \
    wlan/adaptor:kbuild \
    wlan/core/gen4m:kbuild \
    bt/mt66xx/wmt:kbuild \
    gps:kbuild \
    fmradio/Build/mt6631_6635:kbuild

# Shared configuration for the above. Anything per-module - MODULE_NAME,
# BT_PLATFORM, CFG_FM_PLAT and the KBUILD_EXTRA_SYMBOLS paths - is set inside
# each module Makefile instead, because the ext-module macro passes no
# per-module flags and these values differ per driver.
TARGET_KERNEL_ADDITIONAL_FLAGS += \
    MTK_COMBO_CHIP=SOC2_1X1 \
    CONNAC_VER=1_0 \
    WLAN_CHIP_ID=6833 \
    MTK_ANDROID_WMT=y \
    MTK_ANDROID_EMI=y \
    CONFIG_MTK_COMBO_WIFI_HIF=axi \
    WIFI_IP_SET=1 \
    MTK_WLAN_SERVICE_PATH=wlan_service/



# Boot mode is chosen by the bootloader: stock lk.img injects
# androidboot.force_normal_boot=1 on normal boots and omits it for recovery.
# Hardcoding it here would make recovery unreachable.
BOARD_KERNEL_OFFSET := 0x00080000
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)

# CAMELLIA-LOS F4: without this the Soong init_rc gate in
# external/wpa_supplicant_8 never fires, so no service defines
# wpa_supplicant and Wi-Fi STA/P2P can never start.
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true

