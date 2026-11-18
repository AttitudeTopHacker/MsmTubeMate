-- ====================================================================
-- Msm TubeMate Supabase Database Schema
-- Organization: ORG: msm.movin 2022
-- Includes: User Profiles, Cloud Download History, Custom Bookmarks (RLS Enabled)
-- ====================================================================

-- 1. User Profiles
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  full_name text,
  avatar_url text,
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- 2. Cloud Download History
create table if not exists public.download_history (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  title text not null,
  platform text not null, -- 'YouTube', 'Instagram', 'Facebook', 'X', 'WhatsApp'
  media_type text not null, -- 'audio' or 'video'
  format_label text not null, -- e.g., '1080p Full HD', '320K MP3'
  file_size text,
  thumbnail_url text,
  source_url text not null,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 3. Custom Saved Sites / Bookmarks
create table if not exists public.saved_sites (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  site_name text not null,
  site_url text not null,
  icon_name text,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- Enable Row Level Security (RLS)
alter table public.profiles enable row level security;
alter table public.download_history enable row level security;
alter table public.saved_sites enable row level security;

-- RLS Policies
create policy "Users manage own profile" on public.profiles 
  for all using (auth.uid() = id);

create policy "Users manage own history" on public.download_history 
  for all using (auth.uid() = user_id);

create policy "Users manage own sites" on public.saved_sites 
  for all using (auth.uid() = user_id);

-- Profile auto-creation trigger on new auth sign up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, avatar_url)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
