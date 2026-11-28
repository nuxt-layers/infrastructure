import assert from 'node:assert/strict';
import {request} from 'node:https';
import {readFileSync} from 'node:fs';
const [endpoint,caPath,...previous]=process.argv.slice(2);
assert.match(endpoint,/^127\.0\.0\.1:\d+$/);
const ca=readFileSync(caPath);
const probe=name=>new Promise((resolve,reject)=>{
  const req=request({hostname:'127.0.0.1',port:Number(endpoint.split(':')[1]),servername:name,headers:{host:name},ca,agent:false,timeout:3000},res=>{
    const cert=res.socket.getPeerCertificate();res.resume();res.on('end',()=>resolve({status:res.statusCode,serial:cert.serialNumber,san:cert.subjectaltname}));
  });
  req.on('error',reject);req.on('timeout',()=>req.destroy(Error('timeout')));req.end();
});
for(const [i,name] of ['site-a.fixture.test','site-b.fixture.test'].entries()){
  let result,lastError;const until=Date.now()+120000;
  while(Date.now()<until){
    try{result=await probe(name);if(result.status===200)break;}
    catch(error){lastError=error.code??error.message;}
    await new Promise(r=>setTimeout(r,1000));
  }
  assert.equal(result?.status,200,'Trusted issued certificate unavailable: '+name+' at '+endpoint+'; last error: '+(lastError??'none'));
  assert.ok(result.san.includes('DNS:'+name)&&result.serial);
  if(previous.length)assert.equal(result.serial,previous[i],'Certificate changed across proxy restart');
  console.log(result.serial);
}
await assert.rejects(()=>probe('unknown.fixture.test'));
