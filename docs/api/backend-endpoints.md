# Backend Endpoints

Base path:

```text
/api
```

## Health

```http
GET /api/health
```

Checks API and database connectivity.

## Demo Data

```http
GET /api/demo/summary
```

Returns counts for demo schools, buses, routes, stops, students, and parents.

```http
GET /api/demo/route
```

Returns the Bengaluru demo school, route, morning stops, and evening stops.

```http
GET /api/demo/stops/:stopId/children
```

Returns children assigned to a specific pickup stop.

## Trips

```http
POST /api/trips/start
```

Driver begins a trip.

Body:

```json
{
  "busId": "00000000-0000-4000-8000-000000000301",
  "driverId": "00000000-0000-4000-8000-000000000102",
  "routeId": "00000000-0000-4000-8000-000000000401",
  "type": "morning_pickup"
}
```

```http
POST /api/trips/mark-stop-children
```

Driver marks children at a stop as boarded, absent, dropped, or still onboard.

Body:

```json
{
  "tripId": "<active-trip-id>",
  "stopId": "00000000-0000-4000-8000-000000000501",
  "driverId": "00000000-0000-4000-8000-000000000102",
  "children": [
    {
      "studentId": "00000000-0000-4000-8000-000000000601",
      "status": "boarded"
    }
  ]
}
```

```http
GET /api/trips/:tripId
```

Returns trip details, recent GPS locations, and student trip events.

```http
POST /api/trips/complete
```

Driver completes an active trip.

Body:

```json
{
  "tripId": "<active-trip-id>",
  "driverId": "00000000-0000-4000-8000-000000000102"
}
```

## Realtime Tracking

Socket event from driver app:

```text
driver.location.updated
```

Payload:

```json
{
  "tripId": "<active-trip-id>",
  "busId": "00000000-0000-4000-8000-000000000301",
  "latitude": 12.9121,
  "longitude": 77.6446,
  "speedKmph": 24,
  "heading": 82
}
```

Broadcast event for parent/admin clients:

```text
bus.location.updated
```

