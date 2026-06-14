import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule } from './database/database.module';
import { DemoModule } from './demo/demo.module';
import { HealthModule } from './health/health.module';
import { TrackingModule } from './tracking/tracking.module';
import { TripsModule } from './trips/trips.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    DatabaseModule,
    HealthModule,
    DemoModule,
    TripsModule,
    TrackingModule,
  ],
})
export class AppModule {}
