import { NestFactory } from '@nestjs/core';
import { WorkerModule } from './worker.module';
import { WorkerService } from './worker.service';

let appContext;

export const pubSubHandler = async (event: any) => {
  if (!appContext) {
    appContext = await NestFactory.createApplicationContext(WorkerModule);
  }

  const workerService = appContext.get(WorkerService);

  const pubSubMessage = Buffer.from(event.data, 'base64').toString();
  const payload = JSON.parse(pubSubMessage);

  await workerService.handlePubSubMessage(payload);
};
