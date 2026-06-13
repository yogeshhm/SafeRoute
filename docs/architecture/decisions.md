# Architecture Decisions

## ADR 001: Use A Monorepo

Status: Accepted

SafeRoute will use a monorepo:

```text
apps/api
apps/mobile
apps/admin
docs
infra
```

Reason:

- Easier early development.
- Shared product vocabulary.
- One place for backend, mobile, admin, and documentation.
- Easier future CI/CD setup.

## ADR 002: Use NestJS For Backend

Status: Accepted

NestJS with TypeScript is selected for the backend.

Reason:

- Strong structure for a large-scale application.
- TypeScript DTOs and services reduce ambiguity.
- Good WebSocket support.
- Good path to queues, workers, modules, and microservices later.
- Good fit with a React/Next.js admin panel.

## ADR 003: Use PostgreSQL With PostGIS

Status: Accepted

PostgreSQL + PostGIS is selected for primary data.

Reason:

- Strong relational integrity for school, student, parent, route, trip, and attendance data.
- PostGIS supports geofence radius checks for stops.
- Better long-term fit than MySQL for location-heavy workflows.

## ADR 004: Use Redis For Latest State And Queues

Status: Accepted

Redis will be used for:

- Latest bus location.
- WebSocket fanout support.
- BullMQ jobs.
- Notification queues.
- Rate limiting.

Reason:

The database should keep durable history. Redis should carry fast-changing operational state.

## ADR 005: Use Google Maps For Version 1

Status: Accepted

Google Maps is selected for Version 1.

Reason:

- Familiar and trusted parent experience.
- Strong Bengaluru road and ETA support.
- Good route and traffic data.
- Official mobile ecosystem support.

Pricing must be monitored and API keys must be restricted.

## ADR 006: Simulated Bus Before Real Bus

Status: Accepted

Version 1 development should include a demo bus simulator.

Reason:

- Allows full workflow testing before real driver onboarding.
- Tests ETA, stop arrival, boarding, drop, notifications, and live map updates.
- Reduces risk during school demo.

