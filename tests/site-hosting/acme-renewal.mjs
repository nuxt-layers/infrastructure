import assert from 'node:assert/strict';
import {request} from 'node:https';
import {readFileSync} from 'node:fs';
const [endpoint,caPath]=process.argv.slice(2);
assert.match(endpoint,/^127\.0\.0\.1:\d+$/);
const ca=readFileSync(caPath);
const names=['site-a.fixture.test','site-b.fixture.test'];
function probe(name){
  return new Promise((resolve,reject)=>{
    const req=request({hostname:'127.0.0.1',port:Number(endpoint.split(':')[1]),servername:name,headers:{host:name},ca,agent:false,timeout:3000},res=>{
      const cert=res.socket.getPeerCertificate();res.resume();
      res.on('error',reject);
      res.on('end',()=>{try{
        assert.equal(res.statusCode,200);
        assert.ok(cert.serialNumber&&cert.subjectaltname?.includes('DNS:'+name));
        const end=Date.parse(cert.valid_to),start=Date.parse(cert.valid_from);
        assert.ok(Number.isFinite(end)&&Number.isFinite(start)&&end>Date.now());
        assert.ok(end-start<=20*60*1000,'Not a short-validity fixture certificate');
        resolve({serial:cert.serialNumber,end});
      }catch(e){reject(e);}});
    });
    req.on('error',reject);req.on('timeout',()=>req.destroy(Error('request timeout')));req.end();
  });
}
const initial=new Map();
const deadline=Date.now()+120000;
while(initial.size<names.length&&Date.now()<deadline){
  for(const name of names)if(!initial.has(name)){
    try{initial.set(name,await probe(name));}catch(e){console.error(name+': '+e.message);}
  }
  if(initial.size<names.length)await new Promise(r=>setTimeout(r,1000));
}
assert.equal(initial.size,names.length,'Initial short-validity issuance failed');
console.log('PASS: both short-validity certificates trusted');
const renewed=new Map();
const until=Date.now()+180000;
while(Date.now()<until&&renewed.size<names.length){
  for(const name of names){
    // Every sample after initial readiness must succeed with full TLS validation.
    const current=await probe(name),old=initial.get(name);
    if(current.serial!==old.serial){
      assert.ok(Date.now()<old.end,'Renewal observed after original expiry');
      assert.ok(current.end>old.end,'Renewal did not extend expiry');
      if(!renewed.has(name))console.log('PASS: '+name+' renewed before expiry ('+old.serial+' -> '+current.serial+')');
      renewed.set(name,current);
    }else assert.ok(!renewed.has(name),'Previously renewed certificate reverted');
  }
  if(renewed.size<names.length)await new Promise(r=>setTimeout(r,1000));
}
assert.equal(renewed.size,names.length,'Automatic renewal not observed for both sites');
console.log('PASS: periodic automatic renewal with continuous sampled trusted HTTPS');
