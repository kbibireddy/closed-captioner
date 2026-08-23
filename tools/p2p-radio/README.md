# p2p-radio — Mac test radio

This tool is a nearby Closed Captioner **radio**: it **sends and receives** over Multipeer Connectivity (local Wi‑Fi and/or Bluetooth). It does **not** use cellular or any server.

“Radio” matches the in-app control — one peer that can talk both ways.

## Requirements

- macOS 13+
- Xcode / Swift toolchain (`swift --version`)
- A **physical iPhone** with Closed Captioner installed (Simulator has no Bluetooth; local-network discovery is flaky)
- Phone and Mac on the **same Wi‑Fi**, **or** Bluetooth on and no Wi‑Fi network
- App **open** in the foreground, radio **ON**
- Allow **Local Network** on the phone the first time

## Run

From the repository root:

```bash
cd tools/p2p-radio
swift run p2p-radio
```

It starts **silent**. Nothing is sent until you type a line and press Enter.

On the phone:

1. Open Closed Captioner.
2. Tap the **radio** icon (top right) so it lights up.
3. Allow Local Network if iOS asks.
4. Type a line in the Mac terminal and press **Enter**.
5. The nearby **message log** should show `[Your-Mac-Name] your text`.

Incoming traffic on the Mac prints as:

```
[Karthiks-iPhone] hello  14:02:11
```

If the line was **relayed** (someone else originated it; a neighbor forwarded it here), the neighbor that emitted it to this process is appended:

```
[Karthiks-iPhone] hello  14:02:11  via Mids-iPhone
```

Two Mac processes can talk to each other the same way.

Ctrl+C stops.

## If nothing appears

- Radio is off (default). Turn it on.
- Phone and Mac not nearby / not on the same LAN.
- Local Network permission denied: Settings → Closed Captioner → Local Network.
- App backgrounded or on the Settings overlay the whole time (stay on the main caption screen).
- Mac firewall blocking Bonjour (rare on the same Wi‑Fi).
- Service type mismatch: both sides must use `cc-p2p` (see `P2PConfig.swift`).
- Stale `p2p-radio` process: quit the old terminal (`Ctrl+C`) and `swift run` again, then toggle radio off/on on the phone.
- Phone log shows `Inviting … → connecting → notConnected`: rebuild the app (encryption is optional for iOS↔Mac) and restart the Mac tool. Allow **Local Network** for Terminal if macOS asks.

This stub travels over **local Wi‑Fi / Bonjour** more often than Bluetooth. Two iPhones are still required to prove Bluetooth in a room with no network.

## Protocol

JSON envelope, UTF-8:

```json
{"v":1,"text":"hello","from":"Karthiks-MacBook"}
```

Bonjour service type: `cc-p2p` (`_cc-p2p._tcp` in the iOS Info.plist).
Discovery info: `role=emit`, `id=<uuid>`.

Keep `Sources/RadioPeer/P2PConfig.swift` in sync with `ClosedCaptioner/Services/P2PConfig.swift`.
