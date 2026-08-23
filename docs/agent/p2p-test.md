# Nearby P2P caption test (for AI agents)

> **Entry point:** [`AGENTS.md`](../../AGENTS.md). Usage for humans: [`tools/p2p-radio/README.md`](../../tools/p2p-radio/README.md).

Nearby messaging. Radio on: iOS browses and advertises. Swipe up on a caption to send. Mac CLI sends and receives. No cellular, no server.

## What shipped

| Piece | Behavior |
|--------|----------|
| Radio icon, top right | Off by default. On = browse + advertise Multipeer `cc-p2p`. |
| Live log strip | Directly **above the bottom banner**. Transparent. New York serif (`AppType.display`) like captions / Settings titles. Multi-line until 180 characters. Relative age (`1s ago`). Height hugs one row, then grows to 50pt **+ 75%** and scrolls. Top of a full window fades to clear; latest row stays at the bottom. |
| Log row | `[display name] message… HH:mm:ss` — one line, message truncated. Newest at the bottom. Max **200** rows; oldest is dropped. |
| Display name | Settings → General → User info. Defaults to device host name; user can change it. |
| Center caption | Speech / keyboard / poof only. Incoming P2P never replaces it. |
| Mac radio | `tools/p2p-radio` advertises + browses. Sends only what you type. Prints incoming as `[name] text  HH:mm:ss`. |

Radio **on** browses and advertises. Two phones with radio on can see each other. Swipe **up** on the center caption to send it.

## How to test

1. Install Closed Captioner on a physical iPhone (see [`device-deploy.md`](device-deploy.md)).
2. On the Mac: `cd tools/p2p-radio && swift run p2p-radio` (no default message).
3. On the phone: open the app, tap the radio (top right) on, allow Local Network.
4. Type a line in the Mac terminal → a **new row is appended** in the log, not in the center caption.
5. Put text on the main screen (mic or keyboard). Swipe **up** on the caption.
6. Caption flies off the top, is saved to History, and a row with **your display name** appears in the log only after the send succeeds. Mac terminal should print the same text.
7. Turn the radio off → log strip hides; center captions are unchanged. Eraser does not clear the log.

## Do not break

- Mic long-press, 15s auto-stop, banners, interstitials, IAP, settings, themes.
- Do not write received P2P text into `SpeechService`, history, or the center caption.
- Do not start browsing on launch.

## Permissions

`Info.plist` / generated keys:

- `NSLocalNetworkUsageDescription`
- `NSBonjourServices` = `_cc-p2p._tcp`
- `NSBluetoothAlwaysUsageDescription`

## Limits

- App must stay in the foreground.
- Mac stub is not a Bluetooth-radio proof; it usually uses LAN Bonjour.
- Keep `P2PConfig.swift` copies in the app and the tool identical.
