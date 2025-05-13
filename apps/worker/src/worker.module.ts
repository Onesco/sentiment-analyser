import { Module } from '@nestjs/common';
import { WorkerService } from './worker.service';
import { DatabaseModule } from '@app/database';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SentimentEntity } from '@app/entities';

@Module({
  imports: [DatabaseModule, TypeOrmModule.forFeature([SentimentEntity])],
  providers: [WorkerService],
})
export class WorkerModule {}
