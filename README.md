# MLG Clicker — Preservation Patch

> *"We had brainrot back then too. We just didn't have a word for it yet."*

MLG Clicker is a 2015 Android clicker game built around the MLG/dank memes culture of the early 2010s — airhorns, smoke, 360 no-scopes, and all. It is a genuine artefact of early internet humour and deserves to be preserved and playable.

This repository contains a patch script that makes the game installable and playable on modern Android devices. No gameplay is modified. No ads are removed. The game runs as close to the original as possible.

---

## About the Developer

MLG Clicker was originally developed by **Quantum Games**. The studio has since rebranded or reorganised as **Flexus Games**, who continue to develop and release titles.

If you enjoy this game and want to support the people who made it, check out their current work:

- **Flexus Games on Google Play:** https://play.google.com/store/apps/developer?id=Flexus+Games
- **Flexus Games on Twitter/X:** @FLEXUS.GAMES

---

## Why This Patch Exists

MLG Clicker shipped with two things that cause problems on modern devices:

**1. Google Play License Verification**

A system that checks with Google's servers on startup to confirm the app was legitimately downloaded. Standard practice in 2015. The problem: the developer's app registration is no longer active. Every time the game launches, it contacts a verification server that rejects the request, triggering a popup that fires repeatedly and makes the game unplayable. This is not the user's fault. It is abandoned infrastructure.

**2. Ad orientation bugs**

The ad SDKs bundled with the game were built for Android 8/9 era devices. On modern Android, the ad activities do not correctly lock to the game's portrait orientation, causing ads to render stretched, compressed, or in landscape when the game is in portrait. This makes some ads visually broken and the close button difficult to tap.

**A contact attempt was made to Flexus Games in early 2026. No response was received after several months. Given the game has been unplayable for 2–3 years with no fix and no developer activity, this patch was created in the interest of preservation.**

---

## What the Patch Does

| | |
|---|---|
| Removes license verification call | ✓ |
| Locks ad activity orientation to portrait | ✓ |
| Modifies gameplay | ✗ |
| Removes ads | ✗ |
| Changes any game content | ✗ |
| Drops support for older Android devices | ✗ |

The goal is that someone pulling an old phone out of a drawer — the same device they played this on in 2015 — gets the same experience they remember, minus the broken popup.

---

## Known Issues

- **Ad rendering bugs on modern Android:** Some ads may still display incorrectly — black areas, missing sprites, or broken interactive formats. The orientation patch improves the most common cases but the underlying ad SDKs are too outdated to be fully fixed without removing them entirely, which is outside the scope of this project. Rewarded ads (watch an ad for a bonus) may still function correctly even if the ad itself renders poorly.

---

## Transparency

Every run of the patch script produces a `patch_log.txt` file in the same folder. It records exactly what was checked, what was changed, what was skipped, and what succeeded or failed. If you want to verify what the script did to your APK, the log has the full picture.

---

## Requirements

- Java JDK 8 or higher
- ADB (Android Debug Bridge) for installation
- The original MLG Clicker APK (`com.quantumgames.mlg`)
- Windows: `patch.bat` — Linux/macOS: `patch.sh`

The scripts will automatically download `apktool` and `uber-apk-signer` if not present.

---

## Usage

Place your original APK in the same folder as the patch script and run:

**Windows:**
```bat
patch.bat
```

**Linux / macOS:**
```bash
bash patch.sh
```

Or specify a path to the APK:
```bat
patch.bat C:\path\to\mlg-clicker.apk
```
```bash
bash patch.sh /path/to/mlg-clicker.apk
```

Then install to your device:
```bash
adb uninstall com.quantumgames.mlg
adb install mlgclicker_patched_aligned_signed.apk
```

---

## Philosophy

This patch fixes what is broken due to server-side abandonment and compatibility drift on modern hardware. No gameplay is modified. No ads are removed. No content is changed. The game runs as the developer shipped it, on any Android device it originally supported.

Preservation means keeping things as they were — not improving them, not modernising them, not making them more convenient. Just making them work again.

---

## Takedown

This project exists out of respect for the original work, not in spite of it. If you are the original developer or rights holder and wish this repository to be taken down, open an issue or contact the repository owner and it will be removed promptly, no questions asked.

All rights to MLG Clicker and its content remain with the original developer.

---

## Technical Notes

**Patch 1 — License verification**

In `smali_classes2/com/quantumgames/mlg/RunnerActivity.smali`, the following call in `onCreate` was replaced with a no-op:

```smali
# Before
invoke-static {v3, v4, p1, v2}, Lcom/yoyogames/runner/RunnerJNILib;->CallExtensionFunction(Ljava/lang/String;Ljava/lang/String;I[Ljava/lang/Object;)Ljava/lang/Object;

# After
const/4 v0, 0x0
```

This is the call to `GooglePlayLicensingAsExt::checkLicensing`. Removing it prevents the license check from ever being initiated. All surrounding code — extension setup, gameplay, ads, save data — is untouched.

**Patch 2 — Ad orientation**

`android:screenOrientation="portrait"` is added to ad activity declarations in `AndroidManifest.xml` that do not already specify an orientation. This affects the following SDKs: Appodeal, Facebook Audience Network, IronSource, Unity Ads, Chartboost, AdColony, AppLovin, InMobi, Tapjoy, MyTarget, Yandex Ads, Smaato.
