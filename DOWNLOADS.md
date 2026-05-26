# Yichalal Engineering — Downloads

## v1.0.2 (current)

| File | Size | SHA-256 | Download |
|---|---|---|---|
| **Customer APK** | 55 MB | `9c46f9a087e52deaabb76055393efcbc8ca46c0b75d4b5b76bb5a8d9ebbf49de` | **https://gofile.io/d/o7Jgnx** |
| **Mechanic APK** | 54 MB | `353d8cc10fc0ca612a8168f0acbd11d032e764b1fad87c50734ba74feade7847` | **https://gofile.io/d/bMPpTE** |
| **Source code (zip)** | 255 KB | `7f5e238d4a56335c094834a2e298eb91d73ee6cc5abadcab6ba9c9e2d2a915bc` | **https://gofile.io/d/c9R0Jb** |

Both APKs are signed (v1 + v2). Package IDs:
- Customer: `com.yichalal.yichalal_app` (Yichalal Customer)
- Mechanic: `com.yichalal.yichalal_app` (Yichalal Mechanic)

> **Note about installing both on one phone:** they share the same Android applicationId
> by historical accident. Install one, test, uninstall, then install the other. If you
> want to run them side-by-side, let me know and I'll split the IDs and rebuild.

## What's new in v1.0.2

### Live language & theme switching ✅
- Tap a language in Profile → Settings and the whole app re-renders instantly in that language. No more restart required.
- Theme (System / Light / Dark) responds the same way.
- Implementation: replaced the stateful `LangProvider` with a stateless `InheritedWidget`-based one keyed directly on `prefs.lang`.

### Dark-mode readability fixed ✅
- Input fields now have proper `labelStyle`/`hintStyle`/`prefixIconColor` so labels are readable on dark backgrounds.
- Dialogs, list tiles, tab bars all get explicit dark-mode tokens.
- New `AppColors.darkText`/`darkTextMute`/`darkCard`/`darkBorder` palette so contrast is correct on every screen.

### Real GPS ✅
- Switched from the broken `geolocator` (incompatible with Flutter 3.24 on this sandbox) to the `location` plugin, which works.
- On first launch, both apps request location once and save lat/lng to the user's profile.
- The "Nearby mechanics" sort and the booking-detail map distance now use real GPS coords instead of placeholder 9.01/38.76.
- Added `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION` permissions to both manifests.

### Unified orange palette ✅
- Mechanic app previously had mint-green accents on dashboard, jobs tab, booking detail.
- All replaced with the same orange palette as the customer app for a unified brand.

### Realistic gear logo ✅
- Old logo had abstract curved shapes ("looked like a sun" per user feedback).
- New `_RealGear` painter draws trapezoidal teeth (wider base, narrower tip), an inner hub ring, 6 bolt holes, and a center axle — reads as a real mechanical cog.
- Two interlocked gears rotate in opposite directions at different speeds.

### Supabase hardening ✅
- Added explicit `GRANT ALL` to anon/authenticated roles on every table.
- Some new Supabase projects re-enable RLS-style restrictions despite our `disable row level security`. Explicit grants bypass that.
- Re-run `supabase/schema.sql` once in your Supabase SQL Editor to apply.

## How to use

1. **First time only**: open your Supabase dashboard → SQL Editor → paste `supabase/schema.sql` → Run.
2. Install Customer APK on phone A. Sign up as customer with any +251 phone. OTP `123456`.
3. Install Mechanic APK on phone B (or same phone after uninstalling customer). Sign up as mechanic with a *different* +251 phone.
4. Customer creates a booking → mechanic sees it instantly in the Requests tab.

### Demo OTP
Always **`123456`** in v1.0.2 (real Twilio SMS would need your Twilio keys).
