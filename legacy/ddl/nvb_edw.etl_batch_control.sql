CREATE SET TABLE nvb_edw.etl_batch_control,
    FALLBACK,
    NO BEFORE JOURNAL,
    NO AFTER JOURNAL,
    CHECKSUM = DEFAULT
(
    batch_date DATE FORMAT 'YYYY-MM-DD',
    job_name VARCHAR(30) CHARACTER SET UNICODE,
    status VARCHAR(10) CHARACTER SET UNICODE,
    row_count BIGINT,
    batch_id BIGINT NOT NULL DEFAULT 20250630,
    load_ts TIMESTAMP(0) NOT NULL DEFAULT TIMESTAMP '2025-06-30 23:00:00',
    src_system_cd VARCHAR(12) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'COREBANK' COMPRESS ('COREBANK','CLEARING','CRM'),
    record_status_cd CHAR(1) CHARACTER SET LATIN DEFAULT 'A' COMPRESS ('A','D') CHECK (record_status_cd IN ('A','D')),
    effective_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '2024-01-01',
    expiry_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '9999-12-31',
    last_step_cd VARCHAR(30) CHARACTER SET LATIN DEFAULT '10_close_batch',
    window_start_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '2024-01-01',
    window_end_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '2025-06-30',
    reject_count BIGINT DEFAULT 0 CHECK (reject_count >= 0),
    scheduler_group_cd VARCHAR(12) CHARACTER SET LATIN DEFAULT 'NVB_NIGHTLY'
)
PRIMARY INDEX (batch_date);

COMMENT ON TABLE nvb_edw.etl_batch_control IS
    'Retail banking ledger and processing records in NOK; retained for control and reporting.';
COMMENT ON COLUMN nvb_edw.etl_batch_control.batch_date IS
    'Business identifier used by nightly reconciliation and consumer joins.';
COMMENT ON COLUMN nvb_edw.etl_batch_control.batch_id IS
    'Delivery identifier assigned by overnight operations.';
COMMENT ON COLUMN nvb_edw.etl_batch_control.load_ts IS
    'Logical delivery timestamp; fixed for repeatable restarts of the same delivery.';

COLLECT STATISTICS
    COLUMN (batch_date),
    COLUMN (batch_id),
    COLUMN (src_system_cd, record_status_cd)
ON nvb_edw.etl_batch_control;
