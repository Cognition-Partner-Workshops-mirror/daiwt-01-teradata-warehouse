-- Regional branch managers: monthly operating review league.
SEL b.town, p.customer_count, p.net_amount, p.league_rank
FROM nvb_mart.mart_branch_performance p JOIN nvb_edw.dim_branch b ON p.branch_id=b.branch_id
ORDER BY p.league_rank;
