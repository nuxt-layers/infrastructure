// Offline protocol model only; no provider network, credentials or financial transactions.
import assert from 'node:assert/strict';
import {createHmac,timingSafeEqual,randomBytes} from 'node:crypto';
const key=randomBytes(32);
const records=new Map(), operations=new Map(), delivered=new Set();
let sequence=0;
function operation(merchant,idempotency,input){
  assert.match(merchant,/^synthetic-[ab]$/);
  const scope=merchant+':'+idempotency, fingerprint=JSON.stringify(input);
  if(operations.has(scope)){
    const prior=operations.get(scope);
    assert.equal(prior.fingerprint,fingerprint,'idempotency conflict');
    return prior.result;
  }
  if(operations.size>=100)throw Error('capacity');
  let result;
  if(input.action==='authorise'){
    assert.ok(Number.isSafeInteger(input.amount)&&input.amount>0);
    const id='fixture-'+ ++sequence;
    result={id,status:input.decline?'declined':'authorised',amount:input.amount};
    records.set(id,{...result,merchant});
  }else{
    const record=records.get(input.id);
    if(!record||record.merchant!==merchant)throw Error('not found');
    const allowed={capture:'authorised',cancel:'authorised',refund:'captured'};
    if(!Object.hasOwn(allowed,input.action)||record.status!==allowed[input.action])throw Error('invalid transition');
    record.status={capture:'captured',cancel:'cancelled',refund:'refunded'}[input.action];
    result={id:record.id,status:record.status,amount:record.amount};
  }
  operations.set(scope,{fingerprint,result});return result;
}
function signature(timestamp,body){return createHmac('sha256',key).update(timestamp+'.'+body).digest();}
function consume(timestamp,body,mac,now){
  if(!Number.isSafeInteger(timestamp)||Math.abs(now-timestamp)>300||!Buffer.isBuffer(mac)||mac.length!==32||!timingSafeEqual(mac,signature(timestamp,body)))throw Error('invalid callback');
  const event=JSON.parse(body);
  if(delivered.has(event.id))return false;
  delivered.add(event.id);return true;
}
const a='synthetic-a',b='synthetic-b';
const create={action:'authorise',amount:100};
const first=operation(a,'create',create);
assert.deepEqual(operation(a,'create',create),first);
assert.throws(()=>operation(a,'create',{...create,amount:101}),/conflict/);
assert.notEqual(operation(b,'create',create).id,first.id);
assert.throws(()=>operation(b,'steal',{action:'capture',id:first.id}),/not found/);
assert.equal(operation(a,'capture',{action:'capture',id:first.id}).status,'captured');
assert.equal(operation(a,'refund',{action:'refund',id:first.id}).status,'refunded');
assert.throws(()=>operation(a,'again',{action:'capture',id:first.id}),/invalid transition/);
const cancel=operation(a,'cancel-create',create);
assert.equal(operation(a,'cancel',{action:'cancel',id:cancel.id}).status,'cancelled');
assert.equal(operation(a,'decline',{...create,decline:true}).status,'declined');
const now=100000,body=JSON.stringify({id:'event-1',type:'synthetic.capture'});
assert.equal(consume(now,body,signature(now,body),now),true);
assert.equal(consume(now,body,signature(now,body),now),false);
assert.throws(()=>consume(now,body,Buffer.alloc(32),now),/invalid callback/);
assert.throws(()=>consume(now,body,signature(now,body),now+301),/invalid callback/);
assert.throws(()=>consume(now,body+' ',signature(now,body),now),/invalid callback/);
console.log('PASS: offline payment transitions, merchant scope, idempotency and signed callback replay/tamper/expiry');
