# Edge Functions & RPC Reference

## Edge Functions
- `create-chat-session`: starts a new onboarding conversation
- `add-chat-message`: adds a message and returns a mock bot response
- `extract-worker-profile`: (Mock AI) extracts profile from chat transcript
- `rank-candidates-for-job`: executes ranking logic and caches results

## SQL RPCs (Postgres Functions)
- `calculate_commute_score(distance_meters)`: returns score & band (Excellent, Good, etc.)
- `rank_candidates_for_job(job_id)`: returns ranked list of job seekers
- `route_candidate(job_seeker_id)`: returns routing decision (Direct, Agency, etc.)
- `get_employer_dashboard_summary(org_id)`: summary stats for employers
- `issue_verification_badge(org_id, badge_name)`: admin tool to verify orgs
