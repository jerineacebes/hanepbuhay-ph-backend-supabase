-- Calculate commute score based on distance bands
create or replace function public.calculate_commute_score(distance_meters float)
returns jsonb
language plpgsql
as $$
declare
  distance_km float;
  score float;
  band text;
begin
  distance_km := distance_meters / 1000.0;
  
  if distance_km < 2 then
    score := 1.0;
    band := 'excellent';
  elsif distance_km < 5 then
    score := 0.8;
    band := 'good';
  elsif distance_km < 10 then
    score := 0.6;
    band := 'acceptable';
  elsif distance_km < 20 then
    score := 0.4;
    band := 'risky';
  else
    score := 0.2;
    band := 'poor';
  end if;
  
  return jsonb_build_object(
    'score', score,
    'band', band,
    'distance_km', round(distance_km::numeric, 2)
  );
end;
$$;

-- Rank candidates for a specific job
create or replace function public.rank_candidates_for_job(p_job_id uuid)
returns table (
  job_seeker_id uuid,
  full_name text,
  total_score numeric,
  score_breakdown jsonb
)
language plpgsql
as $$
declare
  v_job_location extensions.geography(point, 4326);
  v_job_skills text[];
  v_job_exp_min int;
begin
  -- Get job details
  select location_coords, 
         (select array_agg(value) from public.job_requirements where job_id = p_job_id and requirement_type = 'skill')
  into v_job_location, v_job_skills
  from public.jobs
  where id = p_job_id;

  return query
  with candidate_stats as (
    select 
      js.id,
      p.full_name,
      extensions.st_distance(js.location_coords, v_job_location) as dist_meters,
      (
        select count(*)::float / coalesce(array_length(v_job_skills, 1), 1)
        from unnest(js.skills) s
        where s = any(v_job_skills)
      ) as skill_fit,
      least(js.experience_years::float / 5.0, 1.0) as exp_fit
    from public.job_seekers js
    join public.profiles p on p.id = js.id
    where js.availability_status = 'available'
  ),
  scored_candidates as (
    select 
      cs.id,
      cs.full_name,
      public.calculate_commute_score(cs.dist_meters) as commute_info,
      cs.skill_fit,
      cs.exp_fit,
      0.7 as semantic_placeholder -- Placeholder for pgvector similarity
    from candidate_stats cs
  )
  select 
    sc.id,
    sc.full_name,
    round((
      (sc.commute_info->>'score')::numeric * 0.3 +
      sc.skill_fit::numeric * 0.4 +
      sc.exp_fit::numeric * 0.2 +
      sc.semantic_placeholder::numeric * 0.1
    ), 2) as total_score,
    jsonb_build_object(
      'commute', sc.commute_info,
      'skills', sc.skill_fit,
      'experience', sc.exp_fit,
      'semantic', sc.semantic_placeholder
    ) as score_breakdown
  from scored_candidates sc
  order by total_score desc;
end;
$$;

-- Issue verification badge
create or replace function public.issue_verification_badge(
  p_organization_id uuid,
  p_badge_name text,
  p_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
as $$
declare
  v_badge_id uuid;
begin
  -- Only admins can issue badges (checked via RLS or this security definer function)
  if not exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  ) then
    raise exception 'Unauthorized';
  end if;

  select id into v_badge_id from public.verification_badges where name = p_badge_name;
  
  if v_badge_id is null then
    raise exception 'Badge not found';
  end if;

  insert into public.organization_verifications (organization_id, badge_id, verified_by, metadata)
  values (p_organization_id, v_badge_id, auth.uid(), p_metadata)
  on conflict (organization_id, badge_id) do update
  set verified_at = now(), metadata = p_metadata;
  
  update public.organizations set is_verified = true, verified_at = now() where id = p_organization_id;
end;
$$;

-- Employer Dashboard Summary RPC
create or replace function public.get_employer_dashboard_summary(p_org_id uuid)
returns jsonb
language plpgsql
as $$
declare
  v_active_jobs int;
  v_total_apps int;
  v_hired_count int;
begin
  select count(*) into v_active_jobs from public.jobs where organization_id = p_org_id and is_active = true;
  select count(*) into v_total_apps from public.applications a join public.jobs j on j.id = a.job_id where j.organization_id = p_org_id;
  select count(*) into v_hired_count from public.applications a join public.jobs j on j.id = a.job_id where j.organization_id = p_org_id and a.status = 'hired';

  return jsonb_build_object(
    'active_jobs', v_active_jobs,
    'total_applications', v_total_apps,
    'hired_count', v_hired_count
  );
end;
$$;
