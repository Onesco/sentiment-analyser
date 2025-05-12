export interface PubSubMessage {
  data: string;
  attributes?: { [key: string]: string };
  messageId?: string;
  publishTime?: string;
}

export enum SentimentType {
  POSITIVE = 'POSITIVE',
  NEGATIVE = 'NEGATIVE',
  NEUTRAL = 'NEUTRAL',
}

export type Score = number | null | undefined;
