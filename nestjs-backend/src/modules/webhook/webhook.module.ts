import { Module } from '@nestjs/common';
import { WebhookController } from './webhook.controller';
import { ExecutionLogModule } from '../execution-log/execution-log.module';
import { QueueModule } from '../queue/queue.module';

@Module({
  imports: [ExecutionLogModule, QueueModule],
  controllers: [WebhookController],
})
export class WebhookModule {}
