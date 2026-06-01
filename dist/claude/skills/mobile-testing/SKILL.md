---
name: mobile-testing
description: Mobile-specific test scenarios for iOS 18 and Android 14/15 native apps. Covers permissions and consent flows, lifecycle/interruptions, connectivity, deep linking, UI/form factors (Dynamic Type, dark mode, foldables), push notifications, authentication/biometrics, in-app purchases, manual-verifiable accessibility, and cross-version concerns. Use when the feature under test is a mobile app or has mobile-specific surfaces. Loaded by the QA Engineer when the Test Lead specifies mobile platform.
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 2 — Testing Throughout the SDLC, §2.2.2 Test Types (functional and non-functional — ISO 25010 quality characteristics: usability, compatibility, portability, reliability, performance efficiency, security); Chapter 4 — Test Analysis and Design, §4.4.3 Checklist-Based Testing.
> Learning objectives: FL-2.2.2 (K2) distinguish test types (this skill enumerates mobile-relevant non-functional characteristics per ISO 25010 — lifecycle, connectivity, permissions, accessibility, etc.); FL-4.4.3 (K2) explain checklist-based testing (this skill IS a domain checklist for native mobile).
> See also: §2.2.1 test levels (mobile cases live mostly at system and acceptance levels); the `sdlc-and-test-lifecycle` skill for the test-type taxonomy.

# Mobile testing — what not to forget

A senior-QA-lead checklist for manual testing of native mobile apps,
current to iOS 18 / iPadOS 18 and Android 14 (API 34) / Android 15
(API 35, "Vanilla Ice Cream").

For each item: the scenario, why it matters, concrete test ideas,
iOS↔Android divergence, and a primary-source URL.

**How to use:** when planning a new mobile feature, walk all 10
sections and ask "does this feature touch X?" — every "yes" surfaces
1–3 test cases worth adding to the checklist.

---

## 1. Permissions and Consent Flows

Permissions are the single biggest source of "works on my device"
bugs. Every permission has at least 4 reachable states (granted,
denied, denied-permanently, revoked-while-app-open); several have a
"partial / limited" state too.

### 1.1 iOS — App Tracking Transparency (ATT)

- **Scenario:** Any app that links user/device data with third-party
  data for advertising must call
  `ATTrackingManager.requestTrackingAuthorization` before accessing IDFA.
- **Why test:** App Store rejections for missing or misleading purpose
  strings; SDKs degrade silently when IDFA is unavailable; the prompt
  can only be shown once per install.
- **Test cases:**
  1. Fresh install → trigger the flow that requires tracking → verify
     the ATT system prompt appears with `NSUserTrackingUsageDescription`
     string exactly as in Info.plist.
  2. Deny tracking → verify no IDFA is sent to analytics/ad SDKs and
     the app still works.
  3. Settings → Privacy & Security → Tracking → toggle off → reopen
     app → verify status is re-read on `applicationDidBecomeActive`.
- **Platform notes:** iOS-only. Four states: `notDetermined`,
  `restricted`, `denied`, `authorized`.
