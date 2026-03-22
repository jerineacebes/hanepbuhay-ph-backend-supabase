-- Jobs table
create table public.jobs (
  id uuid default gen_random_uuid() primary key,
  organization_id uuid references public.organizations(id) on delete cascade not null,
  title text not null,
  description text,
  work_setup text default 'onsite', -- onsite, remote, hybrid
  employment_type text default 'full-time', -- full-time, part-time, contract, project
  wage_range_min numeric,
  wage_range_max numeric,
  location_text text,
  location_coords extensions.geography(point, 4326),
  is_active boolean default true,
  metadata jsonb default '{}'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Job Requirements (structured requirements)
create table public.job_requirements (
  id uuid default gen_random_uuid() primary key,
  job_id uuid references public.jobs(id) on delete cascade,
  requirement_type text not null, -- skill, credential, experience, availability
  value text not null,
  is_mandatory boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Applications
create table public.applications (
  id uuid default gen_random_uuid() primary key,
  job_id uuid references public.jobs(id) on delete cascade,
  job_seeker_id uuid references public.job_seekers(id) on delete cascade,
  status text default 'applied', -- applied, screening, interview, offered, hired, rejected
  metadata jsonb default '{}'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Candidate Matches (cached match scores)
create table public.candidate_matches (
  id uuid default gen_random_uuid() primary key,
  job_id uuid references public.jobs(id) on delete cascade,
  job_seeker_id uuid references public.job_seekers(id) on delete cascade,
  total_score numeric not null,
  score_breakdown jsonb not null, -- {commute: 0.8, skills: 0.9, ...}
  is_shortlisted boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique (job_id, job_seeker_id)
);

-- Routing Decisions
create table public.routing_decisions (
  id uuid default gen_random_uuid() primary key,
  job_seeker_id uuid references public.job_seekers(id) on delete cascade,
  decision text not null, -- direct_hire, agency_routing, needs_followup, not_eligible
  reason_codes text[],
  explanation text,
  assigned_organization_id uuid references public.organizations(id),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Audit Logs
create table public.audit_logs (
  id uuid default gen_random_uuid() primary key,
  profile_id uuid references public.profiles(id),
  action text not null,
  target_table text,
  target_id uuid,
  old_data jsonb,
  new_data jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Notifications
create table public.notifications (
  id uuid default gen_random_uuid() primary key,
  profile_id uuid references public.profiles(id) on delete cascade,
  title text not null,
  content text,
  type text,
  is_read boolean default false,
  link text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS
alter table public.jobs enable row level security;
alter table public.job_requirements enable row level security;
alter table public.applications enable row level security;
alter table public.candidate_matches enable row level security;
alter table public.routing_decisions enable row level security;
alter table public.audit_logs enable row level security;
alter table public.notifications enable row level security;

-- Policies: Jobs
create policy "Jobs are viewable by everyone."
  on public.jobs for select
  using ( is_active = true );

create policy "Employers can manage their own jobs."
  on public.jobs for all
  using ( exists (
    select 1 from public.organization_members
    where organization_id = public.jobs.organization_id
    and profile_id = auth.uid()
  ) );

-- Policies: Applications
create policy "Job seekers can view their own applications."
  on public.applications for select
  using ( job_seeker_id = auth.uid() );

create policy "Employers can view applications for their jobs."
  on public.applications for select
  using ( exists (
    select 1 from public.jobs j
    join public.organization_members om on om.organization_id = j.organization_id
    where j.id = public.applications.job_id
    and om.profile_id = auth.uid()
  ) );

-- Triggers
create trigger update_jobs_updated_at
  before update on public.jobs
  for each row execute procedure public.handle_updated_at();

create trigger update_applications_updated_at
  before update on public.applications
  for each row execute procedure public.handle_updated_at();
