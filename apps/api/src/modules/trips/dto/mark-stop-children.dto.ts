import { IsArray, IsEnum, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export enum ChildStopStatus {
  Boarded = 'boarded',
  Absent = 'absent',
  Dropped = 'dropped',
  StillOnboard = 'still_onboard',
}

export class ChildStopMarkDto {
  @IsString()
  studentId!: string;

  @IsEnum(ChildStopStatus)
  status!: ChildStopStatus;
}

export class MarkStopChildrenDto {
  @IsString()
  tripId!: string;

  @IsString()
  stopId!: string;

  @IsString()
  driverId!: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ChildStopMarkDto)
  children!: ChildStopMarkDto[];
}

