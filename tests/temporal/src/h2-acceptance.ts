import { generateKeyPairSync, sign, randomUUID } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { connect as connectHttp2, type SecureClientSessionOptions } from 'node:http2';
import { connect as connectTls, type ConnectionOptions as TlsOptions } from 'node:tls';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Client, Connection, type ConnectionOptions } from '@temporalio/client';
import { NativeConnection, Worker } from '@temporalio/worker';
import { phase3Workflow } from './phase3-workflows.js';

const [mode, root] = process.argv.slice(2);
if (!root) throw new Error('Missing fixture directory');
const clientDir = join(root, 'client');
const read = (name: string) => readFileSync(join(clientDir, name));
if (mode === 'keys') {
  const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 3072 });
  writeFileSync(join(clientDir, 'jwt.key'), privateKey.export({ type: 'pkcs8', format: 'pem' }), { mode: 0o600 });
  writeFileSync(join(root, 'public', 'jwks.json'), JSON.stringify({ keys: [{ ...publicKey.export({ format: 'jwk' }), kid: 'h2', alg: 'RS256', use: 'sig' }] }));
} else {
  const address = process.env.TEMPORAL_ADDRESS;
  if (!address || !/^127\.0\.0\.1:\d+$/.test(address)) throw new Error('Expected disposable loopback endpoint');
  const key = read('jwt.key');
  const badKey = generateKeyPairSync('rsa', { modulusLength: 2048 }).privateKey;
  function token(permissions: string[], expired = false, invalid = false) {
    const encode = (v: unknown) => Buffer.from(JSON.stringify(v)).toString('base64url');
    const now = Math.floor(Date.now() / 1000);
    const input = encode({ alg: 'RS256', typ: 'JWT', kid: 'h2' }) + '.' + encode({ sub: 'h2-fixture', iat: now - 60, exp: expired ? now - 30 : now + 600, permissions });
    return input + '.' + sign('RSA-SHA256', Buffer.from(input), invalid ? badKey : key).toString('base64url');
  }
  const tls = { serverRootCACertificate: read('ca.crt'), serverNameOverride: 'temporal', clientCertPair: { crt: read('client.crt'), key: read('client.key') } };
  const admin = token(['temporal-system:admin']);
  const writer = token(['h2-a:write', 'h2-a:worker']);
  const reader = token(['h2-a:read']);
  const describe = (connection: Connection, namespace: string) => connection.withDeadline(Date.now() + 5000, () => connection.workflowService.describeNamespace({ namespace }));
  async function use<T>(apiKey: string | undefined, transport: ConnectionOptions['tls'], fn: (c: Connection) => Promise<T>) {
    const c = Connection.lazy({ address, tls: transport, ...(apiKey ? { metadata: { authorization: 'Bearer ' + apiKey } } : {}), connectTimeout: '5 seconds' });
    try { return await fn(c); } finally { await c.close(); }
  }
  // A deadline is not evidence of transport rejection. Require HTTP/2 session
  // establishment for the positive control and explicit closure/error for negatives.
  async function transportProbe(label: string, secure: boolean, options: SecureClientSessionOptions, allowed: boolean) {
    await new Promise<void>((resolve, reject) => {
      const session = connectHttp2((secure ? 'https://' : 'http://') + address, options);
      let settled = false;
      const finish = (error?: Error) => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        session.destroy();
        if (error) reject(error); else resolve();
      };
      const timer = setTimeout(() => finish(new Error(label + ': inconclusive transport timeout')), 5000);
      session.once('remoteSettings', () => finish(allowed ? undefined : new Error(label + ': HTTP/2 transport unexpectedly established')));
      session.on('error', (err: NodeJS.ErrnoException) => {
        const code = err.code ?? '';
        const rejected = /^(ERR_SSL_|ERR_TLS_|ERR_HTTP2_ERROR$|ERR_HTTP2_SESSION_ERROR$|ECONNRESET$|EPIPE$|SELF_SIGNED_CERT_IN_CHAIN$|UNABLE_TO_VERIFY_LEAF_SIGNATURE$|UNABLE_TO_GET_ISSUER_CERT_LOCALLY$|CERT_SIGNATURE_FAILURE$)/.test(code);
        finish(!allowed && rejected ? undefined : new Error(label + ': unexpected transport error ' + code, { cause: err }));
      });
      session.once('close', () => finish(allowed ? new Error(label + ': transport closed before HTTP/2 settings') : undefined));
    });
    console.log('PASS: ' + label);
  }
  // Force TLS 1.2 for certificate-negative probes: the peer must accept or
  // reject the client certificate before the TLS handshake can complete.
  async function certificateProbe(label: string, options: TlsOptions, allowed: boolean) {
    await new Promise<void>((resolve, reject) => {
      const socket = connectTls({ host: '127.0.0.1', port: Number(address!.split(':')[1]),
        ALPNProtocols: ['h2'], ...options, minVersion: 'TLSv1.2', maxVersion: 'TLSv1.2' });
      let settled = false;
      const finish = (error?: Error) => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        socket.destroy();
        if (error) reject(error); else resolve();
      };
      const timer = setTimeout(() => finish(new Error(label + ': inconclusive TLS timeout')), 10000);
      socket.once('secureConnect', () => finish(allowed && socket.authorized && socket.alpnProtocol === 'h2'
        ? undefined : new Error(label + ': unexpected TLS handshake success or invalid positive control')));
      socket.on('error', (err: NodeJS.ErrnoException) => {
        const code = err.code ?? '';
        const rejected = /^(ERR_SSL_|ERR_TLS_|ECONNRESET$|EPIPE$|SELF_SIGNED_CERT_IN_CHAIN$|UNABLE_TO_VERIFY_LEAF_SIGNATURE$|UNABLE_TO_GET_ISSUER_CERT_LOCALLY$|CERT_SIGNATURE_FAILURE$)/.test(code);
        finish(!allowed && rejected ? undefined : new Error(label + ': unexpected TLS error ' + code, { cause: err }));
      });
      socket.once('close', () => finish(new Error(label + ': TLS socket closed without a conclusive handshake result')));
    });
    console.log('PASS: ' + label);
  }
  function grpcCode(err: unknown): number | undefined {
    for (let current = err; current && typeof current === 'object'; ) {
      const e = current as { code?: number; cause?: unknown };
      if (typeof e.code === 'number') return e.code;
      if (e.cause === current) break;
      current = e.cause;
    }
    return undefined;
  }
  async function deny(label: string, code: number, fn: () => Promise<unknown>) {
    try { await fn(); } catch (err) {
      if (grpcCode(err) !== code) throw new Error(label + ': unexpected failure', { cause: err });
      console.log('PASS: ' + label);
      return;
    }
    throw new Error(label + ': unexpectedly allowed');
  }
  if (mode === 'bootstrap') {
    try { await use(admin, tls, async c => {
      for (const namespace of ['h2-a', 'h2-b']) {
        try { await describe(c, namespace); }
        catch (err) {
          if ((err as { code?: number }).code !== 5) throw err;
          await c.withDeadline(Date.now() + 5000, () => c.workflowService.registerNamespace({ namespace, workflowExecutionRetentionPeriod: { seconds: 86400 } }));
        }
      }
      await describe(c, 'h2-a');
      await describe(c, 'h2-b');
    }); } catch (err) {
      const code = (err as { code?: number }).code;
      console.error('Bootstrap gRPC status:', code ?? 'unknown', (err as Error).message);
      process.exitCode = [4, 5, 14].includes(code ?? -1) ? 10 : 1;
    }
  } else if (mode === 'accept') {
    await use(admin, tls, async c => { await describe(c, 'h2-a'); await describe(c, 'h2-b'); });
    const secure = { ca: read('ca.crt'), cert: read('client.crt'), key: read('client.key'), servername: 'temporal', rejectUnauthorized: true };
    await transportProbe('trusted mutual TLS HTTP/2', true, secure, true);
    await transportProbe('plaintext refused', false, {}, false);
    await certificateProbe('trusted TLS 1.2 control', secure, true);
    await certificateProbe('missing client certificate', { ca: secure.ca, servername: 'temporal', rejectUnauthorized: true }, false);
    await certificateProbe('untrusted client certificate', { ...secure, cert: read('untrusted.crt'), key: read('untrusted.key') }, false);
    await certificateProbe('untrusted server CA', { ...secure, ca: read('wrong-ca.crt') }, false);
    await certificateProbe('wrong server identity', { ...secure, servername: 'wrong.invalid' }, false);
    await certificateProbe('trusted TLS 1.2 remains available', secure, true);
    await transportProbe('trusted transport remains available', true, secure, true);
    await use(admin, tls, c => describe(c, 'h2-a'));
    await use(writer, tls, c => describe(c, 'h2-a'));
    await deny('missing JWT', 7, () => use(undefined, tls, c => describe(c, 'h2-a')));
    await deny('invalid JWT signature', 7, () => use(token(['h2-a:write'], false, true), tls, c => describe(c, 'h2-a')));
    await deny('expired JWT', 7, () => use(token(['h2-a:write'], true), tls, c => describe(c, 'h2-a')));
    await deny('cross-namespace read', 7, () => use(writer, tls, c => describe(c, 'h2-b')));
    const workflowId = 'h2-' + randomUUID(), taskQueue = 'h2-' + randomUUID();
    const start = (c: Connection, namespace: string) => c.withDeadline(Date.now() + 5000, () => new Client({ connection: c, namespace }).workflow.start(phase3Workflow, { workflowId, taskQueue, args: [false], workflowExecutionTimeout: '60 seconds' }));
    await deny('reader cannot start workflow', 7, () => use(reader, tls, c => start(c, 'h2-a')));
    await deny('cross-namespace workflow start', 7, () => use(writer, tls, c => start(c, 'h2-b')));
    const native = await NativeConnection.connect({ address, tls, metadata: { authorization: 'Bearer ' + writer } });
    try {
      const worker = await Worker.create({ connection: native, namespace: 'h2-a', taskQueue, workflowsPath: fileURLToPath(new URL('./phase3-workflows.ts', import.meta.url)), activities: { async retryProbe() { return 42; } }, shutdownGraceTime: '10 seconds' });
      await worker.runUntil(() => use(writer, tls, async c => {
        const handle = await start(c, 'h2-a');
        if (await handle.result() !== 42) throw new Error('Unexpected workflow result');
      }));
    } finally { await native.close(); }
    await use(reader, tls, async c => {
      if (await new Client({ connection: c, namespace: 'h2-a' }).workflow.getHandle(workflowId).result() !== 42) throw new Error('Historical read failed');
    });
    console.log('PASS: authenticated scoped worker execution and read-only historical retrieval');
  } else throw new Error('Unknown H2 mode');
}
