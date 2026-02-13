-- Store plain AI Gateway token per user in Vault so ai-proxy can send per-user token to the gateway.
-- Gateway can then validate token (hash -> ai_gateway_tokens) and log usage per user.

alter table public.ai_gateway_tokens
  add column if not exists vault_secret_id uuid references vault.secrets(id) on delete set null;

comment on column public.ai_gateway_tokens.vault_secret_id is 'Vault secret holding the plain token for this user (so ai-proxy can send it to the gateway).';

-- Internal: set plain token for a user (create/update Vault secret, link to ai_gateway_tokens). service_role only.
create or replace function public.set_ai_gateway_plain_token_for_user(p_user_id uuid, p_plain_token text)
returns void
language plpgsql security definer set search_path = public, vault
as $$
declare v_secret_id uuid; v_name text;
begin
  v_name := 'ai_gateway_plain_' || p_user_id::text;
  select vault_secret_id into v_secret_id from public.ai_gateway_tokens where user_id = p_user_id and name = 'default';
  if v_secret_id is not null then
    perform vault.update_secret(v_secret_id, p_plain_token, v_name, 'AI Gateway token for user');
  else
    v_secret_id := vault.create_secret(p_plain_token, v_name, 'AI Gateway token for user');
    update public.ai_gateway_tokens set vault_secret_id = v_secret_id where user_id = p_user_id and name = 'default';
  end if;
end;
$$;
grant execute on function public.set_ai_gateway_plain_token_for_user(uuid, text) to service_role;

-- Internal: get plain token for a user (for ai-proxy). service_role only.
create or replace function public.get_ai_gateway_plain_token_for_user(p_user_id uuid)
returns text
language plpgsql security definer set search_path = public, vault
as $$
declare v_plain text;
begin
  select s.decrypted_secret into v_plain
  from public.ai_gateway_tokens t
  join vault.decrypted_secrets s on s.id = t.vault_secret_id
  where t.user_id = p_user_id and t.name = 'default';
  return v_plain;
end;
$$;
grant execute on function public.get_ai_gateway_plain_token_for_user(uuid) to service_role;
