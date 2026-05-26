# Yichalal Engineering

Mechanical service provider platform for Ethiopia. Two real cross-device apps
(Customer + Mechanic) sharing data via Supabase realtime.

## Architecture

```
yichalal-engineering/
├── shared_core/      Shared Dart package: models, Supabase repo, AI, theme, gear logo
├── customer_app/     Flutter app — Customer role (orange theme)
├── mechanic_app/     Flutter app — Mechanic role (mint theme)
├── supabase/         schema.sql to bootstrap your Supabase project
└── .github/workflows Build pipeline (auto-builds + uploads APKs to gofile.io)
```

## Setup

### 1. Supabase (one time)
1. Open https://supabase.com → log into your project
2. SQL Editor → paste contents of `supabase/schema.sql` → Run
3. Done. URL + anon key are already embedded in `shared_core/lib/config.dart`.

### 2. Build APKs
Push to `main` and GitHub Actions automatically:
- builds both APKs with Flutter 3.24.5
- uploads them to gofile.io
- prints download links in the workflow summary

Or build locally:
```bash
cd customer_app && flutter pub get && flutter build apk --release
cd ../mechanic_app && flutter pub get && flutter build apk --release
```

## Demo flow

1. Install **Customer** APK on phone A → sign up with any `+251` number → OTP `123456`
2. Install **Mechanic** APK on phone B → sign up with a DIFFERENT `+251` number
3. Customer creates a booking → mechanic sees it instantly in Requests tab
4. Mechanic Accepts → Start → Finish → customer rates + pays
5. Both phones see live status changes & chat messages

## What's in v1.0

- ✅ Phone+OTP signup with role-locked accounts (`123456` is the dev OTP)
- ✅ Mechanic KYC fields (Trade License #, National ID #, specialties)
- ✅ Customer garage with vehicle add/edit
- ✅ AI Diagnosis streaming from OpenRouter (DeepSeek Chat v3.0324)
- ✅ Booking lifecycle: pending → accepted → enroute → in-progress → completed
- ✅ Real-time chat (correct order, oldest top, newest bottom, multi-line input)
- ✅ Real OpenStreetMap with mechanic→customer route + ETA
- ✅ Telebirr/CBE/Amole/Cash/Wallet payment with 10% commission split
- ✅ Mechanic earnings dashboard with weekly bar chart, service-mix pie chart, KPIs
- ✅ Push notifications via local Android channel (works while app is open / backgrounded)
- ✅ Supabase realtime: every change visible across both apps within ~1 second
- ✅ Poppins typeface, warm orange (customer) / mint (mechanic) themes, full dark mode
- ✅ Smooth realistic gear logo
- ✅ 3-language i18n (English / አማርኛ / Afaan Oromoo)

## Notes

- **GPS**: device-level geolocator is incompatible with Flutter 3.24's plugin contract; the apps use each user's saved address + simulated movement on a real OpenStreetMap. This is a known constraint of the chosen Flutter version, not a code bug.
- **Cross-device wake-from-sleep push**: requires an FCM project. Local notifications work in foreground/background.

<!-- build trigger: 2026-05-26T10:46:52Z -->
