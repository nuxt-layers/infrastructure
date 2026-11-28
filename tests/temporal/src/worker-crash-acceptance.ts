import { spawn, type ChildProcess } from 'node:child_process';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { Client, Connection } from '@temporalio/client';
import { NativeConnection, Worker } from '@temporalio/worker';
import { workerCrashWorkflow } from './functional-workflows.js';

const [mode, id] = process.argv.slice(2);
const address = process.env.TEMPORAL_ADDRESS;
if (!address || !/^127\.0\.0\.1:\d+$/.test(address) || !/^infra-phase3-[a-f0-9]+$/.test(id ?? '')) throw new Error('Invalid disposable fixture');
const marker = id + '-checkpoint';
const queue = id + '-worker-crash';
const delay = (ms: number) => new Promise<void>(r => setTimeout(r, ms));
const require = createRequire(import.meta.url);
const { Context } = createRequire(require.resolve('@temporalio/worker'))('@temporalio/activity');

async function runWorker() {
  const native = await NativeConnection.connect({ address });
  try {
    const worker = await Worker.create({
      connection: native, namespace: 'default', taskQueue: queue,
      workflowsPath: fileURLToPath(new URL('./functional-workflows.ts', import.meta.url)),
      activities: {
        async crashCheckpoint(value: string) {
          const ctx = Context.current();
          if (mode === 'first' && ctx.info.attempt === 1) {
            ctx.heartbeat(value);
            // Remain active until the controller kills this process.
            await delay(40000);
            throw new Error('First worker was not killed');
          }
          if (mode !== 'second' || ctx.info.attempt !== 2 || ctx.info.heartbeatDetails !== value) {
            throw new Error('Expected attempt two with persisted checkpoint');
          }
          return 'recovered:' + value;
        },
      },
      shutdownGraceTime: '5 seconds',
    });
    if (mode === 'second') process.once('message', message => { if (message === 'stop') worker.shutdown(); });
    await worker.run();
  } finally { await native.close(); }
}
type Running = { child: ChildProcess; done: Promise<{ code: number | null; signal: NodeJS.Signals | null }> };
function launch(which: string): Running {
  const child = spawn(process.execPath, ['--import', 'tsx', fileURLToPath(import.meta.url), which, id], {
    stdio: ['ignore', 'inherit', 'inherit', 'ipc'], env: process.env,
  });
  const done = new Promise<{ code: number | null; signal: NodeJS.Signals | null }>((resolve, reject) => {
    child.once('error', reject);
    child.once('exit', (code, signal) => resolve({ code, signal }));
  });
  // Observe spawn failures immediately; controller still awaits the original promise.
  void done.catch(() => {});
  return { child, done };
}
async function bounded<T>(promise: Promise<T>, ms: number, label: string): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  try { return await Promise.race([promise, new Promise<never>((_, reject) => {
    timer = setTimeout(() => reject(new Error('Timed out: ' + label)), ms);
  })]); } finally { if (timer) clearTimeout(timer); }
}
async function controller() {
  const connection = await Connection.connect({ address, connectTimeout: '10 seconds' });
  const client = new Client({ connection, namespace: 'default' });
  let first: Running | undefined, second: Running | undefined;
  try {
    first = launch('first');
    const handle = await client.workflow.start(workerCrashWorkflow, {
      workflowId: id, taskQueue: queue, args: [marker], workflowExecutionTimeout: '2 minutes',
    });
    const deadline = Date.now() + 45000;
    let checkpointObserved = false;
    while (Date.now() < deadline) {
      if (first.child.exitCode !== null || first.child.signalCode !== null) throw new Error('First worker exited before crash');
      const desc = await connection.withDeadline(Date.now() + 5000, () => connection.workflowService.describeWorkflowExecution({
        namespace: 'default', execution: { workflowId: id },
      }));
      const activity = desc.pendingActivities?.find(a => a.attempt === 1);
      const payload = activity?.heartbeatDetails?.payloads?.[0];
      if (payload?.data && JSON.parse(Buffer.from(payload.data).toString('utf8')) === marker) {
        checkpointObserved = true; break;
      }
      await delay(250);
    }
    if (!checkpointObserved) throw new Error('Server did not confirm attempt-one checkpoint');
    console.log('PASS: server persisted active attempt-one checkpoint');
    if (!first.child.kill('SIGKILL')) throw new Error('Unable to terminate active worker');
    const exit = await bounded(first.done, 10000, 'first worker exit');
    if (exit.code === 0) throw new Error('First worker exited normally instead of crashing');
    console.log('PASS: active worker process forcibly terminated');
    second = launch('second');
    const result = await bounded(Promise.race([handle.result(), second.done.then(() => { throw new Error('Replacement worker exited prematurely'); })]), 100000, 'replacement worker result');
    if (result !== 'recovered:' + marker) throw new Error('Checkpoint recovery result mismatch');
    const history = await handle.fetchHistory();
    if (history.events?.filter(e => e.activityTaskCompletedEventAttributes).length !== 1) throw new Error('Expected exactly one completed activity');
    second.child.send('stop');
    const stopped = await bounded(second.done, 15000, 'replacement worker drain');
    if (stopped.code !== 0) throw new Error('Replacement worker did not shut down cleanly');
    console.log('PASS: replacement worker recovered durable checkpoint on attempt two; exactly one completed activity');
  } finally {
    for (const running of [first, second]) {
      if (running && running.child.exitCode === null && running.child.signalCode === null) {
        running.child.kill('SIGKILL');
        await bounded(running.done, 10000, 'worker cleanup').catch(error => console.error(error));
      }
    }
    await connection.close();
  }
}
if (mode === 'controller') await controller();
else if (mode === 'first' || mode === 'second') await runWorker();
else throw new Error('Unknown worker crash mode');
