-- Smart Router Function
create or replace function public.route_candidate(p_job_seeker_id uuid)
returns jsonb
language plpgsql
as $$
declare
  v_exp_years int;
  v_credential_count int;
  v_verified_count int;
  v_decision text;
  v_reasons text[];
  v_explanation text;
  v_agency_id uuid;
begin
  -- Get candidate data
  select experience_years into v_exp_years from public.job_seekers where id = p_job_seeker_id;
  select count(*) into v_credential_count from public.job_seeker_credentials where job_seeker_id = p_job_seeker_id;
  select count(*) into v_verified_count from public.job_seeker_credentials where job_seeker_id = p_job_seeker_id and verification_status = 'verified';

  if v_credential_count = 0 then
    v_decision := 'needs_followup';
    v_reasons := array['no_credentials'];
    v_explanation := 'Candidate has no uploaded credentials (NBI, Health Card, etc.).';
  elsif v_exp_years >= 2 and v_verified_count = v_credential_count then
    v_decision := 'direct_hire';
    v_reasons := array['experienced', 'verified'];
    v_explanation := 'Candidate has 2+ years experience and all credentials are verified.';
  else
    v_decision := 'agency_routing';
    v_reasons := array['needs_upskilling_or_verification'];
    v_explanation := 'Candidate needs additional verification or upskilling via an agency partner.';
    
    -- Assign to a random agency for Phase 1
    select id into v_agency_id from public.organizations where type = 'agency' limit 1;
  end if;

  -- Store decision
  insert into public.routing_decisions (job_seeker_id, decision, reason_codes, explanation, assigned_organization_id)
  values (p_job_seeker_id, v_decision, v_reasons, v_explanation, v_agency_id);

  return jsonb_build_object(
    'decision', v_decision,
    'reasons', v_reasons,
    'explanation', v_explanation,
    'assigned_organization_id', v_agency_id
  );
end;
$$;

-- Storage Buckets Setup (SQL API)
insert into storage.buckets (id, name, public) 
values ('worker-documents', 'worker-documents', false),
       ('verification-files', 'verification-files', false)
on conflict (id) do nothing;

-- Storage Policies
create policy "Workers can upload their own documents."
  on storage.objects for insert
  with check (
    bucket_id = 'worker-documents' AND
    (auth.uid())::text = (storage.foldername(name))[1]
  );

create policy "Workers can view their own documents."
  on storage.objects for select
  using (
    bucket_id = 'worker-documents' AND
    (auth.uid())::text = (storage.foldername(name))[1]
  );

create policy "Admins and Agencies can view worker documents."
  on storage.objects for select
  using (
    bucket_id = 'worker-documents' AND
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'agency_staff', 'peso_staff')
    )
  );
