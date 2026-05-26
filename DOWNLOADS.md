# Yichalal Engineering — Latest Build (v1.1.0)

Built: 2026-05-26 — built on GitHub Actions, signed APKs.

## 📱 Customer APK
**https://gofile.io/d/ki5OCM**

Install on a customer's phone. Package: `com.yichalal.customer`

## 🔧 Mechanic APK
**https://gofile.io/d/cy0626**

Install on a mechanic's phone. Package: `com.yichalal.mechanic`

Both APKs can co-exist on the same phone (different package IDs).

## 📦 Full source code (zip)
**https://gofile.io/d/LfiCCt**

Includes `customer_app/`, `mechanic_app/`, `shared_core/`, `supabase/schema.sql`.

## 🚀 Quick start

1. **One-time Supabase setup** (the only thing you need to do once):
   - Open https://supabase.com/dashboard/project/mfnoyegiuuwthygprjua
   - Left sidebar → **SQL Editor** → **New query**
   - Open `supabase/schema.sql` from the source zip → copy all → paste → **Run**
   - Done. Schema is idempotent (safe to re-run).

2. **Install both APKs** on your phones.

3. **Use demo OTP `123456`** to sign in/up. Any +251 phone works.

## ✅ What's working in v1.1.0

- Phone+OTP auth via Supabase
- Vehicle add (the `photo_url` schema mismatch is bypassed in client code)
- AI diagnosis via OpenRouter (`openai/gpt-oss-120b:free` primary, backup model fallback, local engine if both fail)
- Language switch (English / አማርኛ / Afaan Oromoo) applies instantly
- Theme switch (System / Light / Dark) applies instantly
- Real-time booking sync between customer & mechanic apps via Supabase
- KYC trade-license / national-ID / workshop photos for mechanic signup
- Real OpenStreetMap (no Google key needed)
- ETB pricing, PDF invoice, wallet, 10% commission
- Local push notifications (in-app + phone tray when app is recent)

## Versions

- Customer: `com.yichalal.customer` v1.1.0+7
- Mechanic: `com.yichalal.mechanic` v1.1.0+7
- Shared core: see `shared_core/` for theme, l10n, models, repo, AI, notify

## SHA-256 verification

```
4a22a1e7f680bfe78a7566b1e193868fe670ab70f0ef83294a4268d1e1b2403b  yichalal-customer-v1.1.0.apk
137128552d9e7fb3861b44cd45d2b56cc1244e83d5739604266988f0deb03e1f  yichalal-mechanic-v1.1.0.apk
20276968484dec613316ef5534d8355b8fae1503b3d9f48d935f32855538fcaf  yichalal-source-v1.1.0.zip
```
