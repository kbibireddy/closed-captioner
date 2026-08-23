# In-app purchases (Remove Ads)

> **Entry point:** [`AGENTS.md`](../../AGENTS.md) at the repo root.

Closed Captioner sells one non-consumable: **Remove Ads**.

| Item | Value |
|------|-------|
| App Store Connect app | [6754772689](https://appstoreconnect.apple.com/apps/6754772689) |
| Product ID (must match code) | `ClosedCaptioner` |
| Type | Non-consumable |
| Code | `ClosedCaptioner/IAP/IAPConfig.swift` |
| Local StoreKit file | `ClosedCaptioner.storekit` (Xcode **Run** only) |

## Why Purchases shows Retry

`Product.products(for:)` returns an **empty list** (it does not throw) when Apple does not know that product ID for this app. The UI then shows **Retry** / purchase unavailable.

| How the app was installed | Which catalog StoreKit uses |
|---------------------------|-----------------------------|
| **Product → Run** in Xcode with the ClosedCaptioner scheme | Local `ClosedCaptioner.storekit` |
| TestFlight, App Store, or `xcodebuild` device install | **Live** App Store / sandbox |

## Live-store checklist (browser)

1. [Agreements, Tax, and Banking](https://appstoreconnect.apple.com/agreements) — **Paid Apps** must be **Active** (bank + tax complete).
2. [In-App Purchases](https://appstoreconnect.apple.com/apps/6754772689/distribution/iaps) — product ID exactly `ClosedCaptioner`, status **Ready to Submit** or **Approved**, all metadata (name, description, price, review screenshot) filled.
3. If the app is already on the store, submit the IAP for review from that page (or attach it to the next iOS version).
4. After ASC is correct, wait (often minutes, sometimes hours) and tap **Retry** in Settings → Purchases.

Agents cannot accept Paid Apps contracts or enter banking. Escalate those to the human.

## Local Xcode testing

Scheme **ClosedCaptioner** → Run → Options → StoreKit Configuration = `ClosedCaptioner.storekit`. This bypasses ASC. `xcodebuild` install does **not** use that file.
