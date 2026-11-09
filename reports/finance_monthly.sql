-- Finance Control: monthly deposit totals for the management pack.
SEL month_start, SUM(closing_balance) closing_balance, SUM(average_balance) average_balance
FROM nvb_mart.mart_monthly_balance
WHERE EXTRACT(YEAR FROM month_start)=2025 GROUP BY 1 ORDER BY 1;
