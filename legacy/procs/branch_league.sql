REPLACE PROCEDURE nvb_edw.branch_league(IN as_of_date DATE)
SQL SECURITY INVOKER
BEGIN
    DECLARE v_rows BIGINT DEFAULT 0;
    DECLARE v_branches BIGINT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        UPDATE nvb_edw.etl_batch_control
        SET status = 'FAILED', last_step_cd = '06_branch_league'
        WHERE job_name = 'NIGHTLY' AND batch_date = as_of_date;
        RESIGNAL;
    END;

    IF as_of_date IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'League table requires a business date';
    END IF;
    SELECT COUNT(DISTINCT branch_id) INTO v_branches
    FROM nvb_edw.dim_customer WHERE record_status_cd = 'A';

    DELETE FROM nvb_mart.mart_branch_performance WHERE batch_id = 20250630;
    INSERT INTO nvb_mart.mart_branch_performance
    (
        branch_id,
        customer_count,
        net_amount,
        league_rank
    )
    SELECT
        c.branch_id,
        COUNT(DISTINCT c.customer_id),
        ZEROIFNULL(SUM(t.amount)),
        RANK() OVER (ORDER BY ZEROIFNULL(SUM(t.amount)) DESC)
    FROM nvb_edw.dim_customer AS c
    LEFT JOIN nvb_edw.dim_account AS a
        ON c.customer_id = a.customer_id AND a.record_status_cd = 'A'
    LEFT JOIN nvb_edw.fct_transaction AS t
        ON a.account_id = t.account_id
       AND t.txn_date BETWEEN DATE '2024-01-01' AND as_of_date
       AND t.record_status_cd = 'A'
    WHERE c.record_status_cd = 'A'
    GROUP BY 1;
    SET v_rows = ACTIVITY_COUNT;

    IF v_rows <> v_branches THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Branch league population is incomplete';
    END IF;
END;
