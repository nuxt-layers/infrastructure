// Inspect rendered Compose JSON supplied on stdin; never print secrets.
import assert from 'node:assert/strict';
let input='';
for await(const chunk of process.stdin){input+=chunk;if(input.length>2_000_000)throw Error('Config too large');}
const c=JSON.parse(input);
assert.ok(c.services&&Object.keys(c.services).length);
for(const [name,s] of Object.entries(c.services)){
  assert.match(s.image??'',/@sha256:[0-9a-f]{64}$/,'Immutable image required: '+name);
  assert.ok(!s.build&&!s.privileged&&!s.network_mode&&!s.pid&&!s.ipc,'Unsafe service configuration: '+name);
  assert.ok(!s.ports?.length,'Database/support service must not publish ports: '+name);
  assert.ok(Number(s.mem_limit)>0&&Number(s.cpus)>0&&Number(s.pids_limit)>0,'Resource budget missing: '+name);
  assert.ok(s.logging?.driver==='json-file'&&s.logging.options?.['max-size']&&s.logging.options?.['max-file'],'Bounded logging required: '+name);
  for(const n of Object.keys(s.networks??{}))assert.equal(c.networks?.[n]?.internal,true,'Network not private: '+n);
  assert.ok(Object.keys(s.networks??{}).length,'Network missing: '+name);
  for(const v of s.volumes??[])assert.ok(v.type==='volume'&&!String(v.target).includes('docker.sock'),'Only named storage permitted: '+name);
  for(const k of Object.keys(s.environment??{}))if(/PASSWORD|SECRET|TOKEN|PRIVATE_KEY/i.test(k))assert.ok(k.endsWith('_FILE')&&String(s.environment[k]).startsWith('/run/secrets/'),'Inline secret prohibited: '+name+'/'+k);
}
console.log('PASS: rendered private infrastructure manifest policy (static only)');
