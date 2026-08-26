# ClosedCaptioner — project steering

Concise map of what the app is, how it is built, what is broken, and what is next.  
For task-specific runbooks, see [`AGENTS.md`](../AGENTS.md) and [`docs/agent/`](agent/).

---

## What it is

Native **iOS 16.4+** SwiftUI app for **live speech-to-text captions** in portrait. Mic → on-screen text → optional edit, history, nearby share. Monetized with **AdMob** (banner + interstitial) and a **Remove Ads** non-consumable IAP.

| Item | Value |
|------|-------|
| Scheme / target | `ClosedCaptioner` |
| Bundle ID | `RaveSociety.ClosedCaptioner` |
| Team | RaveSociety (`66R936J3XS`) |
| Marketing version | **1.2** (`MARKETING_VERSION` in Xcode) |
| Build number | Xcode Cloud `CI_BUILD_NUMBER` at archive time |
| Repo | `kbibireddy/closed-captioner` · branch `main` |
| ASC app | [6754772689](https://appstoreconnect.apple.com/apps/6754772689) |

---

## Features (current)

### Core captioning
- **Mic** (long-press): English (`en-US`) speech recognition via `Speech` + `AVFoundation`.
- Auto-stops after **15 seconds** (`MicController.MAX_RECORDING_TIME_IN_SEC`).
- **Emojis** (Preferences → Captions): off by default; experimental. When on, added after speech text stabilizes (~2.5s) via `EmojiService` / NaturalLanguage.
- **Keyboard overlay** to edit current caption.
- **Eraser**: flash + “Poof” animation; saves prior text to history when applicable.
- **Shake** (mic off, main screen): replaces text with a pickup line; 5s cooldown.

### Appearance
- **Day / Night** in Settings → Preferences → Appearance (persisted). Default Night.
- **Six themes**: Grove (default), Harbor, Ember, Ink, Dusk, **Stealth** (low-contrast; replaces old “Discreet” mode).
- **Fonts** (Preferences): System (default), New York, Avenir Next, Futura, Rounded. OfferLab-inspired palettes via `Theme.swift` / `AppType`.

### Settings (gear, full-screen overlay)
| Tab | Purpose |
|-----|---------|
| **Preferences** | Display name, emoji detection (experimental), Huddle relay, Day/Night, theme, font |
| **KPIs** | App vs phone CPU/memory/threads; 15 min @ 3s for live series, 1 h @ 30s for slow counters; Message Log can be cleared |
| **Activity** | Captions history (source chips) + Huddle log (plain log lines); Day/Night-style switcher |
| **Purchases** | Remove Ads IAP + Restore |

### Huddle (nearby P2P) (Multipeer `cc-p2p`)
- **Huddle icon** (top right): off by default; on = browse + advertise on local network. Stays on in the background until you turn it off, force-quit, or the auto-off timer (Preferences, default 30 minutes). At most one local iOS notification per launch, and only after lock or a full minute off-screen.
- **Flick up** (±60° of vertical) anywhere on the caption canvas to broadcast (finger-follow, velocity fly-off, then **Sent!**). Wrong direction → **Try again** + ↑, caption returns.
- Incoming messages go to the **log strip** above the bottom banner — **never** the center caption.
- **Relay messages** (Preferences): forward with TTL 4; **on by default**. Works while Huddle is on, including in the background when iOS has not suspended the process.
- **Keep Huddle on** (Preferences): 30 min / 1 h / 4 h / 8 h / until off.
- Mac test peer: `tools/p2p-radio` — see [`docs/agent/p2p-test.md`](agent/p2p-test.md).

### Monetization
- **Banners**: top + bottom adaptive AdMob units in `ControlsView` VStack (never over buttons).
- **Interstitials**: every 3rd mic stop; after closing Activity → Captions (non-premium).
- **ATT**: prompted shortly after first foreground (before AdMob start / banners) via `AdsBootstrap.prepareForForeground`.
- **Remove Ads**: product ID `ClosedCaptioner` (non-consumable). Premium hides all ads.

### Built but not in UI
- **`ExportManager`**: text / PDF / HTML export — no settings entry yet.

---

## Architecture

**MVVM** with small controllers and singleton managers.

```
ContentView
├── SpeechService          ← recognition, emojis
├── MicController          ← 15s timer, bridges SpeechService
├── AppStateViewModel      ← theme, day/night, overlays, display name, relay flag
├── HistoryManager         ← UserDefaults persistence
├── P2PInboxService        ← Huddle (Multipeer) + log + KPI counters
├── PremiumManager         ← StoreKit 2, entitlements
└── ControlsView           ← chrome, banners, P2P HUD, mic/keyboard/eraser

SettingsView → Preferences | KPIs | Activity | Purchases
```

| Layer | Key files |
|-------|-----------|
| **Models** | `ColorMode`, `Theme`, `CaptionText` |
| **ViewModels** | `AppStateViewModel` |
| **Views** | `ContentView`, `ControlsView`, `CaptionTextDisplay`, `SettingsView`, … |
| **Services** | `SpeechService`, `AudioService`, `P2PInboxService`, `ShakeDetectionService`, `PickupLineService`, `AppPerformanceMonitor` |
| **Controllers** | `MicController` |
| **Managers** | `HistoryManager`, `ExportManager` |
| **Ads** | `AdsBootstrap`, `BannerAdView`, `InterstitialCoordinator`, `AdConfig` |
| **IAP** | `PremiumManager`, `IAPConfig`, `ClosedCaptioner.storekit` |

### UI layering (z-order)
1. Caption canvas (center)
2. `ControlsView` — top bar, banners, P2P log, bottom bar
3. Overlays — keyboard, settings (zIndex 10)

### Persistence (`UserDefaults`)
Theme, color mode, display name, relay flag, caption history, P2P KPI counters (persist; no in-app reset).

---

## Main screen controls

| Location | Action |
|----------|--------|
| Top left | Settings |
| Top right | Huddle + status (`Tap to join` off; on: ↓/↑ B/s from 30s window) |
| Bottom left | Keyboard |
| Bottom center | Mic (long-press start/stop) |
| Bottom right | Eraser |
| Center caption | Flick **up** (±60°) anywhere on canvas to send (Huddle on); **Sent!** / **Try again** |

Day/Night, theme, and font are **not** on the main screen — Settings → Preferences only.

---

## Release & ops

| Topic | Doc |
|-------|-----|
| Device install | [`docs/agent/device-deploy.md`](agent/device-deploy.md) |
| Xcode Cloud → App Store | [`docs/agent/xcode-cloud.md`](agent/xcode-cloud.md) |
| IAP / Remove Ads Retry | [`docs/agent/iap.md`](agent/iap.md) |
| AdMob `app-ads.txt` | [`docs/agent/app-ads-txt.md`](agent/app-ads-txt.md) — must live at **domain root** `https://kbibireddy.github.io/app-ads.txt` |
| P2P testing | [`docs/agent/p2p-test.md`](agent/p2p-test.md) |
| Privacy copy | [`PrivacyPolicy.md`](../PrivacyPolicy.md) |

**CI:** Push to `main` → Xcode Cloud archives Release → uploads to App Store Connect. Bump `MARKETING_VERSION` before a new store version; do not reuse a version already **Ready for Distribution**.

**Local IAP testing:** Xcode **Run** with scheme StoreKit config `ClosedCaptioner.storekit`. TestFlight / `xcodebuild` installs use the **live** store catalog.

---

## Known issues & gaps

| Issue | Status / fix |
|-------|----------------|
| **Remove Ads shows Retry / purchase unavailable** on TestFlight or device deploy | StoreKit returns empty catalog until ASC **Paid Apps** agreement is Active and IAP `ClosedCaptioner` is **Ready to Submit** with full metadata. See [`docs/agent/iap.md`](agent/iap.md). Local `.storekit` only applies to Xcode Run. |
| **Export** | `ExportManager` implemented; no user-facing export action. |
| **Speech locale** | Hard-coded `en-US` only. |
| **Huddle / P2P** | Background keep-alive exists (`UIBackgroundTask` + audio/Bluetooth modes) with auto-off timer; iOS may still suspend. Relay is best-effort TTL hop. |
| **ASC assets** | Prefer Desktop `Closed Captioner Assets/output/processed_screenshots/1242x2688` for store screenshots. |

No automated test target in the Xcode project.

---

## What's next (suggested)

**Store / monetization**
- Finish ASC IAP setup (Paid Apps, product metadata, review screenshot) so Remove Ads works on TestFlight.
- Confirm Xcode Cloud **1.2** build attached to ASC version 1.2 and submit for review when listing is complete.

**Product**
- Expose history export in Settings (wire `ExportManager`).
- Multi-language speech locales.
- Optional caption font size control (architecture note in old README).

**P2P**
- Harden relay / duplicate handling under load; document limits in UI if needed.

**Housekeeping**
- Add unit tests for `HistoryManager`, `PremiumManager` product-ID mapping, P2P envelope parsing.

---

## Agent quick rules

1. Read [`AGENTS.md`](../AGENTS.md) first; open only the agent doc for your task.
2. Match existing MVVM patterns; keep banner layout in a single `ControlsView` VStack.
3. Do not write incoming P2P text into `SpeechService` or center caption.
4. Do not commit unless the user asks.
5. Escalate to human: Developer Mode, PLA/Paid Apps contracts, phone unlock, ASC banking.
