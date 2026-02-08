-- Household-level Immich settings. API key stored in Supabase Vault (encrypted).
-- Requires Supabase Vault extension (enabled by default on Supabase Cloud).

create table if not exists public.household_settings (
  household_id uuid primary key references public.households(id) on delete cascade,
  immich_server_url text,
  immich_vault_secret_id uuid,
  updated_at timestamptz not null default now()
);

create trigger household_settings_updated_at
  before update on public.household_settings
  for each row execute function public.set_updated_at();

alter table public.household_settings enable row level security;

create policy "Members can read household_settings"
  on public.household_settings for select
  using (
    exists (
      select 1 from public.household_members m
      where m.household_id = household_settings.household_id and m.user_id = auth.uid()
    )
  );

create policy "Members can insert household_settings"
  on public.household_settings for insert to authenticated
  with check (
    exists (
      select 1 from public.household_members m
      where m.household_id = household_settings.household_id and m.user_id = auth.uid()
    )
  );

create policy "Members can update household_settings"
  on public.household_settings for update
  using (
    exists (
      select 1 from public.household_members m
      where m.household_id = household_settings.household_id and m.user_id = auth.uid()
    )
  )
  with check (true);

-- Returns Immich server_url and api_key for a household. Only callable by members.
-- SECURITY DEFINER so we can read vault.decrypted_secrets (run as migration owner).
create or replace function public.get_household_immich_config(p_household_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, vault
as $$
declare
  v_url text;
  v_secret_id uuid;
  v_api_key text;
begin
  if not exists (
    select 1 from public.household_members m
    where m.household_id = p_household_id and m.user_id = auth.uid()
  ) then
    raise exception 'Not a member of this household';
  end if;

  select immich_server_url, immich_vault_secret_id
  into v_url, v_secret_id
  from public.household_settings
  where household_id = p_household_id;

  if v_url is null or v_secret_id is null then
    return jsonb_build_object('server_url', null, 'api_key', null);
  end if;

  select decrypted_secret into v_api_key
  from vault.decrypted_secrets
  where id = v_secret_id;

  return jsonb_build_object('server_url', v_url, 'api_key', v_api_key);
end;
$$;

comment on function public.get_household_immich_config(uuid) is
  'Returns Immich server_url and api_key for household. Call only after user consent.';

-- Saves Immich URL and API key for household. API key is stored in Vault.
create or replace function public.set_household_immich_config(
  p_household_id uuid,
  p_server_url text,
  p_api_key text
)
returns void
language plpgsql
security definer
set search_path = public, vault
as $$
declare
  v_secret_id uuid;
  v_name text;
begin
  if not exists (
    select 1 from public.household_members m
    where m.household_id = p_household_id and m.user_id = auth.uid()
  ) then
    raise exception 'Not a member of this household';
  end if;

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

comment on function public.set_household_immich_config(uuid, text, text) is
  'Saves Immich URL and API key for household. API key stored in Vault. Requires member consent.';

grant execute on function public.get_household_immich_config(uuid) to authenticated;
grant execute on function public.set_household_immich_config(uuid, text, text) to authenticated;
