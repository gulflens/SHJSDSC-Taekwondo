-- =====================================================================
-- 0022_peer_benchmarks.sql
--
-- Pillar 12: materialised cohort statistics. One row per (cohort, metric)
-- tuple with mean, standard deviation, sample size, and last-computed
-- timestamp. Cohort dimensions any of which may be null to mean
-- "unconstrained on this dimension".
--
-- Recompute is initiated from the iOS client today (BenchmarkComputer
-- + repository.recomputeBenchmarks). Promote to a Supabase scheduled
-- function later if recomputes get expensive.
-- =====================================================================

create table if not exists peer_benchmark (
    id                  uuid primary key default gen_random_uuid(),
    belt_rank           jsonb,
    age_division        text,
    weight_class        text,
    metric_key          text not null,
    mean                numeric not null,
    standard_deviation  numeric not null,
    sample_size         int not null check (sample_size >= 0),
    computed_at         timestamptz not null default now()
);

-- Lookup pattern: given an athlete's age group + belt + metric, find best fit.
create index if not exists peer_benchmark_lookup_idx
    on peer_benchmark (metric_key, age_division, weight_class);

create index if not exists peer_benchmark_metric_idx
    on peer_benchmark (metric_key);

-- =====================================================================
-- RLS — public read inside the club (any authed user); coach+ can write.
-- =====================================================================
alter table peer_benchmark enable row level security;

create policy "peer_benchmark_read"
    on peer_benchmark
    for select using (auth.uid() is not null);

create policy "peer_benchmark_write"
    on peer_benchmark
    for all
    using (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'))
    with check (auth_role() in ('admin','developer','technicalDirector','branchManager','coach'));
