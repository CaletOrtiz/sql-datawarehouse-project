FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN pip install --no-cache-dir duckdb==1.5.6

COPY gen_tpch.py run_pipeline.py ./
COPY scripts ./scripts

CMD ["python", "run_pipeline.py"]
