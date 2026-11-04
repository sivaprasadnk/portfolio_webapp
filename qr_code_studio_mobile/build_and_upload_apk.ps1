$ErrorActionPreference = "Stop"

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectDir

$driveFileId = "1tA_7wredq1F7cNN9ibXVeXXGd9BaQtmh"
$apkBuildPath = Join-Path $projectDir "build\app\outputs\flutter-apk\app-release.apk"
$apkAssetPath = Join-Path $projectDir "playstore_assets\qr_code_studio_v1.0.0_release.apk"

Write-Host "1/3 Building signed release APK..." -ForegroundColor Cyan
flutter build apk --release

Write-Host "2/3 Copying APK to playstore_assets..." -ForegroundColor Cyan
Copy-Item $apkBuildPath $apkAssetPath -Force

Write-Host "3/3 Uploading APK to Google Drive (updating file ID: $driveFileId)..." -ForegroundColor Cyan
$gdriveCmd = "C:\Users\HP\.gemini\config\plugins\gdrive\skills\gdrive\scripts\gdrive.cmd"
if (Test-Path $gdriveCmd) {
    & $gdriveCmd --version | Out-Null
}
gdrive mutate update $driveFileId $apkAssetPath --mime-type "application/vnd.android.package-archive"
gdrive readonly url $driveFileId

Write-Host "Done! Release APK built and uploaded to Google Drive." -ForegroundColor Green

