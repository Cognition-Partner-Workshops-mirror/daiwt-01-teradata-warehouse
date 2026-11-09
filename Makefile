PY = .venv/bin/python
.PHONY: setup reset test
setup:
	python3 -m venv .venv
	.venv/bin/pip install -r requirements.txt
	$(PY) data/generate.py
	$(PY) golden/compute_baselines.py
reset:
	rm -rf data/exports
	$(PY) data/generate.py
	$(PY) golden/compute_baselines.py
	$(if $(S3),aws s3 rm "$(S3)" --recursive --region us-west-2 && aws s3 sync data/exports "$(S3)" --region us-west-2,true)
test:
	$(PY) -m pytest -q
