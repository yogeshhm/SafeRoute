import { Body, Controller, Post } from '@nestjs/common';
import { StartTripDto } from './dto/start-trip.dto';
import { TripsService } from './trips.service';

@Controller('trips')
export class TripsController {
  constructor(private readonly tripsService: TripsService) {}

  @Post('start')
  startTrip(@Body() body: StartTripDto) {
    return this.tripsService.startTrip(body);
  }
}

