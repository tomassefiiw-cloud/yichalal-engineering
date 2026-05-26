# Yichalal Engineering — v1.0.1 Downloads

> Build agent automatically updates this file after every successful CI run.
> All gofile.io links are public, permanent, no account needed.

## v1.0.1 — Live preferences, unified orange branding, vehicle-save fix

| | gofile.io | SHA-256 |
|---|---|---|
| 📱 **Customer APK** (55 MB) | https://gofile.io/d/HtaI1u | `118b298afb82b3a4a54b6ce757c9f01d64c9de94978afbe1faabf97e78e4b6ff` |
| 🔧 **Mechanic APK** (54 MB) | https://gofile.io/d/7MiMQc | `f5dfb7acccdb7e418e79f7f0aa3cb7723e2d4962efc56a30bcce1bcb103b9d6d` |
| 📦 **Full source code** | https://gofile.io/d/KskySo | `c5e656ab81694b7cfad5b3eb83f2743e287bd00ed3d24dd30d4e125461a07043` |

## What changed in v1.0.1

- ✅ **Language switch works LIVE** — open Profile → Settings → tap አማርኛ / English / Afaan Oromoo, applies instantly across the whole app
- ✅ **Theme switch works LIVE** — System / Light / Dark mode, persisted to disk
- ✅ **Unified orange branding** — mechanic app no longer uses mint; both apps look like siblings now
- ✅ **Vehicle save** — explicit inline error messages instead of silent failure
- ✅ **Dark mode readable** — chat bubbles, diagnose results, profile cards all use theme-aware text colors
- ✅ **Auth screens** — both apps use orange palette consistently

## Install

1. Open the gofile link on your Android phone → click the file → Download
2. First time only: Settings → Apps → ⋮ → Install unknown apps → enable for your browser
3. Tap the downloaded APK → Install

## Demo flow

- **Customer phone:** install Customer APK, sign up with `+251911...`
- **Mechanic phone:** install Mechanic APK, sign up with `+251922...`
- Both connect to the same Supabase project, so bookings, chats, status changes propagate live across both phones.
- OTP is always `123456` (demo mode).

## Configuration

The apps ship with Supabase URL + publishable key + OpenRouter key all baked in.
**No setup needed on your phone.** Just install and use.

Source repo: https://github.com/tomassefiiw-cloud/yichalal-engineering
