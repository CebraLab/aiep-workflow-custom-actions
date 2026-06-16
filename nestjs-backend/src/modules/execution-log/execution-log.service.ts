import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ExecutionLog, LogStatus, WorkflowType } from './execution-log.entity';

@Injectable()
export class ExecutionLogService {
  constructor(
    @InjectRepository(ExecutionLog)
    private readonly repo: Repository<ExecutionLog>,
  ) {}

  create(data: {
    callbackId: string;
    workflowType: WorkflowType;
    objectId: string;
    objectType: string;
    requestPayload: Record<string, unknown>;
    jobId?: string;
  }): Promise<ExecutionLog> {
    return this.repo.save(this.repo.create({ ...data, status: 'PENDING' }));
  }

  updateStatus(
    id: string,
    status: LogStatus,
    extra?: Partial<ExecutionLog>,
  ): Promise<void> {
    return this.repo.update(id, { status, ...extra } as any).then(() => undefined);
  }
}
