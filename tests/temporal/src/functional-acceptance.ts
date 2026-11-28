import { Client, Connection, WorkflowNotFoundError } from '@temporalio/client';
import { NativeConnection, Worker } from '@temporalio/worker';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { markerWorkflow, heartbeatWorkflow } from './functional-workflows.js';

// The worker already depends on this exact activity SDK in the frozen graph.
// Resolve from the worker package to respect pnpm's isolated dependency layout.
const require = createRequire(import.meta.url);
const workerRequire = createRequire(require.resolve('@temporalio/worker'));
const { Context } = workerRequire('@temporalio/activity');
const [mode, id] = process.argv.slice(2);
const address = process.env.TEMPORAL_ADDRESS;
const delay = (ms: number) => new Promise<void>(resolve => setTimeout(resolve, ms));
async function until<T>(fn: () => Promise<T | undefined>, label: string): Promise<T> {
  const deadline = Date.now() + 60000;
  while (Date.now() < deadline) {
    const value = await fn();
    if (value !== undefined) return value;
    await delay(500);
  }
  throw new Error('Timed out: ' + label);
}

async function main() {
  if (!address || !/^127\.0\.0\.1:\d+$/.test(address) || !/^infra-phase3-[a-f0-9]+$/.test(id ?? '') ||
      !['schedule','heartbeat','visibility','separation'].includes(mode)) throw new Error('Invalid fixture invocation');
  const connection = await Connection.connect({ address, connectTimeout: '10 seconds' });
  const native = await NativeConnection.connect({ address });
  const client = new Client({ connection, namespace: 'default' });
  const queue = id + '-a';
  const workerFor = (namespace: string, taskQueue: string) => Worker.create({
    connection: native, namespace, taskQueue,
    workflowsPath: fileURLToPath(new URL('./functional-workflows.ts', import.meta.url)),
    activities: {
      async checkpoint() {
        const ctx = Context.current();
        if (ctx.info.attempt === 1) {
          ctx.heartbeat('checkpoint-1');
          // No more heartbeats. Allow server-side heartbeat timeout; do not throw.
          await new Promise(resolve => setTimeout(resolve, 9000));
          return 'unexpected-first-attempt';
        }
        if (ctx.info.attempt !== 2 || ctx.info.heartbeatDetails !== 'checkpoint-1') {
          throw new Error('Expected persisted heartbeat checkpoint on second attempt');
        }
        return 'checkpoint-recovered';
      },
    },
    shutdownGraceTime: '15 seconds',
  });
  const start = (c: Client, q: string, workflowId: string, marker: string) =>
    c.workflow.start(markerWorkflow, { workflowId, taskQueue: q, args: [marker], workflowExecutionTimeout: '2 minutes' });
  const ids = async (c: Client, workflowId: string) => {
    const result = [];
    for await (const item of c.workflow.list({ query: "WorkflowId = '" + workflowId + "' AND ExecutionStatus = 'Completed'" })) result.push(item.workflowId);
    return result;
  };
  try {
    const worker = await workerFor('default', queue);
    await worker.runUntil(async () => {
      if (mode === 'schedule') {
        const schedule = await client.schedule.create({
          scheduleId: id, spec: { intervals: [{ every: '5 seconds' }] },
          action: { type: 'startWorkflow', workflowType: markerWorkflow, taskQueue: queue, args: ['scheduled'], workflowExecutionTimeout: '2 minutes' },
          state: { remainingActions: 1 },
        });
        try {
          const action = await until(async () => (await schedule.describe()).info.recentActions[0], 'automatic schedule action');
          if (await client.workflow.getHandle(action.action.workflow.workflowId, action.action.workflow.firstExecutionRunId).result() !== 'scheduled') throw new Error('Scheduled result mismatch');
          const desc = await schedule.describe();
          if (desc.info.recentActions.length !== 1 || desc.state.remainingActions !== 0) throw new Error('Expected one scheduled action');
          console.log('PASS: automatic scheduled dispatch executed once');
        } finally { await schedule.delete(); }
      } else if (mode === 'heartbeat') {
        const result = await client.workflow.execute(heartbeatWorkflow, { workflowId: id, taskQueue: queue, workflowExecutionTimeout: '2 minutes' });
        if (result !== 'checkpoint-recovered') throw new Error('Heartbeat recovery failed');
        console.log('PASS: heartbeat timeout and second-attempt checkpoint recovery');
      } else if (mode === 'visibility') {
        const handle = await start(client, queue, id, 'visible');
        if (await handle.result() !== 'visible') throw new Error('Visibility workflow result mismatch');
        await until(async () => {
          const found = await ids(client, id);
          if (found.length > 1) throw new Error('Unexpected duplicate visibility result');
          return found.length === 1 && found[0] === id ? true : undefined;
        }, 'completed workflow visibility');
        console.log('PASS: SQL advanced visibility returned exact completed workflow');
      } else {
        const otherNamespace = id + '-ns';
        await connection.workflowService.registerNamespace({ namespace: otherNamespace, workflowExecutionRetentionPeriod: { seconds: 86400 } });
        await until(async () => {
          try { await connection.workflowService.describeNamespace({ namespace: otherNamespace }); return true; }
          catch (error) {
            if ((error as { code?: number }).code !== 5) throw error;
            return undefined;
          }
        }, 'namespace registration');
        const other = new Client({ connection, namespace: otherNamespace });
        const first = await start(client, queue, id, 'namespace-a');
        if (await first.result() !== 'namespace-a') throw new Error('Namespace A result mismatch');
        try {
          await other.workflow.getHandle(id).describe();
          throw new Error('Workflow leaked into second namespace');
        } catch (error) { if (!(error instanceof WorkflowNotFoundError)) throw error; }
        // Same ID and queue in another namespace; no worker in that namespace yet.
        const second = await start(other, queue, id, 'namespace-b');
        await delay(2000);
        if ((await second.describe()).status.name !== 'RUNNING') throw new Error('Wrong namespace worker consumed task');
        const otherWorker = await workerFor(otherNamespace, queue);
        await otherWorker.runUntil(async () => {
          if (await second.result() !== 'namespace-b') throw new Error('Namespace B result mismatch');
        });
        const wrongQueue = queue + '-b';
        const third = await start(client, wrongQueue, id + '-queue', 'queue-b');
        await delay(2000);
        if ((await third.describe()).status.name !== 'RUNNING') throw new Error('Wrong queue worker consumed task');
        const queueWorker = await workerFor('default', wrongQueue);
        await queueWorker.runUntil(async () => {
          if (await third.result() !== 'queue-b') throw new Error('Queue B result mismatch');
        });
        console.log('PASS: namespace-scoped identity and independent namespace/queue task routing (not authorisation)');
      }
    });
  } finally { await native.close(); await connection.close(); }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
