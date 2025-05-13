import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { DatabaseModule } from '../../../libs/database/database.module';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SentimentEntity } from '../../../libs/entities/sentiment.entity';
import { CacheModule } from '@nestjs/cache-manager';
import * as redisStore from 'cache-manager-ioredis';

@Module({
  imports: [
    DatabaseModule,
    TypeOrmModule.forFeature([SentimentEntity]),
    CacheModule.register({
      store: redisStore,
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379', 10),
      ttl: 3600,
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}