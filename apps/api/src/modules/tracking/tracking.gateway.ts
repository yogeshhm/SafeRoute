import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server } from 'socket.io';
import { DatabaseService } from '../database/database.service';
import { LocationUpdateDto } from './dto/location-update.dto';

@WebSocketGateway({
  cors: {
    origin: true,
    credentials: true,
  },
})
export class TrackingGateway {
  constructor(private readonly database: DatabaseService) {}

  @WebSocketServer()
  server!: Server;

  @SubscribeMessage('driver.location.updated')
  async handleLocationUpdate(@MessageBody() payload: LocationUpdateDto) {
    const event = {
      ...payload,
      recordedAt: new Date().toISOString(),
    };

    await this.database.query(
      `
        INSERT INTO trip_locations (
          trip_id,
          bus_id,
          latitude,
          longitude,
          speed_kmph,
          heading,
          recorded_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7)
      `,
      [
        payload.tripId,
        payload.busId,
        payload.latitude,
        payload.longitude,
        payload.speedKmph ?? null,
        payload.heading ?? null,
        event.recordedAt,
      ],
    );

    this.server.to(`trip:${payload.tripId}`).emit('bus.location.updated', event);

    return {
      ok: true,
      event,
    };
  }
}
