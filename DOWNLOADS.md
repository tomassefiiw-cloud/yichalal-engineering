# Yichalal Engineering — Downloads

## v1.0.3 (latest)

Download links appear in the GitHub Actions build summary:
👉 https://github.com/tomassefiiw-cloud/yichalal-engineering/actions

> Both APKs use the **OpenRouter model `openai/gpt-oss-120b:free`** for AI diagnosis
> and `https://mfnoyegiuuwthygprjua.supabase.co` for the live cross-device database.

## What's new in v1.0.3

### Vehicle add — auto-recovers from "foreign key" errors ✅
Previously, if your `profiles` row was missing in Supabase (which happens
when you signed up before the schema was applied, or after a DB wipe),
adding a vehicle threw a cryptic foreign-key error. Now the app detects
this and re-creates your profile row automatically before retrying the
insert — no more silent failures.

### Chat — guaranteed correct order ✅
Chat messages are now sorted **client-side** by timestamp so the newest
message is always at the bottom regardless of how Supabase orders the
stream. The view also auto-scrolls to the bottom on every new message.

### Settings always reachable ✅
Added a **Settings ⚙** icon directly to the app bar of both apps — no need
to dig into Profile to change language or theme. The icon is on every
screen.

### Mechanic — much wider earnings analytics ✅
- 6 stat cards in a 3×2 grid (week / 30 days / all time / avg per job / total jobs / cancel rate)
- 7-day bar chart **and** 30-day line chart with gradient fill
- Pipeline strip (pending → active → completed)
- Pie chart of earnings by service type, with line-by-line breakdown
- "Top earning days" table (top 5 days in the last 30)
- Recent transactions list

### Title bar — no more overlap ✅
"Yichalal" + "CUSTOMER" / "MECHANIC" badge now use `FittedBox` so they
scale down on narrow phones instead of clipping/overlapping with the
appbar icons.

### Repo cleanups ✅
- Explicit `ascending: true/false` on every realtime stream's `.order(...)`.
- `Auth.ensureProfileExists()` helper used by the vehicle form.
- Bumped to v1.0.3 (+4).

## How to install

1. Open the **Actions** page above → click the most recent successful run.
2. Scroll to the **build summary** at the top of the page — you'll see
   3 gofile.io links: Customer APK, Mechanic APK, and Source zip.
3. Download the APK to your phone → Open it → Install
   (allow "install from unknown source" once).
4. **First time only:** open your Supabase dashboard
   ([https://supabase.com/dashboard/project/mfnoyegiuuwthygprjua](https://supabase.com/dashboard/project/mfnoyegiuuwthygprjua)) →
   SQL Editor → paste contents of `supabase/schema.sql` → Run.

### Demo OTP
Always **`123456`** (real Twilio SMS would need your Twilio keys).

## Application IDs (so both can coexist on one phone)
- Customer: `com.yichalal.customer` — "Yichalal Customer"
- Mechanic: `com.yichalal.mechanic` — "Yichalal Mechanic"
