/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 *
 * Per-variant identity for camellia.
 *
 * WHY THIS EXISTS
 * ---------------
 * ro.product.property_source_order is "odm,vendor,product,system", and the odm
 * build.prop hardcodes the China model. That makes it impossible to fix the
 * user-visible identity from the per-sku prop files, which only reach
 * ro.product.vendor.* - odm always wins. Additionally, a bare ro.product.brand
 * in a vendor etc prop file is rejected outright: those load in vendor_init
 * context and build_prop is system_restricted_prop with no set_prop grant.
 * Overriding the properties directly from init is the only mechanism that works.
 *
 * KEYING
 * ------
 * The model is a function of (sku, hwc), not sku alone: sku=camellia covers BOTH
 * the China M2103K19C and the India M2103K19I, which differ only by hwc.
 *
 * NFC
 * ---
 * Upstream's helper rewrites ro.boot.product.hardware.sku to "nfc" for NFC
 * variants. We deliberately do NOT do that. camellia's NFC gating keys on the
 * real sku value in three places (odm permissions dir, init.stnfc.rc property
 * trigger, and the kernel st21nfc cmdline check); rewriting the property would
 * silently disable NFC on exactly the units that have the hardware.
 */

#include "include/libinit_utils.h"

#include <android-base/properties.h>
#include <string>
#include <unistd.h>
#include <vector>

using android::base::GetProperty;

static const std::string kHwcProp = "ro.boot.hwc";
static const std::string kSkuProp = "ro.boot.product.hardware.sku";

struct variant_info {
    std::string hwc_value;   // ro.boot.hwc ("" = any)
    std::string sku_value;   // ro.boot.product.hardware.sku ("" = any)
    std::string brand;
    std::string device;
    std::string marketname;
    std::string model;
    std::string board;
};

/*
 * build_fingerprint is deliberately NOT set here. The tree pins a stock MIUI
 * fingerprint via PRODUCT_BUILD_PROP_OVERRIDES (standard LineageOS practice -
 * rosemary, lisa, alioth, munch and vayu all do it) and rewriting it from init
 * would clobber that working value. Revisit only with per-variant strings
 * verified against each region's factory ROM.
 */
static const std::vector<variant_info> kVariants = {
    // hwc,      sku,           brand,   device,      marketname,           model,        board
    {"CN",      "camellia",   "Redmi", "camellia",  "Redmi Note 10 5G",   "M2103K19C", "camellia"},
    {"India",   "camellia",   "Redmi", "camellia",  "Redmi Note 10T 5G",  "M2103K19I", "camellia"},
    {"India",   "camelliap",  "POCO",  "camellia",  "POCO M3 Pro 5G",     "M2103K19PI","camellia"},
    {"Global",  "camellian",  "Redmi", "camellian", "Redmi Note 10 5G",   "M2103K19G", "camellian"},
    {"Global",  "camellianp", "POCO",  "camellian", "POCO M3 Pro 5G",     "M2103K19PG","camellian"},

    /*
     * Catch-all. Upstream tables have none, which means an unmatched unit -
     * camelliar, or any SKU Xiaomi adds later - silently keeps whatever the odm
     * build.prop hardcoded, reproducing the exact bug this library fixes.
     * Matches anything (both keys empty) and must stay last.
     */
    {"",        "",           "Redmi", "camellia",  "Redmi Note 10 5G",   "M2103K19C", "camellia"},
};

static void set_variant_props(const variant_info& v) {
    set_ro_build_prop("brand", v.brand, true);
    set_ro_build_prop("device", v.device, true);
    set_ro_build_prop("model", v.model, true);
    set_ro_build_prop("marketname", v.marketname, true);
    set_ro_build_prop("name", v.device, true);

    /* set_ro_build_prop() only walks the ro.product.<source>.* namespace, so
     * ro.product.board needs an explicit override. */
    property_override("ro.product.board", v.board);

    property_override("vendor.usb.product_string", v.marketname);
    if (access("/system/bin/recovery", F_OK) != 0) {
        property_override("bluetooth.device.default_name", v.marketname);
    }
}

void vendor_load_properties() {
    std::string hwc = GetProperty(kHwcProp, "");
    std::string sku = GetProperty(kSkuProp, "");

    for (const auto& v : kVariants) {
        if (!v.hwc_value.empty() && v.hwc_value != hwc) continue;
        if (!v.sku_value.empty() && v.sku_value != sku) continue;
        set_variant_props(v);
        return;
    }
}
