import { Module } from '@nestjs/common';
import { QueueService } from './queue.service';
import { QueueAuthService } from '../../common/queue-auth.service';
import { ExecutionLogModule } from '../execution-log/execution-log.module';

@Module({
  imports: [ExecutionLogModule],
  providers: [QueueService, QueueAuthService],
  exports: [QueueService, QueueAuthService],
})
export class QueueModule {}
