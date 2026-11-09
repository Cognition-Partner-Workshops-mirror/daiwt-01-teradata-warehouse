CREATE MULTISET TABLE nvb_edw.fct_loan,
    FALLBACK,
    NO BEFORE JOURNAL,
    NO AFTER JOURNAL,
    CHECKSUM = DEFAULT
(
    loan_id INTEGER,
    account_id INTEGER,
    outstanding DECIMAL(18,2),
    arrears_days INTEGER,
    batch_id BIGINT NOT NULL DEFAULT 20250630,
    load_ts TIMESTAMP(0) NOT NULL DEFAULT TIMESTAMP '2025-06-30 23:00:00',
    src_system_cd VARCHAR(12) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'COREBANK' COMPRESS ('COREBANK','CLEARING','CRM'),
    record_status_cd CHAR(1) CHARACTER SET LATIN DEFAULT 'A' COMPRESS ('A','D') CHECK (record_status_cd IN ('A','D')),
    effective_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '2024-01-01',
    expiry_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '9999-12-31',
    loan_status_cd VARCHAR(10) CHARACTER SET LATIN DEFAULT 'LIVE' COMPRESS ('LIVE','CLOSED'),
    currency_cd CHAR(3) CHARACTER SET LATIN DEFAULT 'NOK' COMPRESS ('NOK'),
    contractual_rate DECIMAL(6,2) DEFAULT 5.25 CHECK (contractual_rate >= 0),
    repayment_frequency_cd VARCHAR(10) CHARACTER SET LATIN DEFAULT 'MONTHLY' COMPRESS ('MONTHLY','QUARTERLY'),
    collateral_type_cd VARCHAR(12) CHARACTER SET LATIN DEFAULT 'PROPERTY' COMPRESS ('PROPERTY','UNSECURED')
)
PRIMARY INDEX (loan_id);

COMMENT ON TABLE nvb_edw.fct_loan IS
    'Retail banking ledger and processing records in NOK; retained for control and reporting.';
COMMENT ON COLUMN nvb_edw.fct_loan.loan_id IS
    'Business identifier used by nightly reconciliation and consumer joins.';
COMMENT ON COLUMN nvb_edw.fct_loan.batch_id IS
    'Delivery identifier assigned by overnight operations.';
COMMENT ON COLUMN nvb_edw.fct_loan.load_ts IS
    'Logical delivery timestamp; fixed for repeatable restarts of the same delivery.';

COLLECT STATISTICS
    COLUMN (loan_id),
    COLUMN (batch_id),
    COLUMN (src_system_cd, record_status_cd)
ON nvb_edw.fct_loan;
