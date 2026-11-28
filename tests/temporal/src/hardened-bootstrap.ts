import { Client, Connection } from '@temporalio/client';
const address = process.env.TEMPORAL_ADDRESS;
if (!address || !/^127\.0\.0\.1:\d+$/.test(address)) throw new Error('Expected disposable loopback endpoint');
const connection = await Connection.connect({ address, connectTimeout: '5 seconds' });
try {
  const client = new Client({ connection, namespace: 'default' });
  const call = <T>(fn: () => Promise<T>) => connection.withDeadline(Date.now() + 5000, fn);
  try {
    await call(() => client.connection.workflowService.describeNamespace({ namespace: 'default' }));
  } catch (error) {
    if ((error as { code?: number }).code !== 5) throw error;
    await call(() => client.connection.workflowService.registerNamespace({ namespace: 'default', workflowExecutionRetentionPeriod: { seconds: 86400 } }));
  }
  console.log('PASS: explicit namespace bootstrap');
} finally { await connection.close(); }
