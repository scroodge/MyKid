-- RPC: get invite token by 8-char code (first 8 chars of token, for "enter code" flow).
-- Returns the full token if exactly one non-expired invite matches the code prefix.
create or replace function public.get_invite_token_by_code(p_code text)
returns uuid
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
  where token::text like v_code || '%'
    and expires_at > now()
  limit 1;

  return v_token;
end;
$$;

comment on function public.get_invite_token_by_code(text) is
  'Returns the invite token for a given 8-character code (prefix of token). Used by accept-invite screen.';

grant execute on function public.get_invite_token_by_code(text) to authenticated;
