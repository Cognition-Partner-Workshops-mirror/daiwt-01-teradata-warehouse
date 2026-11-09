CREATE SET TABLE nvb_edw.dim_branch,
    FALLBACK,
    NO BEFORE JOURNAL,
    NO AFTER JOURNAL,
    CHECKSUM = DEFAULT
(
    branch_id INTEGER,
    town VARCHAR(30) CHARACTER SET UNICODE NOT CASESPECIFIC,
    batch_id BIGINT NOT NULL DEFAULT 20250630,
    load_ts TIMESTAMP(0) NOT NULL DEFAULT TIMESTAMP '2025-06-30 23:00:00',
    src_system_cd VARCHAR(12) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'COREBANK' COMPRESS ('COREBANK','CLEARING','CRM'),
    record_status_cd CHAR(1) CHARACTER SET LATIN DEFAULT 'A' COMPRESS ('A','D') CHECK (record_status_cd IN ('A','D')),
    effective_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '2024-01-01',
    expiry_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '9999-12-31',
    branch_name VARCHAR(80) CHARACTER SET UNICODE NOT CASESPECIFIC DEFAULT 'Nordvik Lokalbank',
    region_cd VARCHAR(8) CHARACTER SET LATIN DEFAULT 'NORGE' COMPRESS ('NORGE'),
    branch_type_cd VARCHAR(10) CHARACTER SET LATIN DEFAULT 'RETAIL' COMPRESS ('RETAIL','ADVISORY'),
    service_language_cd CHAR(2) CHARACTER SET LATIN DEFAULT 'nb' COMPRESS ('nb','nn'),
    branch_status_cd VARCHAR(10) CHARACTER SET LATIN DEFAULT 'OPEN' COMPRESS ('OPEN','CLOSED')
)
UNIQUE PRIMARY INDEX (branch_id);

COMMENT ON TABLE nvb_edw.dim_branch IS
    'Current retail banking reference attributes; corrections overwrite the current record.';
COMMENT ON COLUMN nvb_edw.dim_branch.branch_id IS
    'Business identifier used by nightly reconciliation and consumer joins.';
COMMENT ON COLUMN nvb_edw.dim_branch.batch_id IS
    'Delivery identifier assigned by overnight operations.';
COMMENT ON COLUMN nvb_edw.dim_branch.load_ts IS
    'Logical delivery timestamp; fixed for repeatable restarts of the same delivery.';

COLLECT STATISTICS
    COLUMN (branch_id),
    COLUMN (batch_id),
    COLUMN (src_system_cd, record_status_cd)
ON nvb_edw.dim_branch;
