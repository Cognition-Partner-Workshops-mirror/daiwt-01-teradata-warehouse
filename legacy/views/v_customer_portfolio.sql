REPLACE VIEW nvb_mart.v_customer_portfolio AS
SELECT
    c.customer_id,
    c.customer_name,
    c.town,
    b.branch_name,
    b.region_cd,
    s.segment,
    COUNT(a.account_id) AS account_count,
    SUM(CASE WHEN a.dormant_flag = 'Y' THEN 1 ELSE 0 END) AS dormant_account_count,
    COUNT(DISTINCT a.product_id) AS product_count,
    ZEROIFNULL(MAX(s.spend)) AS trailing_year_debit_spend,
    MAX(c.load_ts) AS customer_delivery_ts
FROM nvb_edw.dim_customer AS c
INNER JOIN nvb_edw.dim_branch AS b
    ON c.branch_id = b.branch_id
LEFT JOIN nvb_edw.dim_account AS a
    ON c.customer_id = a.customer_id AND a.record_status_cd = 'A'
LEFT JOIN nvb_mart.mart_customer_segment AS s
    ON c.customer_id = s.customer_id
WHERE c.record_status_cd = 'A'
GROUP BY 1, 2, 3, 4, 5, 6;
