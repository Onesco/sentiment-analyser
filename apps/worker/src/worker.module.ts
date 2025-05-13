import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { WorkerService } from './worker.service';
import { DatabaseModule } from '../../../libs/common/src/';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SentimentEntity } from '../../../libs/common/src/';

@Module({
  imports: [
    DatabaseModule,
    HttpModule,
    TypeOrmModule.forFeature([SentimentEntity]),
  ],
  providers: [WorkerService],
})
export class WorkerModule {}
