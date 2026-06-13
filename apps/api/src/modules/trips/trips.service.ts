import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { StartTripDto } from './dto/start-trip.dto';

@Injectable()
export class TripsService {
  startTrip(dto: StartTripDto) {
    return {
      tripId: randomUUID(),
      status: 'active',
      ...dto,
      startedAt: new Date().toISOString(),
    };
  }
}

