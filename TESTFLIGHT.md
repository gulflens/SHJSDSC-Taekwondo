# TestFlight checklist

What's done in code (this commit):
- ✅ `ITSAppUsesNonExemptEncryption = false` — skips the encryption export
  questionnaire on every upload.
- ✅ `NSPhotoLibraryUsageDescription` — required since we use PhotosPicker.
- ✅ `NSCameraUsageDescription` — for future camera-based athlete photos.
- ✅ `LSApplicationCategoryType = sports` — App Store category.
- ✅ Bundle id `com.gulflens.SHJSDSC`, version 1.0, build 1.

What you still need to do (manual, browser/Xcode work):

## 1. App Store Connect record (browser, ~5 min)

1. Open https://appstoreconnect.apple.com → My Apps → **+** → **New App**.
2. Fill in:
   - **Platforms:** iOS (and macOS if you want a Mac Catalyst build later)
   - **Name:** SHJSDSC Taekwondo
   - **Primary language:** English (UAE)
   - **Bundle ID:** `com.gulflens.SHJSDSC` (must already be registered in
     Apple Developer → Identifiers; if not, register it first there)
   - **SKU:** anything unique, e.g. `shjsdsc-001`
   - **User access:** Full Access
3. Click **Create**.

## 2. App icon (need design, ~30 min)

The current AppIcon.appiconset is empty — TestFlight upload will fail
without one.

Quickest path: use https://makeappicon.com or Bakery (Mac App Store) to
generate the full set from a single 1024×1024 PNG. Drop the generated
icons into `Resources/Assets.xcassets/AppIcon.appiconset/`. Replace the
empty entries in the existing `Contents.json` with filename references.

Design guideline for taekwondo: a stylised tae-geuk symbol (red+blue) on
a flat background, no text, no transparency, full bleed.

## 3. Code signing (~5 min)

In Xcode → SHJSDSC target → Signing & Capabilities:
- **Automatically manage signing** — ON
- **Team:** select your Apple Developer team (the one with the
  `com.gulflens.SHJSDSC` bundle id registered)
- Same for Debug AND Release configurations.

If "Failed to register bundle identifier", you need to register it at
developer.apple.com → Identifiers first.

## 4. Archive + upload (~10 min)

1. Xcode → top toolbar → set destination to **Any iOS Device (arm64)**.
2. Product → **Archive** (waits ~3-5 min).
3. Organizer window opens → select the archive → **Distribute App** →
   **App Store Connect** → **Upload** → leave defaults → **Distribute**.
4. Wait for "Upload Successful". App Store Connect takes another 10-30
   min to process the build before it shows up under your app's
   TestFlight tab.

## 5. TestFlight Internal Testing (~5 min)

1. App Store Connect → your app → **TestFlight** tab.
2. Once the build appears with status "Ready to Test":
3. Click the build → fill in **Test Information** (what to test, beta app
   description, contact email).
4. **Internal Testing** group is already created with you in it. Toggle
   the build into the group. You'll get a TestFlight email within minutes.
5. Install TestFlight on your iPhone, accept the invite, install the
   build, run it.

## 6. External testers (optional, ~24 hour Beta App Review)

If you want non-Apple-team people to test:
1. **External Testing** → **Add Group** (e.g. "SSDSC Coaches").
2. Add testers by email or share a public link.
3. Submit the build for **Beta App Review** (~24h). After approval,
   testers can install.

## 7. Things to mention in the TestFlight build description

Copy-paste suggestion for "What to Test":

> Login flows: email/password sign-in, parent sign-up via member number.
> Core flows by role: TD dashboard, coach class attendance, admin
> announcement publishing, parent home, athlete profile.
> Tournament + grading flows including bracket generation and live match
> scoring.
> Bilingual: switch to العربية from Settings → Language and verify
> all screens layout RTL correctly.

## Things that will block submission to the public App Store
(not TestFlight, but heads-up for later):

- **Privacy Policy URL** — required at App Store Connect → App Privacy.
  Points to a hosted privacy policy describing what you collect (likely:
  athlete names, coach contact, photos, performance data).
- **Privacy "nutrition label"** — answer the App Store Connect questionnaire
  about what data you collect, what you link to identity, and tracking.
  Defaults: "Contact info → Name, Email"; "User content → Photos";
  "Identifiers → User ID"; all linked to identity, not used for tracking.
- **Demo account** — provide a test account in the App Store Connect
  review notes so Apple's reviewers can sign in. Use one of the demo
  emails seeded in DemoRepository.
- **Sign in with Apple** — if you use Sign in with Google or any
  third-party login, App Store guideline 4.8 *requires* you to also offer
  Sign in with Apple. We have email/password as the primary path which
  technically avoids this trap, but if you re-enable Apple Sign-In
  (currently disabled in SignInView since you replaced the button),
  you're already compliant.
- **Children's Privacy** (COPPA / UAE equivalents) — many of your athletes
  are minors. App Store age rating must reflect this; you'll need parental
  consent flow if any data collected from <13 year olds. Worth talking to
  a lawyer for the UAE jurisdiction specifically.
