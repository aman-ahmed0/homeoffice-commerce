# Backend

Flask product API using SQLAlchemy and PostgreSQL.

## Current runtime

The Docker image uses Python 3.11 and Gunicorn 26.2.0, runs as a non-root user,
and starts one Gunicorn worker. See `Dockerfile` for the authoritative startup
command and `requirements.txt` for dependencies.

The deployed application does not use Flask's development server.

## Endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/api/products` | Product catalogue |
| GET | `/api/products/<id>` | Individual product |
| GET | `/healthz` | HTTP health endpoint |

The health endpoint measures HTTP responsiveness, not database readiness.

## Configuration

The Helm deployment supplies `DB_HOST`, `DB_PORT`, and `FLASK_ENV` through
a ConfigMap. `POSTGRES_USER`, `POSTGRES_PASSWORD`, and `POSTGRES_DB` come
from the existing `db-secret`.

Do not reuse repository example credentials for cloud deployment.

## Startup and scaling

Application startup includes database initialization and initial product
seeding. The current deployment keeps one backend replica and one worker.

Review initialization behaviour before increasing concurrency or replicas.

`seed.py` contains a destructive database reset. It is not part of the
current runtime image and must not be used against data you need to retain.

## Deployment

Use the [Helm chart](../charts/homeoffice-commerce/) and the
[Azure infrastructure guide](../infrastructure/README.md).

See the [project roadmap](../README.md#roadmap) for upcoming automation
and operational improvements.