-- Fix function return type: drop and recreate to change from uuid to text

-- Drop existing function
DROP FUNCTION IF EXISTS public.get_invite_token_by_code(text);

-- Create function with text return type
CREATE OR REPLACE FUNCTION public.get_invite_token_by_code(p_code text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code text;
  v_token uuid;
BEGIN
  IF p_code IS NULL OR length(trim(p_code)) < 8 THEN
    RETURN NULL;
  END IF;

  -- Normalize: take first 8 chars, lowercase (token is stored as uuid lowercase).
  v_code := lower(regexp_replace(trim(p_code), '[^a-zA-Z0-9]', '', 'g'));
  v_code := left(v_code, 8);

  IF length(v_code) < 8 THEN
    RETURN NULL;
  END IF;

  -- Find invite where token (as text) starts with the code and is not expired.
  SELECT token INTO v_token
  FROM public.household_invites
  WHERE replace(token::text, '-', '') LIKE v_code || '%'
    AND expires_at > now()
  ORDER BY created_at DESC
  LIMIT 1;

  -- Return as text
  IF v_token IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN v_token::text;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_invite_token_by_code(text) TO authenticated;

-- Verify return type
SELECT pg_typeof(public.get_invite_token_by_code('8588F635')) as return_type;
