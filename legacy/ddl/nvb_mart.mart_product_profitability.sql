CREATE SET TABLE nvb_mart.mart_product_profitability,
    FALLBACK,
    NO BEFORE JOURNAL,
    NO AFTER JOURNAL,
    CHECKSUM = DEFAULT
(
    product_id INTEGER,
    average_balance DECIMAL(18,2),
    annual_income DECIMAL(18,2),
    batch_id BIGINT NOT NULL DEFAULT 20250630,
    load_ts TIMESTAMP(0) NOT NULL DEFAULT TIMESTAMP '2025-06-30 23:00:00',
    src_system_cd VARCHAR(12) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'COREBANK' COMPRESS ('COREBANK','CLEARING','CRM'),
    record_status_cd CHAR(1) CHARACTER SET LATIN DEFAULT 'A' COMPRESS ('A','D') CHECK (record_status_cd IN ('A','D')),
    effective_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '2024-01-01',
    expiry_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '9999-12-31'
)
PRIMARY INDEX (product_id);

COMMENT ON TABLE nvb_mart.mart_product_profitability IS
    'Published retail banking control summary; released after nightly reconciliation.';
COMMENT ON COLUMN nvb_mart.mart_product_profitability.product_id IS
    'Business identifier used by nightly reconciliation and consumer joins.';
COMMENT ON COLUMN nvb_mart.mart_product_profitability.batch_id IS
    'Delivery identifier assigned by overnight operations.';
COMMENT ON COLUMN nvb_mart.mart_product_profitability.load_ts IS
    'Logical delivery timestamp; fixed for repeatable restarts of the same delivery.';

COLLECT STATISTICS
    COLUMN (product_id),
    COLUMN (batch_id),
    COLUMN (src_system_cd, record_status_cd)
ON nvb_mart.mart_product_profitability;
