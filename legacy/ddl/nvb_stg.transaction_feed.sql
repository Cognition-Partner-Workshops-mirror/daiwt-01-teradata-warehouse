CREATE MULTISET TABLE nvb_stg.transaction_feed,
    NO FALLBACK,
    NO BEFORE JOURNAL,
    NO AFTER JOURNAL,
    CHECKSUM = DEFAULT
(
    transaction_id VARCHAR(80) CHARACTER SET UNICODE NOT CASESPECIFIC,
    account_id VARCHAR(80) CHARACTER SET UNICODE NOT CASESPECIFIC,
    txn_date VARCHAR(80) CHARACTER SET UNICODE NOT CASESPECIFIC,
    amount VARCHAR(80) CHARACTER SET UNICODE NOT CASESPECIFIC,
    channel VARCHAR(80) CHARACTER SET UNICODE NOT CASESPECIFIC,
    merchant_id VARCHAR(80) CHARACTER SET UNICODE NOT CASESPECIFIC
)
NO PRIMARY INDEX;

COMMENT ON TABLE nvb_stg.transaction_feed IS
    'Retained upstream landing delivery; replace before the nightly integration run.';
COMMENT ON COLUMN nvb_stg.transaction_feed.transaction_id IS
    'Raw upstream identifier; casting and validation occur in the integration job.';

COLLECT STATISTICS COLUMN (transaction_id) ON nvb_stg.transaction_feed;
