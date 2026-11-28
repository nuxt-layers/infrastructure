import { createHash, createHmac } from 'node:crypto';
import { createConnection } from 'node:net';
import { request as httpRequest } from 'node:http';
import assert from 'node:assert/strict';
const [s3, mail, smtp, access, secret, tenantAccess, tenantSecret, mode] = process.argv.slice(2);
for (const address of [s3,mail,smtp]) assert.match(address, /^127\.0\.0\.1:\d+$/);
const hash = data => createHash('sha256').update(data).digest('hex');
const hmac = (key,data) => createHmac('sha256',key).update(data).digest();
// Explicit body framing and full response consumption; no implicit connection pooling.
function exchange(endpoint,method,path,headers={},body='') {
  return new Promise((resolve,reject)=>{
    const req=httpRequest('http://'+endpoint+path,{
      method,agent:false,headers:{...headers,...(method==='PUT'?{'content-length':Buffer.byteLength(body)}:{})},
      signal:AbortSignal.timeout(30000)
    },res=>{
      const chunks=[];
      let size=0;
      res.on('data',chunk=>{size+=chunk.length;if(size>1048576){res.destroy(new Error('Response exceeds fixture limit'));return;}chunks.push(chunk);});
      res.on('error',reject);
      res.on('aborted',()=>reject(new Error('Response aborted')));
      res.on('end',()=>{
        const value=Buffer.concat(chunks).toString('utf8');
        resolve({status:res.statusCode,ok:res.statusCode>=200&&res.statusCode<300,text:async()=>value,json:async()=>JSON.parse(value)});
      });
    });
    req.on('error',reject);
    req.end(method==='PUT'?body:undefined);
  }).catch(error=>{throw new Error(method+' '+path+' at '+endpoint+' failed: '+error.message,{cause:error});});
}
async function request(method,path,body='',key=secret, identity=access) {
  const date = new Date().toISOString().replace(/[:-]|\.\d{3}/g,'');
  const day = date.slice(0,8);
  assert.ok(method==='PUT'||body==='', 'Non-PUT requests must sign an empty payload');
  const payload = hash(body);
  const headers = {host:s3,'x-amz-content-sha256':payload,'x-amz-date':date};
  const signed = Object.keys(headers).sort().join(';');
  const canonical = [method,path,'',Object.keys(headers).sort().map(k=>k+':'+headers[k]+'\n').join(''),signed,payload].join('\n');
  const scope = day+'/us-east-1/s3/aws4_request';
  const signing = hmac(hmac(hmac(hmac('AWS4'+key,day),'us-east-1'),'s3'),'aws4_request');
  headers.authorization = 'AWS4-HMAC-SHA256 Credential='+identity+'/'+scope+', SignedHeaders='+signed+', Signature='+hmac(signing,['AWS4-HMAC-SHA256',date,scope,hash(canonical)].join('\n')).toString('hex');
  const response=await exchange(s3,method,path,headers,body);
  console.log('S3 '+method+' '+path+' -> '+response.status);
  return response;
}
async function ready(label,fn) {
  const deadline=Date.now()+90000;let last;
  do {try{if(await fn())return;last='unexpected response';}catch(error){last=error.message;}await new Promise(r=>setTimeout(r,1000));}while(Date.now()<deadline);
  throw new Error(label+' readiness timeout: '+last);
}
await ready('S3',async()=> (await request('GET','/')).ok);
await ready('Mailpit',async()=> (await exchange(mail,'GET','/api/v1/messages')).ok);
const bucket='/infra-fixture';
const restricted=(method,path,body='')=>request(method,path,body,tenantSecret,tenantAccess);
if(mode==='--after-restart') {
  const response=await request('GET',bucket+'/persist.txt');
  assert.equal(response.status,200);
  assert.equal(await response.text(),'restart checkpoint');
  assert.equal((await request('DELETE',bucket+'/persist.txt')).ok,true);
  assert.equal((await request('DELETE',bucket)).ok,true);
  console.log('PASS: S3 persistence across service restart');
  process.exit(0);
}
assert.equal((await request('PUT',bucket)).ok,true);
const path=bucket+'/probe.txt', payload='synthetic infrastructure fixture';
assert.equal((await request('PUT',path,payload)).ok,true);
assert.equal(await (await request('GET',path)).text(),payload);
assert.equal((await request('HEAD',path)).ok,true);
assert.equal((await request('GET',path,'','invalid')).status,403);
assert.equal((await exchange(s3,'GET',path)).status,403);
assert.equal((await request('GET',bucket)).ok,true);
assert.equal((await request('DELETE',path)).ok,true);
assert.equal((await request('GET',path)).status,404);
assert.equal((await request('PUT','/infra-other')).ok,true);
assert.equal((await request('PUT','/infra-other/private.txt','private')).ok,true);
assert.equal((await restricted('PUT',bucket+'/scoped.txt','scoped')).ok,true);
assert.equal(await (await restricted('GET',bucket+'/scoped.txt')).text(),'scoped');
for(const [method,path] of [['GET','/infra-other/private.txt'],['GET','/infra-other'],['PUT','/infra-other/denied.txt'],['DELETE','/infra-other/private.txt']]) {
  const response=await restricted(method,path,method==='PUT'?'denied':'');
  const error=await response.text();
  assert.equal(response.status,403,method+' '+path+' expected access denial; response: '+error.slice(0,500));
  assert.match(error,/<Code>AccessDenied<\/Code>/,method+' '+path+' must fail on authorisation, not request validity');
}
assert.equal(await (await request('GET','/infra-other/private.txt')).text(),'private');
assert.equal((await request('GET','/infra-other/denied.txt')).status,404);
assert.equal((await restricted('DELETE',bucket+'/scoped.txt')).ok,true);
assert.equal((await request('DELETE','/infra-other/private.txt')).ok,true);
assert.equal((await request('DELETE','/infra-other')).ok,true);
assert.equal((await request('PUT',bucket+'/persist.txt','restart checkpoint')).ok,true);
console.log('PASS: scoped bucket access and cross-bucket read/write/list/delete denial');
console.log('PASS: signed S3 bucket/object lifecycle and invalid/anonymous denial');
const port=Number(smtp.split(':')[1]);
const socket=createConnection({host:'127.0.0.1',port});
socket.setEncoding('utf8');
const lines=[];let pending='';let failure;
socket.on('data',chunk=>{pending+=chunk;while(pending.includes('\r\n')){const i=pending.indexOf('\r\n');lines.push(pending.slice(0,i));pending=pending.slice(i+2);}});
socket.on('error',e=>{failure=e;});
async function reply(code){const until=Date.now()+5000;while(Date.now()<until){if(failure)throw failure;while(lines.length){const line=lines.shift();if(/^\d{3} /.test(line)){assert.equal(Number(line.slice(0,3)),code);return;}}await new Promise(r=>setTimeout(r,20));}throw new Error('SMTP timeout');}
async function send(line,code){socket.write(line+'\r\n');await reply(code);}
try{await reply(220);await send('EHLO fixture.invalid',250);await send('MAIL FROM:<sender@fixture.invalid>',250);await send('RCPT TO:<recipient@fixture.invalid>',250);await send('DATA',354);await send('From: sender@fixture.invalid\r\nTo: recipient@fixture.invalid\r\nSubject: Infrastructure fixture\r\n\r\nSynthetic message\r\n.',250);await send('QUIT',221);}finally{socket.destroy();}
await ready('SMTP capture',async()=>{const response=await exchange(mail,'GET','/api/v1/messages');const data=await response.json();return data.messages?.some(m=>m.Subject==='Infrastructure fixture');});
console.log('PASS: SMTP delivery captured locally');
