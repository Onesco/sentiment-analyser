import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { SentimentType } from '@app/interface';

describe('AppController', () => {
  let appController: AppController;
  let appService: AppService;

  const mockAppService = {
    getOneById: jest
      .fn()
      .mockResolvedValue({ id: '123', text: 'sample result' }),
    sentimentAnalyser: jest
      .fn()
      .mockResolvedValue({ sentiment: 'positive' as SentimentType }),
    summarize: jest.fn().mockResolvedValue({ summary: 'short summary' }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [{ provide: AppService, useValue: mockAppService }],
    }).compile();

    appController = module.get<AppController>(AppController);
    appService = module.get<AppService>(AppService);
  });

  describe('getOneById', () => {
    it('should return result by ID', async () => {
      const result = await appController.getOneById('123');
      expect(result).toEqual({ id: '123', text: 'sample result' });
      expect(appService.getOneById).toHaveBeenCalledWith('123');
    });
  });

  describe('getSentiment', () => {
    it('should return sentiment result', async () => {
      const result = await appController.getSentiment({
        textToAnalyze: 'This is amazing',
      });
      expect(result).toEqual({ sentiment: 'positive' });
      expect(appService.sentimentAnalyser).toHaveBeenCalledWith(
        'This is amazing',
      );
    });
  });

  describe('summarize', () => {
    it('should return summarized text', async () => {
      const result = await appController.summarize({
        text: 'Long text here...',
      });
      expect(result).toEqual({ summary: 'short summary' });
      expect(appService.summarize).toHaveBeenCalledWith('Long text here...');
    });
  });
});
