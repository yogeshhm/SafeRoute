import { Injectable } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';

const DEMO_SCHOOL_ID = '00000000-0000-4000-8000-000000000001';
const DEMO_ROUTE_ID = '00000000-0000-4000-8000-000000000401';

type SummaryRow = {
  schools: string;
  buses: string;
  routes: string;
  stops: string;
  students: string;
  parents: string;
};

type RouteStopRow = {
  id: string;
  name: string;
  address: string | null;
  latitude: string;
  longitude: string;
  radius_meters: number;
  morning_sequence: number;
  evening_sequence: number;
  is_school: boolean;
};

type StopChildRow = {
  id: string;
  full_name: string;
  grade: string | null;
  section: string | null;
  roll_number: string | null;
  parent_name: string;
  parent_phone: string | null;
};

@Injectable()
export class DemoService {
  constructor(private readonly database: DatabaseService) {}

  async summary() {
    const result = await this.database.query<SummaryRow>(
      `
        SELECT
          (SELECT count(*) FROM schools)::text AS schools,
          (SELECT count(*) FROM buses)::text AS buses,
          (SELECT count(*) FROM routes)::text AS routes,
          (SELECT count(*) FROM route_stops)::text AS stops,
          (SELECT count(*) FROM students)::text AS students,
          (SELECT count(*) FROM users WHERE role = 'parent')::text AS parents
      `,
    );

    return result.rows[0];
  }

  async route() {
    const [school, route, stops] = await Promise.all([
      this.database.query(
        `
          SELECT id, name, address, city, state, latitude, longitude
          FROM schools
          WHERE id = $1
        `,
        [DEMO_SCHOOL_ID],
      ),
      this.database.query(
        `
          SELECT r.id, r.name, r.description, b.bus_number, b.registration_number
          FROM routes r
          LEFT JOIN buses b ON b.id = r.bus_id
          WHERE r.id = $1
        `,
        [DEMO_ROUTE_ID],
      ),
      this.database.query<RouteStopRow>(
        `
          SELECT
            id,
            name,
            address,
            latitude,
            longitude,
            radius_meters,
            morning_sequence,
            evening_sequence,
            is_school
          FROM route_stops
          WHERE route_id = $1
          ORDER BY morning_sequence ASC
        `,
        [DEMO_ROUTE_ID],
      ),
    ]);

    return {
      school: school.rows[0] ?? null,
      route: route.rows[0] ?? null,
      morningStops: stops.rows,
      eveningStops: [...stops.rows].sort((a, b) => a.evening_sequence - b.evening_sequence),
    };
  }

  async stopChildren(stopId: string) {
    const result = await this.database.query<StopChildRow>(
      `
        SELECT
          s.id,
          s.full_name,
          s.grade,
          s.section,
          s.roll_number,
          u.full_name AS parent_name,
          u.phone AS parent_phone
        FROM students s
        INNER JOIN users u ON u.id = s.parent_user_id
        WHERE s.morning_pickup_stop_id = $1
          AND s.is_active = true
        ORDER BY s.full_name ASC
      `,
      [stopId],
    );

    return {
      stopId,
      children: result.rows,
    };
  }
}

