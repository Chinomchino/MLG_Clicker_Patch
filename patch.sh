#!/usr/bin/env bash
# MLG Clicker - Preservation Patch Script
# Fixes broken Google Play license verification on abandoned game
# Fixes ad orientation and rendering bugs on modern Android
# Original game by Quantum Games / Flexus Games - all rights reserved
# Patch maintained for preservation purposes - takedown requests honoured

set -e

APKTOOL_VERSION="2.9.3"
SIGNER_VERSION="1.3.0"
APKTOOL_JAR="apktool_${APKTOOL_VERSION}.jar"
SIGNER_JAR="uber-apk-signer-${SIGNER_VERSION}.jar"
APKTOOL_URL="https://github.com/iBotPeaches/Apktool/releases/download/v${APKTOOL_VERSION}/${APKTOOL_JAR}"
SIGNER_URL="https://github.com/patrickfav/uber-apk-signer/releases/download/v${SIGNER_VERSION}/${SIGNER_JAR}"

INPUT_APK="${1:-mlg-clicker.apk}"
OUT_DIR="mlgclicker_out"
PATCHED_APK="mlgclicker_patched.apk"
TARGET_SMALI="${OUT_DIR}/smali_classes2/com/quantumgames/mlg/RunnerActivity.smali"
MANIFEST="${OUT_DIR}/AndroidManifest.xml"
TARGET_LINE='    invoke-static {v3, v4, p1, v2}, Lcom/yoyogames/runner/RunnerJNILib;->CallExtensionFunction(Ljava/lang/String;Ljava/lang/String;I[Ljava/lang/Object;)Ljava/lang/Object;'
REPLACEMENT='    const/4 v0, 0x0'
LOGFILE="patch_log.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $1"; echo "[+] $1" >> "$LOGFILE"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; echo "[!] $1" >> "$LOGFILE"; }
die()  { echo -e "${RED}[x]${NC} $1"; echo "[x] $1" >> "$LOGFILE"; exit 1; }

check_java() {
    if ! command -v java >/dev/null 2>&1; then
        echo ""
        echo -e "${RED}[x]${NC} Java not found. Please install JDK 8 or higher and re-run this script."
        echo ""
        echo "  Install options:"
        echo ""
        echo "  Debian / Ubuntu / WSL:"
        echo "    sudo apt update && sudo apt install -y default-jdk"
        echo ""
        echo "  Fedora / RHEL:"
        echo "    sudo dnf install -y java-17-openjdk"
        echo ""
        echo "  Arch:"
        echo "    sudo pacman -S jdk-openjdk"
        echo ""
        echo "  macOS (Homebrew):"
        echo "    brew install openjdk"
        echo ""
        echo "[x] Java not found" >> "$LOGFILE"
        exit 1
    fi
    log "Java found: $(java -version 2>&1 | head -1)"
}

fetch_tool() {
    local jar="$1" url="$2"
    if [ ! -f "$jar" ]; then
        warn "$jar not found, downloading..."
        if command -v curl >/dev/null 2>&1; then
            curl -L -o "$jar" "$url" || die "Failed to download $jar — download manually from: $url"
        elif command -v wget >/dev/null 2>&1; then
            wget -O "$jar" "$url" || die "Failed to download $jar — download manually from: $url"
        else
            die "Neither curl nor wget found. Download $jar manually from: $url"
        fi
        log "Downloaded $jar"
    else
        log "$jar already present, skipping download"
    fi
}

patch_license() {
    log "Patch 1/2: Removing license verification call..."
    if ! grep -qF "$TARGET_LINE" "$TARGET_SMALI"; then
        warn "Target line not found - may already be patched or wrong APK version"
        echo "[!] Target line not found - may already be patched or wrong APK version" >> "$LOGFILE"
        return 1
    fi
    python3 -c "
import sys
content = open(sys.argv[1], encoding='utf-8').read()
old = sys.argv[2]
new = sys.argv[3]
if old not in content:
    sys.exit(1)
open(sys.argv[1], 'w', encoding='utf-8').write(content.replace(old, new, 1))
" "$TARGET_SMALI" "$TARGET_LINE" "$REPLACEMENT" || die "License patch failed — target line not found after grep check"
    log "License verification call removed (GooglePlayLicensingAsExt::checkLicensing -> no-op)"
}

