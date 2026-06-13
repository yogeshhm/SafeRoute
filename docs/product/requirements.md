# SafeRoute Product Requirements

## Product Summary

SafeRoute helps schools and parents track children safely during school transport.

The first rollout targets Bengaluru, India, with support for around 10 schools initially and a future path to many schools.

## Users

### Parent

Parents should be able to:

- See only their own child or children.
- See assigned bus and trip status.
- Receive ETA notifications for pickup and drop.
- Receive child boarded notification.
- Receive child reached school notification.
- Receive child dropped notification in the evening.
- Receive emergency alerts.

### Driver

Drivers should be able to:

- Log in securely.
- View today's assigned bus and route.
- Begin morning pickup.
- See upcoming stops in order.
- At each stop, see only children assigned to that stop.
- Mark selected children boarded, absent, or not boarded.
- Mark all present children boarded at a stop after review.
- Arrive at school and complete morning trip.
- Begin return trip.
- Mark children dropped at each assigned drop stop.
- Send emergency alert.

### Admin

Initial admin can be any SafeRoute operator.

Future roles:

- Super Admin
- Principal Admin
- Transport Manager
- Driver
- Parent

Admins should be able to:

- Create and manage schools.
- Create and manage buses.
- Create and manage drivers.
- Create and manage routes.
- Create and manage pickup/drop stops.
- Assign children to parents, buses, routes, pickup stops, and drop stops.
- View live trips.
- View trip history and attendance.
- Review notification history.

## Core Concept

Children are assigned to specific route stops.

Example:

```text
Route 1
  Stop A: HSR Layout
    Children: Aarav, Diya
  Stop B: Koramangala
    Children: Meera, Kabir
  Stop C: Indiranagar
    Children: Anaya
  School: National Public School, Koramangala
```

When the bus is approaching Stop A, only parents of children assigned to Stop A should receive the ETA notification.

When the driver reaches Stop A, the driver should see only Stop A children.

## Morning Trip Flow

1. Driver taps Begin Morning Pickup.
2. Backend creates an active morning trip.
3. Driver app begins sending GPS.
4. Backend tracks movement against route stops.
5. Parents for the next stop receive arrival ETA.
6. Driver reaches a stop.
7. Driver reviews children assigned to that stop.
8. Driver marks children boarded, absent, or not boarded.
9. Parents receive child-specific notifications.
10. Bus continues to next stop.
11. Driver marks Arrived at School.
12. Parents of onboarded children receive reached school notification.
13. Morning trip completes.

## Evening Trip Flow

1. Driver taps Begin Return Trip.
2. Backend creates an active return trip.
3. Parents receive return trip started notification.
4. Backend tracks bus toward drop stops.
5. Parents for the next drop stop receive ETA.
6. Driver reaches drop stop.
7. Driver reviews children assigned to that drop stop.
8. Driver marks children dropped or still onboard.
9. Parents receive child-specific drop notification.
10. Driver completes route and trip.

## Version 1 Notifications

- Morning pickup started.
- Bus arriving at pickup stop in approx. X minutes.
- Child boarded.
- Child marked absent.
- Child reached school.
- Return trip started.
- Child arriving at drop stop in approx. X minutes.
- Child dropped.
- Trip completed.
- Emergency alert.

## Future Features

- QR code student ID scan.
- RFID student card scan.
- Dedicated GPS hardware device in bus.
- Principal dashboard.
- Transport manager dashboard.
- Parent OTP handover confirmation.
- Route optimization.
- Fee/payment module.
- Incident reporting.
- In-app chat with school transport desk.

