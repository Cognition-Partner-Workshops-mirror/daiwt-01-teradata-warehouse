CREATE SET TABLE nvb_edw.dim_merchant,
    FALLBACK,
    NO BEFORE JOURNAL,
    NO AFTER JOURNAL,
    CHECKSUM = DEFAULT
(
    merchant_id INTEGER,
    merchant_name VARCHAR(40) CHARACTER SET UNICODE NOT CASESPECIFIC,
    category VARCHAR(15) CHARACTER SET UNICODE,
    batch_id BIGINT NOT NULL DEFAULT 20250630,
    load_ts TIMESTAMP(0) NOT NULL DEFAULT TIMESTAMP '2025-06-30 23:00:00',
    src_system_cd VARCHAR(12) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'COREBANK' COMPRESS ('COREBANK','CLEARING','CRM'),
    record_status_cd CHAR(1) CHARACTER SET LATIN DEFAULT 'A' COMPRESS ('A','D') CHECK (record_status_cd IN ('A','D')),
    effective_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '2024-01-01',
    expiry_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '9999-12-31',
    country_cd CHAR(2) CHARACTER SET LATIN DEFAULT 'NO' COMPRESS ('NO','SE','DK'),
    settlement_currency_cd CHAR(3) CHARACTER SET LATIN DEFAULT 'NOK' COMPRESS ('NOK'),
    acquirer_cd VARCHAR(12) CHARACTER SET LATIN DEFAULT 'NVB' COMPRESS ('NVB'),
    merchant_status_cd VARCHAR(10) CHARACTER SET LATIN DEFAULT 'ACTIVE' COMPRESS ('ACTIVE','BLOCKED')
)
UNIQUE PRIMARY INDEX (merchant_id);

COMMENT ON TABLE nvb_edw.dim_merchant IS
    'Current retail banking reference attributes; corrections overwrite the current record.';
COMMENT ON COLUMN nvb_edw.dim_merchant.merchant_id IS
    'Business identifier used by nightly reconciliation and consumer joins.';
COMMENT ON COLUMN nvb_edw.dim_merchant.batch_id IS
    'Delivery identifier assigned by overnight operations.';
COMMENT ON COLUMN nvb_edw.dim_merchant.load_ts IS
    'Logical delivery timestamp; fixed for repeatable restarts of the same delivery.';

COLLECT STATISTICS
    COLUMN (merchant_id),
    COLUMN (batch_id),
    COLUMN (src_system_cd, record_status_cd)
ON nvb_edw.dim_merchant;
