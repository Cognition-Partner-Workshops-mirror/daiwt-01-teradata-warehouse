CREATE MULTISET TABLE nvb_edw.fct_product_order,
    FALLBACK,
    NO BEFORE JOURNAL,
    NO AFTER JOURNAL,
    CHECKSUM = DEFAULT
(
    order_id INTEGER,
    customer_id INTEGER,
    product_id INTEGER,
    order_date DATE FORMAT 'YYYY-MM-DD',
    status VARCHAR(10) CHARACTER SET UNICODE,
    batch_id BIGINT NOT NULL DEFAULT 20250630,
    load_ts TIMESTAMP(0) NOT NULL DEFAULT TIMESTAMP '2025-06-30 23:00:00',
    src_system_cd VARCHAR(12) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'COREBANK' COMPRESS ('COREBANK','CLEARING','CRM'),
    record_status_cd CHAR(1) CHARACTER SET LATIN DEFAULT 'A' COMPRESS ('A','D') CHECK (record_status_cd IN ('A','D')),
    effective_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '2024-01-01',
    expiry_date DATE FORMAT 'YYYY-MM-DD' DEFAULT DATE '9999-12-31',
    application_channel_cd VARCHAR(10) CHARACTER SET LATIN DEFAULT 'ONLINE' COMPRESS ('ONLINE','BRANCH','MOBILE'),
    decision_system_cd VARCHAR(12) CHARACTER SET LATIN DEFAULT 'RETAIL_RULES',
    currency_cd CHAR(3) CHARACTER SET LATIN DEFAULT 'NOK' COMPRESS ('NOK'),
    manual_review_ind CHAR(1) CHARACTER SET LATIN DEFAULT 'N' COMPRESS ('N','Y')
)
PRIMARY INDEX (order_id);

COMMENT ON TABLE nvb_edw.fct_product_order IS
    'Retail banking ledger and processing records in NOK; retained for control and reporting.';
COMMENT ON COLUMN nvb_edw.fct_product_order.order_id IS
    'Business identifier used by nightly reconciliation and consumer joins.';
COMMENT ON COLUMN nvb_edw.fct_product_order.batch_id IS
    'Delivery identifier assigned by overnight operations.';
COMMENT ON COLUMN nvb_edw.fct_product_order.load_ts IS
    'Logical delivery timestamp; fixed for repeatable restarts of the same delivery.';

COLLECT STATISTICS
    COLUMN (order_id),
    COLUMN (batch_id),
    COLUMN (src_system_cd, record_status_cd)
ON nvb_edw.fct_product_order;
