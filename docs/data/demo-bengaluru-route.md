# Demo Bengaluru Route

This demo route is for development and product testing. It should be replaced with real school-approved route data before production.

## Demo School

Name: National Public School, Koramangala

Public address reference: Next to National Games Village, 80 Feet Road, Koramangala, Bengaluru, Karnataka 560047.

## Demo Stops

Approximate route:

```text
Morning:
HSR Layout -> Koramangala -> Indiranagar -> National Public School, Koramangala

Evening:
National Public School, Koramangala -> Indiranagar -> Koramangala -> HSR Layout
```

## Demo Coordinates

Coordinates are approximate and should be refined before a live demo.

| Type | Name | Latitude | Longitude | Radius meters |
| --- | --- | ---: | ---: | ---: |
| Pickup/Drop | HSR Layout Sector 2 | 12.9121 | 77.6446 | 250 |
| Pickup/Drop | Koramangala 5th Block | 12.9346 | 77.6192 | 250 |
| Pickup/Drop | Indiranagar 100 Feet Road | 12.9784 | 77.6408 | 250 |
| School | National Public School, Koramangala | 12.9466 | 77.6220 | 250 |

## Demo Children

| Child | Parent | Morning Pickup | Evening Drop |
| --- | --- | --- | --- |
| Aarav Sharma | Priya Sharma | HSR Layout Sector 2 | HSR Layout Sector 2 |
| Diya Rao | Kiran Rao | HSR Layout Sector 2 | HSR Layout Sector 2 |
| Meera Nair | Anjali Nair | Koramangala 5th Block | Koramangala 5th Block |
| Kabir Menon | Rohan Menon | Koramangala 5th Block | Koramangala 5th Block |
| Anaya Iyer | Kavya Iyer | Indiranagar 100 Feet Road | Indiranagar 100 Feet Road |

## Simulator Requirement

The simulator should:

- Create an active trip.
- Move a virtual bus along the route.
- Publish location updates every few seconds.
- Trigger "approaching stop" events.
- Allow simulated driver boarding/drop actions.
- Trigger parent notifications in a test channel.

