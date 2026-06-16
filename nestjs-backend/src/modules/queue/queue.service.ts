import { Injectable, Logger } from '@nestjs/common';

export interface DispatchJobData {
  logId: string;
  endpointUrl: string;
  body: Record<string, unknown>;
}

@Injectable()
export class QueueService {
  private readonly logger = new Logger(QueueService.name);

  async addDispatchJob(data: DispatchJobData): Promise<void> {
    try {
      const queue = await this.tryGetQueue();
      if (queue) {
        await queue.add('send-to-external', data, {
          attempts: 7,
          backoff: { type: 'exponential', delay: 60000 },
          removeOnComplete: false,
          removeOnFail: false,
        });
        this.logger.log(`Job enqueued for log ${data.logId}`);
        return;
      }
    } catch {
      // Redis not available
    }
    throw new Error('Redis unavailable');
  }

  private async tryGetQueue() {
    try {
      const { default: BullMQ } = await import('bullmq');
      const { default: IORedis } = await import('ioredis');
      const connection = new IORedis({
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(String(process.env.REDIS_PORT || '6379'), 10),
        maxRetriesPerRequest: null,
        connectTimeout: 2000,
        lazyConnect: true,
        retryStrategy() {
          return null;
        },
      });
      connection.on('error', () => {});
      await connection.connect();
      return new BullMQ.Queue('dispatch', { connection });
    } catch {
      return null;
    }
  }
}
