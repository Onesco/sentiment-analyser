import { IsString } from 'class-validator';

export class CreateSummaryDto {
  @IsString()
  text: string;
}
