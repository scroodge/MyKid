-- MyKid — полная схема БД для однократного применения
-- Использование: новый проект Supabase → SQL Editor → вставить и выполнить весь файл.
-- Либо оставить пошаговые миграции в supabase/migrations/ и применять: supabase db push
--
-- Требования: Supabase с включённым Vault (по умолчанию в Cloud). Auth (email) включён вручную в Dashboard.

-- ========== 1. Journal entries ==========
create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  text text not null default '',
  assets jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists journal_entries_user_id_idx on public.journal_entries (user_id);
create index if not exists journal_entries_user_id_date_idx on public.journal_entries (user_id, date desc);

alter table public.journal_entries enable row level security;

create policy "Users can manage own journal entries"
  on public.journal_entries for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

create trigger journal_entries_updated_at
  before update on public.journal_entries
  for each row execute function public.set_updated_at();

-- ========== 2. Children + child_id on journal_entries ==========
create table if not exists public.children (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  date_of_birth date,
  immich_album_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists children_user_id_idx on public.children (user_id);
alter table public.children enable row level security;

create policy "Users can manage own children"
  on public.children for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create trigger children_updated_at
  before update on public.children
  for each row execute function public.set_updated_at();

alter table public.journal_entries
  add column if not exists child_id uuid references public.children(id) on delete set null;
create index if not exists journal_entries_child_id_idx on public.journal_entries (child_id);

-- ========== 3. Storage avatars bucket ==========
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = excluded.public;

create policy "Users can upload own avatar"
on storage.objects for insert to authenticated
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.jwt()->>'sub'));

create policy "Users can update own avatar"
on storage.objects for update to authenticated
using (bucket_id = 'avatars' and (owner_id = auth.uid()::text or owner_id is null))
with check (bucket_id = 'avatars' and (owner_id = auth.uid()::text or owner_id is null));

create policy "Users can read own avatar"
on storage.objects for select to authenticated
using (bucket_id = 'avatars' and (owner_id = auth.uid()::text or owner_id is null));

create policy "Public read avatars"
on storage.objects for select to public
using (bucket_id = 'avatars');

-- ========== 4. Children avatar_url + child avatar upload ==========
alter table public.children add column if not exists avatar_url text;

create policy "Users can upload child avatar"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = 'children'
  and (storage.foldername(name))[2] = (select auth.jwt()->>'sub')
);

-- ========== 5. Journal entry location ==========
alter table public.journal_entries add column if not exists location text;

-- ========== 6. Households and members ==========
create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists households_owner_id_idx on public.households (owner_id);

create table if not exists public.household_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  unique (household_id, user_id)
);

create index if not exists household_members_household_id_idx on public.household_members (household_id);
create index if not exists household_members_user_id_idx on public.household_members (user_id);

alter table public.households enable row level security;
alter table public.household_members enable row level security;

create or replace function public.is_household_member(p_household_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.household_members
    where household_id = p_household_id and user_id = auth.uid()
  );
$$ language sql stable security definer set search_path = public;

create or replace function public.is_household_owner(p_household_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.household_members
    where household_id = p_household_id and user_id = auth.uid() and role = 'owner'
  );
$$ language sql stable security definer set search_path = public;

create policy "Members can read household"
  on public.households for select
  using (public.is_household_member(households.id));

create policy "Members can update household"
  on public.households for update
  using (public.is_household_member(households.id))
  with check (true);

create policy "Authenticated can insert household"
  on public.households for insert to authenticated
  with check (owner_id = auth.uid());

create policy "Members can read household_members"
  on public.household_members for select
  using (public.is_household_member(household_members.household_id));

create policy "Owner or household owner can insert household_members"
  on public.household_members for insert to authenticated
  with check (
    (user_id = auth.uid() and exists (
      select 1 from public.households h where h.id = household_members.household_id and h.owner_id = auth.uid()
    ))
    or public.is_household_owner(household_members.household_id)
  );

create policy "Owner or self can delete household_members"
  on public.household_members for delete
  using (user_id = auth.uid() or public.is_household_owner(household_members.household_id));

create trigger households_updated_at
  before update on public.households
  for each row execute function public.set_updated_at();

create or replace function public.user_household_ids()
returns uuid[] as $$
  select array_agg(household_id) from public.household_members where user_id = auth.uid();
$$ language sql stable security definer set search_path = public;

-- ========== 7. Household settings (Immich + Vault) ==========
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
  using (public.is_household_member(household_settings.household_id));

create policy "Members can insert household_settings"
  on public.household_settings for insert to authenticated
  with check (public.is_household_member(household_settings.household_id));

create policy "Members can update household_settings"
  on public.household_settings for update
  using (public.is_household_member(household_settings.household_id))
  with check (true);

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

grant execute on function public.get_household_immich_config(uuid) to authenticated;
grant execute on function public.set_household_immich_config(uuid, text, text) to authenticated;

-- ========== 8. Household invites ==========
create table if not exists public.household_invites (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  email text not null,
  invited_by uuid not null references auth.users(id) on delete cascade,
  token uuid not null unique default gen_random_uuid(),
  expires_at timestamptz not null default (now() + interval '7 days'),
  created_at timestamptz not null default now()
);

create index if not exists household_invites_household_id_idx on public.household_invites (household_id);
create index if not exists household_invites_token_idx on public.household_invites (token);
create index if not exists household_invites_email_idx on public.household_invites (email);

alter table public.household_invites enable row level security;

create policy "Members can read household_invites"
  on public.household_invites for select
  using (public.is_household_member(household_invites.household_id));

