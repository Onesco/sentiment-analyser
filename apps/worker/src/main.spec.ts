import { pubSubHandler } from './main';

jest.mock('@nestjs/core', () => {
  const actual = jest.requireActual('@nestjs/core');
  return {
    ...actual,
    NestFactory: {
      createApplicationContext: jest.fn(),
    },
  };
});

describe('pubSubHandler', () => {
  it('should decode base64, parse JSON, and call WorkerService', async () => {
    const mockHandle = jest.fn();
    const mockWorkerService = { handlePubSubMessage: mockHandle };

    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { NestFactory } = require('@nestjs/core');
    NestFactory.createApplicationContext.mockResolvedValue({
      get: () => mockWorkerService,
    });

    const fakePayload = { id: '4' };
    const fakeEvent = {
      data: Buffer.from(JSON.stringify(fakePayload)).toString('base64'),
    };

    await pubSubHandler(fakeEvent);

    expect(mockHandle).toHaveBeenCalledWith(fakePayload);
  });
});
