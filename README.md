# Blue Screen Saver

A macOS screen saver that shows the Windows BSOD (blue screen of death), randomizing between XP and NT-style crashes.

## Requirements

- macOS 11 (Big Sur) or later
- Xcode 15 or later to build
- Apple Silicon or Intel Mac

## Build

1. Open `Blue Screen Saver.xcodeproj` in Xcode.
2. Select the **Blue Screen Saver** scheme and **My Mac** as the run destination.
3. Build (**Product → Build**) or run (**Product → Run**) to install a debug build to `~/Library/Screen Savers/`.

Release builds produce a universal binary (`arm64` + `x86_64`) per [Apple’s Screen Saver documentation](https://developer.apple.com/documentation/screensaver).

### Code signing and notarization (distribution)

For sharing outside your machine:

1. Set your **Development Team** under Signing & Capabilities for the target.
2. Archive with **Product → Archive**, then export for distribution.
3. Notarize with `xcrun notarytool` and staple the ticket before distributing the `.saver` zip.

## Install

1. Build or download `Blue Screen Saver.saver`.
2. Double-click the bundle, or copy it to `~/Library/Screen Savers/`.
3. Open **System Settings → Wallpaper → Screen Saver** (on older macOS: **System Settings → Screen Saver**).
4. Choose **Blue Screen Saver** and use **Options…** to adjust crash type, fatality, and font size.

## Sonoma and newer macOS

Apple hosts third-party `.saver` plug-ins in a system compatibility process (`legacyScreenSaver`, sometimes shown as `legacyScreenSaver-x86_64 (Wallpaper)` in Activity Monitor). That process is expected while the saver is running or previewed in Settings.

This release follows Apple’s documented `ScreenSaverView` lifecycle (`startAnimation` / `stopAnimation`) and includes mitigations for Sonoma+ bugs where the host may not stop animation after dismiss:

- Observes `com.apple.screensaver.willstop` to stop animation and exit the plug-in process when appropriate.
- Polls window level as a fallback when the system does not call `stopAnimation`.
- Never calls `exit(0)` during Settings preview (`isPreview`).

After dismissing the screen saver, CPU and memory use should drop. If `legacyScreenSaver` remains stuck at high usage, quit it once in Activity Monitor; that is a known platform issue with third-party screen savers.

## Legacy download

An older build is still linked here for reference: [Dropbox (1.0.3)](https://www.dropbox.com/s/30upmkpsdkyvjug/Blue-Screen-Saver.saver.zip?dl=1). Prefer building 2.0.0 from source for current macOS.
