CREATE MULTISET TABLE nvb_edw.fct_transaction,
    FALLBACK,
    NO BEFORE JOURNAL,
    NO AFTER JOURNAL,
    CHECKSUM = DEFAULT
(
    transaction_id BIGINT,
    account_id INTEGER,
    txn_date DATE FORMAT 'YYYY-MM-DD',
    amount DECIMAL(18,2),
    channel VARCHAR(10) CHARACTER SET UNICODE,
    merchant_id INTEGER,
    batch_id BIGINT NOT NULL DEFAULT 20250630,
    load_ts TIMESTAMP(0) NOT NULL DEFAULT TIMESTAMP '2025-06-30 23:00:00',
    src_system_cd VARCHAR(12) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'COREBANK' COMPRESS ('COREBANK','CLEARING','CRM'),
    record_status_cd CHAR(1) CHARACTER SET LATIN DEFAULT 'A' COMPRESS ('A','D') CHECK (record_status_cd IN ('A','D')),
    effective_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '2024-01-01',
    expiry_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '9999-12-31',
    currency_cd CHAR(3) CHARACTER SET LATIN DEFAULT 'NOK' COMPRESS ('NOK'),
    posting_status_cd VARCHAR(10) CHARACTER SET LATIN DEFAULT 'POSTED' COMPRESS ('POSTED','PENDING'),
    reversal_ind CHAR(1) CHARACTER SET LATIN DEFAULT 'N' COMPRESS ('N','Y'),
    clearing_scheme_cd VARCHAR(12) CHARACTER SET LATIN DEFAULT 'DOMESTIC' COMPRESS ('DOMESTIC','CROSSBORDER')
)
PRIMARY INDEX (transaction_id)
PARTITION BY RANGE_N(txn_date BETWEEN DATE '2024-01-01' AND DATE '2025-06-30' EACH INTERVAL '1' MONTH);

COMMENT ON TABLE nvb_edw.fct_transaction IS
    'Retail banking ledger and processing records in NOK; retained for control and reporting.';
COMMENT ON COLUMN nvb_edw.fct_transaction.transaction_id IS
    'Business identifier used by nightly reconciliation and consumer joins.';
COMMENT ON COLUMN nvb_edw.fct_transaction.batch_id IS
    'Delivery identifier assigned by overnight operations.';
COMMENT ON COLUMN nvb_edw.fct_transaction.load_ts IS
    'Logical delivery timestamp; fixed for repeatable restarts of the same delivery.';

COLLECT STATISTICS
    COLUMN (transaction_id),
    COLUMN (batch_id),
    COLUMN (src_system_cd, record_status_cd)
ON nvb_edw.fct_transaction;
