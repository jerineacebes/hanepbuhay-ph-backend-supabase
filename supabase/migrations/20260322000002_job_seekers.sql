-- Job Seekers table
create table public.job_seekers (
  id uuid references public.profiles(id) on delete cascade primary key,
  summary text,
  skills text[],
  experience_years int default 0,
  preferred_roles text[],
  availability_status text default 'available', -- available, employed, busy
  wage_expectation_min numeric,
  wage_expectation_max numeric,
  location_text text,
  location_coords extensions.geography(point, 4326),
  embedding extensions.vector(1536), -- for semantic search (e.g. text-embedding-3-small)
  metadata jsonb default '{}'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Credentials (NBI, Health Card, etc.)
create table public.job_seeker_credentials (
  id uuid default gen_random_uuid() primary key,
  job_seeker_id uuid references public.job_seekers(id) on delete cascade,
  name text not null,
  issue_date date,
  expiry_date date,
  verification_status text default 'pending', -- pending, verified, rejected
  file_url text,
  metadata jsonb default '{}'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Chat Sessions for onboarding
create table public.chat_sessions (
  id uuid default gen_random_uuid() primary key,
  job_seeker_id uuid references public.job_seekers(id) on delete cascade,
  status text default 'active', -- active, completed, abandoned
  metadata jsonb default '{}'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Chat Messages
create table public.chat_messages (
  id uuid default gen_random_uuid() primary key,
  session_id uuid references public.chat_sessions(id) on delete cascade,
  sender_type text not null, -- bot, user
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Profile Extractions (history of AI extractions)
create table public.profile_extractions (
  id uuid default gen_random_uuid() primary key,
  job_seeker_id uuid references public.job_seekers(id) on delete cascade,
  session_id uuid references public.chat_sessions(id),
  raw_payload jsonb not null,
  extracted_data jsonb not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS
alter table public.job_seekers enable row level security;
alter table public.job_seeker_credentials enable row level security;
alter table public.chat_sessions enable row level security;
alter table public.chat_messages enable row level security;
alter table public.profile_extractions enable row level security;

-- Policies: Job Seekers
create policy "Job seekers can view and update their own profile."
  on public.job_seekers for all
  using ( auth.uid() = id );

create policy "Employers and Agencies can view job seeker profiles."
  on public.job_seekers for select
  using ( exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('employer_staff', 'agency_staff', 'peso_staff', 'admin')
  ) );

-- Policies: Chat Sessions
create policy "Job seekers can manage their own chat sessions."
  on public.chat_sessions for all
  using ( auth.uid() = job_seeker_id );

-- Policies: Chat Messages
create policy "Job seekers can view messages in their own sessions."
  on public.chat_messages for all
  using ( exists (
    select 1 from public.chat_sessions
    where id = public.chat_messages.session_id
    and job_seeker_id = auth.uid()
  ) );

-- Triggers
create trigger update_job_seekers_updated_at
  before update on public.job_seekers
  for each row execute procedure public.handle_updated_at();

create trigger update_chat_sessions_updated_at
  before update on public.chat_sessions
  for each row execute procedure public.handle_updated_at();
