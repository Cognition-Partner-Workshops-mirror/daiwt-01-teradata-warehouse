CREATE SET TABLE nvb_mart.mart_customer_segment,
    FALLBACK,
    NO BEFORE JOURNAL,
    NO AFTER JOURNAL,
    CHECKSUM = DEFAULT
(
    customer_id INTEGER,
    txn_count INTEGER,
    spend DECIMAL(18,2),
    last_txn_date DATE FORMAT 'YYYY-MM-DD',
    segment VARCHAR(12) CHARACTER SET UNICODE,
    batch_id BIGINT NOT NULL DEFAULT 20250630,
    load_ts TIMESTAMP(0) NOT NULL DEFAULT TIMESTAMP '2025-06-30 23:00:00',
    src_system_cd VARCHAR(12) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'COREBANK' COMPRESS ('COREBANK','CLEARING','CRM'),
    record_status_cd CHAR(1) CHARACTER SET LATIN DEFAULT 'A' COMPRESS ('A','D') CHECK (record_status_cd IN ('A','D')),
    effective_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '2024-01-01',
    expiry_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '9999-12-31'
)
PRIMARY INDEX (customer_id);

COMMENT ON TABLE nvb_mart.mart_customer_segment IS
    'Published retail banking control summary; released after nightly reconciliation.';
COMMENT ON COLUMN nvb_mart.mart_customer_segment.customer_id IS
    'Business identifier used by nightly reconciliation and consumer joins.';
COMMENT ON COLUMN nvb_mart.mart_customer_segment.batch_id IS
    'Delivery identifier assigned by overnight operations.';
COMMENT ON COLUMN nvb_mart.mart_customer_segment.load_ts IS
    'Logical delivery timestamp; fixed for repeatable restarts of the same delivery.';

COLLECT STATISTICS
    COLUMN (customer_id),
    COLUMN (batch_id),
    COLUMN (src_system_cd, record_status_cd)
ON nvb_mart.mart_customer_segment;
