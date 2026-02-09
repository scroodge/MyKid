-- Policy that allows anyone (including anonymous) to read invite by token.
-- This is needed so users can see invite details before signing up/login.
-- The policy allows reading any invite, but users still need to be authenticated to accept it.
drop policy if exists "Authenticated can read invite by token" on public.household_invites;
drop policy if exists "Anyone can read invite by token" on public.household_invites;
create policy "Anyone can read invite by token"
  on public.household_invites for select
  using (true);

-- RPC: get invite token by 8-char code (first 8 chars of token, for "enter code" flow).
-- Returns the full token as text if exactly one non-expired invite matches the code prefix.
-- Drop existing function first in case it exists with different return type
drop function if exists public.get_invite_token_by_code(text);

create function public.get_invite_token_by_code(p_code text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_token uuid;
begin
  if p_code is null or length(trim(p_code)) < 8 then
    return null;
  end if;

  -- Normalize: take first 8 chars, lowercase (token is stored as uuid lowercase).
  v_code := lower(regexp_replace(trim(p_code), '[^a-zA-Z0-9]', '', 'g'));
  v_code := left(v_code, 8);

  if length(v_code) < 8 then
    return null;
  end if;

  -- Find invite where token (as text) starts with the code and is not expired.
  select token into v_token
  from public.household_invites
  where replace(token::text, '-', '') like v_code || '%'
    and expires_at > now()
  order by created_at desc
  limit 1;

  if v_token is null then
    return null;
  end if;

  return v_token::text;
end;
$$;

comment on function public.get_invite_token_by_code(text) is
  'Returns the invite token for a given 8-character code (prefix of token). Used by accept-invite screen.';

grant execute on function public.get_invite_token_by_code(text) to authenticated;
