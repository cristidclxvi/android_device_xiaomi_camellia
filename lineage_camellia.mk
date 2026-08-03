#
# Copyright (C) 2026 The LineageOS Project
# Copyright (C) 2026 cristidclxvi
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
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
PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildFingerprint=Redmi/camellia/camellia:13/TP1A.220624.014/V14.0.6.0.TKSMIXM:user/release-keys \
    DeviceProduct=$(PRODUCT_DEVICE)

PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# The 4.14 kernel has no CONFIG_USERFAULTFD, so the userfaultfd GC cannot run.
# Left at "default" the build cannot detect the kernel version (VINTF kernel
# requirements are disabled above) and assumes true, which compiles the whole
# boot classpath without read barriers. ART then rejects its own boot image at
# runtime and odrefresh has to recompile everything before zygote can start.
PRODUCT_ENABLE_UFFD_GC := false
