import { Client, Connection } from '@temporalio/client';
import { NativeConnection, Worker } from '@temporalio/worker';
import { fileURLToPath } from 'node:url';
import { phase3Workflow, ready, release } from './phase3-workflows.js';

const [mode, workflowId] = process.argv.slice(2);
const address = process.env.TEMPORAL_ADDRESS;
const taskQueue = 'infra-phase3-' + workflowId;
const namespace = 'default';

async function main() {
  if (!workflowId || !address || !/^127\.0\.0\.1:\d+$/.test(address) || !['execute','suspend','resume','verify'].includes(mode)) {
    throw new Error('Invalid isolated Phase 3 invocation');
  }
  const connection = await Connection.connect({ address, connectTimeout: '10 seconds' });
  const client = new Client({ connection, namespace });
  try {
    const handle = client.workflow.getHandle(workflowId);
    if (mode === 'verify') {
      if (await handle.result() !== 2) throw new Error('Unexpected historical result');
      console.log('PASS: completed activity retry result remains durable');
      return;
    }
    const native = await NativeConnection.connect({ address });
    let attempts = 0;
    try {
      const worker = await Worker.create({
        connection: native, namespace, taskQueue,
        workflowsPath: fileURLToPath(new URL('./phase3-workflows.ts', import.meta.url)),
        activities: { async retryProbe() {
          attempts++;
          if (attempts === 1) throw new Error('Synthetic transient activity failure');
          return attempts;
        }},
        shutdownGraceTime: '10 seconds',
      });
      await worker.runUntil(async () => {
        if (mode === 'resume') {
          await handle.signal(release);
          if (await handle.result() !== 2 || attempts !== 0) throw new Error('Previously completed activity was not preserved');
          console.log('PASS: suspended workflow resumed after restart without repeating completed activity');
          return;
        }
        const started = await client.workflow.start(phase3Workflow, {
          workflowId, taskQueue, args: [mode === 'suspend'],
          workflowExecutionTimeout: '10 minutes',
        });
        if (mode === 'execute') {
          if (await started.result() !== 2 || attempts !== 2) throw new Error('Expected exactly two activity attempts');
          console.log('PASS: real activity failed once then succeeded on bounded retry');
          return;
        }
        const deadline = Date.now() + 60000;
        while (Date.now() < deadline) {
          if (await started.query(ready)) {
            if (attempts !== 2) throw new Error('Expected completed activity retry before suspension');
            console.log('PASS: running workflow reached durable signal wait');
            return;
          }
          await new Promise(resolve => setTimeout(resolve, 250));
        }
        throw new Error('Workflow did not reach signal wait');
      });
      console.log('PASS: worker drained and stopped');
    } finally { await native.close(); }
  } finally { await connection.close(); }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
