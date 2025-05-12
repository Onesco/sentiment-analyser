import {
  ForbiddenException,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import {
  GoogleAuthError,
  VertexAI,
  ClientError,
  GenerativeModel,
} from '@google-cloud/vertexai';
import { PubSub } from '@google-cloud/pubsub';
import { SentimentEntity } from './entities/sentiment.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

@Injectable()
export class AppService {
  private model: GenerativeModel;
  private pubsub: PubSub;
  private logger: Logger;

  constructor(
    @InjectRepository(SentimentEntity)
    private readonly summariseRepo: Repository<SentimentEntity>,
  ) {
    const vertexAI = new VertexAI({
      project: process.env.GOOGLE_PROJECT_ID,
      location: process.env.REGION,
    });
    this.pubsub = new PubSub();

    this.model = vertexAI.getGenerativeModel({
      model: 'gemini-2.0-flash-001',
    });
    this.logger = new Logger(AppService.name);
  }

  async summarize(text: string) {
    try {
      const result = await this.model.generateContent(`Summarise: ${text}`);
      const summary =
        result.response.candidates?.[0]?.content?.parts?.[0]?.text || '';

      const saved = await this.summariseRepo.save({
        originalText: text,
        summary,
      });

      const response = {
        id: saved.id,
        summary: saved.summary,
        message: 'Summarization completed. Setiment analysis in initiated.',
      };

      this.pubsub
        .topic(process.env.PUBSUB_TOPIC)
        .publishMessage({ data: Buffer.from(JSON.stringify(saved.id)) });

      return response;
    } catch (error) {
      if (error instanceof GoogleAuthError) {
        throw new UnauthorizedException('Authentication failed');
      } else if (error instanceof ClientError) {
        throw new ForbiddenException(error.message);
      }
      throw error;
    }
  }
}
