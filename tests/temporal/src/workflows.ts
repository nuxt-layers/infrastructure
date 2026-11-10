import { sleep } from '@temporalio/workflow';

export async function acceptanceWorkflow(): Promise<string> {
  await sleep('1 second');
  return 'temporal-postgres18-persistence-ok';
}
