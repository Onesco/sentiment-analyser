export enum SentimentType {
  POSITIVE = 'POSITIVE',
  NEUTRAL = 'NEUTRAL',
  NEGATIVE = 'NEGATIVE',
}

export type Score = number | string | undefined;

export interface PubSubMessage {
  data: string;
  attributes?: { [key: string]: string };
  messageId?: string;
  publishTime?: string;
}
