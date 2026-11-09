import hashlib
import importlib.util
import json
from pathlib import Path
import re

import pandas as pd
import pyarrow.parquet as pq
import pytest

ROOT = Path(__file__).resolve().parents[1]


def load(path):
    spec = importlib.util.spec_from_file_location(path.stem, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


generator = load(ROOT / "data/generate.py")
controls = load(ROOT / "golden/compute_baselines.py")


def test_generator_determinism(tmp_path, monkeypatch):
    sample = {"nvb_edw.dim_branch": pd.DataFrame({"branch_id": [1, 2], "town": ["Voss", "Alta"]})}
    monkeypatch.setattr(generator, "frames", lambda: sample)
    generator.generate(tmp_path / "first")
    generator.generate(tmp_path / "second")
    first = {str(p.relative_to(tmp_path / "first")): p.read_bytes() for p in (tmp_path / "first").rglob("*") if p.is_file()}
    second = {str(p.relative_to(tmp_path / "second")): p.read_bytes() for p in (tmp_path / "second").rglob("*") if p.is_file()}
    assert first == second


def test_manifest_and_inputs():
    manifest = json.loads((ROOT / "data/exports/_manifest.json").read_text())
    counts = {entry["table"]: entry["rows"] for entry in manifest}
    for entry in manifest:
        name = entry["table"]
        folder = ROOT / "data/exports" / name
        assert len(pd.read_parquet(folder / f"{name}.parquet")) == entry["rows"]
        assert hashlib.md5((folder / f"{name}.csv").read_bytes()).hexdigest() == entry["md5"]
    for path in (ROOT / "golden/expected").glob("*.json"):
        assert json.loads(path.read_text())["input_rows"] == counts


def test_every_table_has_control():
    defined = set()
    for path in (ROOT / "legacy/ddl").glob("*.sql"):
        defined.update(re.findall(r"CREATE\s+(?:SET|MULTISET)\s+TABLE\s+(\w+\.\w+)", path.read_text(), re.I))
    actual = {p.stem for p in (ROOT / "golden/expected").glob("*.json")}
    assert defined == actual
    assert len(defined) == 20


def test_sql_references():
    definitions = "\n".join(p.read_text() for folder in ("ddl", "views", "macros", "procs") for p in (ROOT / "legacy" / folder).glob("*.sql"))
    defined = set(re.findall(r"(?:TABLE|VIEW|MACRO|PROCEDURE)\s+(nvb_\w+\.\w+)", definitions, re.I))
    for folder in ("bteq", "macros", "procs", "views"):
        for path in (ROOT / "legacy" / folder).glob("*"):
            references = set(re.findall(r"nvb_\w+\.\w+", path.read_text(), re.I))
            assert references <= defined, (path, references - defined)


def test_reconciliation_repeatable(tmp_path):
    controls.compute(ROOT / "data/exports", tmp_path)
    assert (tmp_path / "summary.csv").read_bytes() == (ROOT / "golden/summary.csv").read_bytes()
    for p in (tmp_path / "expected").glob("*.json"):
        assert p.read_bytes() == (ROOT / "golden/expected" / p.name).read_bytes()


def test_empty_metrics():
    result = controls.metrics(pd.DataFrame({"account_id": pd.Series(dtype="int64"), "txn_date": pd.Series(dtype="str"), "amount": pd.Series(dtype="float64")}))
    assert result["rows"] == 0
    assert result["distinct"]["account_id"] == 0
    assert result["sums"]["amount"] == 0
    assert result["dates"]["txn_date"] == {"min": None, "max": None}


def test_missing_delivery(tmp_path):
    with pytest.raises(ValueError, match="No upstream exports"):
        controls.compute(tmp_path, tmp_path / "controls")


def test_business_controls():
    def record(name):
        return json.loads((ROOT / "golden/expected" / f"{name}.json").read_text())
    assert record("nvb_edw.dim_customer")["rows"] == 5000
    assert record("nvb_edw.fct_transaction")["rows"] == 180000
    assert record("nvb_edw.dim_account")["dormant_flag_counts"]["Y"] >= 100
    assert sum(record("nvb_mart.mart_customer_segment")["segment_counts"].values()) == 5000
    assert record("nvb_mart.mart_channel_daily")["sums"]["txn_count"] == 180000
    assert record("nvb_mart.mart_monthly_balance")["rows"] == 8000 * 18


@pytest.fixture
def payment():
    return pd.DataFrame([{
        "transaction_id": " 1 ", "account_id": " 7 ", "txn_date": "2025-06-30",
        "amount": " -12,50 ", "channel": " mobile ", "merchant_id": "3",
    }])


def clean_payment(frame):
    return controls.clean_payments(
        frame, pd.DataFrame({"account_id": [7]}), pd.DataFrame({"merchant_id": [3]})
    )


def test_payment_cleansing(payment):
    result = clean_payment(payment)
    assert result.iloc[0].to_dict() == {
        "transaction_id": 1, "account_id": 7, "txn_date": "2025-06-30",
        "amount": -12.5, "channel": "MOBILE", "merchant_id": 3,
    }
    payment["channel"] = ""
    assert clean_payment(payment).channel.tolist() == ["ONLINE"]


def test_payment_empty_delivery(payment):
    assert clean_payment(payment.iloc[:0]).empty


@pytest.mark.parametrize(("column", "value", "message"), [
    ("transaction_id", "0", "Invalid payment identifier"),
    ("account_id", "999", "Unmatched account"),
    ("merchant_id", "999", "Unmatched merchant"),
    ("channel", "ATM", "Unrecognized payment channel"),
    ("txn_date", "2023-12-31", "outside retained window"),
    ("amount", "bad", "Unable to parse"),
])
def test_payment_rejections(payment, column, value, message):
    payment[column] = value
    with pytest.raises(ValueError, match=message):
        clean_payment(payment)


def test_duplicate_payment_rejected(payment):
    with pytest.raises(ValueError, match="Duplicate transaction"):
        clean_payment(pd.concat([payment, payment], ignore_index=True))


def test_customer_latest_record_and_tie_order():
    source = pd.DataFrame([
        ["1", " Ola\u00a0Nordli ", "1", " Voss ", "2024-01-01 00:00:00"],
        ["1", "Ola Solheim", "1", "Alta", "2025-06-30 20:00:00"],
        ["1", "Ola Vik", "1", "Alta", "2025-06-30 20:00:00"],
    ], columns=["customer_id", "customer_name", "branch_id", "town", "updated_at"])
    result = controls.clean_customers(source, pd.DataFrame({"branch_id": [1]}))
    assert len(result) == 1
    assert result.iloc[0].customer_name == "Ola Vik"
    source["branch_id"] = "99"
    with pytest.raises(ValueError, match="Unmatched branch"):
        controls.clean_customers(source, pd.DataFrame({"branch_id": [1]}))


def test_physical_delivery_contract():
    defaults = json.loads((ROOT / "data/column_defaults.json").read_text())
    for path in (ROOT / "legacy/ddl").glob("*.sql"):
        text = path.read_text()
        columns = re.findall(r"^    ([a-z_]\w*)\s", text, re.M)
        if path.stem.startswith("nvb_edw."):
            assert 10 <= len(columns) <= 25
        if path.stem in defaults:
            assert set(defaults[path.stem]) <= set(columns)
        folder = ROOT / "data/exports" / path.stem
        if folder.exists():
            assert pq.read_schema(folder / f"{path.stem}.parquet").names == columns
    for path in (ROOT / "legacy/bteq").glob("*.btq"):
        assert 40 <= len(path.read_text().splitlines()) <= 120
        assert ".LABEL rejected" in path.read_text()
        assert ".LABEL failed" in path.read_text()
    for folder in ("macros", "procs"):
        for path in (ROOT / "legacy" / folder).glob("*.sql"):
            assert 25 <= len(path.read_text().splitlines()) <= 80
