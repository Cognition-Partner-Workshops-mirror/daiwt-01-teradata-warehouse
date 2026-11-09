CREATE SET TABLE nvb_mart.mart_channel_daily,
    FALLBACK,
    NO BEFORE JOURNAL,
    NO AFTER JOURNAL,
    CHECKSUM = DEFAULT
(
    txn_date DATE FORMAT 'YYYY-MM-DD',
    channel VARCHAR(10) CHARACTER SET UNICODE,
    txn_count INTEGER,
    net_amount DECIMAL(18,2),
    batch_id BIGINT NOT NULL DEFAULT 20250630,
    load_ts TIMESTAMP(0) NOT NULL DEFAULT TIMESTAMP '2025-06-30 23:00:00',
    src_system_cd VARCHAR(12) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'COREBANK' COMPRESS ('COREBANK','CLEARING','CRM'),
    record_status_cd CHAR(1) CHARACTER SET LATIN DEFAULT 'A' COMPRESS ('A','D') CHECK (record_status_cd IN ('A','D')),
    effective_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '2024-01-01',
    expiry_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '9999-12-31'
)
PRIMARY INDEX (txn_date);

COMMENT ON TABLE nvb_mart.mart_channel_daily IS
    'Published retail banking control summary; released after nightly reconciliation.';
COMMENT ON COLUMN nvb_mart.mart_channel_daily.txn_date IS
    'Business identifier used by nightly reconciliation and consumer joins.';
COMMENT ON COLUMN nvb_mart.mart_channel_daily.batch_id IS
    'Delivery identifier assigned by overnight operations.';
COMMENT ON COLUMN nvb_mart.mart_channel_daily.load_ts IS
    'Logical delivery timestamp; fixed for repeatable restarts of the same delivery.';

COLLECT STATISTICS
    COLUMN (txn_date),
    COLUMN (batch_id),
    COLUMN (src_system_cd, record_status_cd)
ON nvb_mart.mart_channel_daily;
