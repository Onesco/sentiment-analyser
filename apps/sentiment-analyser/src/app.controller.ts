import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { AppService } from './app.service';
import {
  CreateSummaryDto,
  GetSentimentDto,
  IdParamDto,
} from './dto/create-summary.dto';
import { SentimentType } from 'libs/interface';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('results/:id')
  async getOneById(@Param('id') id: IdParamDto['id']) {
    return await this.appService.getOneById(id);
  }

  @Post('sentiment')
  async getSentiment(
    @Body() data: GetSentimentDto,
  ): Promise<{ sentiment: SentimentType }> {
    return await this.appService.sentimentAnalyser(data.textToAnalyze);
  }

  @Post('summarize')
  async summarize(@Body() data: CreateSummaryDto): Promise<any> {
    return await this.appService.summarize(data.text);
  }
}
