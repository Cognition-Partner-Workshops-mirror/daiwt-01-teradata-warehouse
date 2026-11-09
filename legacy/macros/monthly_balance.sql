REPLACE MACRO nvb_edw.monthly_balance
(
    p_from DATE,
    p_to DATE
)
AS
(
    DELETE FROM nvb_mart.mart_monthly_balance
    WHERE month_start BETWEEN TRUNC(:p_from, 'MONTH') AND TRUNC(:p_to, 'MONTH');

    INSERT INTO nvb_mart.mart_monthly_balance
    (
        account_id,
        month_start,
        average_balance,
        closing_balance
    )
    SELECT
        b.account_id,
        TRUNC(b.balance_date, 'MONTH'),
        CAST(AVG(CAST(b.balance AS DECIMAL(28,6))) AS DECIMAL(18,2)),
        MAX(CASE
            WHEN b.balance_date = ADD_MONTHS(TRUNC(b.balance_date, 'MONTH'), 1) - 1
            THEN b.balance
        END)
    FROM nvb_edw.fct_daily_balance AS b
    INNER JOIN nvb_edw.dim_account AS a
        ON b.account_id = a.account_id
    WHERE b.balance_date BETWEEN :p_from AND :p_to
      AND b.record_status_cd = 'A'
      AND a.record_status_cd = 'A'
    GROUP BY 1, 2;
);
