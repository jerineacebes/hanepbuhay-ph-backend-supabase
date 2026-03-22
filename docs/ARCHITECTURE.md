# HanepBuhay PH Backend Architecture

## Overview
Hyperlocal AI-powered job matching platform for Philippine blue-collar workers.

## Tech Stack
- **Database:** Supabase Postgres
- **Extensions:** PostGIS (Geo), pgvector (Semantic Search), pgcrypto (Security)
- **Auth:** Supabase Auth (Cookie-based SSR ready)
- **Functions:** Supabase Edge Functions (Deno/TypeScript)
- **Storage:** Supabase Storage
- **Logic:** Rule-based deterministic scoring & smart routing

## Core Models
1. **Job Seeker Domain:** Chat onboarding, automated profile extraction, geo-aware location.
2. **Employer/Organization Domain:** Job management, verification badges, organization tiers.
3. **Matching Engine:** Weighted scoring based on Commute, Skills, Experience, and Availability.
4. **Smart Router:** Automated decision flow (Direct Hire vs Agency Routing).

## Key Components
- **Migrations:** SQL-first schema management.
- **RPCs:** Data-intensive calculations (Ranking, Commute, Routing) handled by Postgres functions.
- **Edge Functions:** Orchestration, Mock LLM Extraction, and API wrappers.
- **RLS:** Granular access control for Job Seekers, Employers, Agencies, and Admins.
