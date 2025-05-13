import { Module } from '@nestjs/common';
import { WorkerService } from './worker.service';
import { DatabaseModule } from 'libs/database/database.module';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SentimentEntity } from 'libs/entities/sentiment.entity';

@Module({
  imports: [DatabaseModule, TypeOrmModule.forFeature([SentimentEntity])],
  providers: [WorkerService],
})
export class WorkerModule {}
