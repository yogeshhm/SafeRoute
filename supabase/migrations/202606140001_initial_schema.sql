CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

CREATE TYPE user_role AS ENUM (
  'super_admin',
  'school_admin',
  'principal',
  'transport_manager',
  'driver',
  'parent'
);

CREATE TYPE trip_type AS ENUM (
  'morning_pickup',
  'evening_drop'
);

CREATE TYPE trip_status AS ENUM (
  'scheduled',
  'active',
  'completed',
  'cancelled'
);

CREATE TYPE stop_event_type AS ENUM (
  'approaching',
  'arrived',
  'departed'
);

CREATE TYPE student_trip_status AS ENUM (
  'pending',
  'boarded',
  'absent',
  'reached_school',
  'dropped',
  'still_onboard'
);

CREATE TYPE notification_status AS ENUM (
  'queued',
  'sent',
  'failed'
);

CREATE TABLE schools (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  name text NOT NULL,
  address text NOT NULL,
  city text NOT NULL,
  state text NOT NULL,
  country text NOT NULL DEFAULT 'India',
  latitude numeric(10, 7) NOT NULL,
  longitude numeric(10, 7) NOT NULL,
  location extensions.geography(Point, 4326) GENERATED ALWAYS AS (
    extensions.ST_SetSRID(extensions.ST_MakePoint(longitude, latitude), 4326)::extensions.geography
  ) STORED,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  school_id uuid REFERENCES schools(id) ON DELETE SET NULL,
  auth_user_id uuid UNIQUE,
  role user_role NOT NULL,
  full_name text NOT NULL,
  phone text,
  email text UNIQUE,
  device_token text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE buses (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  school_id uuid NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  driver_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  bus_number text NOT NULL,
  registration_number text,
  capacity integer NOT NULL CHECK (capacity > 0),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (school_id, bus_number)
);

CREATE TABLE routes (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  school_id uuid NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  bus_id uuid REFERENCES buses(id) ON DELETE SET NULL,
  name text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (school_id, name)
);

CREATE TABLE route_stops (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  route_id uuid NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  name text NOT NULL,
  address text,
  latitude numeric(10, 7) NOT NULL,
  longitude numeric(10, 7) NOT NULL,
  location extensions.geography(Point, 4326) GENERATED ALWAYS AS (
    extensions.ST_SetSRID(extensions.ST_MakePoint(longitude, latitude), 4326)::extensions.geography
  ) STORED,
  radius_meters integer NOT NULL DEFAULT 250 CHECK (radius_meters > 0),
  morning_sequence integer NOT NULL,
  evening_sequence integer NOT NULL,
  is_school boolean NOT NULL DEFAULT false,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (route_id, morning_sequence),
  UNIQUE (route_id, evening_sequence)
);

CREATE TABLE students (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  school_id uuid NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  parent_user_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  route_id uuid NOT NULL REFERENCES routes(id) ON DELETE RESTRICT,
  morning_pickup_stop_id uuid NOT NULL REFERENCES route_stops(id) ON DELETE RESTRICT,
  evening_drop_stop_id uuid NOT NULL REFERENCES route_stops(id) ON DELETE RESTRICT,
  full_name text NOT NULL,
  grade text,
  section text,
  roll_number text,
  qr_code_value text UNIQUE,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE trips (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  school_id uuid NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  route_id uuid NOT NULL REFERENCES routes(id) ON DELETE RESTRICT,
  bus_id uuid NOT NULL REFERENCES buses(id) ON DELETE RESTRICT,
  driver_user_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  type trip_type NOT NULL,
  status trip_status NOT NULL DEFAULT 'scheduled',
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE trip_locations (
  id bigserial PRIMARY KEY,
  trip_id uuid NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  bus_id uuid NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
  latitude numeric(10, 7) NOT NULL,
  longitude numeric(10, 7) NOT NULL,
  location extensions.geography(Point, 4326) GENERATED ALWAYS AS (
    extensions.ST_SetSRID(extensions.ST_MakePoint(longitude, latitude), 4326)::extensions.geography
  ) STORED,
  speed_kmph numeric(6, 2),
  heading numeric(6, 2),
  recorded_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE trip_stop_events (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  trip_id uuid NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  route_stop_id uuid NOT NULL REFERENCES route_stops(id) ON DELETE RESTRICT,
  event_type stop_event_type NOT NULL,
  eta_seconds integer,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE student_trip_events (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  trip_id uuid NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  route_stop_id uuid REFERENCES route_stops(id) ON DELETE RESTRICT,
  status student_trip_status NOT NULL,
  marked_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  school_id uuid NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  recipient_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  trip_id uuid REFERENCES trips(id) ON DELETE SET NULL,
  student_id uuid REFERENCES students(id) ON DELETE SET NULL,
  title text NOT NULL,
  body text NOT NULL,
  status notification_status NOT NULL DEFAULT 'queued',
  provider_message_id text,
  sent_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_schools_location ON schools USING gist (location);
CREATE INDEX idx_users_school_role ON users (school_id, role);
CREATE INDEX idx_buses_school ON buses (school_id);
CREATE INDEX idx_routes_school ON routes (school_id);
CREATE INDEX idx_route_stops_route_sequence ON route_stops (route_id, morning_sequence, evening_sequence);
CREATE INDEX idx_route_stops_location ON route_stops USING gist (location);
CREATE INDEX idx_students_school ON students (school_id);
CREATE INDEX idx_students_parent ON students (parent_user_id);
CREATE INDEX idx_students_stops ON students (morning_pickup_stop_id, evening_drop_stop_id);
CREATE INDEX idx_trips_status ON trips (school_id, status, type);
CREATE INDEX idx_trip_locations_trip_recorded ON trip_locations (trip_id, recorded_at DESC);
CREATE INDEX idx_trip_locations_location ON trip_locations USING gist (location);
CREATE INDEX idx_student_trip_events_trip_student ON student_trip_events (trip_id, student_id, occurred_at DESC);
CREATE INDEX idx_notifications_recipient ON notifications (recipient_user_id, created_at DESC);

