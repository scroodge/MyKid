-- Add monthly token limit to subscriptions table.
-- Premium plan: 100,000 tokens/month (resets at current_period_end).
-- Basic plan: 0 (no AI via ai-proxy).

alter table public.subscriptions
  add column if not exists monthly_token_limit int not null default 0;

-- Set default limits based on plan_id
update public.subscriptions
  set monthly_token_limit = case
    when plan_id = 'premium' then 100000
    else 0
  end
  where monthly_token_limit = 0;

comment on column public.subscriptions.monthly_token_limit is
  'Monthly token limit for AI Gateway usage. Premium: 100K/month, Basic: 0 (no AI). Resets at current_period_end.';