patch_orientation() {
    log "Patch 2/2: Locking ad activity orientations to portrait..."
    local patched=0

    local activities=(
        "com.appodeal.ads.VideoPlayerActivity"
        "com.appodeal.ads.TestActivity"
        "com.facebook.ads.AudienceNetworkActivity"
        "com.ironsource.sdk.controller.ControllerActivity"
        "com.ironsource.sdk.controller.InterstitialActivity"
        "com.ironsource.sdk.controller.OpenUrlActivity"
        "com.unity3d.services.ads.adunit.AdUnitActivity"
        "com.unity3d.services.ads.adunit.AdUnitTransparentActivity"
        "com.unity3d.services.ads.adunit.AdUnitTransparentSoftwareActivity"
        "com.unity3d.services.ads.adunit.AdUnitSoftwareActivity"
        "com.chartboost.sdk.CBImpressionActivity"
        "com.adcolony.sdk.AdColonyInterstitialActivity"
        "com.adcolony.sdk.AdColonyAdViewActivity"
        "com.applovin.adview.AppLovinInterstitialActivity"
        "com.inmobi.rendering.InMobiAdActivity"
        "com.tapjoy.TJAdUnitActivity"
        "com.tapjoy.TJContentActivity"
        "com.my.target.common.MyTargetActivity"
        "com.yandex.mobile.ads.AdActivity"
        "com.smaato.sdk.interstitial.InterstitialAdActivity"
        "com.smaato.sdk.rewarded.widget.RewardedInterstitialAdActivity"
    )

    for activity in "${activities[@]}"; do
        local pattern="android:name=\"${activity}\""
        if grep -qF "$pattern" "$MANIFEST"; then
            if ! grep -qF "${pattern} android:screenOrientation" "$MANIFEST"; then
                python3 -c "
import sys
content = open(sys.argv[1], encoding='utf-8').read()
old = sys.argv[2]
new = old + ' android:screenOrientation=\"portrait\"'
open(sys.argv[1], 'w', encoding='utf-8').write(content.replace(old, new, 1))
" "$MANIFEST" "$pattern"
                log "  Orientation locked: $activity"
                ((patched++)) || true
            fi
        fi
    done

    log "Orientation patch complete: $patched activities locked"
}

main() {
    # Init log
    echo "MLG Clicker Preservation Patch - Log" > "$LOGFILE"
    echo "Run: $(date)" >> "$LOGFILE"
    echo "Input APK: $INPUT_APK" >> "$LOGFILE"
    echo "" >> "$LOGFILE"

    echo ""
    echo "  MLG Clicker Preservation Patch"
    echo "  Original game (c) Quantum Games / Flexus Games"
    echo "  Fixes: dead license server, ad orientation bugs on modern Android"
    echo "  Log: $LOGFILE"
    echo ""

    [ -f "$INPUT_APK" ] || die "Input APK not found: $INPUT_APK\n  Usage: $0 [path-to-apk]"
    log "Input APK found: $INPUT_APK"

    check_java
    fetch_tool "$APKTOOL_JAR" "$APKTOOL_URL"
    fetch_tool "$SIGNER_JAR" "$SIGNER_URL"

    if [ -d "$OUT_DIR" ]; then
        warn "Output directory $OUT_DIR exists, removing..."
        rm -rf "$OUT_DIR"
    fi

    log "Decompiling APK..."
    java -jar "$APKTOOL_JAR" d "$INPUT_APK" -o "$OUT_DIR" >> "$LOGFILE" 2>&1 || die "apktool decompile failed - see $LOGFILE"
    log "Decompile complete"

    [ -f "$TARGET_SMALI" ] || die "Target smali not found: $TARGET_SMALI — wrong APK version?"
    log "Target smali found"

    patch_license || die "License patch failed"
    patch_orientation || die "Orientation patch failed"

    log "Recompiling APK..."
    java -jar "$APKTOOL_JAR" b "$OUT_DIR" -o "$PATCHED_APK" >> "$LOGFILE" 2>&1 || die "apktool build failed - see $LOGFILE"
    log "Recompile complete"

    log "Signing APK..."
    java -jar "$SIGNER_JAR" -a "$PATCHED_APK" >> "$LOGFILE" 2>&1 || die "Signing failed - see $LOGFILE"
    log "Signing complete"

    SIGNED=$(ls mlgclicker_patched*aligned*signed*.apk 2>/dev/null | head -1)
    [ -n "$SIGNED" ] || die "Could not find signed APK output"
    log "Output APK: $SIGNED"

    echo ""
    echo "  Patches applied:"
    echo "    1. License verification call removed (dead server)"
    echo "    2. Ad activity orientation locked to portrait"
    echo ""
    echo "  Output:  $SIGNED"
    echo "  Log:     $LOGFILE"
    echo ""
    echo "  Install with:"
    echo "    adb uninstall com.quantumgames.mlg"
    echo "    adb install \"$SIGNED\""
    echo ""

    echo "" >> "$LOGFILE"
    echo "--- COMPLETED SUCCESSFULLY ---" >> "$LOGFILE"
}

main "$@"
