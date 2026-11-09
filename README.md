# Nordvik Sparebank — enterprise warehouse handover

Nordvik Sparebank is a fictional Norwegian retail bank. All names, accounts,
payments and balances here are synthetic. Amounts are NOK; dates follow the
Norwegian business calendar without a holiday adjustment. The retained ledger
covers 1 January 2024 through 30 June 2025.

## Systems and ownership

Teradata 17.x hosts three databases: `nvb_stg` (landing deliveries),
`nvb_edw` (conformed dimensions, ledger facts and batch controls), and
`nvb_mart` (consumer summaries). BTEQ jobs are launched by the nightly scheduler.
DDL includes monthly ledger partitions and optimizer statistics. Database
creation, users and space allocation are administered outside this repository.

Deploy table DDL before macros, procedures and views. The overnight operations
team loads the pipe-delimited FastExport deliveries with the approved bulk-loader
mapping: skip the header, use UTF-8, and map columns in file order.
The two staging feeds are replaced, not appended. Reference dimensions and
direct upstream ledger facts are likewise replaced before job 01.
CSV and Parquet are alternate encodings of the same delivery, not two batches.
`dim_account.dormant_flag` is supplied as N and recomputed after payment loading.
Customer delivery contains 100 older records to exercise latest-record selection.
Daily balances come from the deposit ledger and are not inferred from payments.

## Nightly processing

See `legacy/schedules/nightly.yaml` and the operations runbook. The retained
control date is 2025-06-30; business-date literals and procedure arguments must
be advanced together for later deliveries. BTEQ input is rendered by the scheduler
using TD_HOST, TD_USER and TD_PASSWORD environment placeholders; do not store
credentials in rendered job files.

| Mart | Consumer | Definition |
| --- | --- | --- |
| mart_monthly_balance | Finance control | Daily mean and calendar month-end balance per account |
| mart_customer_segment | Customer insight | Trailing-year frequency, debit spend and recency tiers |
| mart_branch_performance | Regional branch operations | Customer count and net payments, ranked by value |
| mart_product_profitability | Product finance | Mean ledger balance times annual product rate |
| mart_channel_daily | Digital operations | Daily payment counts and net amounts by channel |
| mart_card_spend_category | Card services | Negative CARD amounts reported as positive spend |

Segmentation uses a trailing twelve-month inclusive window starting 2024-07-01.
No activity within 90 days means DORMANT; at least 50 payments and NOK 20,000
debit spend means PREMIUM; at least 20 payments means ACTIVE; others are
OCCASIONAL. Accounts without payments in the last six months are flagged dormant.
Profitability is an annualized indicative amount, not recognized accounting income.

## Export files and controls

Run `make setup` with Python 3.10+ to create a virtual environment, install
pinned dependencies, generate deliveries and compute reconciliation baselines
used by the nightly control checks / UAT in `golden/expected` and
`golden/summary.csv`. Run `make test` for local controls.
Exports under `data/exports/<database.table>/` are excluded from version control.
Each table has a header-bearing pipe CSV and a Parquet file; the manifest records
row counts and the CSV MD5. All random choices use a fixed seed.

`make reset` discards local deliveries and rebuilds them and the control totals.
`make reset S3=s3://bucket/prefix` additionally removes **all objects in that
prefix** and uploads the replacement delivery using AWS CLI in us-west-2.
Use only a dedicated prefix approved for these synthetic files.
For an alternate destination run
`.venv/bin/python data/generate.py --out /path/to/exports`; add `--s3 s3://bucket/prefix`
to sync without deleting existing remote objects. AWS credentials are supplied
by the operator environment.

The Python controls read the generated Parquet deliveries and implement the
same joins, time windows and calculations as the nightly SQL. They include
row counts, distinct identifiers, monetary sums, date bounds and categorical
counts. Staging controls are retained alongside every core and mart table.
Local tests do not connect to a database; Teradata deployment and runtime
validation remain an operations responsibility.

## Physical delivery contract

Core dimensions and facts carry delivery batch_id, logical load_ts, source-system
code, active/deleted status and effective/expiry dates. These are supplied for
direct ledger loads and defaulted for derived rows. The retained delivery uses
batch 20250630 and logical timestamp 2025-06-30 23:00:00 throughout; timestamps
are delivery attributes, not wall-clock execution measurements.
`data/column_defaults.json` documents the retained delivery's constant attributes
for local export production and controls. DDL defaults mirror those values.
Reference attributes include branch region, product family, card network and
merchant country. Core tables use fallback protection; transient landing tables
do not. Journaling and checksum settings follow the overnight operational profile.

Landing identifiers, amounts and dates arrive as character fields. BTEQ trims
them, standardizes decimal separators and channels, validates casts and reference
keys, then integrates typed rows. Customer updates are ordered by source timestamp
and attribute values to break ties consistently. Duplicate payment identifiers
are rejected rather than arbitrarily retained. No rejection is silently accepted:
the request log contains the offending keys and the delivery is held for review.
Create `control_reports/` in the scheduler workspace before running the jobs.
The nightly schedule records owners, deadlines, dependencies and restart scope.
