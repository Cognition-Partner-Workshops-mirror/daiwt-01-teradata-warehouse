REPLACE PROCEDURE nvb_edw.flag_dormant(IN as_of_date DATE)
SQL SECURITY INVOKER
BEGIN
    DECLARE v_rows BIGINT DEFAULT 0;
    DECLARE v_total BIGINT DEFAULT 0;
    DECLARE v_accounts BIGINT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        UPDATE nvb_edw.etl_batch_control
        SET status = 'FAILED', last_step_cd = '03_dormant'
        WHERE job_name = 'NIGHTLY' AND batch_date = as_of_date;
        RESIGNAL;
    END;

    IF as_of_date IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Business date is required';
    END IF;

    UPDATE nvb_edw.dim_account
    SET dormant_flag = 'N'
    WHERE record_status_cd = 'A';

    FOR branch_row AS branch_cursor CURSOR FOR
        SELECT branch_id
        FROM nvb_edw.dim_branch
        WHERE record_status_cd = 'A'
        ORDER BY branch_id
    DO
        UPDATE nvb_edw.dim_account
        SET dormant_flag = 'Y'
        WHERE record_status_cd = 'A'
          AND customer_id IN
          (
              SELECT customer_id FROM nvb_edw.dim_customer
              WHERE branch_id = branch_row.branch_id
          )
          AND account_id NOT IN
          (
              SELECT account_id FROM nvb_edw.fct_transaction
              WHERE txn_date > ADD_MONTHS(as_of_date, -6)
                AND txn_date <= as_of_date
                AND record_status_cd = 'A'
          );
        SET v_rows = ACTIVITY_COUNT;
        SET v_total = v_total + v_rows;
    END FOR;

    SELECT COUNT(*) INTO v_accounts FROM nvb_edw.dim_account;
    IF v_total > v_accounts THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Dormancy control exceeds account population';
    END IF;
END;
