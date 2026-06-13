import { IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class LocationUpdateDto {
  @IsString()
  tripId!: string;

  @IsString()
  busId!: string;

  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude!: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude!: number;

  @IsOptional()
  @IsNumber()
  speedKmph?: number;

  @IsOptional()
  @IsNumber()
  heading?: number;
}

