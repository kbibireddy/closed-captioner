# Agent Guide — ClosedCaptioner

This file is the entry point for AI coding agents working in this repository. Read it first, then open only the docs relevant to your task.

---

## Project summary

**ClosedCaptioner** is a native iOS app (SwiftUI) for real-time speech-to-text closed captioning. The Xcode project lives at `ClosedCaptioner.xcodeproj`; source is under `ClosedCaptioner/`.

---

## Which file to read

| Task | Read this |
|------|-----------|
| **Any work in this repo** | This file (`AGENTS.md`) |
| **Project overview, features, architecture** | [`README.md`](README.md) |
| **Build or deploy to a physical iPhone** | [`docs/agent/device-deploy.md`](docs/agent/device-deploy.md) |
| **Xcode Cloud / App Store CI** | [`docs/agent/xcode-cloud.md`](docs/agent/xcode-cloud.md) |
| **In-app purchase / Remove Ads / Retry** | [`docs/agent/iap.md`](docs/agent/iap.md) |
| **Nearby P2P radio test (in-app radio + Mac peer)** | [`docs/agent/p2p-test.md`](docs/agent/p2p-test.md) |
| **AdMob `app-ads.txt` / app verification** | [`docs/agent/app-ads-txt.md`](docs/agent/app-ads-txt.md) |
| **Privacy policy content or App Store privacy copy** | [`PrivacyPolicy.md`](PrivacyPolicy.md) |

---

## Agent docs (`docs/agent/`)

Detailed, task-specific guides for agents live here. Prefer these over improvising workflows that are already documented.

| File | When to use |
|------|-------------|
| [`docs/agent/device-deploy.md`](docs/agent/device-deploy.md) | Building, signing, installing, or launching on a connected iPhone; provisioning or Developer Mode errors |
| [`docs/agent/xcode-cloud.md`](docs/agent/xcode-cloud.md) | Xcode Cloud workflow, direct App Store Connect uploads, release automation on push to `main` |
| [`docs/agent/iap.md`](docs/agent/iap.md) | Remove Ads StoreKit empty catalog; Paid Apps agreement; product ID `ClosedCaptioner`; local `.storekit` vs TestFlight |
| [`docs/agent/p2p-test.md`](docs/agent/p2p-test.md) | In-app radio, Multipeer `cc-p2p`, Mac peer at `tools/p2p-radio` |
| [`docs/agent/app-ads-txt.md`](docs/agent/app-ads-txt.md) | AdMob app-ads.txt crawl failures; GitHub Pages domain-root vs project path; Marketing URL requirements |

When you solve a new repeatable workflow problem (especially deploy/CI/tooling), add or update a guide under `docs/agent/` and link it from this file.

---

## Quick reference

| Item | Value |
|------|-------|
| Scheme | `ClosedCaptioner` |
| Bundle ID | `RaveSociety.ClosedCaptioner` |
| Min iOS | 16.4 |
| Architecture | MVVM — see `README.md` |
| AdMob publisher | `pub-7546535789763376` |
| `app-ads.txt` (AdMob crawl) | `https://kbibireddy.github.io/app-ads.txt` (domain **root**, not `/closed-captioner/`) |

---

## Rules of thumb for agents

1. **Deploy to device** → follow `docs/agent/device-deploy.md` end-to-end; do not skip `-allowProvisioningDeviceRegistration`.
2. **App behavior or UI** → read `README.md` and inspect `ClosedCaptioner/` source; match existing MVVM patterns.
3. **AdMob verify / `app-ads.txt`** → follow `docs/agent/app-ads-txt.md`. Project Pages under `/closed-captioner/` is not enough; AdMob needs domain-root + a **live** App Store Marketing URL on `kbibireddy.github.io`.
4. **Do not commit** unless the user explicitly asks.
5. **Escalate to the human** only for actions agents cannot perform (Developer Mode, PLA acceptance, unlock phone, trust certificate).
