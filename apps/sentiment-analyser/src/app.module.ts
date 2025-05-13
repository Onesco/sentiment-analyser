import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { DatabaseModule } from '@app/database';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SentimentEntity } from '@app/entities';
import { CacheModule } from '@nestjs/cache-manager';
import * as redisStore from 'cache-manager-ioredis';

@Module({
  imports: [
    DatabaseModule,
    TypeOrmModule.forFeature([SentimentEntity]),
    CacheModule.register({
      store: redisStore,
      host: process.env.REDIS_HOST,
      port: parseInt(process.env.REDIS_PORT || '6379', 10),
      ttl: 3600,
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
