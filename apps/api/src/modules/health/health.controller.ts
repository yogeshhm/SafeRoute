import { Controller, Get } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';

@Controller('health')
export class HealthController {
  constructor(private readonly database: DatabaseService) {}

  @Get()
  async health() {
    await this.database.query('SELECT 1');

    return {
      ok: true,
      service: 'saferoute-api',
      database: 'ok',
    };
  }
}
