-- RPCs for app to read/write household Immich config (URL + API key in Vault).
-- Required so that after stripe-webhook provisions managed Immich (set_household_immich_config_for_managed),
-- the app can fetch config via get_household_immich_config and either auto-sync on login or "Use family's Immich".

create or replace function public.is_household_member(p_household_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.household_members
    where household_id = p_household_id and user_id = auth.uid()
  );
$$ language sql stable security definer set search_path = public;

create or replace function public.get_household_immich_config(p_household_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, vault
as $$
declare
  v_url text;
  v_secret_id uuid;
  v_api_key text;
begin
  if not public.is_household_member(p_household_id) then
    raise exception 'Not a member of this household';
  end if;
  select immich_server_url, immich_vault_secret_id into v_url, v_secret_id
  from public.household_settings where household_id = p_household_id;
  if v_url is null or v_secret_id is null then
    return jsonb_build_object('server_url', null, 'api_key', null);
  end if;
  select decrypted_secret into v_api_key from vault.decrypted_secrets where id = v_secret_id;
  return jsonb_build_object('server_url', v_url, 'api_key', v_api_key);
end;
$$;

comment on function public.get_household_immich_config(uuid) is
  'Returns Immich server_url and api_key for the household. For members only. Used by app for "Use family''s Immich" and auto-sync.';

create or replace function public.set_household_immich_config(
  p_household_id uuid, p_server_url text, p_api_key text
)
returns void
language plpgsql security definer set search_path = public, vault
as $$
declare v_secret_id uuid; v_name text;
begin
  if not public.is_household_member(p_household_id) then
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
  'Stores Immich server URL and API key for the household (key in Vault). For members only.';

grant execute on function public.get_household_immich_config(uuid) to authenticated;
grant execute on function public.set_household_immich_config(uuid, text, text) to authenticated;
