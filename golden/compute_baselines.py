"""Nightly control checks and UAT reconciliation baselines."""
import argparse
from decimal import Decimal, ROUND_HALF_UP
import json
from pathlib import Path

import numpy as np
import pandas as pd


def money(value):
    return float(value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))


def ledger_means(frame, keys):
    work = frame.assign(cents=(frame.balance * 100).round().astype("int64"))
    totals = work.groupby(keys).cents.agg(["sum", "count"]).reset_index()
    totals["exact_mean"] = [Decimal(int(s)) / Decimal(int(n)) / 100 for s, n in zip(totals["sum"], totals["count"])]
    return totals[keys + ["exact_mean"]]


def clean_customers(frame, branches):
    customer = frame.copy()
    for col in ("customer_id", "branch_id"):
        customer[col] = pd.to_numeric(customer[col].str.strip(), errors="raise").astype("int64")
    for col in ("customer_name", "town"):
        customer[col] = customer[col].str.replace("\u00a0", " ", regex=False).str.strip()
    if (customer.customer_id <= 0).any() or customer.customer_name.fillna("").eq("").any():
        raise ValueError("Invalid customer identifier or name")
    if not customer.branch_id.isin(branches.branch_id).all():
        raise ValueError("Unmatched branch in customer delivery")
    customer["updated_at"] = customer.updated_at.str.strip()
    if pd.to_datetime(customer.updated_at, format="%Y-%m-%d %H:%M:%S", errors="raise").isna().any():
        raise ValueError("Missing customer update timestamp")
    return customer.sort_values(["updated_at", "customer_name", "town", "branch_id"]).drop_duplicates("customer_id", keep="last").reset_index(drop=True)


def clean_payments(frame, accounts, merchants):
    t = frame.copy()
    for col in ("transaction_id", "account_id", "merchant_id"):
        t[col] = pd.to_numeric(t[col].str.strip(), errors="raise").astype("int64")
    t["amount"] = pd.to_numeric(t.amount.str.replace(",", ".", regex=False).str.strip(), errors="raise")
    t["channel"] = t.channel.str.strip().str.upper().replace("", "ONLINE").fillna("ONLINE")
    t["txn_date"] = t.txn_date.str.strip()
    pd.to_datetime(t.txn_date, format="%Y-%m-%d", errors="raise")
    if not t.txn_date.between("2024-01-01", "2025-06-30").all():
        raise ValueError("Payment date outside retained window")
    if (t.transaction_id <= 0).any() or t.amount.isna().any():
        raise ValueError("Invalid payment identifier or amount")
    t["amount"] = t.amount.map(lambda value: money(Decimal(str(value))))
    if t.transaction_id.duplicated().any():
        raise ValueError("Duplicate transaction identifier in delivery")
    if not t.account_id.isin(accounts.account_id).all():
        raise ValueError("Unmatched account in payment delivery")
    if not t.merchant_id.isin(merchants.merchant_id).all():
        raise ValueError("Unmatched merchant in payment delivery")
    if not t.channel.isin(["CARD", "MOBILE", "BRANCH", "ONLINE"]).all():
        raise ValueError("Unrecognized payment channel")
    return t


