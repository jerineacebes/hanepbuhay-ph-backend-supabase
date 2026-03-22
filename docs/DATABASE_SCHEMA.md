# Database Schema Reference

## Enums
- `user_role`: job_seeker, employer_staff, agency_staff, peso_staff, admin
- `organization_type`: employer, agency, peso, admin

## Tables

### Profiles
- `id` (uuid, PK): references auth.users
- `role` (user_role): role of the user
- `full_name` (text): full name
- `metadata` (jsonb): extensible metadata

### Organizations
- `id` (uuid, PK): organization unique identifier
- `name` (text): name
- `type` (organization_type): org category
- `is_verified` (boolean): verification status

### Job Seekers
- `id` (uuid, PK): references profiles.id
- `summary` (text): AI-extracted summary
- `skills` (text[]): list of skills
- `experience_years` (int): years of experience
- `location_coords` (geography): PostGIS point
- `embedding` (vector): pgvector embedding (1536d)

### Jobs
- `id` (uuid, PK): job unique identifier
- `organization_id` (uuid, FK): organization owning the job
- `location_coords` (geography): PostGIS point

### Chat Domain
- `chat_sessions`: session metadata
- `chat_messages`: conversational logs

### Matching & Routing
- `candidate_matches`: cached weighted scores
- `routing_decisions`: explainable routing logic (Direct Hire/Agency)

### Other
- `audit_logs`: action logs
- `notifications`: user notifications
- `verification_badges`: available trust badges
