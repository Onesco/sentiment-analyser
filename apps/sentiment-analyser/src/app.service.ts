import {
  ForbiddenException,
  Inject,
  Injectable,
  InternalServerErrorException,
  Logger,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import {
  GoogleAuthError,
  VertexAI,
  ClientError,
  GenerativeModel,
} from '@google-cloud/vertexai';
import { PubSub } from '@google-cloud/pubsub';
import { SentimentEntity } from '@app/entities';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LanguageServiceClient } from '@google-cloud/language';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { Cache } from 'cache-manager';
import { Score, SentimentType } from '@app/interface';

const threshold = Number(process.env.THRESHOLD);
const TTL = Number(process.env.TTL) ?? 3600;

@Injectable()
export class AppService {
  private model: GenerativeModel;
  private pubsub: PubSub;
  private logger: Logger;
  private languageClient: LanguageServiceClient;

  constructor(
    @InjectRepository(SentimentEntity)
    private readonly sentimentRepository: Repository<SentimentEntity>,
    @Inject(CACHE_MANAGER)
    private readonly cacheManager: Cache,
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
    this.languageClient = new LanguageServiceClient();
  }

  async summarize(text: string) {
    try {
      this.logger.debug('starting summarising...', text?.substring(0, 10));
      const result = await this.model.generateContent(`Summarise: ${text}`);
      const summary =
        result.response.candidates?.[0]?.content?.parts?.[0]?.text || '';

      this.logger.debug(
        'finish summarising and saving document to database. Sumarry: ',
        summary.substring(0, 10),
      );
      const saved = await this.sentimentRepository.save({
        originalText: text,
        summary,
      });

      const response = {
        id: saved.id,
        summary: saved.summary,
        message: 'Summarization completed. Sentiment analysis in initiated.',
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

  async sentimentAnalyser(text: string) {
    try {
      const sentimentPromise = this.languageClient.analyzeSentiment({
        document: {
          content: text,
          type: 'PLAIN_TEXT',
        },
      });

      const getRecordPromise = this.sentimentRepository.findOne({
        where: { summary: text },
      });

      this.logger.debug(
        'starting quering for record and analysising for sentiment...',
        text?.substring(0, 10),
      );
      const [record, sentmentResponse] = await Promise.all([
        getRecordPromise,
        sentimentPromise,
      ]);

      const [result] = sentmentResponse;

      const sentimentSumary = result.documentSentiment;
      if (!sentimentSumary) throw new Error('No sentiment result');

      const sentiment = this.classifySentiment(sentimentSumary.score);

      this.logger.debug('updating record with the sentiment value:', sentiment);

      await this.sentimentRepository.update(
        { id: record.id },
        {
          score: sentimentSumary.score,
          magnitude: sentimentSumary.magnitude,
          sentiment,
        },
      );

      this.cacheManager.set(`sentiment_id:${record.id}`, {
        ...result,
        sentiment,
      });

      return { sentiment };
    } catch (error) {
      throw new InternalServerErrorException(error?.message);
    }
  }

  async getOneById(id: string | number) {
    const cacheKey = `sentiment_id:${id}`;
    const cached = await this.cacheManager.get(cacheKey);
    if (cached) return cached;
    const record = await this.sentimentRepository.findOneBy({
      id: id as string,
    });
    if (!record) {
      throw new NotFoundException(`Sentiment with id ${id} not found`);
    }
    const result = {
      id: record.id,
      originalText: record.originalText,
      summary: record.summary,
      sentiment: record.sentiment,
      createdAt: record.createdAt,
    };
    await this.cacheManager.set(cacheKey, result, TTL);
    return result;
  }

  private classifySentiment(score: Score) {
    if (typeof score !== 'number' || isNaN(score)) {
      return null;
    }
    if (score > threshold) {
      return SentimentType.POSITIVE;
    } else if (score < threshold) {
      return SentimentType.NEGATIVE;
    }
    return SentimentType.NEUTRAL;
  }
}
