-- Audit Fixes: Security & Performance Hardening

-- 1. Security: Set search_path for all functions to prevent search_path hijacking
alter function public.handle_updated_at() set search_path = public;
alter function public.handle_new_user() set search_path = public, auth;
alter function public.calculate_commute_score(float) set search_path = public, extensions;
alter function public.rank_candidates_for_job(uuid) set search_path = public, extensions;
alter function public.issue_verification_badge(uuid, text, jsonb) set search_path = public;
alter function public.get_employer_dashboard_summary(uuid) set search_path = public;
alter function public.route_candidate(uuid) set search_path = public;

-- 2. Performance: Missing Indexes for Foreign Keys and RLS predicates

-- Profiles
create index if not exists idx_profiles_role on public.profiles(role);

-- Organizations
create index if not exists idx_organizations_type on public.organizations(type);

-- Organization Members
create index if not exists idx_organization_members_profile_id on public.organization_members(profile_id);
create index if not exists idx_organization_members_organization_id on public.organization_members(organization_id);

-- Organization Verifications
create index if not exists idx_organization_verifications_badge_id on public.organization_verifications(badge_id);

-- Job Seekers
create index if not exists idx_job_seekers_location_coords on public.job_seekers using gist(location_coords);
create index if not exists idx_job_seekers_skills on public.job_seekers using gin(skills);
create index if not exists idx_job_seekers_preferred_roles on public.job_seekers using gin(preferred_roles);
-- HNSW index for pgvector (using cosine distance as default for matching)
create index if not exists idx_job_seekers_embedding on public.job_seekers using hnsw (embedding vector_cosine_ops);

-- Job Seeker Credentials
create index if not exists idx_job_seeker_credentials_job_seeker_id on public.job_seeker_credentials(job_seeker_id);

-- Chat Sessions
create index if not exists idx_chat_sessions_job_seeker_id on public.chat_sessions(job_seeker_id);

-- Chat Messages
create index if not exists idx_chat_messages_session_id on public.chat_messages(session_id);

-- Profile Extractions
create index if not exists idx_profile_extractions_job_seeker_id on public.profile_extractions(job_seeker_id);
create index if not exists idx_profile_extractions_session_id on public.profile_extractions(session_id);

-- Jobs
create index if not exists idx_jobs_organization_id on public.jobs(organization_id);
create index if not exists idx_jobs_location_coords on public.jobs using gist(location_coords);
create index if not exists idx_jobs_is_active on public.jobs(is_active);

-- Job Requirements
create index if not exists idx_job_requirements_job_id on public.job_requirements(job_id);

-- Applications
create index if not exists idx_applications_job_id on public.applications(job_id);
create index if not exists idx_applications_job_seeker_id on public.applications(job_seeker_id);
create index if not exists idx_applications_status on public.applications(status);

-- Candidate Matches
create index if not exists idx_candidate_matches_job_id on public.candidate_matches(job_id);
create index if not exists idx_candidate_matches_job_seeker_id on public.candidate_matches(job_seeker_id);

-- Routing Decisions
create index if not exists idx_routing_decisions_job_seeker_id on public.routing_decisions(job_seeker_id);
create index if not exists idx_routing_decisions_assigned_org on public.routing_decisions(assigned_organization_id);

-- Audit Logs
create index if not exists idx_audit_logs_profile_id on public.audit_logs(profile_id);
create index if not exists idx_audit_logs_target on public.audit_logs(target_table, target_id);

-- Notifications
create index if not exists idx_notifications_profile_id on public.notifications(profile_id);
create index if not exists idx_notifications_is_read on public.notifications(is_read);

-- 3. RLS Hardening: Re-apply RLS to all tables to ensure it's enabled and correct
-- Note: Some tables were found with RLS disabled in the DB check.
alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.verification_badges enable row level security;
alter table public.organization_verifications enable row level security;
alter table public.job_seekers enable row level security;
alter table public.job_seeker_credentials enable row level security;
alter table public.chat_sessions enable row level security;
alter table public.chat_messages enable row level security;
alter table public.profile_extractions enable row level security;
alter table public.jobs enable row level security;
alter table public.job_requirements enable row level security;
alter table public.applications enable row level security;
alter table public.candidate_matches enable row level security;
alter table public.routing_decisions enable row level security;
alter table public.audit_logs enable row level security;
alter table public.notifications enable row level security;

-- 4. Fix missing policies for profiles found by advisor
-- The advisor noted public.profiles has RLS enabled but no policies. 
-- Migration 0 included them, but they might have failed or been dropped.
do $$ 
begin
  if not exists (select 1 from pg_policies where tablename = 'profiles' and policyname = 'Public profiles are viewable by everyone.') then
    create policy "Public profiles are viewable by everyone." on public.profiles for select using ( true );
  end if;
  if not exists (select 1 from pg_policies where tablename = 'profiles' and policyname = 'Users can update their own profiles.') then
    create policy "Users can update their own profiles." on public.profiles for update using ( auth.uid() = id );
  end if;
end $$;
