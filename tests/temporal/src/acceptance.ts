import { Connection, Client } from '@temporalio/client';
import { NativeConnection, Worker } from '@temporalio/worker';
import { fileURLToPath } from 'node:url';
import { acceptanceWorkflow } from './workflows.js';

const [mode, workflowId] = process.argv.slice(2);
const address = process.env.TEMPORAL_ADDRESS || '127.0.0.1:7233';
const taskQueue = 'nuxt-layers-infrastructure-acceptance';
const expected = 'temporal-postgres18-persistence-ok';

async function main() {
  if (!workflowId || !['execute', 'verify'].includes(mode)) {
    throw new Error('Usage: acceptance.ts execute|verify <workflow-id>');
  }
  const connection = await Connection.connect({ address });
  const client = new Client({ connection, namespace: 'default' });
  try {
    if (mode === 'verify') {
      const actual = await client.workflow.getHandle(workflowId).result();
      if (actual !== expected) throw new Error('Historical workflow result does not match');
      console.log('PASS: workflow result remains readable after Temporal restart');
      return;
    }
    const nativeConnection = await NativeConnection.connect({ address });
    try {
      const worker = await Worker.create({
        connection: nativeConnection,
        taskQueue,
        namespace: 'default',
        workflowsPath: fileURLToPath(new URL('./workflows.ts', import.meta.url)),
      });
      const running = worker.run();
      try {
        const actual = await client.workflow.execute(acceptanceWorkflow, {
          workflowId,
          taskQueue,
          workflowExecutionTimeout: '1 minute',
        });
        if (actual !== expected) throw new Error('Unexpected workflow result');
        console.log('PASS: workflow worker executed and returned expected result');
      } finally {
        worker.shutdown();
        await running;
      }
    } finally {
      await nativeConnection.close();
    }
  } finally {
    await connection.close();
  }
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
