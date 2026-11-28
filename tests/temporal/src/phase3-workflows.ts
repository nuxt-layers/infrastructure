import { condition, defineQuery, defineSignal, proxyActivities, setHandler } from '@temporalio/workflow';

const { retryProbe } = proxyActivities<{ retryProbe(): Promise<number> }>({
  startToCloseTimeout: '10 seconds',
  scheduleToCloseTimeout: '30 seconds',
  retry: { initialInterval: '1 second', maximumAttempts: 2 },
});
export const release = defineSignal('release');
export const ready = defineQuery<boolean>('ready');
export async function phase3Workflow(waitForRelease: boolean): Promise<number> {
  let released = false;
  let waiting = false;
  setHandler(release, () => { released = true; });
  setHandler(ready, () => waiting);
  const attempts = await retryProbe();
  waiting = true;
  if (waitForRelease) await condition(() => released);
  return attempts;
}
