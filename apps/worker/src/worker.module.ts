import { Module } from '@nestjs/common';
import { WorkerService } from './worker.service';
import { DatabaseModule } from '@app/libs/database/database.module';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SentimentEntity } from '@app/libs/entities/sentiment.entity';

@Module({
  imports: [DatabaseModule, TypeOrmModule.forFeature([SentimentEntity])],
  providers: [WorkerService],
})
export class WorkerModule {}
