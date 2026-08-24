# Nearby P2P caption test (for AI agents)

> **Entry point:** [`AGENTS.md`](../../AGENTS.md). Usage for humans: [`tools/p2p-radio/README.md`](../../tools/p2p-radio/README.md).

Nearby messaging. Huddle on: iOS browses and advertises. Flick the caption **up** (±60°) to send. Mac CLI sends and receives. No cellular, no server.

## What shipped

| Piece | Behavior |
|--------|----------|
| Huddle icon, top right | Off by default. On = browse + advertise Multipeer `cc-p2p`. Stays up if you switch apps or lock the phone until you turn it off, force-quit, or the auto-off timer (Settings → General, default 30 minutes). One local notification per launch, only if Huddle is on and you lock the phone or leave the app for 60s. Allow Notifications on first Huddle-on. |
| Huddle status (left of icon) | Off: **Tap to join**. On: **Huddle**, then ↓ B/s and ↑ B/s (rolling 30s average). Detailed counters are in Settings → KPIs. |
| Relay messages | Settings → Preferences → Nearby. **On by default.** Huddle must be on. Forwards payloads that have an `id` (TTL 4). v1 / no-id packets are displayed only, not forwarded. No catch-up. |
| Live log strip | Directly **above the bottom banner**. Transparent. New York serif (`AppType.display`) like captions / Settings titles. Multi-line until 180 characters. Relative age (`1s ago`). Height hugs one row, then grows to 50pt **+ 75%** and scrolls. Top of a full window fades to clear; latest row stays at the bottom. |
| Log row | `[display name] message… HH:mm:ss` — one line, message truncated. Newest at the bottom. Max **200** rows; oldest is dropped. |
| Display name | Settings → General → User info. Defaults to device host name; user can change it. |
| Center caption | Speech / keyboard / poof only. Incoming P2P never replaces it. |
| Mac peer | `tools/p2p-radio` advertises + browses. Sends only what you type. Prints incoming as `[name] text  HH:mm:ss`. |

Huddle **on** browses and advertises. Two phones with Huddle on can see each other. Flick the center caption **up** (or within 60° of up) anywhere on the canvas to send. Wrong direction shows **Try again** + ↑, then the caption returns. After a successful send, **Sent!** fades like **Poof!!!**.

## How to test

1. Install Closed Captioner on a physical iPhone (see [`device-deploy.md`](device-deploy.md)).
2. On the Mac: `cd tools/p2p-radio && swift run p2p-radio` (no default message).
3. On the phone: open the app, tap Huddle (top right) on, allow Local Network. **Huddle** with ↓/↑ rates appears left of the antenna.
4. Type a line in the Mac terminal → a **new row is appended** in the log, not in the center caption. After the session connects, the status should read **1 person**.
5. Put text on the main screen (mic or keyboard). Flick **up** on the canvas (not only on the letters).
6. Caption flies in the flick direction, is saved to History, **Sent!** appears briefly, and a row with **your display name** appears in the log only after the send succeeds. Mac terminal should print the same text. A sideways/down flick shows **Try again** and restores the caption.
7. Turn Huddle off → log strip hides; center captions are unchanged. Eraser does not clear the log.
8. Relay: Settings → Preferences → Nearby → **Relay messages** (on by default). While Huddle is on, the HUD shows **Relaying**. A third phone beyond 1 hop should see the caption only if the middle phone has relay on. Switching apps or locking the phone should **not** tear down the session immediately; the middle phone stays a hop until Huddle off, force-quit, auto-off timer, or iOS suspending the process. Returning to the app rebuilds if iOS did suspend, without resetting KPIs. Detailed forwarded / duplicate counts stay in Settings → KPIs.

## Do not break

- Mic long-press, 15s auto-stop, banners, interstitials, IAP, settings, themes.
- Do not write received P2P text into `SpeechService`, history, or the center caption.
- Do not start browsing on launch.

## Permissions

`Info.plist` / generated keys:

- `NSLocalNetworkUsageDescription`
- `NSBonjourServices` = `_cc-p2p._tcp`
- `NSBluetoothAlwaysUsageDescription`
- Background modes: `audio`, `bluetooth-central`, `bluetooth-peripheral` (Huddle can keep advertising while backgrounded; iOS may still suspend)

## Limits

- Huddle stays up in the background until you turn it off, force-quit, or the auto-off timer. iOS can still freeze Multipeer to save battery; returning to the app rebuilds the session.
- Mac stub is not a Bluetooth Huddle proof; it usually uses LAN Bonjour.
- If the phone log shows Inviting the Mac then `connecting` then `notConnected`, rebuild the app and restart `swift run p2p-radio`. Required encryption without a certificate often fails iOS↔Mac ICE.
- Keep `P2PConfig.swift` copies in the app and the tool identical.
