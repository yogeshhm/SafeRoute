import { Controller, Get, Param } from '@nestjs/common';
import { DemoService } from './demo.service';

@Controller('demo')
export class DemoController {
  constructor(private readonly demoService: DemoService) {}

  @Get('summary')
  summary() {
    return this.demoService.summary();
  }

  @Get('route')
  route() {
    return this.demoService.route();
  }

  @Get('stops/:stopId/children')
  stopChildren(@Param('stopId') stopId: string) {
    return this.demoService.stopChildren(stopId);
  }
}

