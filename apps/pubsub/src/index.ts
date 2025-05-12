import { PubSubMessage, SentimentType, Score } from './interfaces';
import { LanguageServiceClient } from '@google-cloud/language';
import { AppDataSource } from './data-source';
import { SentimentEntity } from './entities/sentiment.entity';
import * as dotenv from 'dotenv';

dotenv.config();

const languageClient = new LanguageServiceClient();
let isInitialized = false;

async function initializeDataSource() {
  if (!isInitialized) {
    await AppDataSource.initialize();
    isInitialized = true;
  }
}
const threshold = Number(process.env.THRESHOLD);

export const pubSubHandler = async (message: PubSubMessage): Promise<void> => {
  await initializeDataSource();

  const raw = Buffer.from(message.data, 'base64').toString();
  const id = JSON.parse(raw);

  const repo = AppDataSource.getRepository(SentimentEntity);

  try {
    const document = await repo.findOne({ where: { id } });

    const [result] = await languageClient.analyzeSentiment({
      document: {
        content: document?.summary,
        type: 'PLAIN_TEXT',
      },
    });

    const sentimentSumary = result.documentSentiment;
    if (!sentimentSumary) throw new Error('No sentiment result');

    const sentiment = classifySentiment(sentimentSumary.score);

    await repo.update(
      { id: document?.id },
      {
        score: sentimentSumary.score,
        magnitude: sentimentSumary.magnitude,
        sentiment,
      },
    );
    console.log(
      'successful analysed and updated record with its sentiment value. id:',
      id,
    );
  } catch (error) {
    console.error('something went during sentiment processing', error);
    throw error;
  }
};

const classifySentiment = (score: Score) => {
  if (typeof score !== 'number' || isNaN(score)) {
    return null;
  }
  if (score > threshold) {
    return SentimentType.POSITIVE;
  } else if (score < threshold) {
    return SentimentType.NEGATIVE;
  }
  return SentimentType.NEUTRAL;
};
