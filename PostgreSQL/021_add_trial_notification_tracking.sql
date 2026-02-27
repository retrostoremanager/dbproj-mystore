-- Add columns to track trial expiration notification sends (EPIC-0-006-003)
-- Prevents duplicate emails when the timer job runs multiple times

ALTER TABLE company ADD COLUMN IF NOT EXISTS trial_notification_7d_sent_at TIMESTAMPTZ NULL;
ALTER TABLE company ADD COLUMN IF NOT EXISTS trial_notification_3d_sent_at TIMESTAMPTZ NULL;
ALTER TABLE company ADD COLUMN IF NOT EXISTS trial_notification_1d_sent_at TIMESTAMPTZ NULL;

COMMENT ON COLUMN company.trial_notification_7d_sent_at IS 'When the 7-day trial expiration reminder was sent';
COMMENT ON COLUMN company.trial_notification_3d_sent_at IS 'When the 3-day trial expiration reminder was sent';
COMMENT ON COLUMN company.trial_notification_1d_sent_at IS 'When the 1-day trial expiration reminder was sent';

-- Function: Get companies with trial expiring in exactly N days who haven't received that notification
-- p_days: 7, 3, or 1
CREATE OR REPLACE FUNCTION company_get_expiring_trials(p_days INTEGER)
RETURNS TABLE (
    id INTEGER,
    email TEXT,
    status TEXT,
    trial_start_date TIMESTAMPTZ,
    trial_end_date TIMESTAMPTZ,
    subscription_tier TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.email, c.status, c.trial_start_date, c.trial_end_date, c.subscription_tier
    FROM company c
    WHERE c.status = 'Active'
      AND LOWER(c.subscription_tier) = 'trial'
      AND c.trial_end_date > NOW()
      AND (c.trial_end_date AT TIME ZONE 'UTC')::date = ((NOW() AT TIME ZONE 'UTC') + (p_days || ' days')::interval)::date
      AND (
          (p_days = 7 AND c.trial_notification_7d_sent_at IS NULL)
          OR (p_days = 3 AND c.trial_notification_3d_sent_at IS NULL)
          OR (p_days = 1 AND c.trial_notification_1d_sent_at IS NULL)
      );
END;
$$;

-- Function: Mark that a trial expiration notification was sent
CREATE OR REPLACE FUNCTION company_mark_trial_notification_sent(p_id INTEGER, p_days INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected INTEGER;
BEGIN
    IF p_days = 7 THEN
        UPDATE company SET trial_notification_7d_sent_at = NOW(), last_modified_date = NOW() WHERE id = p_id;
    ELSIF p_days = 3 THEN
        UPDATE company SET trial_notification_3d_sent_at = NOW(), last_modified_date = NOW() WHERE id = p_id;
    ELSIF p_days = 1 THEN
        UPDATE company SET trial_notification_1d_sent_at = NOW(), last_modified_date = NOW() WHERE id = p_id;
    ELSE
        RETURN 0;
    END IF;
    
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RETURN v_rows_affected;
END;
$$;
