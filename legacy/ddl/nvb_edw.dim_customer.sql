CREATE SET TABLE nvb_edw.dim_customer,
    FALLBACK,
    NO BEFORE JOURNAL,
    NO AFTER JOURNAL,
    CHECKSUM = DEFAULT
(
    customer_id INTEGER,
    customer_name VARCHAR(80) CHARACTER SET UNICODE NOT CASESPECIFIC,
    branch_id INTEGER,
    town VARCHAR(30) CHARACTER SET UNICODE NOT CASESPECIFIC,
    updated_at TIMESTAMP(0),
    batch_id BIGINT NOT NULL DEFAULT 20250630,
    load_ts TIMESTAMP(0) NOT NULL DEFAULT TIMESTAMP '2025-06-30 23:00:00',
    src_system_cd VARCHAR(12) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'COREBANK' COMPRESS ('COREBANK','CLEARING','CRM'),
    record_status_cd CHAR(1) CHARACTER SET LATIN DEFAULT 'A' COMPRESS ('A','D') CHECK (record_status_cd IN ('A','D')),
    effective_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '2024-01-01',
    expiry_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '9999-12-31',
    customer_type_cd VARCHAR(12) CHARACTER SET LATIN DEFAULT 'PERSONAL' COMPRESS ('PERSONAL','BUSINESS'),
    residence_country_cd CHAR(2) CHARACTER SET LATIN DEFAULT 'NO' COMPRESS ('NO','SE','DK'),
    preferred_language_cd CHAR(2) CHARACTER SET LATIN DEFAULT 'nb' COMPRESS ('nb','nn','en'),
    kyc_status_cd VARCHAR(12) CHARACTER SET LATIN DEFAULT 'VERIFIED' COMPRESS ('VERIFIED','REVIEW'),
    consent_marketing_ind CHAR(1) CHARACTER SET LATIN DEFAULT 'N' COMPRESS ('N','Y') CHECK (consent_marketing_ind IN ('N','Y'))
)
UNIQUE PRIMARY INDEX (customer_id);

COMMENT ON TABLE nvb_edw.dim_customer IS
    'Current retail banking reference attributes; corrections overwrite the current record.';
COMMENT ON COLUMN nvb_edw.dim_customer.customer_id IS
    'Business identifier used by nightly reconciliation and consumer joins.';
COMMENT ON COLUMN nvb_edw.dim_customer.batch_id IS
    'Delivery identifier assigned by overnight operations.';
COMMENT ON COLUMN nvb_edw.dim_customer.load_ts IS
    'Logical delivery timestamp; fixed for repeatable restarts of the same delivery.';

COLLECT STATISTICS
    COLUMN (customer_id),
    COLUMN (batch_id),
    COLUMN (src_system_cd, record_status_cd)
ON nvb_edw.dim_customer;
