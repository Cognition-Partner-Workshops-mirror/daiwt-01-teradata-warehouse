CREATE SET TABLE nvb_edw.dim_product,
    FALLBACK,
    NO BEFORE JOURNAL,
    NO AFTER JOURNAL,
    CHECKSUM = DEFAULT
(
    product_id INTEGER,
    product_name VARCHAR(30) CHARACTER SET UNICODE NOT CASESPECIFIC,
    annual_rate DECIMAL(6,2),
    batch_id BIGINT NOT NULL DEFAULT 20250630,
    load_ts TIMESTAMP(0) NOT NULL DEFAULT TIMESTAMP '2025-06-30 23:00:00',
    src_system_cd VARCHAR(12) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'COREBANK' COMPRESS ('COREBANK','CLEARING','CRM'),
    record_status_cd CHAR(1) CHARACTER SET LATIN DEFAULT 'A' COMPRESS ('A','D') CHECK (record_status_cd IN ('A','D')),
    effective_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '2024-01-01',
    expiry_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '9999-12-31',
    product_family_cd VARCHAR(12) CHARACTER SET LATIN DEFAULT 'RETAIL' COMPRESS ('RETAIL'),
    currency_cd CHAR(3) CHARACTER SET LATIN DEFAULT 'NOK' COMPRESS ('NOK'),
    product_status_cd VARCHAR(10) CHARACTER SET LATIN DEFAULT 'LIVE' COMPRESS ('LIVE','WITHDRAWN'),
    rate_basis_cd VARCHAR(8) CHARACTER SET LATIN DEFAULT 'ACT365' COMPRESS ('ACT365','ACT360'),
    minimum_balance DECIMAL(18,2) DEFAULT 0.00 CHECK (minimum_balance >= 0)
)
UNIQUE PRIMARY INDEX (product_id);

COMMENT ON TABLE nvb_edw.dim_product IS
    'Current retail banking reference attributes; corrections overwrite the current record.';
COMMENT ON COLUMN nvb_edw.dim_product.product_id IS
    'Business identifier used by nightly reconciliation and consumer joins.';
COMMENT ON COLUMN nvb_edw.dim_product.batch_id IS
    'Delivery identifier assigned by overnight operations.';
COMMENT ON COLUMN nvb_edw.dim_product.load_ts IS
    'Logical delivery timestamp; fixed for repeatable restarts of the same delivery.';

COLLECT STATISTICS
    COLUMN (product_id),
    COLUMN (batch_id),
    COLUMN (src_system_cd, record_status_cd)
ON nvb_edw.dim_product;
