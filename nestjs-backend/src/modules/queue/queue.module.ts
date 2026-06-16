import { Module } from '@nestjs/common';
import { QueueService } from './queue.service';
import { ExecutionLogModule } from '../execution-log/execution-log.module';

@Module({
  imports: [ExecutionLogModule],
  providers: [QueueService],
  exports: [QueueService],
})
export class QueueModule {}
