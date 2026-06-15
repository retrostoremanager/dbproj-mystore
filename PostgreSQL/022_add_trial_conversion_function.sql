-- Function: Get companies with expired trial who have payment method and no active subscription (EPIC-0-006-004)
-- Used by trial-to-paid conversion job to find companies ready for Stripe subscription creation
CREATE OR REPLACE FUNCTION company_get_expired_trials_for_conversion()
RETURNS TABLE (
    id INTEGER,
    email TEXT,
    status TEXT,
    trial_start_date TIMESTAMPTZ,
    trial_end_date TIMESTAMPTZ,
    subscription_tier TEXT,
    stripe_customer_id TEXT,
    default_payment_method_id TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.email, c.status, c.trial_start_date, c.trial_end_date, c.subscription_tier,
           pm.stripe_customer_id,
           pm.stripe_payment_method_id AS default_payment_method_id
    FROM company c
    INNER JOIN LATERAL (
        SELECT stripe_customer_id, stripe_payment_method_id
        FROM payment_method
        WHERE company_id = c.id
        ORDER BY is_default DESC, created_date DESC
        LIMIT 1
    ) pm ON true
    LEFT JOIN subscription s ON s.company_id = c.id AND s.status IN ('active', 'trialing')
    WHERE c.status = 'Active'
      AND c.trial_end_date <= NOW()
      AND s.id IS NULL;
END;
$$;

COMMENT ON FUNCTION company_get_expired_trials_for_conversion() IS 'Returns companies with expired trial, payment method on file, and no active subscription. For trial-to-paid conversion.';

-- Function: Update company subscription tier (for trial-to-paid conversion)
CREATE OR REPLACE FUNCTION company_update_subscription_tier(p_id INTEGER, p_subscription_tier TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected INTEGER;
BEGIN
    UPDATE company
    SET subscription_tier = p_subscription_tier, last_modified_date = NOW()
    WHERE id = p_id;
    
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RETURN v_rows_affected;
END;
$$;
