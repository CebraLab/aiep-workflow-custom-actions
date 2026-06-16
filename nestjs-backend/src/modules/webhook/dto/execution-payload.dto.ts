export interface ExecutionPayloadDto {
  callbackId: string;
  origin: {
    portalId: number;
    actionDefinitionId: number;
    actionDefinitionVersion: number;
  };
  context: {
    source: string;
    workflowId: number;
  };
  object: {
    objectId: number;
    objectType: string;
    properties: Record<string, unknown>;
  };
  inputFields: Record<string, unknown>;
}
