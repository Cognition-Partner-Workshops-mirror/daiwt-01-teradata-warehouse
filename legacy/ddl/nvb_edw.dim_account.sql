CREATE SET TABLE nvb_edw.dim_account,
    FALLBACK,
    NO BEFORE JOURNAL,
    NO AFTER JOURNAL,
    CHECKSUM = DEFAULT
(
    account_id INTEGER,
    customer_id INTEGER,
    product_id INTEGER,
    opened_date DATE FORMAT 'YYYY-MM-DD',
    dormant_flag CHAR(1) CHARACTER SET LATIN COMPRESS ('N','Y'),
    batch_id BIGINT NOT NULL DEFAULT 20250630,
    load_ts TIMESTAMP(0) NOT NULL DEFAULT TIMESTAMP '2025-06-30 23:00:00',
    src_system_cd VARCHAR(12) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'COREBANK' COMPRESS ('COREBANK','CLEARING','CRM'),
    record_status_cd CHAR(1) CHARACTER SET LATIN DEFAULT 'A' COMPRESS ('A','D') CHECK (record_status_cd IN ('A','D')),
    effective_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '2024-01-01',
    expiry_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '9999-12-31',
    currency_cd CHAR(3) CHARACTER SET LATIN DEFAULT 'NOK' COMPRESS ('NOK'),
    account_status_cd VARCHAR(10) CHARACTER SET LATIN DEFAULT 'OPEN' COMPRESS ('OPEN','BLOCKED','CLOSED'),
    accrual_basis_cd VARCHAR(8) CHARACTER SET LATIN DEFAULT 'ACT365' COMPRESS ('ACT365','ACT360'),
    overdraft_limit DECIMAL(18,2) DEFAULT 0.00 CHECK (overdraft_limit >= 0)
)
UNIQUE PRIMARY INDEX (account_id);

COMMENT ON TABLE nvb_edw.dim_account IS
    'Current retail banking reference attributes; corrections overwrite the current record.';
COMMENT ON COLUMN nvb_edw.dim_account.account_id IS
    'Business identifier used by nightly reconciliation and consumer joins.';
COMMENT ON COLUMN nvb_edw.dim_account.batch_id IS
    'Delivery identifier assigned by overnight operations.';
COMMENT ON COLUMN nvb_edw.dim_account.load_ts IS
    'Logical delivery timestamp; fixed for repeatable restarts of the same delivery.';

COLLECT STATISTICS
    COLUMN (account_id),
    COLUMN (batch_id),
    COLUMN (src_system_cd, record_status_cd)
ON nvb_edw.dim_account;
