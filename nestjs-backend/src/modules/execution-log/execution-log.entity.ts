import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
} from 'typeorm';

export type WorkflowType = 'admision-callcenter' | 'admision-no-callcenter' | 'difusion';

export type LogStatus = 'PENDING' | 'PROCESSING' | 'SUCCESS' | 'FAILED' | 'RETRYING';

@Entity('execution_logs')
export class ExecutionLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'callback_id' })
  callbackId: string;

  @Column({ name: 'workflow_type' })
  workflowType: WorkflowType;

  @Column({ name: 'object_id' })
  objectId: string;

  @Column({ name: 'object_type' })
  objectType: string;

  @Column({ default: 'PENDING' })
  status: LogStatus;

  @Column('json', { name: 'request_payload', nullable: true })
  requestPayload: Record<string, unknown>;

  @Column('json', { name: 'response_payload', nullable: true })
  responsePayload: Record<string, unknown>;

  @Column({ name: 'error_message', nullable: true })
  errorMessage: string;

  @Column({ name: 'retry_count', default: 0 })
  retryCount: number;

  @Column({ name: 'job_id', nullable: true })
  jobId: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @Column({ name: 'completed_at', nullable: true })
  completedAt: Date;
}
