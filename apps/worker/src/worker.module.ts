import { Module } from '@nestjs/common';
import { WorkerService } from './worker.service';
import { DatabaseModule } from '../../../libs/common/src/database/database.module';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SentimentEntity } from '../../../libs/common/src/entities/sentiment.entity';

@Module({
  imports: [DatabaseModule, TypeOrmModule.forFeature([SentimentEntity])],
  providers: [WorkerService],
})
export class WorkerModule {}
