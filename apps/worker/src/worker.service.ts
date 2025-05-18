import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SentimentEntity } from '../../../libs/common/src/entities/sentiment.entity';

@Injectable()
export class WorkerService {
  constructor(
    @InjectRepository(SentimentEntity)
    private readonly sentimentRepository: Repository<SentimentEntity>,
  ) {}

  async handlePubSubMessage(data: { id: string }) {
    console.log('received data', data);
    try {
      const record = await this.sentimentRepository.findOneBy({ id: data.id });

      if (!record) {
        console.warn(`Record not found: ${data.id}`);
        return;
      }
      const res = await fetch(`${process.env.SERVER_BASE_URL}/sentiment`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ textToAnalyze: record.summary }),
      });
      if (!res.ok) {
        throw new Error(`HTTP ${res.status}: ${await res.text()}`);
      }
      console.log(
        'successful analysed and updated record with its sentiment value. id:',
        record?.id,
      );
    } catch (error) {
      console.error('something went during sentiment processing', error);
      throw error;
    }
  }
}
