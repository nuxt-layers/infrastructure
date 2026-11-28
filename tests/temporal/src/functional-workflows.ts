import { proxyActivities } from '@temporalio/workflow';

export async function markerWorkflow(marker: string): Promise<string> { return marker; }

const { checkpoint } = proxyActivities<{ checkpoint(): Promise<string> }>({
  heartbeatTimeout: '3 seconds',
  startToCloseTimeout: '20 seconds',
  scheduleToCloseTimeout: '45 seconds',
  retry: { initialInterval: '1 second', maximumAttempts: 2 },
});
export async function heartbeatWorkflow(): Promise<string> { return checkpoint(); }
