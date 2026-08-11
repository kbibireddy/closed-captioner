# AdMob `app-ads.txt` Verification

> **Entry point:** [`AGENTS.md`](../../AGENTS.md)

How to keep Google AdMob app verification working for Closed Captioner. Do not assume “file exists on the marketing site” is enough.

---

## Canonical snippet

Repo copies (same content):

- [`app-ads.txt`](../../app-ads.txt) (repo root — also published via project GitHub Pages)
- [`docs/app-ads.txt`](../app-ads.txt)

```
google.com, pub-7546535789763376, DIRECT, f08c47fec0942fa0
```

Publisher ID: `pub-7546535789763376` (matches `AdConfig` / `GADApplicationIdentifier`).

---

## Critical gotcha: domain **root**, not project path

AdMob crawls:

```text
https://<domain-from-App-Store-Marketing-URL>/app-ads.txt
```

It does **not** crawl a subdirectory, even if that subdirectory is the marketing page.

| URL | Status |
|-----|--------|
| `https://kbibireddy.github.io/closed-captioner/app-ads.txt` | Reachable, but **ignored** by AdMob crawler |
| `https://kbibireddy.github.io/app-ads.txt` | **Required** — domain root |

Project GitHub Pages (`username.github.io/repo/`) cannot satisfy AdMob by itself. Publish root file from the **user** Pages site:

- Repo: [`kbibireddy/kbibireddy.github.io`](https://github.com/kbibireddy/kbibireddy.github.io)
- Live file: [https://kbibireddy.github.io/app-ads.txt](https://kbibireddy.github.io/app-ads.txt)

When changing the AdMob publisher line, update **both** this repo’s `app-ads.txt` / `docs/app-ads.txt` **and** `kbibireddy.github.io`’s root `app-ads.txt`.

---

## Critical gotcha: live App Store **Marketing URL**

AdMob resolves the crawl domain from the **Marketing URL** on the **live** App Store listing (not Support URL, not a pending version only).

| Field | Role for AdMob |
|-------|----------------|
| **Marketing URL** | Domain AdMob uses for `app-ads.txt` |
| **Support URL** | Not used for `app-ads.txt` (ours is `github.com/...` — cannot host `/app-ads.txt`) |

Checklist:

1. In App Store Connect → version → **Marketing URL** must be set to a URL whose **host** is `kbibireddy.github.io` (e.g. `https://kbibireddy.github.io/closed-captioner/`).
2. That Marketing URL must be on the **Ready for Distribution / live** listing. Empty Marketing URL on live 1.0 → AdMob cannot verify even if root `app-ads.txt` is correct.
3. Marketing URL cannot be added to a live version without a new version release (Promotional Text alone is editable).
4. After Marketing URL is live, AdMob → app → **Verify** → **Check for updates**. Crawls are often fast; sometimes take longer.

Verify the store side after release:

```bash
curl -s "https://itunes.apple.com/lookup?id=6754772689" | python3 -c \
  'import sys,json; r=json.load(sys.stdin)["results"][0]; print(r.get("sellerUrl"))'
# Expect a URL under kbibireddy.github.io (sellerUrl maps to Marketing URL)
```

---

## Quick verification commands

```bash
# Must be HTTP 200 + the google.com line
curl -sI "https://kbibireddy.github.io/app-ads.txt"
curl -s  "https://kbibireddy.github.io/app-ads.txt"

# Nice to have (project Pages) — not sufficient alone
curl -sI "https://kbibireddy.github.io/closed-captioner/app-ads.txt"
```

---

## Age rating (related App Review trap)

If the binary includes AdMob, App Store Connect **Age Ratings → Advertising** must be **Yes**. Mismatch → Guideline **2.3.6 Accurate Metadata** rejection. See App Information → Age Ratings after any ads change.

---

## Agent rules of thumb

1. Never “fix” AdMob verify by only committing `app-ads.txt` under `closed-captioner` Pages.
2. Always confirm **root** URL `https://kbibireddy.github.io/app-ads.txt` returns 200.
3. Always confirm **live** Marketing URL host is `kbibireddy.github.io` before declaring verification unblocked.
4. Do not change AdMob publisher IDs without updating root Pages + both repo copies.
