import assert from 'node:assert/strict';
import {request} from 'node:https';
import {readFileSync} from 'node:fs';
import {join} from 'node:path';
const [endpoint,folder,phase]=process.argv.slice(2);
assert.match(endpoint,/^127\.0\.0\.1:\d+$/);
assert.ok(['apply','withdraw','reapply'].includes(phase));
const ca=readFileSync(join(folder,'ca.pem'));
const wrong=readFileSync(join(folder,'wrong.pem'));
const call=(name,trust=ca)=>new Promise((resolve,reject)=>{
    const req=request({hostname:'127.0.0.1',port:Number(endpoint.split(':')[1]),servername:name,ca:trust,agent:false,timeout:3000,headers:{host:name,'x-forwarded-host':'attacker.invalid','x-forwarded-proto':'http','x-forwarded-for':'203.0.113.42'}},res=>{
        let body='';res.setEncoding('utf8');res.on('data',c=>{body+=c;if(body.length>16384)res.destroy(Error('oversized response'));});
        res.on('error',reject);res.on('end',()=>resolve({status:res.statusCode,body}));
    });
    req.on('error',reject);req.on('timeout',()=>req.destroy(Error('request timeout')));req.end();
});
async function wait(name,status){
    const deadline=Date.now()+30000;let last;
    do{try{last=await call(name);if(last.status===status)return last;}catch(error){last=error.message;}await new Promise(r=>setTimeout(r,500));}while(Date.now()<deadline);
    throw Error(name+' expected '+status+', observed '+JSON.stringify(last));
}
for(const site of ['site-a','site-b']){
    const name=site+'.fixture.test';
    const expected=phase==='withdraw'&&site==='site-a'?404:200;
    const res=await wait(name,expected);
    if(expected===200){
        const [marker,host,proto,forwarded]=res.body.trim().split('|');
        assert.equal(marker,site);assert.equal(host,name);assert.equal(proto,'https');
        assert.ok(forwarded&&!forwarded.includes('203.0.113.42'),'untrusted forwarded-for leaked');
    }
}
if(phase==='apply'){
    await assert.rejects(()=>call('site-a.fixture.test',wrong));
    await assert.rejects(()=>call('unknown.fixture.test'));
}
console.log('PASS: Traefik route '+phase+', trusted TLS and forwarded-header boundary');
