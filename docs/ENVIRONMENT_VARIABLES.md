# NailMyJob Environment Variables

This document lists all environment variables used by the NailMyJob application.

## Required Variables

These variables **must** be set for the application to run in production.

### Database (Supabase PostgreSQL)

Production uses **Supabase** for PostgreSQL hosting. You only need the `DATABASE_URL`.

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | Supabase connection string | `postgresql://postgres.[ref]:[pass]@aws-0-us-east-1.pooler.supabase.com:6543/postgres` |

#### Getting Your Supabase Connection String

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Settings → Database**
4. Copy the **Connection string (URI)** under "Connection pooling"

**Important Notes:**
- Use **Transaction mode (port 6543)** for Rails apps - this uses connection pooling via PgBouncer
- Use **Session mode (port 5432)** only for migrations if needed
- The app is configured with `prepared_statements: false` for PgBouncer compatibility

#### Local Development

For local development, you can still use individual variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_HOST` | PostgreSQL host | `localhost` |
| `DATABASE_PORT` | PostgreSQL port | `5432` |
| `DATABASE_USERNAME` | PostgreSQL username | `postgres` |
| `DATABASE_PASSWORD` | PostgreSQL password | `password` |

### Rails

| Variable | Description | Example |
|----------|-------------|---------|
| `SECRET_KEY_BASE` | Rails secret key (generate with `rails secret`) | `abc123...` |
| `RAILS_ENV` | Rails environment | `production` |
| `RAILS_LOG_LEVEL` | Log level | `info` |
| `RAILS_SERVE_STATIC_FILES` | Serve static files | `true` |
| `RAILS_LOG_TO_STDOUT` | Log to stdout for Docker | `true` |

### Redis

| Variable | Description | Example |
|----------|-------------|---------|
| `REDIS_URL` | Redis connection URL | `redis://redis:6379/0` |

### Application

| Variable | Description | Example |
|----------|-------------|---------|
| `APP_HOST` | Application hostname (for email links) | `app.nailmyjob.com` |

---

## Email (Mailgun)

| Variable | Description | Example |
|----------|-------------|---------|
| `MAILGUN_API_KEY` | Mailgun private API key | `key-abc123...` |
| `MAILGUN_DOMAIN` | Mailgun sending domain | `mg.nailmyjob.com` |
| `MAILGUN_SMTP_PASSWORD` | SMTP password (usually same as API key) | `key-abc123...` |
| `MAILGUN_REGION` | Mailgun region (`us` or `eu`) | `us` |
| `MAILER_FROM_ADDRESS` | Default from address | `NailMyJob <noreply@nailmyjob.com>` |

---

## AI Services (Optional)

These are optional for MVP but required for voice features.

| Variable | Description | Example |
|----------|-------------|---------|
| `OPENAI_API_KEY` | OpenAI API key for AI parsing | `sk-abc123...` |
| `DEEPGRAM_API_KEY` | Deepgram API key for voice transcription | `abc123...` |

---

## File Storage (Optional)

For production file storage (logos, PDFs, etc.).

| Variable | Description | Example |
|----------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | S3-compatible access key | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | S3-compatible secret key | `abc123...` |
| `AWS_BUCKET` | S3 bucket name | `nailmyjob-production` |
| `AWS_REGION` | S3 region | `us-east-1` |
| `AWS_ENDPOINT` | Custom S3 endpoint (for Hetzner Object Storage) | `https://fsn1.your-objectstorage.com` |

---

## Performance Tuning

| Variable | Description | Default |
|----------|-------------|---------|
| `RAILS_MAX_THREADS` | Puma threads per worker | `3` |
| `WEB_CONCURRENCY` | Puma worker processes | `2` |
| `JOB_CONCURRENCY` | Sidekiq job concurrency | `5` |
| `PORT` | Application port | `3000` |

---

## Bitwarden Secrets Manager

For automated deployments, store secrets in Bitwarden Secrets Manager with these IDs:

```
# Database (Supabase)
bws://nailmyjob/DATABASE_URL     # Full Supabase connection string

# Rails
bws://nailmyjob/SECRET_KEY_BASE

# Mailgun
bws://nailmyjob/MAILGUN_API_KEY
bws://nailmyjob/MAILGUN_DOMAIN
bws://nailmyjob/MAILGUN_SMTP_PASSWORD

# AI Services
bws://nailmyjob/OPENAI_API_KEY
bws://nailmyjob/DEEPGRAM_API_KEY

# File Storage
bws://nailmyjob/AWS_ACCESS_KEY_ID
bws://nailmyjob/AWS_SECRET_ACCESS_KEY
bws://nailmyjob/AWS_BUCKET
```

### GitHub Repository Variables

You'll also need to set these **repository variables** in GitHub (Settings → Secrets and Variables → Actions → Variables):

| Variable | Description |
|----------|-------------|
| `BWS_DATABASE_URL_ID` | Bitwarden secret ID for DATABASE_URL |
| `BWS_SECRET_KEY_BASE_ID` | Bitwarden secret ID for SECRET_KEY_BASE |
| `BWS_MAILGUN_API_KEY_ID` | Bitwarden secret ID for MAILGUN_API_KEY |
| `BWS_MAILGUN_DOMAIN_ID` | Bitwarden secret ID for MAILGUN_DOMAIN |
| `BWS_MAILGUN_SMTP_PASSWORD_ID` | Bitwarden secret ID for MAILGUN_SMTP_PASSWORD |
| `APP_HOST` | Your app domain (e.g., `app.nailmyjob.com`) |
| `MAILER_FROM_ADDRESS` | Email from address |

---

## Quick Setup

### Development

```bash
# Copy example env file
cp .env.example .env

# Edit with your values
nano .env

# Start services (uses local PostgreSQL)
docker compose up -d
```

### Production (Hetzner + Supabase)

Production uses Supabase for PostgreSQL. The deployment is automated via GitHub Actions.

**One-time setup:**

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Get your connection string from Settings → Database → Connection pooling (Transaction mode)
3. Add the connection string to Bitwarden Secrets Manager as `DATABASE_URL`
4. Add the Bitwarden secret ID as `BWS_DATABASE_URL_ID` in GitHub repository variables
5. Push to `main` branch - GitHub Actions handles the rest

**Manual deployment (if needed):**

```bash
# Set DATABASE_URL in .env file
echo "DATABASE_URL=postgresql://postgres.[ref]:[pass]@aws-0-us-east-1.pooler.supabase.com:6543/postgres" >> .env

# Deploy
docker compose -f docker-compose.production.yml up -d
```

---

## Generating Secrets

```bash
# Generate Rails secret key
docker compose run --rm web bin/rails secret

# Generate secure password
openssl rand -base64 32
```
