# SafeRoute

SafeRoute is a school bus safety and tracking platform for parents, drivers, and school administrators.

The product goal is not just live bus tracking. It is a child safety workflow:

- Drivers start and complete trips.
- Parents see only their child's assigned bus and stop.
- Children are grouped by pickup and drop stops.
- Parents receive ETA and boarding/drop notifications.
- Schools get an auditable history of trips, stops, and child movement.

## Recommended Product Surfaces

SafeRoute should be built as one platform with three user-facing surfaces and one backend service:

| Surface | User | Purpose |
| --- | --- | --- |
| Parent mobile app | Parents/guardians | Track assigned child bus, receive notifications, view trip status |
| Driver mobile app | Bus drivers/attendants | Start trips, send GPS, mark children boarded/dropped at each stop |
| Admin web panel | SafeRoute team first, school admins later | Manage schools, routes, buses, drivers, parents, students, stops, reports |
| Backend API | System service | Owns permissions, data, trip workflow, notifications, real-time updates |

This is not four separate products. It is one platform with multiple interfaces.

## Technical Direction

| Area | Choice |
| --- | --- |
| Mobile | Flutter |
| Backend | NestJS with TypeScript |
| Admin web | Next.js / React |
| Database | PostgreSQL + PostGIS |
| Cache and queues | Redis + BullMQ |
| Realtime | WebSocket gateway |
| Push notifications | Firebase Cloud Messaging |
| Maps | Google Maps Platform |
| Initial city | Bengaluru, India |

## Why This Stack

NestJS, PostgreSQL/PostGIS, Redis, and Flutter are a strong fit for a large-scale safety product:

- TypeScript helps keep APIs, events, and DTOs predictable as the project grows.
- PostgreSQL gives reliable relational data for schools, students, parents, routes, trips, and attendance.
- PostGIS supports geofencing, stop radius checks, and location queries.
- Redis supports latest bus location, queues, rate limits, and realtime fanout.
- Flutter supports both parent and driver mobile apps from one codebase.
- Google Maps gives familiar parent UX, routing, ETA, and traffic-aware features.

## Version 1 Scope

Version 1 should include:

- Multi-school data model, even if the first rollout is small.
- One admin role initially, with school principal/admin roles later.
- Driver phone GPS as the first tracking source.
- Manual boarding/drop marking by stop.
- Parent app notifications for trip, ETA, boarding, school arrival, return, and drop.
- Simulated bus route for testing before using a real bus.

## Driver Wording

Use clear and calm wording:

- Begin Morning Pickup
- Arrived at Stop
- Review Children
- Confirm Boarded
- Continue to Next Stop
- Arrived at School
- Begin Return Trip
- Confirm Dropped
- Complete Trip

Avoid rough wording like "Bus Started".

## Demo Route

Initial testing will use Bengaluru demo data:

- School: National Public School, Koramangala
- Morning route: HSR Layout -> Koramangala -> Indiranagar -> School
- Evening route: School -> Indiranagar -> Koramangala -> HSR Layout

The demo bus simulator should move from stop to stop and trigger the same events a real driver phone would trigger.

## Repository Layout

Planned monorepo layout:

```text
apps/
  api/       # NestJS backend
  mobile/    # Flutter parent + driver app
  admin/     # Next.js admin panel
docs/
  product/
  architecture/
  api/
  data/
infra/
  docker/
```

## Local Development

Install dependencies after cloning:

```bash
npm install
```

Run the API:

```bash
npm run dev:api
```

Run the admin panel:

```bash
npm run dev:admin
```

Local PostgreSQL/PostGIS and Redis config is available at:

```text
infra/docker/docker-compose.yml
```

Supabase project setup is documented at:

```text
docs/architecture/supabase-setup.md
```

Backend API endpoints are documented at:

```text
docs/api/backend-endpoints.md
```
