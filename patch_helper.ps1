# patch_helper.ps1
# Called by patch.bat - handles string replacement operations
# Arguments: -Action <license|orientation> -LogFile <path> -OutDir <path>

param(
    [string]$Action,
    [string]$LogFile,
    [string]$OutDir
)

function Write-Log {
    param([string]$msg)
    Write-Host $msg
    Add-Content -Path $LogFile -Value $msg
}

if ($Action -eq "license") {
    $file = "$OutDir\smali_classes2\com\quantumgames\mlg\RunnerActivity.smali"
    $target = "    invoke-static {v3, v4, p1, v2}, Lcom/yoyogames/runner/RunnerJNILib;->CallExtensionFunction(Ljava/lang/String;Ljava/lang/String;I[Ljava/lang/Object;)Ljava/lang/Object;"
    $replacement = "    const/4 v0, 0x0"

    if (-not (Test-Path $file)) {
        Write-Log "[x] Smali file not found: $file"
        exit 1
    }

    $content = Get-Content $file -Raw

    if (-not $content.Contains($target)) {
        Write-Log "[!] License patch target not found - may already be patched or wrong APK version"
        exit 1
    }

    $content = $content.Replace($target, $replacement)
    Set-Content $file $content -NoNewline
    Write-Log "[+] License verification call removed (GooglePlayLicensingAsExt::checkLicensing -> no-op)"
    exit 0
}

if ($Action -eq "orientation") {
    $file = "$OutDir\AndroidManifest.xml"

    if (-not (Test-Path $file)) {
        Write-Log "[x] Manifest not found: $file"
        exit 1
    }

    $adActivities = @(
        "com.appodeal.ads.VideoPlayerActivity",
        "com.appodeal.ads.TestActivity",
        "com.facebook.ads.AudienceNetworkActivity",
        "com.ironsource.sdk.controller.ControllerActivity",
        "com.ironsource.sdk.controller.InterstitialActivity",
        "com.ironsource.sdk.controller.OpenUrlActivity",
        "com.unity3d.services.ads.adunit.AdUnitActivity",
        "com.unity3d.services.ads.adunit.AdUnitTransparentActivity",
        "com.unity3d.services.ads.adunit.AdUnitTransparentSoftwareActivity",
        "com.unity3d.services.ads.adunit.AdUnitSoftwareActivity",
        "com.chartboost.sdk.CBImpressionActivity",
        "com.adcolony.sdk.AdColonyInterstitialActivity",
        "com.adcolony.sdk.AdColonyAdViewActivity",
        "com.applovin.adview.AppLovinInterstitialActivity",
        "com.inmobi.rendering.InMobiAdActivity",
        "com.tapjoy.TJAdUnitActivity",
        "com.tapjoy.TJContentActivity",
        "com.my.target.common.MyTargetActivity",
        "com.yandex.mobile.ads.AdActivity",
        "com.smaato.sdk.interstitial.InterstitialAdActivity",
        "com.smaato.sdk.rewarded.widget.RewardedInterstitialAdActivity"
    )

    $content = Get-Content $file -Raw
    $patched = 0
    $skipped = 0

    foreach ($activity in $adActivities) {
        $pattern = 'android:name="' + $activity + '"'
        if ($content.Contains($pattern)) {
            if (-not $content.Contains($pattern + " android:screenOrientation")) {
                $content = $content.Replace($pattern, $pattern + ' android:screenOrientation="portrait"')
                Write-Log "    [+] Orientation locked: $activity"
                $patched++
            } else {
                $skipped++
            }
        }
    }

    Set-Content $file $content -NoNewline
    Write-Log "[+] Orientation patch complete: $patched locked, $skipped already set"
    exit 0
}

Write-Log "[x] Unknown action: $Action"
exit 1
