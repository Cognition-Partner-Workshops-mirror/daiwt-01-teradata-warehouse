REPLACE MACRO nvb_edw.card_category
(
    p_from DATE,
    p_to DATE
)
AS
(
    DELETE FROM nvb_mart.mart_card_spend_category
    WHERE batch_id = 20250630;

    INSERT INTO nvb_mart.mart_card_spend_category
    (
        category,
        txn_count,
        spend
    )
    SELECT
        COALESCE(m.category, 'UNCLASSIFIED'),
        COUNT(t.transaction_id),
        SUM(-t.amount)
    FROM nvb_edw.fct_transaction AS t
    INNER JOIN nvb_edw.dim_merchant AS m
        ON t.merchant_id = m.merchant_id
    WHERE t.txn_date BETWEEN :p_from AND :p_to
      AND t.channel = 'CARD'
      AND t.amount < 0
      AND t.record_status_cd = 'A'
      AND m.record_status_cd = 'A'
    GROUP BY 1;
);
