-- =================================================================
-- Yichalal Engineering — Supabase schema (idempotent, safe to re-run)
--
-- TO APPLY:
--   1. Open https://supabase.com/dashboard/project/yptrodblyfscyqngakie/sql/new
--   2. Paste this entire file
--   3. Click Run
--   4. Done. Both APKs work end-to-end across devices.
-- =================================================================

-- ── PROFILES ─────────────────────────────────────────────────────────
create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  phone text unique not null,
  email text,
  role text not null check (role in ('customer','mechanic','admin')),
  address text default '',
  language text default 'en',
  engine_types text[] default array[]::text[],
  kyc_verified boolean default false,
  trade_license_url text,
  national_id_url text,
  workshop_photo_urls text[] default array[]::text[],
  specialties text[] default array[]::text[],
  wallet_balance numeric default 0,
  lat double precision,
  lng double precision,
  is_online boolean default true,
  created_at timestamptz default now()
);

-- ── VEHICLES ─────────────────────────────────────────────────────────
create table if not exists vehicles (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  make text not null,
  model text not null,
  year int not null,
  vin text,
  engine_type text not null,
  plate_number text not null,
  color text,
  mileage int,
  photo_url text,
  created_at timestamptz default now()
);
create index if not exists vehicles_owner_idx on vehicles(owner_id);

-- ── BOOKINGS ─────────────────────────────────────────────────────────
create table if not exists bookings (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references profiles(id) on delete cascade,
  mechanic_id uuid references profiles(id) on delete set null,
  vehicle_id uuid not null references vehicles(id) on delete cascade,
  service_type text not null,
  description text default '',
  photo_urls text[] default array[]::text[],
  scheduled_at timestamptz not null,
  address text not null,
  lat double precision,
  lng double precision,
  status text default 'pending' check (status in ('pending','accepted','enroute','inprogress','completed','cancelled','declined')),
  payment_method text,
  payment_status text default 'unpaid' check (payment_status in ('unpaid','held_in_escrow','paid','refunded')),
  labor_cost numeric default 0,
  parts_cost numeric default 0,
  service_fee numeric default 0,
  total numeric default 0,
  rating numeric default 0,
  review text,
  mechanic_reply text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index if not exists bookings_customer_idx on bookings(customer_id);
create index if not exists bookings_mechanic_idx on bookings(mechanic_id);
create index if not exists bookings_status_idx on bookings(status);

-- ── CHATS ────────────────────────────────────────────────────────────
create table if not exists chats (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id) on delete cascade,
  sender_id uuid not null references profiles(id) on delete cascade,
  text text not null,
  ts timestamptz default now()
);
create index if not exists chats_booking_idx on chats(booking_id, ts);

-- ── WALLET TRANSACTIONS ──────────────────────────────────────────────
create table if not exists wallet_txns (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  amount numeric not null,
  description text not null,
  ts timestamptz default now()
);
create index if not exists txns_user_idx on wallet_txns(user_id, ts desc);

-- ── SERVICE RECORDS ──────────────────────────────────────────────────
create table if not exists service_records (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references vehicles(id) on delete cascade,
  title text not null,
  details text default '',
  cost numeric default 0,
  mileage_at int,
  date timestamptz default now()
);

-- ── DIAGNOSES ────────────────────────────────────────────────────────
create table if not exists diagnoses (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references vehicles(id) on delete cascade,
  symptom text not null,
  probable_cause text,
  severity text,
  estimated_repair text,
  estimated_cost_min numeric,
  estimated_cost_max numeric,
  date timestamptz default now()
);

-- ── INVENTORY ────────────────────────────────────────────────────────
create table if not exists inventory (
  id uuid primary key default gen_random_uuid(),
  mechanic_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  quantity int default 0,
  price numeric default 0
);

-- ── NOTIFICATIONS ────────────────────────────────────────────────────
create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  body text default '',
  booking_id uuid references bookings(id) on delete cascade,
  read boolean default false,
  ts timestamptz default now()
);
create index if not exists notif_user_idx on notifications(user_id, ts desc);

