import { proxyActivities } from '@temporalio/workflow';

export async function markerWorkflow(marker: string): Promise<string> { return marker; }

const { checkpoint } = proxyActivities<{ checkpoint(): Promise<string> }>({
  heartbeatTimeout: '3 seconds',
  startToCloseTimeout: '20 seconds',
  scheduleToCloseTimeout: '45 seconds',
  retry: { initialInterval: '1 second', maximumAttempts: 2 },
});
export async function heartbeatWorkflow(): Promise<string> { return checkpoint(); }

const { crashCheckpoint } = proxyActivities<{ crashCheckpoint(marker: string): Promise<string> }>({
  heartbeatTimeout: '15 seconds',
  startToCloseTimeout: '45 seconds',
  scheduleToCloseTimeout: '100 seconds',
  retry: { initialInterval: '1 second', maximumAttempts: 2 },
});
export async function workerCrashWorkflow(marker: string): Promise<string> { return crashCheckpoint(marker); }
