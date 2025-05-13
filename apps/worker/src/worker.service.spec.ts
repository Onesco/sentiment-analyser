import { Test, TestingModule } from '@nestjs/testing';
import { WorkerService } from './worker.service';
import { HttpService } from '@nestjs/axios';
import { SentimentEntity } from '../../../libs/common/src/';
import { getRepositoryToken } from '@nestjs/typeorm';
import { AxiosResponse } from 'axios';
import { of } from 'rxjs';

xdescribe('WorkerService', () => {
  let service: WorkerService;
  let httpService: HttpService;
  let repoMock: any;

  beforeEach(async () => {
    repoMock = {
      findOneBy: jest.fn(),
    };

    const httpMock = {
      post: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WorkerService,
        {
          provide: getRepositoryToken(SentimentEntity),
          useValue: repoMock,
        },
        {
          provide: HttpService,
          useValue: httpMock,
        },
      ],
    }).compile();

    service = module.get<WorkerService>(WorkerService);
    httpService = module.get<HttpService>(HttpService);
  });

  it('should skip if record not found', async () => {
    repoMock.findOneBy.mockResolvedValue(null);

    const result = await service.handlePubSubMessage({ id: '4' });

    expect(repoMock.findOneBy).toHaveBeenCalledWith({ id: '4' });
    expect(result).toBeUndefined();
  });

  it('should send sentiment to endpoint if record found', async () => {
    const fakeRecord = { id: '4', summary: 'this is a test' };
    repoMock.findOneBy.mockResolvedValue(fakeRecord);

    const mockResponse: AxiosResponse = {
      data: 'ok',
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {
        headers: undefined,
      },
    };

    httpService.post = jest.fn(() => of(mockResponse));

    await service.handlePubSubMessage({ id: '4' });

    expect(httpService.post).toHaveBeenCalledWith(
      expect.stringContaining('/sentiment'),
      { textToAnalyze: 'this is a test' },
    );
  });

  it('should throw and log if request fails', async () => {
    const fakeRecord = { id: '4', summary: 'this is a test' };
    repoMock.findOneBy.mockResolvedValue(fakeRecord);

    httpService.post = jest.fn(() => {
      throw new Error('HTTP error');
    });

    await expect(service.handlePubSubMessage({ id: '4' })).rejects.toThrow(
      'HTTP error',
    );
  });
});
