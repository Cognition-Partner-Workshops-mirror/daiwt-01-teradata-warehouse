REPLACE MACRO nvb_edw.channel_daily
(
    p_from DATE,
    p_to DATE
)
AS
(
    DELETE FROM nvb_mart.mart_channel_daily
    WHERE txn_date BETWEEN :p_from AND :p_to;

    INSERT INTO nvb_mart.mart_channel_daily
    (
        txn_date,
        channel,
        txn_count,
        net_amount
    )
    SELECT
        t.txn_date,
        COALESCE(NULLIF(TRIM(t.channel), ''), 'ONLINE'),
        COUNT(*),
        ZEROIFNULL(SUM(t.amount))
    FROM nvb_edw.fct_transaction AS t
    INNER JOIN nvb_edw.dim_calendar AS d
        ON t.txn_date = d.calendar_date
    WHERE t.txn_date BETWEEN :p_from AND :p_to
      AND t.record_status_cd = 'A'
    GROUP BY 1, 2;
);
