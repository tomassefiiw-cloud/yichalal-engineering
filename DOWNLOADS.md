# Yichalal Engineering — Downloads

> **Latest: v1.0.5** — building now via GitHub Actions.
> When build finishes, this file is updated with fresh gofile links.

## What v1.0.5 fixes
- **Vehicle add** — 3-step profile recovery: checks profile by id, then by phone (adopts server's id if different), then recreates if missing, with retry-once on insert error. Plus clearer human-readable error messages.
- **Realistic gear** — true machined-cog silhouette with cubic-bezier involute tooth flanks, rounded tip crown, concave root fillets between teeth, 6 bolt holes, raised hub ring, chamfered axle, radial gradient + drop shadow.
- **Dark-mode text visibility** — AI chat bubbles, KYC pending banner (mechanic), "no vehicles" warning (customer) now use explicit theme-aware colors.

## Always-on functionality
- Live Supabase cross-device sync (customer signs up → mechanic sees the booking)
- Add vehicle with proactive profile recovery (no more "could not add to profile" errors)
- AI diagnosis via OpenRouter (primary `openai/gpt-oss-120b:free`, backup `liquid/lfm-2.5-1.2b-instruct:free`, then local rule engine)
- Real OpenStreetMap with simulated mechanic-to-customer movement + ETA
- ETB-only payments (Telebirr/CBE/Amole/Cash/Wallet) with PDF invoices
- In-app chat with newest-message-at-bottom ordering
- Customer & mechanic wallets with 10% platform commission deduction
- Live language switching (English / አማርኛ / Afaan Oromoo)
- Light/Dark/System theme with adaptive text colors
- Mechanic earnings analytics (7-day bar chart, 30-day line chart, by-service-type breakdown, all-time totals)

## How to install on Android
1. Download the APK below to your phone
2. Settings → Apps → Special access → Install unknown apps → enable for your browser
3. Tap the APK file → Install
4. Open the app, enter any +251 phone, use OTP `123456`

## Supabase setup (one-time, 1 minute)
If you see "Server not initialised yet" banner at the top:
1. Open https://supabase.com/dashboard/project/mfnoyegiuuwthygprjua/sql/new
2. Paste contents of `supabase/schema.sql` from the source zip
3. Click **Run** — banner disappears, signup works
