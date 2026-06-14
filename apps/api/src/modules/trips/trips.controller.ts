import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { CompleteTripDto } from './dto/complete-trip.dto';
import { MarkStopChildrenDto } from './dto/mark-stop-children.dto';
import { StartTripDto } from './dto/start-trip.dto';
import { TripsService } from './trips.service';

@Controller('trips')
export class TripsController {
  constructor(private readonly tripsService: TripsService) {}

  @Post('start')
  startTrip(@Body() body: StartTripDto) {
    return this.tripsService.startTrip(body);
  }

  @Post('complete')
  completeTrip(@Body() body: CompleteTripDto) {
    return this.tripsService.completeTrip(body);
  }

  @Post('mark-stop-children')
  markStopChildren(@Body() body: MarkStopChildrenDto) {
    return this.tripsService.markStopChildren(body);
  }

  @Get(':tripId')
  tripDetail(@Param('tripId') tripId: string) {
    return this.tripsService.tripDetail(tripId);
  }
}
