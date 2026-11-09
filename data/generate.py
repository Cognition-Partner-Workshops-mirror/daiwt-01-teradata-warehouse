"""Produce synthetic upstream FastExport deliveries in NOK."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

import numpy as np
import pandas as pd


def frames():
    rng = np.random.default_rng(1704)
    dates = pd.date_range("2024-01-01", "2025-06-30")
    towns = ["Bergen", "Tromso", "Bodo", "Voss", "Arendal", "Molde", "Alta", "Hamar"]
    first = ["Kari", "Ola", "Ingrid", "Lars", "Signe", "Eirik", "Astrid", "Nils"]
    last = ["Nordli", "Bergvik", "Solheim", "Dahl", "Lund", "Vik", "Haug", "Strand"]
    result = {}
    result["nvb_edw.dim_branch"] = pd.DataFrame({"branch_id": range(1, 9), "town": towns})
    result["nvb_edw.dim_product"] = pd.DataFrame({"product_id": range(1, 5), "product_name": ["Brukskonto", "Sparekonto", "Boliglan", "Kredittkort"], "annual_rate": [1.5, 3.5, 5.25, 19.9]})
    customer = pd.DataFrame({"customer_id": range(1, 5001), "customer_name": [f"{first[i % 8]} {last[(i // 8) % 8]} {i:04d}" for i in range(5000)], "branch_id": rng.integers(1, 9, 5000), "town": rng.choice(towns, 5000), "updated_at": ["2025-06-30 20:00:00"] * 5000})
    old = customer.iloc[:100].copy()
    old["updated_at"] = "2024-01-01 00:00:00"
    old["town"] = "Voss"
    result["nvb_stg.customer_feed"] = pd.concat([old, customer], ignore_index=True)
    result["nvb_edw.dim_account"] = pd.DataFrame({"account_id": range(1, 8001), "customer_id": np.concatenate([np.arange(1, 5001), rng.integers(1, 5001, 3000)]), "product_id": rng.integers(1, 5, 8000), "opened_date": ["2024-01-01"] * 8000, "dormant_flag": ["N"] * 8000})
    result["nvb_edw.dim_card"] = pd.DataFrame({"card_id": range(1, 6001), "account_id": range(1, 6001), "card_type": rng.choice(["DEBIT", "CREDIT"], 6000)})
    result["nvb_edw.dim_merchant"] = pd.DataFrame({"merchant_id": range(1, 81), "merchant_name": [f"Nordhandel {i:03d}" for i in range(1, 81)], "category": np.resize(["GROCERY", "TRAVEL", "FUEL", "RETAIL"], 80)})
    result["nvb_edw.dim_calendar"] = pd.DataFrame({"calendar_date": dates.strftime("%Y-%m-%d"), "month_start": dates.to_period("M").to_timestamp().strftime("%Y-%m-%d"), "year_no": dates.year, "month_no": dates.month})
    n = 180000
    txn = pd.DataFrame({"transaction_id": range(1, n + 1), "account_id": rng.integers(1, 7901, n), "txn_date": rng.choice(dates.strftime("%Y-%m-%d"), n), "amount": rng.integers(-250000, 350001, n) / 100, "channel": rng.choice(["CARD", "MOBILE", "BRANCH", "ONLINE"], n), "merchant_id": rng.integers(1, 81, n)})
    result["nvb_stg.transaction_feed"] = txn
    # Daily ledger snapshots are independent of the payment-clearing delivery.
    result["nvb_edw.fct_daily_balance"] = pd.DataFrame({"account_id": np.repeat(np.arange(1, 8001), len(dates)), "balance_date": np.tile(dates.strftime("%Y-%m-%d"), 8000), "balance": rng.integers(-500000, 80000000, 8000 * len(dates)) / 100})
    result["nvb_edw.fct_loan"] = pd.DataFrame({"loan_id": range(1, 1801), "account_id": range(1, 1801), "outstanding": rng.integers(10000000, 450000000, 1800) / 100, "arrears_days": rng.choice([0, 0, 0, 15, 35, 95], 1800)})
    result["nvb_edw.fct_product_order"] = pd.DataFrame({"order_id": range(1, 3501), "customer_id": rng.integers(1, 5001, 3500), "product_id": rng.integers(1, 5, 3500), "order_date": rng.choice(dates.strftime("%Y-%m-%d"), 3500), "status": rng.choice(["APPROVED", "DECLINED", "PENDING"], 3500)})
    defaults = json.loads((Path(__file__).with_name("column_defaults.json")).read_text())
    for table, frame in result.items():
        if table.startswith("nvb_stg."):
            for column in frame:
                if column == "amount":
                    frame[column] = frame[column].map(lambda value: f"{value:.2f}")
                else:
                    frame[column] = frame[column].astype(str)
        else:
            for column, value in defaults[table].items():
                frame[column] = value
    return result


def generate(out):
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    manifest = []
    for table, frame in sorted(frames().items()):
        folder = out / table
        folder.mkdir(exist_ok=True)
        csv = folder / f"{table}.csv"
        frame.to_csv(csv, sep="|", index=False, float_format="%.2f", lineterminator="\n")
        frame.to_parquet(folder / f"{table}.parquet", index=False, compression="snappy")
        manifest.append({"table": table, "rows": len(frame), "md5": hashlib.md5(csv.read_bytes()).hexdigest()})
    (out / "_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Exported {len(manifest)} upstream tables to {out}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="data/exports")
    parser.add_argument("--s3")
    args = parser.parse_args()
    generate(args.out)
    if args.s3:
        if not args.s3.startswith("s3://") or not args.s3[5:].strip("/"):
            parser.error("--s3 requires s3://bucket/prefix")
        subprocess.run(["aws", "s3", "sync", args.out, args.s3, "--region", "us-west-2"], check=True)