def transform(source):
    tables = {k: v.copy() for k, v in source.items()}
    def get(name):
        return tables["nvb_edw." + name]
    c = clean_customers(tables["nvb_stg.customer_feed"], get("dim_branch"))
    tables["nvb_edw.dim_customer"] = c
    t = clean_payments(tables["nvb_stg.transaction_feed"], get("dim_account"), get("dim_merchant"))
    tables["nvb_edw.fct_transaction"] = t
    a = get("dim_account")
    recent = t.loc[t.txn_date.between("2024-12-31", "2025-06-30"), "account_id"]
    a["dormant_flag"] = np.where(a.account_id.isin(recent), "N", "Y")
    b = get("fct_daily_balance")
    monthly = b[["account_id", "balance_date", "balance"]].assign(month_start=b.balance_date.str[:7] + "-01")
    coverage = monthly.groupby(["account_id", "month_start"]).balance_date.agg(["size", "max"]).reset_index()
    month_end = pd.to_datetime(coverage.month_start) + pd.offsets.MonthEnd(0)
    if not coverage["max"].eq(month_end.dt.strftime("%Y-%m-%d")).all() or not coverage["size"].eq(month_end.dt.day).all():
        raise ValueError("Incomplete daily ledger month")
    if not b.account_id.isin(a.account_id).all():
        raise ValueError("Unmatched account in daily ledger")
    avg = ledger_means(monthly, ["account_id", "month_start"])
    avg["average_balance"] = avg.exact_mean.map(money)
    avg = avg.drop(columns="exact_mean")
    closing = monthly.sort_values("balance_date").groupby(["account_id", "month_start"], as_index=False).tail(1)[["account_id", "month_start", "balance"]].rename(columns={"balance": "closing_balance"})
    m = avg.merge(closing)
    tables["nvb_mart.mart_monthly_balance"] = m
    year = t[t.txn_date.between("2024-07-01", "2025-06-30")].merge(a[["account_id", "customer_id"]])
    year["spend"] = (-year.amount).clip(lower=0)
    seg = year.groupby("customer_id").agg(txn_count=("transaction_id", "size"), spend=("spend", "sum"), last_txn_date=("txn_date", "max")).reset_index()
    seg = c[["customer_id"]].merge(seg, how="left").fillna({"txn_count": 0, "spend": 0})
    seg["segment"] = np.select([seg.last_txn_date.isna() | (seg.last_txn_date < "2025-04-01"), (seg.txn_count >= 50) & (seg.spend >= 20000), seg.txn_count >= 20], ["DORMANT", "PREMIUM", "ACTIVE"], default="OCCASIONAL")
    tables["nvb_mart.mart_customer_segment"] = seg
    branch = t.merge(a[["account_id", "customer_id"]]).merge(c[["customer_id", "branch_id"]])
    net = branch.groupby("branch_id").amount.sum()
    league = c.groupby("branch_id").customer_id.nunique().to_frame("customer_count").join(net.rename("net_amount")).fillna(0).reset_index()
    league["league_rank"] = league.net_amount.rank(method="min", ascending=False).astype(int)
    tables["nvb_mart.mart_branch_performance"] = league
    profit = ledger_means(b.merge(a[["account_id", "product_id"]]), ["product_id"]).merge(get("dim_product"))
    profit["annual_income"] = [money(mean * Decimal(str(rate)) / 100) for mean, rate in zip(profit.exact_mean, profit.annual_rate)]
    profit["average_balance"] = profit.exact_mean.map(money)
    tables["nvb_mart.mart_product_profitability"] = profit[["product_id", "average_balance", "annual_income"]].copy()
    tables["nvb_mart.mart_channel_daily"] = t.groupby(["txn_date", "channel"]).agg(txn_count=("transaction_id", "size"), net_amount=("amount", "sum")).reset_index()
    card = t[(t.channel == "CARD") & (t.amount < 0)].merge(get("dim_merchant"))
    card["spend"] = -card.amount
    tables["nvb_mart.mart_card_spend_category"] = card.groupby("category").agg(txn_count=("transaction_id", "size"), spend=("spend", "sum")).reset_index()
    tables["nvb_edw.etl_batch_control"] = pd.DataFrame([{"batch_date": "2025-06-30", "job_name": "NIGHTLY", "status": "COMPLETE", "row_count": len(t)}])
    defaults = json.loads((Path(__file__).resolve().parents[1] / "data/column_defaults.json").read_text())
    for table, values in defaults.items():
        for column, value in values.items():
            if column not in tables[table]:
                tables[table][column] = value
    return tables


def metrics(frame):
    result = {"rows": len(frame), "distinct": {}, "sums": {}, "dates": {}}
    for col in frame:
        values = frame[col]
        if col.endswith("_id"):
            result["distinct"][col] = int(values.nunique())
        elif pd.api.types.is_numeric_dtype(values):
            result["sums"][col] = round(float(values.sum()), 2)
        elif col.endswith("_date") or col in ("month_start", "calendar_date", "load_ts", "updated_at"):
            clean = values.dropna()
            result["dates"][col] = {"min": str(clean.min()) if len(clean) else None, "max": str(clean.max()) if len(clean) else None}
        if col in ("segment", "dormant_flag", "status", "channel", "category") or col.endswith(("_cd", "_ind")):
            result[col + "_counts"] = {str(k): int(v) for k, v in sorted(values.value_counts().items())}
    return result


def compute(exports, out):
    exports, out = Path(exports), Path(out)
    source = {p.parent.name: pd.read_parquet(p) for p in sorted(exports.glob("*/*.parquet"))}
    if not source:
        raise ValueError("No upstream exports found")
    tables = transform(source)
    expected = out / "expected"
    expected.mkdir(parents=True, exist_ok=True)
    rows = []
    for name, frame in sorted(tables.items()):
        record = metrics(frame)
        record["table"] = name
        record["input_rows"] = {k: len(v) for k, v in sorted(source.items())}
        (expected / f"{name}.json").write_text(json.dumps(record, indent=2, sort_keys=True, allow_nan=False) + "\n")
        rows.append({"table": name, "rows": len(frame)})
    pd.DataFrame(rows).to_csv(out / "summary.csv", index=False, lineterminator="\n")
    print(f"Wrote {len(rows)} reconciliation baselines to {out}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--exports", default="data/exports")
    parser.add_argument("--out", default="golden")
    args = parser.parse_args()
    compute(args.exports, args.out)
