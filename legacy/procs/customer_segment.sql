REPLACE PROCEDURE nvb_edw.customer_segment(IN as_of_date DATE)
SQL SECURITY INVOKER
BEGIN
    DECLARE v_rows BIGINT DEFAULT 0;
    DECLARE v_customers BIGINT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        UPDATE nvb_edw.etl_batch_control
        SET status = 'FAILED', last_step_cd = '05_customer_segment'
        WHERE job_name = 'NIGHTLY' AND batch_date = as_of_date;
        RESIGNAL;
    END;

    IF as_of_date IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Segmentation requires a business date';
    END IF;
    SELECT COUNT(*) INTO v_customers
    FROM nvb_edw.dim_customer WHERE record_status_cd = 'A';

    DELETE FROM nvb_mart.mart_customer_segment WHERE batch_id = 20250630;
    INSERT INTO nvb_mart.mart_customer_segment
    (
        customer_id, txn_count, spend, last_txn_date, segment
    )
    SELECT
        c.customer_id,
        COUNT(t.transaction_id),
        ZEROIFNULL(SUM(CASE WHEN t.amount < 0 THEN -t.amount ELSE 0 END)),
        MAX(t.txn_date),
        CASE
            WHEN MAX(t.txn_date) IS NULL OR MAX(t.txn_date) < as_of_date - 90
                THEN 'DORMANT'
            WHEN COUNT(t.transaction_id) >= 50
             AND SUM(CASE WHEN t.amount < 0 THEN -t.amount ELSE 0 END) >= 20000
                THEN 'PREMIUM'
            WHEN COUNT(t.transaction_id) >= 20 THEN 'ACTIVE'
            ELSE 'OCCASIONAL'
        END
    FROM nvb_edw.dim_customer AS c
    LEFT JOIN nvb_edw.dim_account AS a
        ON c.customer_id = a.customer_id AND a.record_status_cd = 'A'
    LEFT JOIN nvb_edw.fct_transaction AS t
        ON a.account_id = t.account_id
       AND t.txn_date BETWEEN ADD_MONTHS(as_of_date, -12) + 1 AND as_of_date
       AND t.record_status_cd = 'A'
    WHERE c.record_status_cd = 'A'
    GROUP BY 1;
    SET v_rows = ACTIVITY_COUNT;

    IF v_rows <> v_customers THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer segment coverage failed';
    END IF;
END;