create policy "Anyone can read invite by token"
  on public.household_invites for select using (true);

create policy "Members can create household_invites"
  on public.household_invites for insert to authenticated
  with check (
    public.is_household_member(household_invites.household_id)
    and invited_by = auth.uid()
  );

create policy "Owner can delete household_invites"
  on public.household_invites for delete
  using (public.is_household_owner(household_invites.household_id));

create or replace function public.accept_household_invite(p_token uuid)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare v_invite record; v_household_id uuid; v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then raise exception 'Not authenticated'; end if;
  select * into v_invite from public.household_invites
  where token = p_token and expires_at > now();
  if not found then
    return jsonb_build_object('success', false, 'error', 'Invite not found or expired');
  end if;
  v_household_id := v_invite.household_id;
  insert into public.household_members (household_id, user_id, role)
  values (v_household_id, v_user_id, 'member')
  on conflict (household_id, user_id) do nothing;
  if public.is_household_member(v_household_id) then
    delete from public.household_invites where id = v_invite.id;
    return jsonb_build_object('success', true, 'household_id', v_household_id);
  end if;
  return jsonb_build_object('success', false, 'error', 'Failed to add user to household');
end;
$$;

grant execute on function public.accept_household_invite(uuid) to authenticated;

-- ========== 9. create_household ==========
create or replace function public.create_household(p_name text default null)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare v_household_id uuid; v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then raise exception 'Not authenticated'; end if;
  insert into public.households (owner_id, name)
  values (v_user_id, p_name)
  returning id into v_household_id;
  insert into public.household_members (household_id, user_id, role)
  values (v_household_id, v_user_id, 'owner')
  on conflict (household_id, user_id) do nothing;
  return v_household_id;
end;
$$;

grant execute on function public.create_household(text) to authenticated;

-- ========== 10. get_invite_token_by_code ==========
drop function if exists public.get_invite_token_by_code(text);

create function public.get_invite_token_by_code(p_code text)
returns text
language plpgsql security definer set search_path = public
as $$
declare v_code text; v_token uuid;
begin
  if p_code is null or length(trim(p_code)) < 8 then return null; end if;
  v_code := lower(regexp_replace(trim(p_code), '[^a-zA-Z0-9]', '', 'g'));
  v_code := left(v_code, 8);
  if length(v_code) < 8 then return null; end if;
  select token into v_token
  from public.household_invites
  where replace(token::text, '-', '') like v_code || '%' and expires_at > now()
  order by created_at desc limit 1;
  if v_token is null then return null; end if;
  return v_token::text;
end;
$$;

grant execute on function public.get_invite_token_by_code(text) to authenticated;

-- ========== 11. Children household_id + shared children & journal RLS ==========
alter table public.children
  add column if not exists household_id uuid references public.households(id) on delete set null;

create index if not exists children_household_id_idx on public.children (household_id);

update public.children c
set household_id = (
  select hm.household_id from public.household_members hm
  where hm.user_id = c.user_id limit 1
)
where c.household_id is null;

drop policy if exists "Users can manage own children" on public.children;
create policy "Users can read own or household children"
  on public.children for select
  using (
    auth.uid() = user_id
    or (household_id is not null and public.is_household_member(household_id))
  );

drop policy if exists "Users can insert own children" on public.children;
drop policy if exists "Users can insert own children without household" on public.children;
drop policy if exists "Users can insert own children in household" on public.children;

create policy "Users can insert own children without household"
  on public.children for insert to authenticated
  with check (auth.uid() = user_id and household_id is null);

create policy "Users can insert own children in household"
  on public.children for insert to authenticated
  with check (
    auth.uid() = user_id
    and household_id is not null
    and public.is_household_member(household_id)
  );

create policy "Users can update own children"
  on public.children for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own children"
  on public.children for delete
  using (auth.uid() = user_id);

-- Journal entries: read for owner or household child entries
drop policy if exists "Users can manage own journal entries" on public.journal_entries;
drop policy if exists "Users can read own or household child journal entries" on public.journal_entries;
drop policy if exists "Users can insert own journal entries" on public.journal_entries;
drop policy if exists "Users can update own journal entries" on public.journal_entries;
drop policy if exists "Users can delete own journal entries" on public.journal_entries;

create policy "Users can read own or household child journal entries"
  on public.journal_entries for select
  using (
    auth.uid() = user_id
    or (
      child_id is not null
      and exists (
        select 1 from public.children c
        where c.id = journal_entries.child_id
          and (c.user_id = auth.uid() or (c.household_id is not null and public.is_household_member(c.household_id)))
      )
    )
  );

create policy "Users can insert own journal entries"
  on public.journal_entries for insert to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own or household child journal entries"
  on public.journal_entries for update
  using (
    auth.uid() = user_id
    or (
      child_id is not null
      and exists (
        select 1 from public.children c
        where c.id = journal_entries.child_id
          and (c.user_id = auth.uid() or (c.household_id is not null and public.is_household_member(c.household_id)))
      )
    )
  )
  with check (
    auth.uid() = user_id
    or (
      child_id is not null
      and exists (
        select 1 from public.children c
        where c.id = journal_entries.child_id
          and (c.user_id = auth.uid() or (c.household_id is not null and public.is_household_member(c.household_id)))
      )
    )
  );

create policy "Users can delete own or household child journal entries"
  on public.journal_entries for delete
  using (
    auth.uid() = user_id
    or (
      child_id is not null
      and exists (
        select 1 from public.children c
        where c.id = journal_entries.child_id
          and (c.user_id = auth.uid() or (c.household_id is not null and public.is_household_member(c.household_id)))
      )
    )
  );
