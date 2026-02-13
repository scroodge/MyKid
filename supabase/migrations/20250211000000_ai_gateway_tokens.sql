-- AI Gateway: per-user tokens and usage tracking.
-- Tokens are validated by AI Gateway (checks token_hash). Usage is logged per request.

create table if not exists public.ai_gateway_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token_hash text not null,
  name text default 'default',
  created_at timestamptz not null default now(),
  unique (user_id, name)
);

create index if not exists ai_gateway_tokens_token_hash_idx on public.ai_gateway_tokens (token_hash);
create index if not exists ai_gateway_tokens_user_id_idx on public.ai_gateway_tokens (user_id);

create table if not exists public.ai_gateway_usage (
  id uuid primary key default gen_random_uuid(),
  token_id uuid not null references public.ai_gateway_tokens(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  input_tokens int not null default 0,
  output_tokens int not null default 0,
  model text,
  created_at timestamptz not null default now()
);

create index if not exists ai_gateway_usage_user_id_created_at_idx on public.ai_gateway_usage (user_id, created_at);
create index if not exists ai_gateway_usage_token_id_idx on public.ai_gateway_usage (token_id);

-- RLS: users see only their own tokens and usage
alter table public.ai_gateway_tokens enable row level security;
alter table public.ai_gateway_usage enable row level security;

create policy "Users can read own tokens"
  on public.ai_gateway_tokens for select
  using (auth.uid() = user_id);

create policy "Users can read own usage"
  on public.ai_gateway_usage for select
  using (auth.uid() = user_id);

-- Token creation and usage logging happen via Edge Functions / AI Gateway with service_role (RLS bypassed).
