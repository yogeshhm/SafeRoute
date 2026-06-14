import { IsString } from 'class-validator';

export class CompleteTripDto {
  @IsString()
  tripId!: string;

  @IsString()
  driverId!: string;
}

