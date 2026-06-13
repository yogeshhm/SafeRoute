import { IsEnum, IsString } from 'class-validator';

export enum TripType {
  MorningPickup = 'morning_pickup',
  EveningDrop = 'evening_drop',
}

export class StartTripDto {
  @IsString()
  busId!: string;

  @IsString()
  driverId!: string;

  @IsString()
  routeId!: string;

  @IsEnum(TripType)
  type!: TripType;
}

