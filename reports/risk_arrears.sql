-- Credit Risk: customers with impaired loan exposure.
SEL customer_id, exposure, impaired_ratio FROM nvb_mart.v_credit_risk
WHERE impaired_ratio>0 ORDER BY exposure DESC;
