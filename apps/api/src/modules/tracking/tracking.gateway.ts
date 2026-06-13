import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server } from 'socket.io';
import { LocationUpdateDto } from './dto/location-update.dto';

@WebSocketGateway({
  cors: {
    origin: true,
    credentials: true,
  },
})
export class TrackingGateway {
  @WebSocketServer()
  server!: Server;

  @SubscribeMessage('driver.location.updated')
  handleLocationUpdate(@MessageBody() payload: LocationUpdateDto) {
    const event = {
      ...payload,
      recordedAt: new Date().toISOString(),
    };

    this.server.to(`trip:${payload.tripId}`).emit('bus.location.updated', event);

    return {
      ok: true,
      event,
    };
  }
}

