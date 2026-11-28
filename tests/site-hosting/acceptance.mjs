import assert from 'node:assert/strict';
import { createServer } from 'node:https';
import { request } from 'node:https';
import { createServer as createHttp, request as httpRequest } from 'node:http';
import { createSecureContext } from 'node:tls';
import { createSocket } from 'node:dgram';
import { Resolver } from 'node:dns/promises';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { once } from 'node:events';
const folder=process.argv[2];
const sites=['site-a.fixture.test','site-b.fixture.test'];
const read=name=>readFileSync(join(folder,name));
const credentials=Object.fromEntries(sites.map(site=>[site,{key:read(site+'.key'),cert:read(site+'.crt')}]));
const contexts=Object.fromEntries(sites.map(site=>[site,createSecureContext(credentials[site])]));
const ca=read('ca.pem');
const wrong=read('wrong.pem');
const dns=createSocket('udp4');
// Minimal authoritative A-only test responder: exact names, no forwarding.
dns.on('message',(packet,remote)=>{
 if(packet.length<17||packet.readUInt16BE(4)!==1)return;
 let offset=12;const labels=[];
 while(offset<packet.length&&packet[offset]!==0){
  const length=packet[offset++];if(length>63||offset+length>packet.length)return;
  labels.push(packet.subarray(offset,offset+length).toString('ascii'));offset+=length;
 }
 if(offset+5>packet.length)return;
 offset++;const type=packet.readUInt16BE(offset),cls=packet.readUInt16BE(offset+2);offset+=4;
 const known=sites.includes(labels.join('.').toLowerCase());
 const answer=known&&type===1&&cls===1;
 const header=Buffer.alloc(12);packet.copy(header,0,0,2);header.writeUInt16BE(known?0x8400:0x8403,2);header.writeUInt16BE(1,4);header.writeUInt16BE(answer?1:0,6);
 const record=Buffer.from([0xc0,0x0c,0,1,0,1,0,0,0,30,0,4,127,0,0,1]);
 dns.send(Buffer.concat([header,packet.subarray(12,offset),...(answer?[record]:[])]),remote.port,remote.address);
});
const server=createServer({...credentials[sites[0]],minVersion:'TLSv1.2',SNICallback:(name,cb)=>contexts[name]?cb(null,contexts[name]):cb(Error('Unknown site'))},(req,res)=>{
 const host=req.headers.host?.split(':')[0];
 if(!sites.includes(host)||host!==req.socket.servername){res.writeHead(421);return res.end();}
 res.writeHead(200,{'content-type':'text/plain'});res.end(host);
});
const http=createHttp((req,res)=>{
 const host=req.headers.host?.split(':')[0];
 if(!sites.includes(host)){res.writeHead(421);return res.end();}
 res.writeHead(308,{location:'https://'+host+':'+server.address().port+'/'});res.end();
});
async function listen(s){s.listen(0,'127.0.0.1');await once(s,'listening');}
try {
 dns.bind(0,'127.0.0.1');await once(dns,'listening');
 const resolver=new Resolver({timeout:1000,tries:1});
 resolver.setServers(['127.0.0.1:'+dns.address().port]);
 for(const site of sites)assert.deepEqual(await resolver.resolve4(site),['127.0.0.1']);
 await assert.rejects(()=>resolver.resolve4('unknown.fixture.test'),{code:'ENOTFOUND'});
 console.log('PASS: isolated authoritative DNS and unknown-name rejection');
 await listen(server);await listen(http);
 function call(site,{trust=ca,host=site,servername=site,version}={}){
  return new Promise((resolve,reject)=>{
   const req=request({hostname:'127.0.0.1',port:server.address().port,servername,ca:trust,headers:{host},agent:false,...(version?{maxVersion:version}:{}),timeout:3000},res=>{
    let body='';res.on('data',c=>body+=c);res.on('end',()=>resolve({status:res.statusCode,body}));
   });req.on('error',reject);req.on('timeout',()=>req.destroy(Error('Timeout')));req.end();
  });
 }
 for(const site of sites)assert.deepEqual(await call(site),{status:200,body:site});
 await assert.rejects(()=>call(sites[0],{trust:wrong}),{code:'UNABLE_TO_VERIFY_LEAF_SIGNATURE'});
 await assert.rejects(()=>call(sites[0],{servername:'unknown.fixture.test'}));
 assert.equal((await call(sites[0],{host:sites[1]})).status,421);
 function redirectProbe(host){
  return new Promise((resolve,reject)=>{
   const req=httpRequest({hostname:'127.0.0.1',port:http.address().port,headers:{Host:host},agent:false,timeout:3000},res=>{
    res.resume();res.on('end',()=>resolve({status:res.statusCode,location:res.headers.location}));res.on('error',reject);
   });
   req.on('error',reject);req.on('timeout',()=>req.destroy(Error('HTTP redirect probe timeout')));req.end();
  });
 }
 for(const site of sites){
  const response=await redirectProbe(site);
  assert.equal(response.status,308);assert.equal(response.location,'https://'+site+':'+server.address().port+'/');
 }
 const unknown=await redirectProbe('unknown.fixture.test');
 assert.equal(unknown.status,421);assert.equal(unknown.location,undefined);
 console.log('PASS: local CA trust, SNI multi-site routing, cross-site denial, HTTP redirect');
} finally {
 dns.close();server.close();http.close();
}
