-- Yichalal Engineering — Supabase schema
-- Paste this into Supabase SQL Editor and click Run.

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

create table if not exists chats (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id) on delete cascade,
  sender_id uuid not null references profiles(id) on delete cascade,
  text text not null,
  ts timestamptz default now()
);
create index if not exists chats_booking_idx on chats(booking_id, ts);

create table if not exists wallet_txns (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  amount numeric not null,
  description text not null,
  ts timestamptz default now()
);
create index if not exists txns_user_idx on wallet_txns(user_id, ts desc);

create table if not exists service_records (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references vehicles(id) on delete cascade,
  title text not null,
  details text default '',
  cost numeric default 0,
  mileage_at int,
  date timestamptz default now()
);

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

create table if not exists inventory (
  id uuid primary key default gen_random_uuid(),
  mechanic_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  quantity int default 0,
  price numeric default 0
);

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

-- Open access for the publishable key (no RLS — this is anon-key-auth design)
alter table profiles disable row level security;
alter table vehicles disable row level security;
alter table bookings disable row level security;
alter table chats disable row level security;
alter table wallet_txns disable row level security;
alter table service_records disable row level security;
alter table diagnoses disable row level security;
alter table inventory disable row level security;
alter table notifications disable row level security;

-- Enable Realtime on the tables the apps watch
alter publication supabase_realtime add table bookings;
alter publication supabase_realtime add table chats;
alter publication supabase_realtime add table notifications;
alter publication supabase_realtime add table profiles;
