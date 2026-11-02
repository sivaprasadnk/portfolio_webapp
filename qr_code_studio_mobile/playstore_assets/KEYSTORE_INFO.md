# Android Release Keystore & Signing Configuration

## 1. Keystore Files
- **Active Gradle Keystore**: `android/app/upload-keystore.jks`
- **Backup Copy**: `playstore_assets/upload-keystore.jks`
- **Gradle Signing Properties**: `android/key.properties`
- **Gradle Build Config**: `android/app/build.gradle.kts`

## 2. Keystore Credentials
- **Keystore Filename**: `upload-keystore.jks`
- **Key Alias**: `upload`
- **Store Password**: `SpnkQrStudio2026!`
- **Key Password**: `SpnkQrStudio2026!`
- **Key Algorithm**: `RSA (2048-bit, SHA384withRSA)`
- **Validity**: `10,000 days` (Valid until March 20, 2054)
- **Distinguished Name (DN)**: `CN=Sivaprasad NK, OU=SPNK Studio, O=Sivaprasad NK, L=Kochi, ST=Kerala, C=IN`

## 3. Certificate Fingerprints
- **SHA-1**:
  `5B:3F:3E:9E:8D:F6:9B:9A:98:E5:49:25:13:3D:0E:4D:CD:AA:A8:8F`
- **SHA-256**:
  `1E:3E:8E:6D:8F:A2:BC:33:EA:FE:00:69:FB:D0:9B:CA:C5:3A:6A:B2:FD:BB:04:10:A9:AC:D6:EE:00:EE:86:19`

## 4. Building Signed Release Bundles for Google Play Store
The `release` build type in `android/app/build.gradle.kts` automatically loads `android/key.properties` and signs the output with `upload-keystore.jks`.

### Build Signed Android App Bundle (`.aab` for Google Play Console)
```powershell
cd "e:\sp\flutter projs\portfolio_webapp\spnk\qr_code_studio_mobile"
flutter build appbundle --release
```
Output file:
`build/app/outputs/bundle/release/app-release.aab`

### Build Signed Release APK (`.apk` for direct installation)
```powershell
cd "e:\sp\flutter projs\portfolio_webapp\spnk\qr_code_studio_mobile"
flutter build apk --release
```
Output file:
`build/app/outputs/flutter-apk/app-release.apk`

> **Important Security Note**: Keep a safe backup of `upload-keystore.jks` and `key.properties` outside of public version control. Notice that `*.jks` and `key.properties` are added to `android/.gitignore`.

