CREATE SET TABLE nvb_edw.dim_card,
    FALLBACK,
    NO BEFORE JOURNAL,
    NO AFTER JOURNAL,
    CHECKSUM = DEFAULT
(
    card_id INTEGER,
    account_id INTEGER,
    card_type VARCHAR(10) CHARACTER SET UNICODE COMPRESS ('DEBIT','CREDIT'),
    batch_id BIGINT NOT NULL DEFAULT 20250630,
    load_ts TIMESTAMP(0) NOT NULL DEFAULT TIMESTAMP '2025-06-30 23:00:00',
    src_system_cd VARCHAR(12) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'COREBANK' COMPRESS ('COREBANK','CLEARING','CRM'),
    record_status_cd CHAR(1) CHARACTER SET LATIN DEFAULT 'A' COMPRESS ('A','D') CHECK (record_status_cd IN ('A','D')),
    effective_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '2024-01-01',
    expiry_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '9999-12-31',
    network_cd VARCHAR(12) CHARACTER SET LATIN DEFAULT 'BANKAXEPT' COMPRESS ('BANKAXEPT','VISA'),
    card_status_cd VARCHAR(10) CHARACTER SET LATIN DEFAULT 'ACTIVE' COMPRESS ('ACTIVE','BLOCKED','EXPIRED'),
    card_expiry_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '2028-01-31',
    contactless_ind CHAR(1) CHARACTER SET LATIN DEFAULT 'Y' COMPRESS ('N','Y'),
    online_enabled_ind CHAR(1) CHARACTER SET LATIN DEFAULT 'Y' COMPRESS ('N','Y')
)
UNIQUE PRIMARY INDEX (card_id);

COMMENT ON TABLE nvb_edw.dim_card IS
    'Current retail banking reference attributes; corrections overwrite the current record.';
COMMENT ON COLUMN nvb_edw.dim_card.card_id IS
    'Business identifier used by nightly reconciliation and consumer joins.';
COMMENT ON COLUMN nvb_edw.dim_card.batch_id IS
    'Delivery identifier assigned by overnight operations.';
COMMENT ON COLUMN nvb_edw.dim_card.load_ts IS
    'Logical delivery timestamp; fixed for repeatable restarts of the same delivery.';

COLLECT STATISTICS
    COLUMN (card_id),
    COLUMN (batch_id),
    COLUMN (src_system_cd, record_status_cd)
ON nvb_edw.dim_card;
