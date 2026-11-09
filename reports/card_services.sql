-- Card Services: category mix of cleared card debits.
SEL category, txn_count, spend, spend/NULLIFZERO(SUM(spend) OVER ()) share_of_spend
FROM nvb_mart.mart_card_spend_category ORDER BY spend DESC;
