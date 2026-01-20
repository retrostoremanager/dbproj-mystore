-- Function: Get Company by ID
CREATE OR REPLACE FUNCTION company_get_by_id(p_id INTEGER)
RETURNS TABLE (
    id INTEGER,
    email VARCHAR(255),
    status VARCHAR(50),
    trial_start_date TIMESTAMP,
    trial_end_date TIMESTAMP,
    verification_token VARCHAR(255),
    verification_token_expires TIMESTAMP,
    subscription_tier VARCHAR(50),
    created_date TIMESTAMP,
    last_modified_date TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.email, c.status, c.trial_start_date, c.trial_end_date,
           c.verification_token, c.verification_token_expires, c.subscription_tier,
           c.created_date, c.last_modified_date
    FROM company c
    WHERE c.id = p_id;
END;
$$;

-- Function: Get Company by Email
CREATE OR REPLACE FUNCTION company_get_by_email(p_email VARCHAR(255))
RETURNS TABLE (
    id INTEGER,
    email VARCHAR(255),
    status VARCHAR(50),
    trial_start_date TIMESTAMP,
    trial_end_date TIMESTAMP,
    verification_token VARCHAR(255),
    verification_token_expires TIMESTAMP,
    subscription_tier VARCHAR(50),
    created_date TIMESTAMP,
    last_modified_date TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.email, c.status, c.trial_start_date, c.trial_end_date,
           c.verification_token, c.verification_token_expires, c.subscription_tier,
           c.created_date, c.last_modified_date
    FROM company c
    WHERE c.email = p_email;
END;
$$;

-- Function: Get Company by Verification Token
CREATE OR REPLACE FUNCTION company_get_by_verification_token(p_token VARCHAR(255))
RETURNS TABLE (
    id INTEGER,
    email VARCHAR(255),
    status VARCHAR(50),
    trial_start_date TIMESTAMP,
    trial_end_date TIMESTAMP,
    verification_token VARCHAR(255),
    verification_token_expires TIMESTAMP,
    subscription_tier VARCHAR(50),
    created_date TIMESTAMP,
    last_modified_date TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.email, c.status, c.trial_start_date, c.trial_end_date,
           c.verification_token, c.verification_token_expires, c.subscription_tier,
           c.created_date, c.last_modified_date
    FROM company c
    WHERE c.verification_token = p_token;
END;
$$;

-- Function: Create Company
CREATE OR REPLACE FUNCTION company_create(
    p_email VARCHAR(255),
    p_status VARCHAR(50),
    p_trial_start_date TIMESTAMP,
    p_trial_end_date TIMESTAMP,
    p_verification_token VARCHAR(255) DEFAULT NULL,
    p_verification_token_expires TIMESTAMP DEFAULT NULL,
    p_subscription_tier VARCHAR(50),
    p_created_date TIMESTAMP,
    p_last_modified_date TIMESTAMP DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INTEGER;
BEGIN
    INSERT INTO company (
        email, status, trial_start_date, trial_end_date,
        verification_token, verification_token_expires, subscription_tier,
        created_date, last_modified_date
    )
    VALUES (
        p_email, p_status, p_trial_start_date, p_trial_end_date,
        p_verification_token, p_verification_token_expires, p_subscription_tier,
        p_created_date, p_last_modified_date
    )
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$;

-- Function: Update Company
CREATE OR REPLACE FUNCTION company_update(
    p_id INTEGER,
    p_email VARCHAR(255),
    p_status VARCHAR(50),
    p_trial_start_date TIMESTAMP,
    p_trial_end_date TIMESTAMP,
    p_verification_token VARCHAR(255) DEFAULT NULL,
    p_verification_token_expires TIMESTAMP DEFAULT NULL,
    p_subscription_tier VARCHAR(50),
    p_last_modified_date TIMESTAMP DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected INTEGER;
BEGIN
    UPDATE company
    SET email = p_email,
        status = p_status,
        trial_start_date = p_trial_start_date,
        trial_end_date = p_trial_end_date,
        verification_token = p_verification_token,
        verification_token_expires = p_verification_token_expires,
        subscription_tier = p_subscription_tier,
        last_modified_date = p_last_modified_date
    WHERE id = p_id;
    
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RETURN v_rows_affected;
END;
$$;
