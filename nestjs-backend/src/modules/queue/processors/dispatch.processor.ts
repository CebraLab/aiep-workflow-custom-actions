import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { ExecutionLogService } from '../../execution-log/execution-log.service';
import { DispatchJobData } from '../queue.service';

@Processor('dispatch')
export class DispatchProcessor extends WorkerHost {
  constructor(private readonly executionLogService: ExecutionLogService) {
    super();
  }

  async process(job: Job<DispatchJobData>): Promise<void> {
    const { logId, endpointUrl, body } = job.data;

    await this.executionLogService.updateStatus(logId, 'PROCESSING', {
      jobId: job.id,
    });

    try {
      const response = await fetch(endpointUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(30000),
      });

      const responseBody = await response.json().catch(() => null);

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${JSON.stringify(responseBody)}`);
      }

      await this.executionLogService.updateStatus(logId, 'SUCCESS', {
        responsePayload: responseBody,
        completedAt: new Date(),
      });
    } catch (error) {
      const isRetrying = job.attemptsMade < (job.opts.attempts || 1) - 1;

      await this.executionLogService.updateStatus(logId, isRetrying ? 'RETRYING' : 'FAILED', {
        errorMessage: error.message,
        retryCount: job.attemptsMade + 1,
        responsePayload: undefined,
        completedAt: isRetrying ? undefined : new Date(),
      });

      throw error;
    }
  }
}