- **Source:** [App Tracking Transparency — Apple Developer](https://developer.apple.com/documentation/apptrackingtransparency).

### 1.2 iOS — Location (Precise vs Approximate, When-In-Use vs Always)

- **Scenario:** Any feature reading `CLLocation`. Users can grant
  approximate-only or temporary one-time location.
- **Why test:** Maps assuming precise accuracy show wrong city block;
  background geofences silently fail with only When-In-Use.
- **Test cases:**
  1. Grant "While Using" with precise OFF → verify map/distance
     features still render and show a nudge for precise.
  2. Grant "Allow Once" → background >5 min → return → verify re-prompt
     and no crash on `nil` location.
  3. Upgrade to "Always" via Settings → verify background geofences
     activate.
- **Platform notes:** Reduced accuracy is 1–20 km (typically ~5 km per
  Apple WWDC20). Don't write tests that assume precise resolution.
- **Source:** [Requesting location authorization — Apple Developer](https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services).

### 1.3 iOS — Photo Library: Full vs Selected / Limited Access

- **Scenario:** iOS 14+ allows "Selected Photos" (limited library)
  and the `PHPicker` out-of-process picker.
- **Why test:** Apps assuming full access show empty grids when user
  selected a few photos; "Manage Selected Photos" must be reachable.
- **Test cases:**
  1. Grant "Selected Photos" with 3 images → verify only those 3
     appear and "Select More Photos…" is exposed.
  2. After Limited access, add a photo to device → reopen picker →
     verify user can add it.
  3. Deny entirely → verify graceful empty state with deep-link to Settings.
- **Platform notes:** Apple recommends `PHPickerViewController`
  (out-of-process) — needs no library permission.
- **Source:** [Selecting photos and videos in iOS](https://developer.apple.com/documentation/photokit/selecting-photos-and-videos-in-ios).

### 1.4 iOS — Camera, Microphone, Contacts, Bluetooth, Local Network

- **Scenario:** Each protected resource needs its own
  `NS…UsageDescription` and runtime prompt.
- **Why test:** Missing purpose strings = App Store rejection; iOS
  crashes if a key is missing.
- **Test cases:**
  1. Local Network: trigger LAN scan (mDNS, AirPlay) → verify
     `NSLocalNetworkUsageDescription` prompt.
  2. Bluetooth: deny `NSBluetoothAlwaysUsageDescription` → verify
     pairing flow shows "Open Settings" CTA.
  3. Mic + Camera simultaneously (video call) → verify both prompts
     chain correctly and recording indicator honored.
- **Platform notes:** iOS 14+ also surfaces clipboard banner on
  `UIPasteboard` reads.
- **Source:** [Apple HIG — Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy).

### 1.5 iOS — Notifications (UNUserNotificationCenter)

- **Scenario:** First `requestAuthorization`. Options: provisional,
  alert, badge, sound, critical, carPlay.
- **Test cases:**
  1. Deny → send push → verify it does NOT appear; analytics shows "denied".
  2. Provisional auth → send push → verify it lands quietly in
     Notification Center.
  3. Settings toggle off → reopen → verify in-app state re-read on resume.
- **Source:** [UNUserNotificationCenter](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter).

### 1.6 iOS — Face ID / Touch ID (LocalAuthentication)

- **Scenario:** Biometric gating with `LAContext.evaluatePolicy`.
  Policies: `.deviceOwnerAuthenticationWithBiometrics` (biometric
  only) vs `.deviceOwnerAuthentication` (biometric OR passcode).
- **Why test:** Items bound with `biometryCurrentSet` are invalidated
  when fingerprint/face set changes; apps that don't handle
  `errSecItemNotFound` lock users out.
- **Test cases:**
  1. Enroll new finger / re-enroll Face ID → reopen → verify
     keychain items re-prompted/re-issued.
  2. Fail biometric 3× → verify `LAError.biometryLockout` falls back
     to passcode.
  3. Cancel prompt → verify `LAError.userCancel` returns user to
     unauthenticated screen, not black/empty.
- **Source:** [LAPolicy.deviceOwnerAuthenticationWithBiometrics](https://developer.apple.com/documentation/localauthentication/lapolicy/deviceownerauthenticationwithbiometrics).

### 1.7 Android — Runtime Permissions, One-Time, "Don't Ask Again"

- **Scenario:** Dangerous permissions via
  `ActivityResultContracts.RequestPermission`.
- **Why test:** Two denials latch the system to "don't show again".
- **Test cases:**
  1. Deny camera once → re-trigger → verify rationale UI appears
     (`shouldShowRequestPermissionRationale`).
  2. Deny twice → verify app sends user to App Settings rather than
     re-prompting.
  3. Grant "Only this time" for location → background → reopen later
     → verify permission revoked and re-prompted.
- **Source:** [App permissions overview](https://developer.android.com/guide/topics/permissions/overview).

### 1.8 Android — POST_NOTIFICATIONS (Android 13+)

- **Scenario:** Apps targeting API 33+ must request
  `android.permission.POST_NOTIFICATIONS` at runtime.
- **Why test:** Notifications are off by default on fresh installs;
  foreground services appear in task manager but not in drawer when denied.
- **Test cases:**
  1. Fresh install on Android 13+ → verify prompt appears before first
     notification is posted.
  2. Deny → start foreground service → verify FGS notification doesn't
     appear in drawer but service still runs.
  3. Upgrade Android 12 → 13+ with notifications previously enabled →
     verify permission pre-granted (no prompt).
- **Source:** [Notification runtime permission](https://developer.android.com/develop/ui/views/notifications/notification-permission).

### 1.9 Android — SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM (Android 14)

- **Scenario:** `SCHEDULE_EXACT_ALARM` is denied by default on
  Android 14 for non-calendar/alarm apps targeting Android 13+.
- **Why test:** Alarms silently never fire when special access isn't
  granted; check `AlarmManager.canScheduleExactAlarms()` first.
- **Test cases:**
  1. Fresh install of reminder feature → verify app routes user to
     "Alarms & reminders" special access screen before scheduling.
  2. User revokes "Alarms & reminders" in Settings → verify previously
     scheduled exact alarms are cancelled and app listens for
     `ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED`.
  3. Calendar/alarm app declaring `USE_EXACT_ALARM` → verify works
     without prompt (granted on install per Play policy).
- **Source:** [Schedule exact alarms denied by default](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms).

### 1.10 Android — Photo Picker vs READ_MEDIA_VISUAL_USER_SELECTED (Android 14+)

- **Scenario:** Android 14 introduced "Selected Photos Access" using
  `READ_MEDIA_VISUAL_USER_SELECTED`; permissionless photo picker is
  the recommended path.
- **Test cases:**
  1. Grant "Select photos and videos" with 2 images → verify only
     those URIs accessible.
  2. Background app for minutes → return → verify re-prompt to
     re-select if access revoked.
  3. Switch "Allow all" → "Selected" via system settings → reopen →
     verify in-app gallery refreshes (don't cache `MediaStore` URIs).
- **Source:** [Partial photo/video access](https://developer.android.com/about/versions/14/changes/partial-photo-video-access).

### 1.11 Android — Predictive Back Gesture (Android 14 opt-in; default on 15)

- **Scenario:** With `android:enableOnBackInvokedCallback="true"`
  Android 14+ shows back-to-home preview; default on Android 15.
- **Test cases:**
  1. Opt-in app on Android 15 → slow swipe back from top-level →
     verify home-screen preview animates and release dismisses to home.
  2. Drill 3 screens deep → slow swipe → verify cross-activity
     animation and release pops.
  3. Form with unsaved changes → verify "Are you sure?"
     `PopScope`/`OnBackPressedCallback` dialog appears via the
     ahead-of-time `canPop` pattern.
- **Source:** [Predictive back gesture](https://developer.android.com/guide/navigation/custom-back/predictive-back-gesture).

### 1.12 Android — Package Visibility (Android 11+)

- **Scenario:** Targeting API 30+ requires `<queries>` declarations to
  see other installed packages.
- **Test cases:** Open `tel:`, `mailto:`, or app-specific intent →
  verify chooser appears with expected apps. Without correct
  `<queries>` you get silent `ActivityNotFoundException`.
- **Source:** [Package visibility filtering](https://developer.android.com/training/package-visibility).

### If your feature touches permissions, add to the checklist:

- Permission prompt copy verified against Info.plist / manifest
- Granted, denied, denied-permanently paths
- Limited / partial access paths (photos, location)
- Settings round-trip — revoke while app is open → re-enter
- Cold-start with permission already denied

---

## 2. Lifecycle and Interruptions

The OS interrupts the app constantly. State-restoration bugs are the
second most common "can't reproduce" class behind permissions.

### 2.1 Incoming Call During App Use

- **Why test:** Audio sessions get stolen; iOS moves app to "inactive"
  without fully backgrounding; CallKit-using apps must coordinate audio.
- **Test cases:**
  1. Start playback/recording → trigger incoming call → decline →
     verify audio session restored and UI responsive.
  2. Answer → end → return to app → verify in-flight transaction
     (upload, form) resumed or surfaced an error.
  3. While in CallKit/Telecom call from another app → try to start
     call in your app → verify graceful "another call active" message.
- **Source:** [CallKit](https://developer.apple.com/documentation/callkit).

### 2.2 Push Notification in Foreground / Background / Killed

- **Why test:** Banners often don't appear in foreground (iOS requires
  `willPresent` to opt in); deep-link routing differs cold vs warm.
- **Test cases:**
  1. App in foreground → push arrives → verify in-app or notification
     banner per design, tap routes correctly.
  2. App backgrounded → push → tap from lockscreen → verify correct
     screen opens (warm start with state preserved).
  3. App killed → push → tap → verify cold start lands on deep-linked
     screen, not home tab.

### 2.3 System Modals (Face ID prompt, Share Sheet, AirDrop)

- **Why test:** View controller goes inactive but not backgrounded;
  timers and live-data streams may continue and update an unseen UI.
- **Test cases:**
  1. Trigger Face ID prompt → swipe to home before responding →
     verify auth state handled.
  2. Present share sheet → rotate device while open → verify no crash
     and sheet stays attached.
  3. Receive AirDrop while typing in a form → verify form state
     preserved after dismissing.

### 2.4 App Backgrounding Mid-Action

- **Why test:** iOS gives ~30 s background time; Android gives ≤10 s
  in `onPause`/`onStop`; long network calls die silently.
- **Test cases:**
  1. Start multi-MB upload → swipe home → return after 2 min →
     verify upload resumed, completed in background, or shows clear retry.
  2. Start card payment → background mid-3DS → return → verify auth
     status reconciles and doesn't double-charge.
  3. Background during form-save → return → verify entered data still
     in fields.

### 2.5 OS-Level Interruptions (Low Battery, Storage, Thermal, Reduce Motion)

- **Why test:** Animations, background fetches, and high-FPS UI
  degrade or are paused.
- **Test cases:**
  1. Enable Low Power Mode → verify background refresh / Live
     Activities / location updates degrade gracefully.
  2. Fill storage near full → trigger download → verify clear "no
     space" error, not silent failure.
  3. Enable Reduce Motion → verify decorative animations are removed
     or replaced with cross-fades.

### 2.6 Process Death and State Restoration

- **Why test:** Users return hours later and expect to be where they
  left off — bugs here destroy retention.
- **Test cases (Android):** Developer Options → "Don't keep
  activities" → navigate 3 screens deep → home → relaunch → verify
  `onSaveInstanceState`/`SavedStateHandle` restored screen state.
- **Test cases (iOS):** Force-quit from app switcher; relaunch →
  verify `NSUserActivity` / scene restoration brings user back.
- **Source:** [Save UI states — Android](https://developer.android.com/topic/libraries/architecture/saving-states).

### If your feature touches lifecycle, add to the checklist:

- Mid-flow interruption (call, push, system modal) for every long
  user action
- Cold-start vs warm-start divergence
- 24+ hour session resume (token refresh, state restoration)
- Process-death walk on Android with "Don't keep activities"

---

## 3. Connectivity Scenarios

Network failures are the most common production bug source after
permissions. Design tests around the *condition*, not the tool.

### 3.1 Offline at App Start

- **Why test:** Splash screens hang forever waiting for config; auth
  refresh blocks UI thread.
- **Test cases:**
  1. Airplane mode → cold start → verify usable offline state
     (cached, skeleton, or clear empty state) appears within 5 s.
  2. Required-network screen shows retry affordance, not frozen spinner.

### 3.2 Offline Mid-Action

- **Test cases:**
  1. Begin checkout → toggle airplane mode mid-submit → verify
     retryable error and cart preserved.
  2. Typing into chat → drop network → send → verify message queues
     with "pending" indicator and retries on reconnect.

### 3.3 Transitioning Online ↔ Offline (Network Flapping)

- **Why test:** Reactive data streams can over-fetch, drain battery,
  or display "Online/Offline" toasts in a tight loop.
- **Test cases:** Trigger 5 connectivity transitions in 30 s → verify
  app debounces UI banners and doesn't double-submit any request.

### 3.4 Slow / Lossy Networks

- **Test cases:**
  1. Throttle to ~150 kbps, 1.5 s RTT → load main feed → verify
     timeouts are reasonable (≥30 s) and progressive image loading works.
  2. Trigger 5 MB upload on lossy link → verify resumable upload or
     sensible retry behavior.
- **Design note:** Use Apple's Network Link Conditioner profiles
  (Edge, 3G, DSL with loss) and Android emulator network presets.

### 3.5 Captive Portals, VPN, Airplane Mode

- **Why test:** TLS validation fails behind some captive portals;
  VPNs can break Universal-Links domain association caching.
- **Test cases:**
  1. Connect to captive portal not yet completed → launch app →
     verify "no internet" state rather than parsing portal HTML.
  2. Enable VPN → relaunch → verify auth still works and deep-link
     verification still resolves.

### 3.6 Background Sync, Data Saver (Android) / Low Data Mode (iOS)

- **Test cases:**
  1. Enable Data Saver → background app → verify no large background
     fetches occur.
  2. iOS Low Data Mode → verify autoplay video is suppressed.
- **Source:** [Optimize network usage](https://developer.android.com/training/basics/network-ops/data-saver).

### 3.7 iCloud / Google Account Sign-In/Out Mid-Session

- **Test cases:** Sign out of iCloud in Settings while app is
  foregrounded → verify re-auth UI within seconds, not a crash.

### If your feature touches network, add to the checklist:

- Offline at start AND mid-action
- Network flapping (5 transitions in 30 s)
- Slow network (≥30 s timeouts honored)
- Captive portal handling
- Token refresh on resume after long sleep

---

## 4. Deep Linking and Navigation

### 4.1 iOS Universal Links

- **Scenario:** `https://example.com/foo` opens the app directly if
  AASA is properly hosted.
- **Why test:** AASA caching can take 24+ hours to propagate;
  user-choice ("breadcrumb" back to Safari) sticks until explicit.
- **Test cases:**
  1. Tap universal link from Notes → verify app opens to deep-linked
     screen via `NSUserActivityTypeBrowsingWeb`.
  2. Tap universal link from Safari address bar (same domain) →
     verify it opens in Safari, not the app (Apple's deliberate behavior).
  3. App not installed → tap link → verify fallback to web page.
- **Source:** [Supporting universal links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app).

### 4.2 iOS Custom URL Schemes

- **Why test:** Schemes can collide; iOS picks arbitrarily on
  collision; calling `openURL:` from your own app to your own scheme
  is not received as universal-link.
- **Test cases:** Tap `myapp://path` from another app or Safari →
  verify your app receives `application:openURL:options:` correctly.

### 4.3 Android App Links (verified) vs Implicit Intents

- **Why test:** A single failed-verify host on Android 11 and lower
  invalidates ALL hosts in the intent filter; Dynamic App Links on
  Android 15+ refresh from server.
- **Test cases:**
  1. Tap verified `https://` link from Gmail → verify no chooser
     dialog; app opens directly.
  2. After publishing, run `adb shell pm verify-app-links --re-verify
     PACKAGE` → verify all declared hosts pass.
  3. Tap link to unverified path on Android 15 → verify Dynamic App
     Link rule in `assetlinks.json` honored without app update.
- **Source:** [About App Links](https://developer.android.com/training/app-links/about).

### 4.4 Cold Start vs Warm Start from a Deep Link

- **Why test:** Cold-start often misses link payload because routing
  initializes after `application:didFinishLaunching`.
- **Test cases:**
  1. Force-kill → tap link → verify destination reached (not home tab
     + then push to destination).
  2. Background (10 min) → tap link → verify same destination AND
     previous state preserved.

### 4.5 Deep Link to Gated (Auth-Required) Screen

- **Test cases:**
  1. Logged-out user taps gated link → verify app routes to login,
     after auth continues to original destination.
  2. Logged-in user with insufficient permissions → verify clear "no
     access" state, not a 404.

### 4.6 Malformed / Expired Parameters

- **Test cases:**
  1. Missing required query param → verify graceful fallback.
  2. Expired token → verify "link expired" message with useful next step.
  3. Injected characters (`%00`, very long, RTL override) → verify no
     crash and no UI spoof.

### If your feature touches deep links, add to the checklist:

- Cold AND warm start from a deep link
- Auth-gated destinations (logged-out, wrong-role)
- Malformed parameters → graceful fallback
- Universal-Link vs Safari-same-domain rule on iOS
- App Link verification on Android (`adb shell pm verify-app-links`)

---

## 5. UI and Form Factor

### 5.1 Dynamic Type (iOS) / Font Scaling (Android)

- **Scenario:** iOS supports 12 sizes including AX1–AX5; Android 14
  introduced non-linear font scaling up to 200 % maximum.
- **Why test:** Tab bars, button labels, and grid cells frequently
  truncate or overlap at AX5 / 200 %.
- **Test cases:**
  1. iOS Settings → Accessibility → Display & Text Size → Larger
     Text → AX5 → walk every screen → verify nothing clipped and CTAs
     remain tappable.
  2. Android Settings → Display → Font size → Largest (200 %) → walk
     every screen; pay attention to titles vs body (non-linear curve
     scales differently).
  3. Toggle text size while app foregrounded → verify re-layout
     without restart (`adjustsFontForContentSizeCategory`).
- **Source:** [Larger Text evaluation criteria — Apple](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/larger-text-evaluation-criteria/); [Android 14 features](https://developer.android.com/about/versions/14/features).

### 5.2 Dark Mode / Light Mode / System-Following

- **Test cases:**
  1. Cold-start in dark mode → verify all screens including modals,
     share sheets, and WebViews use dark colors with adequate contrast.
  2. Toggle system theme while app foregrounded → verify all screens
     update (no stale color cache).
  3. Force per-app light/dark override → verify it persists across
     cold start.

### 5.3 Orientation

- **Test cases:** Rotate every screen → verify no data loss, no
  overlapping text. If portrait-only, verify the lock is consistent
  across cold-start and after returning from system modal.

### 5.4 Split-Screen / Stage Manager / Multi-Window

- **Test cases:**
  1. iPad: open app in 1/3 split → verify single-column layout, no
     clipped controls.
  2. Stage Manager: resize between near-square and tall-narrow →
     verify no crash on resize.
  3. Android tablet: freeform multi-window → resize → verify
     view-models survive configuration changes.

### 5.5 Foldables — Posture Changes

- **Why test:** `FoldingFeature.State.HALF_OPENED` with horizontal
  hinge ("tabletop") should reflow UI so content isn't on the crease.
- **Test cases:**
  1. Pixel Fold / Galaxy Fold: open video playback → enter tabletop →
     verify controls move below crease and video moves above.
  2. Fold device with app open → verify cover-screen continuation or
     graceful state preservation.
- **Source:** [Make your app fold aware](https://developer.android.com/develop/ui/compose/layouts/adaptive/foldables/make-your-app-fold-aware).

### 5.6 Safe Areas, Notches, Dynamic Island, Camera Cutouts

- **Test cases:**
  1. iPhone with Dynamic Island: verify no UI element hidden behind
     it in any orientation; Live Activities render correctly.
  2. Android phone with hole-punch in landscape → verify top-bar
     respects `WindowInsets.displayCutout`.
  3. Edge-to-edge on Android 15 (enforced for `targetSdk = 35`) →
     verify content isn't drawn under gesture pill / status bar
     without insets.

### 5.7 RTL Languages

- **Test cases:**
  1. Switch system language to Arabic or Hebrew → verify horizontal
     layouts mirror, navigation chevrons flip, numerals format correctly.
  2. Verify text alignment, drawable directionality
     (`drawableStart`/`drawableEnd`), and animations mirror.
  3. Verify embedded LTR strings (URLs, emails) display LTR within
     RTL paragraphs.

### If your feature touches UI surface, add to the checklist:

- Largest accessibility text size walk (AX5 / 200 %)
- Dark + light mode parity
- RTL walk
- Safe area / cutout on a notched device
- Fold posture (if foldables supported)

---

## 6. Push Notifications

### 6.1 Permission Flow (Android 13+ POST_NOTIFICATIONS)
Covered in §1.8.

### 6.2 Foreground / Background / Killed Behavior
Covered in §2.2.

### 6.3 Notification Grouping and Channels (Android)

- **Why test:** Once a channel is created, importance can't be
  changed by the app; only the user can. New feature areas need new channels.
- **Test cases:**
  1. Send 10 notifications same channel → verify they group correctly
     under app icon.
  2. User mutes one channel in system settings → verify other channels
     still deliver.
  3. Verify channel name/description in system Settings is
     human-readable and translated.
- **Source:** [Notification channels](https://developer.android.com/develop/ui/compose/notifications/channels).

### 6.4 iOS Interruption Levels (iOS 15+)

- **Scenario:** Set `interruption-level` in push payload to `passive`,
  `active` (default), `time-sensitive`, or `critical`.
- **Why test:** Time-sensitive breaks through Focus modes; misusing
  it is grounds for App Store action. Critical requires special entitlement.
- **Test cases:**
  1. Enable Do Not Disturb → send `active` push → verify silenced;
     send `time-sensitive` → verify breaks through.
  2. `passive` push → verify doesn't light the screen or play sound,
     but is in Notification Center.
- **Source:** [Time Sensitive notifications — WWDC21](https://developer.apple.com/videos/play/wwdc2021/10091/).

### 6.5 Tap Behavior — Cold Start to Deep-Linked Screen
Covered in §4.4 — cold-start tap is the bug-prone path.

### 6.6 Rich Notifications (Images, Actions, Notification Extensions)

- **Test cases:**
  1. Push with remote image attachment → verify image renders.
  2. Notification with quick-reply action → verify input is delivered
     and notification updates.
  3. Notification with two buttons → verify each routes correctly.

### 6.7 Silent / Data Push

- **Test cases:**
  1. iOS `content-available: 1` push → app in background → verify
     handler runs within allowed time budget and reports completion.
  2. Android data-only FCM → verify app foreground service or
     WorkManager handles it without showing a system notification.
  3. Send 5 silent pushes back-to-back on iOS → verify OS throttle
     doesn't drop critical syncs.

### If your feature touches push, add to the checklist:

- Permission denied path (no silent failures)
- Foreground / background / killed delivery
- Cold-start tap → deep-link destination
- Channel grouping (Android) and interruption levels (iOS)
- Silent push handling within OS time budget

---

## 7. Authentication and Biometrics

### 7.1 Face ID / Touch ID Enrollment Changes
Covered in §1.6.

### 7.2 Fallback to Passcode / Device Credential

- **Test cases:**
  1. Cover Face ID camera → wait for "Use Passcode" → enter → verify
     auth succeeds via `.deviceOwnerAuthentication`.
  2. Disable Face ID in Settings → trigger biometric flow → verify
     graceful prompt for app-level password, no crash on
     `LAError.biometryNotAvailable`.

### 7.3 Android BiometricPrompt — Class 3 vs Class 2

- **Scenario:** `BIOMETRIC_STRONG` (Class 3) is required for payments
  and crypto-key-bound flows; `BIOMETRIC_WEAK` (Class 2) is e.g. 2D
  face unlock on budget devices.
- **Test cases:**
  1. On Class-2-only face unlock device → verify app falls back to
     fingerprint or device credential when Strong is required.
  2. With `setAllowedAuthenticators(BIOMETRIC_STRONG or
     DEVICE_CREDENTIAL)` → verify prompt offers both and PIN works.
  3. After 5 failed attempts → verify `ERROR_LOCKOUT` shown and app
     suggests waiting 30 s or using password.
- **Source:** [Biometric auth dialog](https://developer.android.com/identity/sign-in/biometric-auth).

### 7.4 Token Refresh on App Resume After Long Sleep

- **Test cases:**
  1. Leave app open then sleep 24+ hours → unlock → resume → verify
     token refresh transparent, no 401s.
  2. Refresh token expired → verify re-auth UI rather than silent logout.

### 7.5 Logout — What State Must Be Cleared

- **Test cases:** Tap logout → verify:
  1. Keychain (iOS) / EncryptedSharedPreferences / Keystore entries cleared.
  2. `HTTPCookieStorage.shared` / `CookieManager` cleared.
  3. `URLCache` / `OkHttp` cache for authenticated endpoints purged.
  4. WebView session (`WKWebsiteDataStore` / `WebView.clearStorage`) cleared.
  5. Push token unregistered server-side so previous user doesn't get
     notifications for new user.

### 7.6 Multi-Account Scenarios

- **Test cases:**
  1. Sign in to account A → switch to B → verify A's data fully
     replaced in lists, caches, in-memory state.
  2. Push for account A while B active → verify routes correctly or
     is filtered.

### If your feature touches auth/biometrics, add to the checklist:

- Biometric fallback to passcode / device credential
- Enrollment change (`biometryCurrentSet` invalidation)
- 24+ hour token refresh
- Logout state-clearing checklist (5 stores above)
- Multi-account switch isolation

---

## 8. In-App Purchases and Subscriptions

Skip this whole section if your app doesn't sell anything. For apps
that do, it's high-leverage — broken IAP = lost revenue with no other
detection signal.

### 8.1 iOS — Local StoreKit Testing in Xcode

- **Test cases:**
  1. Xcode Transaction Manager → refund a purchase → verify app
     revokes entitlement on next `Transaction.updates`.
  2. Configure "interrupted purchase" → verify resolve-payment UI.
  3. Set subscription renewal to "1 second" → verify renewal handling
     and analytics fire correctly.
- **Source:** [StoreKit testing in Xcode](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode/).

### 8.2 iOS — App Store Sandbox Testing

- **Why test:** Sandbox exercises real App Store Server including
  notifications V2; default speed = 1 month / 5 minutes; subscriptions
  auto-renew up to 12 times before auto-renew turns off.
- **Test cases:**
  1. Fresh sandbox tester → purchase monthly → verify `DID_RENEW`
     notifications V2 ~every 5 min, auto-renew turns off at 13th attempt.
  2. Trigger sandbox refund via Settings → verify `REFUND` notification
     and entitlement revoked.
  3. Cross-grade (monthly → yearly) → verify proration honored and
     entitlement transitions.
  4. Ask to Buy: enable → make purchase → verify pending state
     rendered and resolved.
- **Source:** [Testing IAPs with Sandbox](https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox).

### 8.3 iOS — Subscription State Transitions

- **Scenario:** StoreKit 2 states: `.subscribed`, `.inGracePeriod`
  (grant access), `.inBillingRetryPeriod` (revoke), `.expired`,
  `.revoked`.
- **Test cases:**
  1. Enable Billing Grace Period → simulate failed renewal → verify
     entitlement preserved during grace, revoked at expiration.
  2. Trigger refund → verify `REFUND` updates entitlement.
  3. Family-shared subscription → revoke from owner → verify all
     linked users lose access.

### 8.4 Android — Google Play Test Tracks and License Testers

- **Test cases:**
  1. Add tester emails to License Testing → Internal track → make
     purchase → verify zero charge and entitlement granted.
  2. Use four test cards (Always Approves, Always Declines, Slow
     Approve, Slow Decline) → verify pending purchases
     (`Purchase.PurchaseState.PENDING`) are NOT granted entitlement
     until they transition to `PURCHASED`.
  3. Use Play Billing Lab to switch Play Country → verify localized
     pricing.
- **Source:** [Test Play Billing](https://developer.android.com/google/play/billing/test).

### 8.5 Android — Subscription Lifecycle States

- **Scenario:** States: `PENDING`, `ACTIVE`, `IN_GRACE_PERIOD` (grant),
  `ON_HOLD` (revoke), `PAUSED`, `CANCELED` (active until expiry),
  `EXPIRED`. From Dec 1 2025, account hold durations are automatically
  calculated (60 days minus grace).
- **Test cases:**
  1. Cancel sandbox subscription → verify app keeps entitlement until
     expiry, clearly shows "cancelled — access until X".
  2. Force renewal failure → verify grace-period keeps entitlement and
     on-hold revokes it.
  3. Pause a paused-eligible subscription → verify entitlement ends at
     current period boundary and resumes correctly.

### 8.6 Restore Purchases

- **iOS:** Reinstall on new device same Apple ID → verify
  `Transaction.currentEntitlements` returns active non-consumables and
  subscriptions without user action.
- **Android:** Reinstall same Google account → on launch,
  `BillingClient.queryPurchasesAsync` for `INAPP` and `SUBS` re-grants
  entitlement. Unacknowledged purchases auto-refund after 3 days.

### If your feature touches purchases, add to the checklist:

- Sandbox / Internal track end-to-end purchase
- Refund delivery (entitlement revoke)
- Subscription state transitions (grace, hold, paused)
- Restore on new device
- Pending purchase (Slow Approve) — never grant entitlement prematurely

---

## 9. Accessibility (Manual QA Verifiable)

The slice of accessibility a manual tester can verify without
specialized tools. Full WCAG AAA audit is a separate discipline.

### 9.1 VoiceOver / TalkBack Basic Navigation

- **Test cases:**
  1. Enable VoiceOver / TalkBack → walk primary user journey using
     only swipe-right / swipe-left → verify every interactive element
     reachable in logical order.
  2. Verify each interactive element announces a meaningful label
     (not "Button" or "Image").
  3. Verify focus moves to sensible element when a screen opens
     (e.g., screen title) and when modal appears.

### 9.2 Touch Target Size

- **Scenario:** Apple HIG: 44 × 44 pt minimum. Material Design: 48 ×
  48 dp with ≥8 dp separation between adjacent targets.
- **Test cases:** Inspect every tappable control with no zoom. If two
  controls are <8 dp apart and either is <48 dp, flag it.
- **Source:** [Touch target size](https://support.google.com/accessibility/android/answer/7101858).

### 9.3 Color Contrast

- **Scenario:** WCAG AA — 4.5:1 normal text, 3:1 large (≥18 pt or ≥14
  pt bold) and meaningful non-text UI.
- **Test cases:**
  1. Sample every text-on-background combination (primary, secondary,
     placeholder, disabled, error) → verify ratio meets AA.
  2. Verify dark and light modes independently.
  3. Verify focus indicators and form-field borders ≥3:1 against
     background.

### 9.4 Reduce Motion / Animator Duration Scale

- **Test cases:**
  1. iOS Settings → Accessibility → Motion → Reduce Motion ON →
     verify decorative animations replaced by cross-fades or removed.
  2. Android Developer Options → Animator duration scale OFF →
     verify app usable (animations skippable / not load-bearing).
  3. Verify parallax / motion-driven UI is disabled.

### 9.5 Captions / Audio Descriptions

- **Test cases:** Any in-app video → verify closed-caption track
  reachable, toggleable, visually legible (sufficient contrast and
  size at default Dynamic Type).

### If your feature has UI, add to the checklist:

- Screen reader walk of the primary journey
- Touch target audit (any < 44 pt iOS / 48 dp Android?)
- Contrast walk in light AND dark
- Reduce-motion behavior
- Captions for any video content

---

## 10. Cross-Version Concerns

### 10.1 Minimum-Supported OS Implications

- **Test cases:**
  1. Install on stated minimum iOS / Android → verify launch and
     primary flows; SDK regressions hit here when bumping minimum.
  2. Install on latest OS (current iOS 18, Android 15) → verify no
     deprecation warnings turn into runtime failures.

### 10.2 Feature Flags by OS Version

Common version-gated features:

- **Live Activities** require iOS 16.1+. Without Dynamic Island,
  Lock Screen only.
- **Interactive Widgets** require iOS 17+.
- **Predictive Back (system animations on)** default on Android 15+;
  opt-in on Android 13/14.
- **Selected Photos Access (READ_MEDIA_VISUAL_USER_SELECTED)** Android 14+ only.
- **Dynamic App Links** Android 15+.

**Test cases:** For each gated feature, run on the version where it's
enabled, gated, and absent — verify graceful degradation in each.

### 10.3 Manufacturer Skins (Android)

Samsung One UI, Xiaomi MIUI/HyperOS, OnePlus OxygenOS, Huawei
EMUI/HarmonyOS diverge from AOSP in:

- **Notification handling:** MIUI may throttle FCM unless app is
  whitelisted or "MIUI optimization" is disabled.
- **Battery optimization:** Samsung "Sleeping apps" / "Deep sleeping
  apps"; OxygenOS auto-launch denial; Huawei PowerGenie may force-kill
  background workers.
- **Permission UX:** One UI surfaces "Only this time" prominently;
  some MIUI auto-revokes permissions after days of non-use.
- **Gesture navigation:** Each OEM's gesture nav has slightly
  different edge-conflict zones.

**Test cases:**
1. Recent Samsung Galaxy → verify push still arrives after 24 h of
   the app unused (battery optimization).
2. Xiaomi → verify FCM background notifications arrive without manual
   whitelisting; document any required user steps.
3. Verify edge-swipe drawers and gesture-driven in-app navigation
   don't conflict with OEM system back gesture.

### If your feature targets multiple Android OEMs, add to the checklist:

- Push delivery after 24h idle on Samsung + Xiaomi
- Battery optimization whitelist need (document it)
- Edge-swipe conflict on Samsung Edge Panels
- Minimum OS smoke run

---

## How to use this skill in your checklist

When the Test Lead specifies `mobile-testing`:

1. Walk the 10 sections above for the feature in question.
2. For each section's "If your feature touches X" note, add the
   listed items to your checklist if they apply.
3. Mark each new item with `[mobile]` and the relevant sub-section
   citation, e.g. `[mobile §1.8 — POST_NOTIFICATIONS]`.
4. Be honest about scope: if your feature has no biometric flow,
   skip §7 entirely rather than padding the checklist.

A typical mobile feature surfaces 10–20 items from this walk —
not 80, not 3.
