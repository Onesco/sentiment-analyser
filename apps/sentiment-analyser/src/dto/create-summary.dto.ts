import { IsNumber, IsString, ValidateIf } from 'class-validator';

export class CreateSummaryDto {
  @IsString()
  text: string;
}

export class GetSentimentDto {
  @IsString()
  textToAnalyze: string;
}

export class IdParamDto {
  @ValidateIf((o) => typeof o.id === 'string')
  @IsString()
  @ValidateIf((o) => typeof o.id === 'number')
  @IsNumber()
  id: number | string;
}
