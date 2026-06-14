import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Pool, QueryResultRow } from 'pg';

@Injectable()
export class DatabaseService implements OnModuleDestroy {
  private readonly pool: Pool;

  constructor(configService: ConfigService) {
    const connectionString = configService.get<string>('DATABASE_URL');

    this.pool = new Pool({
      connectionString,
      ssl: connectionString?.includes('supabase.co')
        ? { rejectUnauthorized: false }
        : undefined,
    });
  }

  query<T extends QueryResultRow = QueryResultRow>(sql: string, values: unknown[] = []) {
    return this.pool.query<T>(sql, values);
  }

  async onModuleDestroy() {
    await this.pool.end();
  }
}

