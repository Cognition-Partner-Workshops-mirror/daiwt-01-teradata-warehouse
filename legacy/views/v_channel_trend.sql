REPLACE VIEW nvb_mart.v_channel_trend AS
SELECT
    d.calendar_date AS txn_date,
    d.year_no,
    d.month_no,
    d.month_start,
    'MOBILE' AS channel,
    ZEROIFNULL(m.txn_count) AS txn_count,
    ZEROIFNULL(m.net_amount) AS net_amount,
    CSUM(ZEROIFNULL(m.net_amount), d.calendar_date) AS running_amount,
    MAVG(ZEROIFNULL(m.net_amount), 7, d.calendar_date) AS seven_day_average,
    ZEROIFNULL(m.net_amount) / NULLIFZERO(m.txn_count) AS average_payment,
    CASE
        WHEN m.txn_count IS NULL THEN 'NO_ACTIVITY'
        ELSE 'CLEARED'
    END AS activity_status
FROM nvb_edw.dim_calendar AS d
LEFT JOIN nvb_mart.mart_channel_daily AS m
    ON d.calendar_date = m.txn_date
   AND m.channel = 'MOBILE'
WHERE d.calendar_date BETWEEN DATE '2024-01-01' AND DATE '2025-06-30';
