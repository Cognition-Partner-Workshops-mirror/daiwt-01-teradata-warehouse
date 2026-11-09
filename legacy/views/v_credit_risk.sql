REPLACE VIEW nvb_mart.v_credit_risk AS
SELECT
    a.customer_id,
    c.customer_name,
    b.town AS branch_town,
    COUNT(l.loan_id) AS loan_count,
    SUM(l.outstanding) AS exposure,
    MAX(l.arrears_days) AS worst_arrears_days,
    SUM(CASE WHEN l.arrears_days >= 90 THEN l.outstanding ELSE 0 END)
        / NULLIFZERO(SUM(l.outstanding)) AS impaired_ratio,
    SUM(CASE WHEN l.arrears_days BETWEEN 30 AND 89 THEN l.outstanding ELSE 0 END)
        AS watchlist_exposure,
    CASE
        WHEN MAX(l.arrears_days) >= 90 THEN 'IMPAIRED'
        WHEN MAX(l.arrears_days) >= 30 THEN 'WATCH'
        ELSE 'PERFORMING'
    END AS risk_band
FROM nvb_edw.fct_loan AS l
INNER JOIN nvb_edw.dim_account AS a ON l.account_id = a.account_id
INNER JOIN nvb_edw.dim_customer AS c ON a.customer_id = c.customer_id
INNER JOIN nvb_edw.dim_branch AS b ON c.branch_id = b.branch_id
WHERE l.record_status_cd = 'A'
GROUP BY 1, 2, 3;
