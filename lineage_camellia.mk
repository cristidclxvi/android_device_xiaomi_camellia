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


PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="camellia-user 13 TP1A.220624.014 V14.0.6.0.TKSMIXM release-keys" \
    BuildFingerprint=Redmi/camellia/camellia:13/TP1A.220624.014/V14.0.6.0.TKSMIXM:user/release-keys \
    DeviceProduct=$(PRODUCT_DEVICE)


# Android 16's compatibility matrix (kernel FCM version 6) cannot be satisfied
# by any 4.14 kernel, so OTA kernel-requirement enforcement stays off.
#
# The LTS floor is no longer the problem - that was "Minimum LTS: 4.14.336" and
# this tree now runs 4.14.357-openela. What blocks it is the config list. Two
# rounds of enabling what check_vintf asked for got as far as:
#
#   CONFIG_SONY_FF        - added, kept (HID_SONY was already =y)
#   CONFIG_TRACE_GPU_MEM  - added, kept; it is a promptless bool, so it cannot
#                           come from a defconfig and is selected by
#                           MTK_GPU_SUPPORT instead, the way the GPU driver
#                           selects it upstream
#   CONFIG_HAVE_MOVE_PMD  - does not exist anywhere in 4.14
#   CONFIG_HAVE_MOVE_PUD  - does not exist anywhere in 4.14
#   CONFIG_USERFAULTFD    - exists, deliberately off; see PRODUCT_ENABLE_UFFD_GC
#                           below. ART's userfaultfd GC needs 5.x features this
#                           kernel does not have, so enabling the symbol alone
#                           would make things worse, not better.
#
# The last three would mean backporting 5.x mremap work for a check that only
# gates OTA metadata. Not worth it. The two configs above were kept anyway
# because they are genuine and cost nothing.
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# This kernel is built without CONFIG_USERFAULTFD, so the userfaultfd GC
# cannot run. Left at "default" the build assumes it can, and compiles the
# whole boot classpath without read barriers; ART then rejects its own boot
# image at runtime and odrefresh has to recompile everything before zygote can
# start. Still required on 4.14.357 - the sublevel bump did not enable
# USERFAULTFD, it is simply absent from the defconfig.
PRODUCT_ENABLE_UFFD_GC := false
