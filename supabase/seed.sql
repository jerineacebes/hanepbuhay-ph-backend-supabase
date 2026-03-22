-- Seed Data for Phase 1

-- 1. Organizations
insert into public.organizations (name, slug, type, description, is_verified)
values 
  ('HanepBuhay Admin', 'admin', 'admin', 'System administration', true),
  ('Buhay Construction', 'buhay-const', 'employer', 'Hyperlocal construction company', true),
  ('Tulong Agency', 'tulong-agency', 'agency', 'Verified agency partner for upskilling', true),
  ('PESO Quezon City', 'peso-qc', 'peso', 'Public Employment Service Office', true)
on conflict do nothing;

-- 2. Verification Badges
insert into public.verification_badges (name, description)
values 
  ('SEC Registered', 'Verified SEC Registration'),
  ('PEZA Accredited', 'Verified PEZA Accreditation'),
  ('Verified Employer', 'Manually verified by HanepBuhay team')
on conflict do nothing;

-- 3. Mock Jobs
insert into public.jobs (organization_id, title, description, work_setup, employment_type, wage_range_min, wage_range_max, location_text, location_coords)
values 
  ((select id from public.organizations where slug = 'buhay-const'), 'Construction Worker', 'Needs 3 workers for a 6-month project.', 'onsite', 'contract', 15000, 18000, 'Quezon City', extensions.st_point(121.0483, 14.6507)::extensions.geography),
  ((select id from public.organizations where slug = 'buhay-const'), 'Carpenter', 'Expert carpenter needed for finishing work.', 'onsite', 'full-time', 20000, 25000, 'Pasig City', extensions.st_point(121.0583, 14.5733)::extensions.geography)
on conflict do nothing;

-- 4. Job Requirements
insert into public.job_requirements (job_id, requirement_type, value, is_mandatory)
values 
  ((select id from public.jobs where title = 'Construction Worker'), 'skill', 'construction', true),
  ((select id from public.jobs where title = 'Construction Worker'), 'skill', 'heavy lifting', true),
  ((select id from public.jobs where title = 'Construction Worker'), 'experience', '1', true),
  ((select id from public.jobs where title = 'Carpenter'), 'skill', 'carpentry', true),
  ((select id from public.jobs where title = 'Carpenter'), 'skill', 'furniture making', false)
on conflict do nothing;
