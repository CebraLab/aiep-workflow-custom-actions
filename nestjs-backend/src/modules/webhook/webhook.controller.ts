import { Controller, Post, Body, UseGuards, Logger } from '@nestjs/common';
import { ExecutionLogService } from '../execution-log/execution-log.service';
import type { WorkflowType } from '../execution-log/execution-log.entity';
import { QueueService } from '../queue/queue.service';
import { HubspotSignatureGuard } from '../../common/guards/hubspot-signature.guard';
import type { ExecutionPayloadDto } from './dto/execution-payload.dto';

@Controller('api/hubspot/execute')
@UseGuards(HubspotSignatureGuard)
export class WebhookController {
  private readonly logger = new Logger(WebhookController.name);

  constructor(
    private readonly executionLogService: ExecutionLogService,
    private readonly queueService: QueueService,
  ) {}

  @Post('admision-callcenter')
  async admisionCallCenter(@Body() payload: ExecutionPayloadDto) {
    return this.handleExecution(payload, 'admision-callcenter');
  }

  @Post('admision-no-callcenter')
  async admisionNoCallCenter(@Body() payload: ExecutionPayloadDto) {
    return this.handleExecution(payload, 'admision-no-callcenter');
  }

  @Post('difusion')
  async difusion(@Body() payload: ExecutionPayloadDto) {
    return this.handleExecution(payload, 'difusion');
  }

  private async handleExecution(
    payload: ExecutionPayloadDto,
    type: WorkflowType,
  ) {
    const externalPayload = this.buildExternalPayload(payload);
    const endpointUrl = this.getEndpointUrl(type);

    const log = await this.executionLogService.create({
      callbackId: payload.callbackId,
      workflowType: type,
      objectId: String(payload.object.objectId),
      objectType: payload.object.objectType,
      requestPayload: externalPayload,
    });

    const result: { success: boolean; error?: string } = { success: false };

    try {
      await this.queueService.addDispatchJob({
        logId: log.id,
        endpointUrl,
        body: externalPayload,
      });
      this.logger.log(`Job enqueued for ${type} (log: ${log.id})`);
      result.success = true;
    } catch {
      this.logger.warn(`Redis unavailable. Forwarding ${type} synchronously.`);
      this.logger.log(`Payload to ${endpointUrl}: ${JSON.stringify(externalPayload)}`);
      const forwardResult = await this.forwardToExternal(log.id, endpointUrl, externalPayload);
      result.success = forwardResult.success;
      result.error = forwardResult.error;
    }

    if (result.success) {
      return {
        outputFields: {
          hs_execution_state: 'SUCCESS',
          externalStatus: 'SENT',
        },
      };
    }

    return {
      outputFields: {
        hs_execution_state: 'FAIL_CONTINUE',
        externalStatus: 'ERROR',
        errorMessage: result.error || 'Unknown error',
      },
    };
  }

  private async forwardToExternal(
    logId: string,
    endpointUrl: string,
    body: Record<string, unknown>,
  ): Promise<{ success: boolean; error?: string }> {
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

      this.logger.log(`Sync forward to ${endpointUrl} succeeded (log: ${logId})`);
      return { success: true };
    } catch (error) {
      await this.executionLogService.updateStatus(logId, 'FAILED', {
        errorMessage: error.message,
        retryCount: 1,
      });
      this.logger.error(`Sync forward to ${endpointUrl} failed: ${error.message}`);
      return { success: false, error: error.message };
    }
  }

  private buildExternalPayload(payload: ExecutionPayloadDto) {
    const properties: Record<string, unknown> = {};

    for (const [key, value] of Object.entries(payload.inputFields)) {
      properties[key] = value;
    }

    return {
      objectId: String(payload.object.objectId),
      properties,
    };
  }

  private getEndpointUrl(type: WorkflowType): string {
    const baseUrl =
      process.env.EXTERNAL_API_BASE_URL ||
      'https://cornfield-pointer-upcountry.ngrok-free.dev';
    const paths: Record<WorkflowType, string> = {
      'admision-callcenter': '/api/v1/queues/hubspot/workflow/admision/callcenter',
      'admision-no-callcenter':
        '/api/v1/queues/hubspot/workflow/admision/no-callcenter',
      difusion: '/api/v1/queues/hubspot/workflow/difusion',
    };
    return `${baseUrl}${paths[type]}`;
  }
}
