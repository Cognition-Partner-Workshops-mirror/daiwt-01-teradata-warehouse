# Night operator runbook

All times are Europe/Oslo. Confirm the deposit-ledger and payment-clearing
deliveries share the business date before releasing job 01. Replace upstream
tables using the approved bulk loader; retain manifest counts in the batch log.
Run table DDL only during installation; deploy macros/procedures before BTEQ.

Render environment placeholders in a protected scheduler workspace. Stop on
any nonzero BTEQ return code; do not release dependent jobs. Empty SELECT/INSERT
activity is logged by BTEQ's standard activity report. Compare controls before
publishing the reporting connection to consumers.

Restart: reload all upstream deliveries for the control date, then rerun jobs
01 through 10 in order. All summary builds replace their content. Do not run
two copies concurrently. After a failure during a delete/insert build, treat the
mart as unavailable until its rebuild succeeds. Job 10 records the payment count
only after all earlier jobs pass. Preserve the prior reporting snapshot until
reconciliation is approved. Escalate mismatches to Finance Control and Data Ops.

## Delivery and control state

The scheduler creates a protected control_reports directory before opening BTEQ.
Capture standard output and ERROROUT in the request log. Job 02 exports payment
count, amount and date bounds; job 10 exports the release-state row. Retain these
files with the manifest and the Finance Control approval for 400 days.

The single NIGHTLY row in etl_batch_control is the delivery-level state, not a
job-history table. Each step looks it up, registers it if missing, marks RUNNING
and records last_step_cd. Only job 10 may set COMPLETE. A failed request sets
FAILED; the scheduler must prevent concurrent requests using nvb_nightly_exclusive.
The scheduler request log is the authoritative per-job execution history.
There is no automatic skip based solely on a previous COMPLETE row.

Code 12 indicates a rejected delivery or failed SQL request; code 99 indicates
that the failure-state update itself failed. In either case hold downstream jobs.
Validation SELECTs print offending keys in the retained request log before
branching to the rejection label. No invalid rows are silently discarded.
Restore the same input files and restart at the failed job only when all earlier
outputs remain intact; otherwise restart at job 01. Do not advance the control
date, batch identifier or logical load timestamp during a same-delivery restart.

Payment and product-summary replacements use explicit BT/ET boundaries.
Summary macros replace their requested date or delivery slice as one request.
Procedure rebuilds can leave an unavailable slice on failure: keep the reporting
connection on its previously approved snapshot until successful rerun.
Never release a partly rebuilt population because a later check happened to pass.

The six-month dormancy cutoff uses ADD_MONTHS, not a fixed 180-day interval.
At the retained control date the inclusive first recent-payment date is
2024-12-31. Segmentation starts 2024-07-01 and regards dates before 2025-04-01
as stale. Finance requires every day including calendar month-end in each
account-month before monthly balances can be published.
