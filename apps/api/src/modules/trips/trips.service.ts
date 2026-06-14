import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { CompleteTripDto } from './dto/complete-trip.dto';
import { MarkStopChildrenDto } from './dto/mark-stop-children.dto';
import { StartTripDto } from './dto/start-trip.dto';

type TripRow = {
  id: string;
  school_id: string;
  route_id: string;
  bus_id: string;
  driver_user_id: string;
  type: string;
  status: string;
  started_at: Date | null;
  completed_at: Date | null;
};

@Injectable()
export class TripsService {
  constructor(private readonly database: DatabaseService) {}

  async startTrip(dto: StartTripDto) {
    const bus = await this.database.query<{ school_id: string }>(
      `
        SELECT school_id
        FROM buses
        WHERE id = $1
          AND driver_user_id = $2
          AND is_active = true
      `,
      [dto.busId, dto.driverId],
    );

    if (!bus.rowCount) {
      throw new BadRequestException('Driver is not assigned to this active bus.');
    }

    const activeTrip = await this.database.query<{ id: string }>(
      `
        SELECT id
        FROM trips
        WHERE bus_id = $1
          AND status = 'active'
        LIMIT 1
      `,
      [dto.busId],
    );

    if (activeTrip.rowCount) {
      throw new BadRequestException('This bus already has an active trip.');
    }

    const result = await this.database.query<TripRow>(
      `
        INSERT INTO trips (
          school_id,
          route_id,
          bus_id,
          driver_user_id,
          type,
          status,
          started_at
        )
        VALUES ($1, $2, $3, $4, $5, 'active', now())
        RETURNING *
      `,
      [bus.rows[0].school_id, dto.routeId, dto.busId, dto.driverId, dto.type],
    );

    return {
      trip: result.rows[0],
    };
  }

  async completeTrip(dto: CompleteTripDto) {
    const result = await this.database.query<TripRow>(
      `
        UPDATE trips
        SET status = 'completed',
            completed_at = now(),
            updated_at = now()
        WHERE id = $1
          AND driver_user_id = $2
          AND status = 'active'
        RETURNING *
      `,
      [dto.tripId, dto.driverId],
    );

    if (!result.rowCount) {
      throw new NotFoundException('Active trip not found for this driver.');
    }

    return {
      trip: result.rows[0],
    };
  }

  async markStopChildren(dto: MarkStopChildrenDto) {
    const trip = await this.database.query<TripRow>(
      `
        SELECT *
        FROM trips
        WHERE id = $1
          AND driver_user_id = $2
          AND status = 'active'
      `,
      [dto.tripId, dto.driverId],
    );

    if (!trip.rowCount) {
      throw new NotFoundException('Active trip not found for this driver.');
    }

    if (!dto.children.length) {
      throw new BadRequestException('At least one child must be marked.');
    }

    const values: unknown[] = [];
    const tuples = dto.children
      .map((child, index) => {
        const offset = index * 5;
        values.push(dto.tripId, child.studentId, dto.stopId, child.status, dto.driverId);
        return `($${offset + 1}, $${offset + 2}, $${offset + 3}, $${offset + 4}, $${offset + 5})`;
      })
      .join(', ');

    const result = await this.database.query(
      `
        INSERT INTO student_trip_events (
          trip_id,
          student_id,
          route_stop_id,
          status,
          marked_by_user_id
        )
        VALUES ${tuples}
        RETURNING *
      `,
      values,
    );

    return {
      tripId: dto.tripId,
      stopId: dto.stopId,
      marked: result.rows,
    };
  }

  async tripDetail(tripId: string) {
    const trip = await this.database.query<TripRow>(
      `
        SELECT *
        FROM trips
        WHERE id = $1
      `,
      [tripId],
    );

    if (!trip.rowCount) {
      throw new NotFoundException('Trip not found.');
    }

    const [locations, studentEvents] = await Promise.all([
      this.database.query(
        `
          SELECT latitude, longitude, speed_kmph, heading, recorded_at
          FROM trip_locations
          WHERE trip_id = $1
          ORDER BY recorded_at DESC
          LIMIT 20
        `,
        [tripId],
      ),
      this.database.query(
        `
          SELECT
            e.id,
            e.status,
            e.occurred_at,
            s.full_name AS student_name,
            rs.name AS stop_name
          FROM student_trip_events e
          INNER JOIN students s ON s.id = e.student_id
          LEFT JOIN route_stops rs ON rs.id = e.route_stop_id
          WHERE e.trip_id = $1
          ORDER BY e.occurred_at DESC
        `,
        [tripId],
      ),
    ]);

    return {
      trip: trip.rows[0],
      recentLocations: locations.rows,
      studentEvents: studentEvents.rows,
    };
  }
}
