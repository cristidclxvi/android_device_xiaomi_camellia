#
# Copyright (C) 2026 The LineageOS Project
# Copyright (C) 2026 cristidclxvi
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
# core_64_bit.mk, not core_64_bit_only.mk: a 64-bit primary zygote with a
# 32-bit secondary, matching stock's ro.zygote=zygote64_32, so armeabi-v7a
# apps install and run. core_64_bit_only.mk set TARGET_SUPPORTS_32_BIT_APPS
# to false, which emptied TARGET_CPU_ABI_LIST_32_BIT and left the ROM
# arm64-only.
#
# core_64_bit_only.mk also set TARGET_SUPPORTS_OMX_SERVICE := false and
# core_64_bit.mk does not, so set it here or base_vendor.mk pulls in an OMX
# HAL we do not ship. It has to be before the inherit chain reaches
# base_vendor.mk, which is why it lives in the product makefile and not in
# BoardConfig.mk.
TARGET_SUPPORTS_OMX_SERVICE := false

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from device makefile.
$(call inherit-product, device/xiaomi/camellia/device.mk)

# Inherit some common LineageOS stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# Device identifier (matches stock SKU detection: ro.boot.product.hardware.sku)
PRODUCT_NAME := lineage_camellia
PRODUCT_DEVICE := camellia
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := M2103K19C

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

# Build fingerprint mirrors stock vendor.img build.prop (extracted from MIUI 14.0.6 V14.0.6.0.TKSMIXM)
# so vendor blobs find expected props at runtime.
# Android 16's framework compatibility matrix (kernel FCM version 6) requires a
# minimum kernel of 4.14.336. We ship 4.14.186 - the newest MiCode published for
# camellia - so check_vintf fails without this. Measured, not guessed: removing
# this flag produces
#   "No compatible kernel requirement found (kernel FCM version = 6) ...
#    compatible kernel versions are: Minimum LTS: 4.14.336"
#
# This is the single strongest argument for bumping to 4.14.x-openela: LineageOS
# ships davinci officially on 4.14.357-openela, which clears the bar. That bump
# would let this flag go AND likely delete the Connectivity BPF patches, since
# davinci runs an unmodified Connectivity module.
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="camellia-user 13 TP1A.220624.014 V14.0.6.0.TKSMIXM release-keys" \
    BuildFingerprint=Redmi/camellia/camellia:13/TP1A.220624.014/V14.0.6.0.TKSMIXM:user/release-keys \
    DeviceProduct=$(PRODUCT_DEVICE)


# The 4.14 kernel has no CONFIG_USERFAULTFD, so the userfaultfd GC cannot run.
# Left at "default" the build cannot detect the kernel version (VINTF kernel
# requirements are disabled above) and assumes true, which compiles the whole
# boot classpath without read barriers. ART then rejects its own boot image at
# runtime and odrefresh has to recompile everything before zygote can start.
PRODUCT_ENABLE_UFFD_GC := false
