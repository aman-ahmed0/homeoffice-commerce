FROM python:3.13.15-alpine3.24 AS dependencies

WORKDIR /build

COPY requirements.txt .
RUN python -m pip install \
    --no-cache-dir \
    --only-binary=:all: \
    --target=/packages \
    -r requirements.txt

FROM python:3.13.15-alpine3.24 AS runtime

RUN python -m pip uninstall --yes pip \
    && rm -rf /root/.cache

WORKDIR /app

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONPATH=/packages

COPY --from=dependencies /packages /packages
COPY app.py db.py models.py ./

USER 10001:10001

EXPOSE 5000

CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "1", "--timeout", "60", "--no-control-socket", "--access-logfile", "-", "--error-logfile", "-", "app:app"]