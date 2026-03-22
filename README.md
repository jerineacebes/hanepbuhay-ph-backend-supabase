# HanepBuhay PH Backend (Supabase)

## Project Overview
HanepBuhay PH is a hyperlocal, AI-powered job matching platform designed for Philippine blue-collar workers. 
This repository contains the backend and database layer of the application, completely driven by Supabase.

It includes:
- A PostgreSQL database schema with PostGIS (geo-queries) and pgvector (semantic search) support.
- Pre-configured Data Definition Language (DDL) migrations and policies (RLS).
- Seed data for local testing.
- Supabase Edge Functions for business logic (like chat orchestration and mock AI profile extraction).

## Features / Current Scope
- **Job Seeker Domain:** Automated chat onboarding models and profile extraction.
- **Employer Domain:** Organization management, verification badges, and job posting models.
- **Smart Matching Engine:** Database-level functions to calculate commute scores and rank candidates based on skills, experience, and availability.
- **Smart Routing:** Automated decision logic to route candidates directly or through verified agencies.

*Note: This repo focuses entirely on the database logic, schema, and edge functions. There is no frontend application in this repository.*

## Tech Stack
- **Database:** Supabase Postgres (PostgreSQL 17)
- **Extensions:** `postgis`, `pgvector`, `pgcrypto`
- **Logic:** Supabase Edge Functions (Deno / TypeScript), Postgres RPCs
- **Tooling:** Supabase CLI, Node.js (for CLI wrapper)

## Prerequisites
To run this backend locally, you will need:
- **Docker Desktop** (Required by Supabase CLI to run local services)
- **Node.js** & **npm** (To run the Supabase CLI wrapper)
- **Git**
- **Deno** (Optional, but recommended for Edge Function IDE support and linting)

## Repository Structure
- `supabase/config.toml` - Supabase local development configuration.
- `supabase/migrations/` - SQL migrations defining tables, functions, and RLS policies.
- `supabase/seed.sql` - Mock data loaded automatically upon database reset.
- `supabase/functions/` - Deno-based Edge Functions for serverless execution.
- `docs/` - Architecture and database schema reference documentation.

## Environment Variables
The core database and edge functions rely on environment variables auto-injected by the Supabase CLI. 

However, `supabase/config.toml` can consume an `OPENAI_API_KEY` for Supabase Studio AI features. See `.env.example` for details.

```bash
cp .env.example .env
```

## Local Setup

Follow these steps to get the Supabase environment running locally:

1. **Clone the repository:**
   ```bash
   git clone <repo-url>
   cd hanepbuhay-ph-backend-supabase
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Start local Supabase:**
   Make sure Docker is running, then execute:
   ```bash
   npm run supabase:start
   ```
   *This command pulls the necessary Docker images, starts the database, applies migrations, and runs `supabase/seed.sql`.*

4. **Serve Edge Functions locally:**
   In a new terminal window, serve the Deno functions:
   ```bash
   npm run supabase:functions
   ```

## Database Workflow

This project uses an offline-first workflow. All schema changes must be captured in migrations.

- **Access Local Studio:** After starting Supabase, open [http://127.0.0.1:56323](http://127.0.0.1:56323) to view the database UI.
- **Reset the Database:** 
  If you need to wipe your local database and re-apply all migrations and seeds from scratch:
  ```bash
  npm run supabase:reset
  ```
- **Create a New Migration:**
  ```bash
  npx supabase migration new my_new_feature
  ```

## Edge Functions Workflow
Edge functions are located in `supabase/functions/`. They run on Deno.

- **Serve functions locally:** `npm run supabase:functions`
- **Testing:** You can invoke them locally using `curl` or Postman. For example:
  ```bash
  curl -i --location --request POST 'http://127.0.0.1:56321/functions/v1/extract-worker-profile' \
    --header 'Authorization: Bearer <your-anon-key>' \
    --header 'Content-Type: application/json' \
    --data '{"session_id": "some-uuid"}'
  ```
  *(Note: You can find your anon key by running `npm run supabase:status`)*

## Verification / Smoke Test

To verify the setup was successful:
1. Run `npm run supabase:status` to ensure all services are running.
2. Open the **Local Studio** at `http://localhost:56323` and navigate to the **Table Editor**. You should see tables like `organizations`, `jobs`, and `job_seekers` populated with seed data.
3. Check the Edge Functions output in the terminal where you ran `npm run supabase:functions`. It should say `Functions are ready`.

## Common Development Commands

| Command | Description |
|---------|-------------|
| `npm run supabase:start` | Starts local Supabase stack |
| `npm run supabase:stop` | Stops local Supabase stack |
| `npm run supabase:status` | Shows local endpoints and keys |
| `npm run supabase:reset` | Recreates database, runs migrations and seeds |
| `npm run supabase:functions` | Serves all Edge Functions locally |

## Troubleshooting
- **Docker not running:** `supabase:start` will fail immediately. Ensure Docker Desktop / Engine is running.
- **Ports already in use:** If ports `56321`-`56327` are taken, check `supabase/config.toml` to customize them.
- **Missing Edge Function Types:** Ensure your IDE has a Deno extension installed and initialized for the `supabase/functions` directory.

## Contribution / Development Notes
- Do not make schema changes directly in the Supabase Studio without capturing them in a migration file.
- Use `npx supabase db diff -f your_migration_name` if you prefer using the Studio to make changes and generate a migration automatically.
- Keep Edge Functions lightweight. Shared code should go in `supabase/functions/_shared/`.

## Deployment Notes
To push database changes to a linked remote Supabase project:
```bash
npx supabase db push
```
To deploy Edge Functions:
```bash
npx supabase functions deploy
```