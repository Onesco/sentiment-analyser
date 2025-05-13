import { Injectable } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { SentimentEntity } from '../../../libs/common/src/';
import { lastValueFrom } from 'rxjs';

const serverBaseUrl = process.env.SERVER_BASE_URL;

@Injectable()
export class WorkerService {
  constructor(
    @InjectRepository(SentimentEntity)
    private readonly sentimentRepository: Repository<SentimentEntity>,
    private readonly httpService: HttpService,
  ) {}

  async handlePubSubMessage(data: { id: string }) {
    try {
      const record = await this.sentimentRepository.findOneBy({ id: data.id });

      if (!record) {
        console.warn(`Record not found: ${data.id}`);
        return;
      }
      const resolvedUrl = new URL('/sentiment', serverBaseUrl).href;
      await lastValueFrom(
        this.httpService.post(resolvedUrl, {
          textToAnalyze: record.summary,
        }),
      );
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
