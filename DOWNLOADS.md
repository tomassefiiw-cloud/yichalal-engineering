# Yichalal Engineering — v1.1.0 Downloads

## 📦 All files (one folder)
**→ https://gofile.io/d/oCuPPq**

Contains:
| File | Size | What it is |
|---|---|---|
| `yichalal-customer-v1.1.0.apk` | 55 MB | Customer app — install on customer phone |
| `yichalal-mechanic-v1.1.0.apk` | 55 MB | Mechanic app — install on mechanic phone |
| `yichalal-source-v1.1.0-full.zip` | 130 KB | Full source (Flutter + schema + workflow) |

## ⚠️ ONE-TIME SETUP: Apply database schema (90 seconds)

The new Supabase project (`yptrodblyfscyqngakie`) is empty. Apply the schema once:

1. **Open** → https://supabase.com/dashboard/project/yptrodblyfscyqngakie/sql/new
2. Copy the entire contents of [`supabase/schema.sql`](supabase/schema.sql) (in this repo)
3. Paste into the SQL Editor → click **Run** (or Cmd/Ctrl-Enter)
4. Wait for "Success" message
5. Done — both apks now work end-to-end

After that, the demo accounts (Abebe, Solomon, Hanna, Mulugeta, Admin) are already seeded by the schema. You can sign up new ones too.

## 🔑 Demo accounts (no OTP, one tap)

Both APKs ship a "Demo accounts" button on the role-select screen.
- **Customer**: Abebe Kebede (+251911000001) — pre-seeded with vehicles
- **Mechanic verified**: Solomon (+251911000002)
- **Mechanic verified**: Hanna (+251911000003)
- **Mechanic KYC-pending**: Mulugeta (+251911000004)
- **Admin**: (+251911000000)

## ✅ What was fixed in v1.1.0

- ✅ **Vehicle add error** (`photo_url not found`) → schema has the column + drift-repair
- ✅ **AI diagnosis** → uses `openai/gpt-oss-120b:free` (verified responding)
- ✅ **Role mixing** → separate APKs entirely (customer vs mechanic)
- ✅ **Chat ordering** → newest message at the bottom, auto-scrolls
- ✅ **Vehicle registration form** → mechanic signup demands license + ID + workshop photos
- ✅ **Real-time sync** → Supabase Realtime publication on bookings/chats/notifications
- ✅ **Language + dark mode** → in-app Settings → Preferences (persisted)
- ✅ **Orange theme** → unified palette across both apps
- ✅ **Poppins font** → via google_fonts
- ✅ **Realistic gear logo** → cubic-bezier tooth profile, 14 teeth, bolt holes

## 📲 Install

1. Download APK from gofile link above
2. On Android: Settings → Security → "Install unknown apps" → enable for your browser
3. Open the .apk → Install