-- ── DISABLE RLS ──────────────────────────────────────────────────────
alter table profiles            disable row level security;
alter table vehicles            disable row level security;
alter table bookings            disable row level security;
alter table chats               disable row level security;
alter table wallet_txns         disable row level security;
alter table service_records     disable row level security;
alter table diagnoses           disable row level security;
alter table inventory           disable row level security;
alter table notifications       disable row level security;

-- ── GRANTS to anon/publishable role ──────────────────────────────────
grant usage on schema public to anon, authenticated;
grant all on profiles, vehicles, bookings, chats, wallet_txns,
            service_records, diagnoses, inventory, notifications
       to anon, authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;

-- ── REALTIME ─────────────────────────────────────────────────────────
do $$
declare
  tbl text;
begin
  foreach tbl in array array['bookings','chats','notifications','profiles','vehicles']
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and tablename = tbl
    ) then
      execute format('alter publication supabase_realtime add table %I', tbl);
    end if;
  end loop;
end $$;

-- ── DRIFT REPAIR (heals partial schemas) ─────────────────────────────
alter table vehicles  add column if not exists photo_url text;
alter table vehicles  add column if not exists vin text;
alter table vehicles  add column if not exists color text;
alter table vehicles  add column if not exists mileage int;
alter table profiles  add column if not exists trade_license_url text;
alter table profiles  add column if not exists national_id_url text;
alter table profiles  add column if not exists workshop_photo_urls text[] default array[]::text[];
alter table profiles  add column if not exists specialties text[] default array[]::text[];
alter table profiles  add column if not exists engine_types text[] default array[]::text[];
alter table profiles  add column if not exists lat double precision;
alter table profiles  add column if not exists lng double precision;
alter table profiles  add column if not exists is_online boolean default true;
alter table profiles  add column if not exists wallet_balance numeric default 0;
alter table bookings  add column if not exists photo_urls text[] default array[]::text[];
alter table bookings  add column if not exists mechanic_reply text;
alter table bookings  add column if not exists review text;
alter table bookings  add column if not exists rating numeric default 0;
alter table bookings  add column if not exists payment_method text;
alter table bookings  add column if not exists payment_status text default 'unpaid';

-- ── Reload PostgREST cache so new columns are visible immediately ────
notify pgrst, 'reload schema';

-- ── DEMO SEED (one-tap demo accounts) ────────────────────────────────
insert into profiles (id, full_name, phone, role, address, language, wallet_balance, lat, lng, is_online, kyc_verified)
values
  ('11111111-1111-1111-1111-111111111111','Demo Customer (Abebe)','+251911000001','customer','Bole, Addis Ababa','en',5000,9.0108,38.7613,true,true),
  ('22222222-2222-2222-2222-222222222222','Demo Mechanic (Solomon)','+251911000002','mechanic','Megenagna, Addis Ababa','en',12450,9.0192,38.8000,true,true),
  ('33333333-3333-3333-3333-333333333333','Demo Mechanic (Hanna)','+251911000003','mechanic','Sarbet, Addis Ababa','en',8200,9.0023,38.7506,true,true),
  ('44444444-4444-4444-4444-444444444444','Demo Mechanic (Mulugeta)','+251911000004','mechanic','Piassa, Addis Ababa','en',0,9.0353,38.7531,true,false),
  ('55555555-5555-5555-5555-555555555555','Demo Admin','+251911000000','admin','HQ, Addis Ababa','en',0,9.01,38.76,true,false)
on conflict (id) do nothing;

update profiles set specialties = array['Engine','Transmission','Electrical'] where id = '22222222-2222-2222-2222-222222222222';
update profiles set specialties = array['EV','Hybrid','Diagnostics'] where id = '33333333-3333-3333-3333-333333333333';
update profiles set specialties = array['Bodywork','Detailing'] where id = '44444444-4444-4444-4444-444444444444';
