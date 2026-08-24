# Closed Captioner

Native iOS app for live speech-to-text captions in portrait. Speak into the mic, see large on-screen text, edit, save history, and optionally share nearby with **Huddle**.

**→ Full product map (features, architecture, ops, known issues):** [`docs/STEERING.md`](docs/STEERING.md)

| Item | Value |
|------|-------|
| Display name | Closed Captioner |
| Bundle ID | `RaveSociety.ClosedCaptioner` |
| Min iOS | 16.4 |
| Marketing version | 1.2 |
| Architecture | MVVM |

## Features (1.2)

- **Live captions** (English `en-US`): long-press mic to start/stop; auto-stops after 15 seconds
- **Appearance**: Day / Night in Settings → Preferences; six themes (Grove default, Harbor, Ember, Ink, Dusk, Stealth)
- **Fonts**: System, New York, Avenir Next, Futura, Rounded
- **Keyboard edit**, eraser with Poof animation, caption history in Activity → Captions
- **Optional emojis** after speech settles (Preferences → Captions; off by default, experimental)
- **Shake** (mic off): pickup line; 5s cooldown
- **Huddle** (nearby Multipeer `cc-p2p`): share captions over the local network; flick up on the canvas to send; incoming messages stay in the log strip, never the main caption
- **Settings**: Preferences, KPIs, Activity (Captions + Huddle), Purchases
- **Ads** (AdMob banners + interstitials) with optional **Remove Ads** one-time IAP (`ClosedCaptioner`)

Export to text / PDF / HTML exists in code (`ExportManager`) but is not exposed in the UI yet.

## Main screen controls

| Location | Action |
|----------|--------|
| Top left | Settings |
| Top right | Huddle (off: Tap to join; on: ↓/↑ B/s) |
| Bottom left | Keyboard |
| Bottom center | Mic (long-press start/stop) |
| Bottom right | Eraser |
| Caption canvas | Flick up (±60°) to send when Huddle is on |

Day/Night, theme, and font live in **Settings → Preferences**, not on the main screen.

## Architecture (high level)

```
ContentView
├── SpeechService / MicController
├── AppStateViewModel (theme, day/night, overlays, Huddle prefs)
├── HistoryManager
├── P2PInboxService (Huddle)
├── PremiumManager (StoreKit 2)
└── ControlsView (chrome, banners, Huddle HUD)

Settings → Preferences | KPIs | Activity | Purchases
```

Details and file map: [`docs/STEERING.md`](docs/STEERING.md).

## Setup

1. Open `ClosedCaptioner.xcodeproj` in Xcode
2. Select the `ClosedCaptioner` scheme
3. Run on a device (speech recognition needs a real device for best results)
4. Grant microphone and speech recognition when prompted
5. For local IAP testing: scheme Run → Options → StoreKit Configuration = `ClosedCaptioner.storekit`

Agent docs (deploy, Xcode Cloud, IAP, AdMob, Huddle test): [`AGENTS.md`](AGENTS.md)

## Requirements

- iOS 16.4+
- Microphone and speech recognition
- Local Network (optional, for Huddle)

## License

MIT
