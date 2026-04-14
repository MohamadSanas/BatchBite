# Campus Food Delivery Backend

FastAPI backend for a campus multi-vendor food delivery platform.

## Stack

- FastAPI
- SQLAlchemy 2.0
- PostgreSQL (Supabase recommended)
- JWT auth

## Project Structure

```
backend/
  app/
    core/          # security utilities
    routes/        # API route modules
    database/      # engine/session setup
    models/        # SQLAlchemy entities
    schemas/       # pydantic request/response models
    config.py      # app settings
    deps.py        # shared auth/role dependencies
    main.py        # app factory and startup lifecycle
  requirements.txt
  .env.example
```

## Quick Start

1. Create and activate venv
2. Install deps:
   - `pip install -r requirements.txt`
3. Create env file:
   - copy `.env.example` to `.env`
4. Update `DATABASE_URL` in `.env`
5. Start API:
   - `uvicorn app.main:app --reload`

## Environment Variables

- `DATABASE_URL`: Postgres or SQLite URL
- `SECRET_KEY`: JWT signing secret
- `ALGORITHM`: JWT algorithm (default: `HS256`)
- `ACCESS_TOKEN_EXPIRE_MINUTES`: token lifetime
- `CORS_ORIGINS`: comma-separated allowed origins
- `SEED_ADMIN_EMAIL`: optional admin email for startup seeding
- `SEED_ADMIN_PASSWORD`: optional admin password for startup seeding
- `SEED_ADMIN_NAME`: optional admin display name
- `SEED_DEMO_DATA`: set `true` to seed admin/sellers/buyers and sample foods
- `DEMO_UNIVERSITY`: campus name for demo users
- `DEMO_DEFAULT_PASSWORD`: password used for demo accounts

## Supabase Connection Example

Use Session Pooler for IPv4 environments:

`postgresql+psycopg://postgres.<project_ref>:<password>@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres?sslmode=require`

## Notes

- For Supabase pooler URLs, SQLAlchemy client-side pooling is disabled in `app/database/session.py` via `NullPool`.
- Database tables are created on startup (`Base.metadata.create_all`).
- Food items support optional `image_url` at creation (`POST /food`).
- For production maturity, next step is migration-first workflow via Alembic.
