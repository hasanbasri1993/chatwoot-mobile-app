Goal
- Fix iOS build pipeline (pod install codegen errors, Xcode 26.5 fmt compilation, Paper mode failures) and submit production build to TestFlight via EAS.
Constraints & Preferences
- Paper mode architecture (newArchEnabled: false)
- Xcode 26.5 local environment
- EAS Build with App Store Connect submission
- pnpm package manager
Progress
Done
- Patched react-native-screens TypeScript codegen files to fix Unknown prop type for "onSearchFocus": "undefined" error
- Added patch_fmt_for_xcode26 post-install hook to ios/Podfile to disable consteval in fmt library for Xcode 26.5
- Downgraded react-native-screens from ^4.11.1 (resolving to 4.25.1) to exact 4.11.1 to bypass Paper mode compilation errors (didSetProps, tabScreenFocusHasChanged, Fabric-only event emitters)
- Configured eas.json for iOS production build with correct ASC App ID (6744578760) and "image": "latest"
- Downgraded pnpm to 9.15.0 in package.json for EAS compatibility
- Successfully built iOS IPA and submitted to App Store Connect TestFlight
In Progress
- (none)
Blocked
- (none)
Key Decisions
- Pinned react-native-screens to 4.11.1 instead of patching newer versions for Paper mode compatibility
- Used ios/Podfile post_install hook to patch fmt/base.h rather than upgrading the fmt podspec
- Set EAS iOS image to latest to satisfy App Store Connect's iOS 26 SDK requirement (90725 error)
- Corrected ASC App ID from 6744543675 to 6744578760 after discovering mismatched App Store Connect records
Next Steps
- Monitor App Store Connect email for binary processing completion
- Add TestFlight testers/groups once build appears in App Store Connect
- Verify local iOS simulator build with patched Podfile and pinned dependencies
Critical Context
- react-native-screens 4.25.1 contains Fabric-only code paths that fail compilation in Paper mode (RCT_NEW_ARCH_ENABLED=0)
- Xcode 26.5 Apple Clang enforces stricter consteval rules, breaking fmt 11.0.2 FMT_STRING macros
- App Store Connect requires iOS 26 SDK for all new submissions; EAS default image was outdated
- pnpm 10.x causes frozen-lockfile failures on EAS cloud runners; 9.15.0 is stable
- ASC App ID 6744578760 corresponds to "Chatwoot Dulido" (com.daarululuumlido.chatwoot)
Relevant Files
- ios/Podfile: Contains patch_fmt_for_xcode26 function to disable consteval in fmt/base.h
- eas.json: Production build profile with ios.image: "latest" and submit.ios.ascAppId: "6744578760"
- package.json: Pinned react-native-screens to 4.11.1, pnpm to 9.15.0, added patch-package dev dependency
- ios/Podfile.properties.json: newArchEnabled: false (Paper mode)
- node_modules/react-native-screens/ios/: Local patches to RNSTabsScreenComponentView.mm and RNSTabsHostEventEmitter.mm (superseded by version downgrade)
- .storybook/storybook.requires.ts: Regex path separator normalization ([\\/] → /)