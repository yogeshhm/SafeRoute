# Supabase Setup

SafeRoute Supabase project:

```text
Project ref: werhuxysqewoewqsumed
Project URL: https://werhuxysqewoewqsumed.supabase.co
```

## Local CLI Status

The Supabase CLI is not installed globally on this machine yet.

Install/use the CLI when ready, then run:

```bash
supabase login
supabase link --project-ref werhuxysqewoewqsumed
supabase db push
```

If you prefer not to install globally, use the project/dev dependency flow later.

## Environment Variables

Copy `.env.example` to `.env` and fill in secret values locally.

Do not commit `.env`.

Required for backend database access:

```text
DATABASE_URL=postgresql://postgres:<PASSWORD>@db.werhuxysqewoewqsumed.supabase.co:5432/postgres
```

Required for public client access:

```text
SUPABASE_URL=https://werhuxysqewoewqsumed.supabase.co
SUPABASE_PUBLISHABLE_KEY=<publishable key>
```

## Files Added

```text
supabase/config.toml
supabase/migrations/202606140001_initial_schema.sql
supabase/seed.sql
```

## Safety

The publishable key is safe for client apps, but the database password and service role key are secrets.

Never commit:

- Database password
- `.env`
- Supabase access token
- Service role key

