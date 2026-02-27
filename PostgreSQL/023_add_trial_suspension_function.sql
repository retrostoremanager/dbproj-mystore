-- Function: Get companies with trial expired 7+ days ago, no payment method, not suspended (EPIC-0-006-005)
-- Used by trial suspension job to find companies to suspend
CREATE OR REPLACE FUNCTION company_get_expired_trials_for_suspension()
RETURNS TABLE (
    id INTEGER,
    email TEXT,
    status TEXT,
    trial_end_date TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.email, c.status, c.trial_end_date
    FROM company c
    WHERE c.status = 'Active'
      AND c.trial_end_date <= NOW() - INTERVAL '7 days'
      AND c.subscription_tier = 'Trial'
      AND NOT EXISTS (
          SELECT 1 FROM payment_method pm WHERE pm.company_id = c.id
      );
END;
$$;

COMMENT ON FUNCTION company_get_expired_trials_for_suspension() IS 'Returns companies with trial expired 7+ days ago, no payment method. For account suspension (EPIC-0-006-005).';

-- Function: Update company status (for trial suspension)
CREATE OR REPLACE FUNCTION company_update_status(p_id INTEGER, p_status TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected INTEGER;
BEGIN
    UPDATE company
    SET status = p_status, last_modified_date = NOW()
    WHERE id = p_id;
    
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RETURN v_rows_affected;
END;
$$;

COMMENT ON FUNCTION company_update_status(INTEGER, TEXT) IS 'Updates company status. Used for trial suspension (EPIC-0-006-005).';
