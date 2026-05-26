# Yichalal Engineering — Downloads

> **Latest stable: v1.0.4** (built 2026-05-26)

## 📱 Customer App
**https://gofile.io/d/vAqtQi**
- File: `yichalal-customer-v1.0.4.apk`
- Size: 55 MB
- SHA-256: `ed28c6dc1bef95aa5f5d7a39ca5c26ca05dc2a94e92b3966515047a756556dda`

## 🔧 Mechanic App
**https://gofile.io/d/y4QrS1**
- File: `yichalal-mechanic-v1.0.4.apk`
- Size: 55 MB
- SHA-256: `226c8076eae189d9cc4833380c6b95c88d6e6ddf5bfb6a327e8e6c2db01c8533`

## 📦 Source code
**https://gofile.io/d/2Etk7Q**
- File: `yichalal-source-v1.0.4.zip`

## What's fixed in v1.0.4
- **Add vehicle bug**: customer can now add vehicles even if the Supabase profile row goes missing — proactive profile recreation + retry-once on insert failures, with clearer human-readable error messages.
- **Dark-mode visibility**: AI Diagnosis text bubbles, KYC pending banner (mechanic), and the "no vehicles" warning (customer booking) now use explicit colors that stay readable in both light and dark themes.
- **Realistic gear**: tooth tips are now softly rounded with quadratic curves and there are subtle root fillets between teeth — looks like a real machined cog, not razor-sharp.
- **Same color palette** in both apps (orange primary, mint accent), same Poppins font, same dark/light theming.

## How to install on Android
1. Download the APK to your phone
2. Settings → Apps → Special access → Install unknown apps → enable for your browser
3. Tap the APK file → Install
4. Open the app, enter any +251 phone, use OTP `123456`

## Supabase setup (one-time, takes 1 minute)
If you see "Server not initialised yet" banner at top of the app:
1. Open https://supabase.com/dashboard/project/mfnoyegiuuwthygprjua/sql/new
2. Paste contents of `supabase/schema.sql` from the source zip
3. Click **Run**
4. Reopen the app — banner disappears, signup works.
