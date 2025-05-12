import { Body, Controller, Get, Post } from '@nestjs/common';
import { AppService } from './app.service';
import { CreateSummaryDto } from './dto/create-summary.dto';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('results/:id')
  getHello(): string {
    return 'TODO';
  }

  @Post('sentiment')
  getHello1(): string {
    return 'TODO';
  }

  @Post('summarize')
  async summarize(@Body() data: CreateSummaryDto): Promise<any> {
    const result = await this.appService.summarize(data.text);
    return result;
  }
}
