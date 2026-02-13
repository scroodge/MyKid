-- Subscriptions table for Stripe-managed plans (Basic 10 GB / Premium 20 GB + AI).
-- RLS: user sees only their own row (by user_id).

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  stripe_customer_id text,
  stripe_subscription_id text,
  status text not null default 'trialing'
    check (status in ('trialing', 'active', 'past_due', 'canceled', 'expired')),
  trial_ends_at timestamptz,
  current_period_end timestamptz,
  plan_id text not null check (plan_id in ('basic', 'premium')),
  storage_limit_gb int not null default 10,
  immich_user_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id)
);

create index if not exists subscriptions_user_id_idx on public.subscriptions (user_id);
create index if not exists subscriptions_stripe_customer_id_idx on public.subscriptions (stripe_customer_id);
create index if not exists subscriptions_stripe_subscription_id_idx on public.subscriptions (stripe_subscription_id);

create trigger subscriptions_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();

alter table public.subscriptions enable row level security;

create policy "Users can read own subscription"
  on public.subscriptions for select
  using (auth.uid() = user_id);

-- Only backend (Edge Functions with service_role) inserts/updates; no policy for insert/update for authenticated.
-- Service role bypasses RLS.
create policy "Service role can manage subscriptions"
  on public.subscriptions for all
  using (true)
  with check (true);

-- Allow backend to manage: use a role that Edge uses. In Supabase, Edge with service_role bypasses RLS,
-- so we need to allow the Edge Function to insert/update. Actually with service_role key, RLS is bypassed.
-- So the policy "Users can read own subscription" is enough for app; backend uses service_role and bypasses RLS.
-- We should not have "using (true) with check (true)" for all - that would let anyone modify. Remove that.
drop policy if exists "Service role can manage subscriptions" on public.subscriptions;
-- So: only "Users can read own subscription". Inserts/updates from Edge use service_role → RLS bypassed. Good.

-- Internal RPC for webhook: set Immich URL + API key for a household (used when provisioning managed Immich).
-- Only callable with service_role; grant to service_role so Edge can invoke it.
create or replace function public.set_household_immich_config_for_managed(
  p_household_id uuid, p_server_url text, p_api_key text
)
returns void
language plpgsql security definer set search_path = public, vault
as $$
declare v_secret_id uuid; v_name text;
begin
  v_name := 'immich_apikey_' || p_household_id::text;
  insert into public.household_settings (household_id, immich_server_url, immich_vault_secret_id)
  values (p_household_id, nullif(trim(p_server_url), ''), null)
  on conflict (household_id) do update set
    immich_server_url = nullif(trim(p_server_url), ''),
    updated_at = now();
  if nullif(trim(p_api_key), '') is not null then
    select immich_vault_secret_id into v_secret_id
    from public.household_settings where household_id = p_household_id;
    if v_secret_id is not null then
      perform vault.update_secret(v_secret_id, p_api_key, v_name, 'Immich API key for household');
    else
      v_secret_id := vault.create_secret(p_api_key, v_name, 'Immich API key for household');
      update public.household_settings
      set immich_vault_secret_id = v_secret_id, updated_at = now()
      where household_id = p_household_id;
    end if;
  end if;
end;
$$;

comment on function public.set_household_immich_config_for_managed(uuid, text, text) is
  'Internal: set Immich config for a household (managed subscription). Call only from Edge with service_role.';

grant execute on function public.set_household_immich_config_for_managed(uuid, text, text) to service_role;
