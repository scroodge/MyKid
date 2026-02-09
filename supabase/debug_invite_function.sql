-- Debug version of get_invite_token_by_code with logging
-- This version returns debug info to help diagnose the issue

create or replace function public.get_invite_token_by_code_debug(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_token uuid;
  v_count int;
  v_debug jsonb;
begin
  v_debug := jsonb_build_object(
    'input_code', p_code,
    'normalized_code', null,
    'found_tokens', jsonb_build_array(),
    'error', null
  );

  if p_code is null or length(trim(p_code)) < 8 then
    v_debug := jsonb_set(v_debug, '{error}', '"Code too short or null"');
    return v_debug;
  end if;

  -- Normalize: take first 8 chars, lowercase
  v_code := lower(regexp_replace(trim(p_code), '[^a-zA-Z0-9]', '', 'g'));
  v_code := left(v_code, 8);
  v_debug := jsonb_set(v_debug, '{normalized_code}', to_jsonb(v_code));

  if length(v_code) < 8 then
    v_debug := jsonb_set(v_debug, '{error}', '"Normalized code too short"');
    return v_debug;
  end if;

  -- Find all matching tokens (for debugging)
  select jsonb_agg(token::text) into v_debug
  from (
    select token
    from public.household_invites
    where replace(token::text, '-', '') like v_code || '%'
      and expires_at > now()
    order by created_at desc
    limit 5
  ) sub;

  if v_debug is null then
    v_debug := jsonb_build_array();
  end if;

  v_debug := jsonb_set(
    jsonb_build_object('input_code', p_code, 'normalized_code', v_code),
    '{found_tokens}',
    v_debug
  );

  -- Get the first matching token
  select token into v_token
  from public.household_invites
  where replace(token::text, '-', '') like v_code || '%'
    and expires_at > now()
  order by created_at desc
  limit 1;

  if v_token is null then
    v_debug := jsonb_set(v_debug, '{error}', '"No matching token found"');
  else
    v_debug := jsonb_set(v_debug, '{result_token}', to_jsonb(v_token::text));
  end if;

  return v_debug;
end;
$$;

grant execute on function public.get_invite_token_by_code_debug(text) to authenticated;

-- Test it:
-- SELECT public.get_invite_token_by_code_debug('6CED6040');
