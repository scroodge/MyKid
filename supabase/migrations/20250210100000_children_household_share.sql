-- Allow family members to see shared children: add household_id and update RLS.

-- Add household_id to children (nullable for backward compatibility)
alter table public.children
  add column if not exists household_id uuid references public.households(id) on delete set null;

create index if not exists children_household_id_idx on public.children (household_id);

-- Backfill: set household_id from the child owner's first household
update public.children c
set household_id = (
  select hm.household_id
  from public.household_members hm
  where hm.user_id = c.user_id
  limit 1
)
where c.household_id is null;

-- Replace RLS policy so members can read own children OR children in their household
drop policy if exists "Users can manage own children" on public.children;
drop policy if exists "Users can read own or household children" on public.children;
drop policy if exists "Users can insert own children" on public.children;
drop policy if exists "Users can update own children" on public.children;
drop policy if exists "Users can delete own children" on public.children;

create policy "Users can read own or household children"
  on public.children for select
  using (
    auth.uid() = user_id
    or (household_id is not null and public.is_household_member(household_id))
  );

create policy "Users can insert own children"
  on public.children for insert to authenticated
  with check (
    auth.uid() = user_id
    and (household_id is null or public.is_household_member(household_id))
  );

create policy "Users can update own children"
  on public.children for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own children"
  on public.children for delete
  using (auth.uid() = user_id);

-- Journal entries: allow reading own entries OR entries for children visible to user (own or household)
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

create policy "Users can update own journal entries"
  on public.journal_entries for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own journal entries"
  on public.journal_entries for delete
  using (auth.uid() = user_id);
