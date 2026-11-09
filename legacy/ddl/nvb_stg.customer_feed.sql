CREATE MULTISET TABLE nvb_stg.customer_feed,
    NO FALLBACK,
    NO BEFORE JOURNAL,
    NO AFTER JOURNAL,
    CHECKSUM = DEFAULT
(
    customer_id VARCHAR(80) CHARACTER SET UNICODE NOT CASESPECIFIC,
    customer_name VARCHAR(160) CHARACTER SET UNICODE NOT CASESPECIFIC,
    branch_id VARCHAR(80) CHARACTER SET UNICODE NOT CASESPECIFIC,
    town VARCHAR(80) CHARACTER SET UNICODE NOT CASESPECIFIC,
    updated_at VARCHAR(26) CHARACTER SET UNICODE NOT CASESPECIFIC
)
NO PRIMARY INDEX;

COMMENT ON TABLE nvb_stg.customer_feed IS
    'Retained upstream landing delivery; replace before the nightly integration run.';
COMMENT ON COLUMN nvb_stg.customer_feed.customer_id IS
    'Raw upstream identifier; casting and validation occur in the integration job.';

COLLECT STATISTICS COLUMN (customer_id) ON nvb_stg.customer_feed;
