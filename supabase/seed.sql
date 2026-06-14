WITH school AS (
  INSERT INTO schools (
    id,
    name,
    address,
    city,
    state,
    latitude,
    longitude
  )
  VALUES (
    '00000000-0000-4000-8000-000000000001',
    'National Public School, Koramangala',
    'Next to National Games Village, 80 Feet Road, Koramangala, Bengaluru, Karnataka 560047',
    'Bengaluru',
    'Karnataka',
    12.9466000,
    77.6220000
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    address = EXCLUDED.address,
    city = EXCLUDED.city,
    state = EXCLUDED.state,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude
  RETURNING id
),
users_seed AS (
  INSERT INTO users (id, school_id, role, full_name, phone, email)
  VALUES
    ('00000000-0000-4000-8000-000000000101', NULL, 'super_admin', 'SafeRoute Admin', '+919000000001', 'admin@saferoute.local'),
    ('00000000-0000-4000-8000-000000000102', (SELECT id FROM school), 'driver', 'Ramesh Kumar', '+919000000002', 'driver@saferoute.local'),
    ('00000000-0000-4000-8000-000000000201', (SELECT id FROM school), 'parent', 'Priya Sharma', '+919000000201', 'priya.sharma@example.local'),
    ('00000000-0000-4000-8000-000000000202', (SELECT id FROM school), 'parent', 'Kiran Rao', '+919000000202', 'kiran.rao@example.local'),
    ('00000000-0000-4000-8000-000000000203', (SELECT id FROM school), 'parent', 'Anjali Nair', '+919000000203', 'anjali.nair@example.local'),
    ('00000000-0000-4000-8000-000000000204', (SELECT id FROM school), 'parent', 'Rohan Menon', '+919000000204', 'rohan.menon@example.local'),
    ('00000000-0000-4000-8000-000000000205', (SELECT id FROM school), 'parent', 'Kavya Iyer', '+919000000205', 'kavya.iyer@example.local')
  ON CONFLICT (id) DO UPDATE SET
    school_id = EXCLUDED.school_id,
    role = EXCLUDED.role,
    full_name = EXCLUDED.full_name,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email
  RETURNING id
),
bus AS (
  INSERT INTO buses (id, school_id, driver_user_id, bus_number, registration_number, capacity)
  VALUES (
    '00000000-0000-4000-8000-000000000301',
    (SELECT id FROM school),
    '00000000-0000-4000-8000-000000000102',
    'Bus 12',
    'KA-01-SR-0012',
    40
  )
  ON CONFLICT (school_id, bus_number) DO UPDATE SET
    driver_user_id = EXCLUDED.driver_user_id,
    registration_number = EXCLUDED.registration_number,
    capacity = EXCLUDED.capacity
  RETURNING id
),
route AS (
  INSERT INTO routes (id, school_id, bus_id, name, description)
  VALUES (
    '00000000-0000-4000-8000-000000000401',
    (SELECT id FROM school),
    (SELECT id FROM bus),
    'Bengaluru Demo Route 1',
    'HSR Layout -> Koramangala -> Indiranagar -> School'
  )
  ON CONFLICT (school_id, name) DO UPDATE SET
    bus_id = EXCLUDED.bus_id,
    description = EXCLUDED.description
  RETURNING id
),
stops AS (
  INSERT INTO route_stops (
    id,
    route_id,
    name,
    address,
    latitude,
    longitude,
    radius_meters,
    morning_sequence,
    evening_sequence,
    is_school
  )
  VALUES
    ('00000000-0000-4000-8000-000000000501', (SELECT id FROM route), 'HSR Layout Sector 2', 'HSR Layout Sector 2, Bengaluru', 12.9121000, 77.6446000, 250, 1, 4, false),
    ('00000000-0000-4000-8000-000000000502', (SELECT id FROM route), 'Koramangala 5th Block', 'Koramangala 5th Block, Bengaluru', 12.9346000, 77.6192000, 250, 2, 3, false),
    ('00000000-0000-4000-8000-000000000503', (SELECT id FROM route), 'Indiranagar 100 Feet Road', 'Indiranagar 100 Feet Road, Bengaluru', 12.9784000, 77.6408000, 250, 3, 2, false),
    ('00000000-0000-4000-8000-000000000504', (SELECT id FROM route), 'National Public School, Koramangala', 'National Public School, Koramangala, Bengaluru', 12.9466000, 77.6220000, 250, 4, 1, true)
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    address = EXCLUDED.address,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    radius_meters = EXCLUDED.radius_meters,
    morning_sequence = EXCLUDED.morning_sequence,
    evening_sequence = EXCLUDED.evening_sequence,
    is_school = EXCLUDED.is_school
  RETURNING id
)
INSERT INTO students (
  id,
  school_id,
  parent_user_id,
  route_id,
  morning_pickup_stop_id,
  evening_drop_stop_id,
  full_name,
  grade,
  section,
  roll_number,
  qr_code_value
)
VALUES
  ('00000000-0000-4000-8000-000000000601', (SELECT id FROM school), '00000000-0000-4000-8000-000000000201', (SELECT id FROM route), '00000000-0000-4000-8000-000000000501', '00000000-0000-4000-8000-000000000501', 'Aarav Sharma', '3', 'A', '3A-01', 'SR-DEMO-AARAV'),
  ('00000000-0000-4000-8000-000000000602', (SELECT id FROM school), '00000000-0000-4000-8000-000000000202', (SELECT id FROM route), '00000000-0000-4000-8000-000000000501', '00000000-0000-4000-8000-000000000501', 'Diya Rao', '3', 'A', '3A-02', 'SR-DEMO-DIYA'),
  ('00000000-0000-4000-8000-000000000603', (SELECT id FROM school), '00000000-0000-4000-8000-000000000203', (SELECT id FROM route), '00000000-0000-4000-8000-000000000502', '00000000-0000-4000-8000-000000000502', 'Meera Nair', '4', 'B', '4B-03', 'SR-DEMO-MEERA'),
  ('00000000-0000-4000-8000-000000000604', (SELECT id FROM school), '00000000-0000-4000-8000-000000000204', (SELECT id FROM route), '00000000-0000-4000-8000-000000000502', '00000000-0000-4000-8000-000000000502', 'Kabir Menon', '4', 'B', '4B-04', 'SR-DEMO-KABIR'),
  ('00000000-0000-4000-8000-000000000605', (SELECT id FROM school), '00000000-0000-4000-8000-000000000205', (SELECT id FROM route), '00000000-0000-4000-8000-000000000503', '00000000-0000-4000-8000-000000000503', 'Anaya Iyer', '2', 'C', '2C-05', 'SR-DEMO-ANAYA')
ON CONFLICT (id) DO UPDATE SET
  parent_user_id = EXCLUDED.parent_user_id,
  route_id = EXCLUDED.route_id,
  morning_pickup_stop_id = EXCLUDED.morning_pickup_stop_id,
  evening_drop_stop_id = EXCLUDED.evening_drop_stop_id,
  full_name = EXCLUDED.full_name,
  grade = EXCLUDED.grade,
  section = EXCLUDED.section,
  roll_number = EXCLUDED.roll_number,
  qr_code_value = EXCLUDED.qr_code_value;

