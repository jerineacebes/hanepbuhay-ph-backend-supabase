-- Organization types
create type organization_type as enum ('employer', 'agency', 'peso', 'admin');

-- Organizations table
create table public.organizations (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  slug text unique not null,
  type organization_type not null default 'employer',
  description text,
  website_url text,
  logo_url text,
  is_verified boolean default false,
  verified_at timestamp with time zone,
  metadata jsonb default '{}'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Organization Members table
create table public.organization_members (
  organization_id uuid references public.organizations(id) on delete cascade,
  profile_id uuid references public.profiles(id) on delete cascade,
  role text default 'member', -- member, admin, owner
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (organization_id, profile_id)
);

-- Verification Badges
create table public.verification_badges (
  id uuid default gen_random_uuid() primary key,
  name text not null unique, -- e.g., 'SEC Registered', 'PEZA Accredited', 'Verified Employer'
  description text,
  icon_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Organization Verifications (Linking badges to orgs)
create table public.organization_verifications (
  organization_id uuid references public.organizations(id) on delete cascade,
  badge_id uuid references public.verification_badges(id) on delete cascade,
  verified_by uuid references public.profiles(id),
  verified_at timestamp with time zone default timezone('utc'::text, now()) not null,
  metadata jsonb default '{}'::jsonb,
  primary key (organization_id, badge_id)
);

-- RLS
alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.verification_badges enable row level security;
alter table public.organization_verifications enable row level security;

-- Policies: Organizations
create policy "Organizations are viewable by everyone."
  on public.organizations for select
  using ( true );

create policy "Admins can manage all organizations."
  on public.organizations for all
  using ( exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  ) );

create policy "Owners/Admins of an organization can update it."
  on public.organizations for update
  using ( exists (
    select 1 from public.organization_members
    where organization_id = public.organizations.id
    and profile_id = auth.uid()
    and role in ('owner', 'admin')
  ) );

-- Policies: Organization Members
create policy "Organization members can view other members of the same organization."
  on public.organization_members for select
  using ( exists (
    select 1 from public.organization_members om
    where om.organization_id = public.organization_members.organization_id
    and om.profile_id = auth.uid()
  ) );

-- Triggers for updated_at
create trigger update_organizations_updated_at
  before update on public.organizations
  for each row execute procedure public.handle_updated_at();
