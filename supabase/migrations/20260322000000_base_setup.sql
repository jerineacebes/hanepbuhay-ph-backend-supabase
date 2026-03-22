-- Enable Extensions
create extension if not exists "vector" with schema extensions;
create extension if not exists "postgis" with schema extensions;
create extension if not exists "pgcrypto" with schema extensions;
create extension if not exists "moddatetime" with schema extensions;

-- Updated at trigger function
create or replace function handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- User Roles
create type user_role as enum ('job_seeker', 'employer_staff', 'agency_staff', 'peso_staff', 'admin');

-- Profiles table (linked to auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  role user_role not null default 'job_seeker',
  full_name text,
  email text unique,
  phone_number text unique,
  avatar_url text,
  metadata jsonb default '{}'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for Profiles
alter table public.profiles enable row level security;

create policy "Public profiles are viewable by everyone."
  on public.profiles for select
  using ( true );

create policy "Users can update their own profiles."
  on public.profiles for update
  using ( auth.uid() = id );

-- Handle new user creation (trigger)
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, email, role)
  values (
    new.id, 
    new.raw_user_meta_data->>'full_name', 
    new.email,
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'job_seeker'::user_role)
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
