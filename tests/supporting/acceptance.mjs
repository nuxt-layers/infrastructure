import { createHash, createHmac } from 'node:crypto';
import { createConnection } from 'node:net';
import assert from 'node:assert/strict';
const [s3, mail, smtp, access, secret] = process.argv.slice(2);
for (const address of [s3,mail,smtp]) assert.match(address, /^127\.0\.0\.1:\d+$/);
const hash = data => createHash('sha256').update(data).digest('hex');
const hmac = (key,data) => createHmac('sha256',key).update(data).digest();
async function request(method,path,body='',key=secret) {
  const date = new Date().toISOString().replace(/[:-]|\.\d{3}/g,'');
  const day = date.slice(0,8);
  const payload = hash(body);
  const headers = {host:s3,'x-amz-content-sha256':payload,'x-amz-date':date};
  const signed = Object.keys(headers).sort().join(';');
  const canonical = [method,path,'',Object.keys(headers).sort().map(k=>k+':'+headers[k]+'\n').join(''),signed,payload].join('\n');
  const scope = day+'/us-east-1/s3/aws4_request';
  const signing = hmac(hmac(hmac(hmac('AWS4'+key,day),'us-east-1'),'s3'),'aws4_request');
  headers.authorization = 'AWS4-HMAC-SHA256 Credential='+access+'/'+scope+', SignedHeaders='+signed+', Signature='+hmac(signing,['AWS4-HMAC-SHA256',date,scope,hash(canonical)].join('\n')).toString('hex');
  return fetch('http://'+s3+path,{method,headers,...(method==='PUT'?{body}:{}),signal:AbortSignal.timeout(5000)});
}
async function ready(fn) {
  for(let i=0;i<30;i++){try{if(await fn())return;}catch{} await new Promise(r=>setTimeout(r,1000));}
  throw new Error('Fixture readiness timeout');
}
await ready(async()=> (await request('GET','/')).ok);
await ready(async()=> (await fetch('http://'+mail+'/api/v1/messages',{signal:AbortSignal.timeout(3000)})).ok);
const bucket='/infra-fixture';
assert.equal((await request('PUT',bucket)).ok,true);
const path=bucket+'/probe.txt', payload='synthetic infrastructure fixture';
assert.equal((await request('PUT',path,payload)).ok,true);
assert.equal(await (await request('GET',path)).text(),payload);
assert.equal((await request('HEAD',path)).ok,true);
assert.equal((await request('GET',path,'','invalid')).status,403);
assert.equal((await fetch('http://'+s3+path,{signal:AbortSignal.timeout(5000)})).status,403);
assert.equal((await request('GET',bucket)).ok,true);
assert.equal((await request('DELETE',path)).ok,true);
assert.equal((await request('GET',path)).status,404);
assert.equal((await request('DELETE',bucket)).ok,true);
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
await ready(async()=>{const response=await fetch('http://'+mail+'/api/v1/messages',{signal:AbortSignal.timeout(3000)});const data=await response.json();return data.messages?.some(m=>m.Subject==='Infrastructure fixture');});
console.log('PASS: SMTP delivery captured locally');
