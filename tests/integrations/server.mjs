// Local synthetic protocol fixture; never a production identity provider.
import { createServer } from 'node:http';
import { generateKeyPairSync, sign, randomUUID, timingSafeEqual } from 'node:crypto';
const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const jwk = {...publicKey.export({format:'jwk'}), kid:'fixture', alg:'RS256', use:'sig'};
const codes = new Map();
const used = new Map();
const b64 = x => Buffer.from(JSON.stringify(x)).toString('base64url');
const equal = (a,b) => typeof a==='string' && typeof b==='string' && Buffer.byteLength(a)===Buffer.byteLength(b) && timingSafeEqual(Buffer.from(a),Buffer.from(b));
const { createHash } = await import('node:crypto');
let issuer;
function reply(res,status,body,headers={}) { res.writeHead(status,{'content-type':'application/json','cache-control':'no-store',...headers}); res.end(JSON.stringify(body)); }
async function body(req) { let s=''; for await(const chunk of req){s+=chunk;if(Buffer.byteLength(s)>16384)throw Error('oversized');} return new URLSearchParams(s); }
function jwt(claims) { const data=b64({alg:'RS256',kid:'fixture',typ:'JWT'})+'.'+b64(claims);return data+'.'+sign('RSA-SHA256',Buffer.from(data),privateKey).toString('base64url'); }
const server=createServer(async(req,res)=>{
 try {
  const url=new URL(req.url,issuer);
  if(req.method==='GET' && url.pathname==='/health')return reply(res,200,{status:'ready',scope:'synthetic'});
  if(req.method==='GET' && url.pathname==='/.well-known/openid-configuration')return reply(res,200,{issuer,authorization_endpoint:issuer+'/authorize',token_endpoint:issuer+'/token',jwks_uri:issuer+'/jwks',response_types_supported:['code'],subject_types_supported:['public'],id_token_signing_alg_values_supported:['RS256'],code_challenge_methods_supported:['S256'],token_endpoint_auth_methods_supported:['none'],scopes_supported:['openid']});
  if(req.method==='GET' && url.pathname==='/jwks')return reply(res,200,{keys:[jwk]});
  if(req.method==='GET' && url.pathname==='/authorize'){
   const q=url.searchParams, redirect=q.get('redirect_uri'), challenge=q.get('code_challenge'), nonce=q.get('nonce'), state=q.get('state');
   if(q.get('client_id')!=='fixture-client'||redirect!==issuer+'/callback'||q.get('response_type')!=='code'||q.get('scope')!=='openid'||q.get('code_challenge_method')!=='S256'||!/^[-_a-zA-Z0-9]{43}$/.test(challenge??'')||!nonce||!state)return reply(res,400,{error:'invalid_request'});
   for(const [k,v] of codes)if(v.expires<Date.now())codes.delete(k);
   if(codes.size>=100)return reply(res,429,{error:'fixture_capacity'});
   const code=randomUUID();codes.set(code,{challenge,nonce,redirect,expires:Date.now()+60000});
   const target=new URL(redirect);target.searchParams.set('code',code);target.searchParams.set('state',state);
   res.writeHead(302,{location:target.href,'cache-control':'no-store'});return res.end();
  }
  if(req.method==='POST' && url.pathname==='/token'){
   const q=await body(req), code=q.get('code'), record=codes.get(code);
   const verifier=q.get('code_verifier')??'';
   if(q.get('grant_type')!=='authorization_code'||q.get('client_id')!=='fixture-client'||!record||record.expires<Date.now()||q.get('redirect_uri')!==record.redirect||!/^[-._~a-zA-Z0-9]{43,128}$/.test(verifier)||!equal(createHash('sha256').update(verifier).digest('base64url'),record.challenge))return reply(res,400,{error:'invalid_grant'});
   codes.delete(code);
   const now=Math.floor(Date.now()/1000);
   return reply(res,200,{token_type:'Bearer',expires_in:60,access_token:randomUUID(),id_token:jwt({iss:issuer,sub:'synthetic-subject',aud:'fixture-client',iat:now,exp:now+60,nonce:record.nonce})});
  }
  if(req.method==='GET' && url.pathname==='/fault/rate-limit')return reply(res,429,{error:'rate_limited'},{'retry-after':'1'});
  if(req.method==='GET' && url.pathname==='/fault/unavailable')return reply(res,503,{error:'unavailable'},{'retry-after':'1'});
  if(req.method==='GET' && url.pathname==='/fault/timeout'){const timer=setTimeout(()=>reply(res,200,{late:true}),2000);res.on('close',()=>clearTimeout(timer));return;}
  if(req.method==='POST' && url.pathname==='/operations'){
   const key=req.headers['idempotency-key'];const payload=await body(req);const value=payload.toString();
   if(typeof key!=='string'||key.length>128||!key)return reply(res,400,{error:'missing_key'});
   if(used.has(key)){const entry=used.get(key);return equal(entry.value,value)?reply(res,200,entry.result):reply(res,409,{error:'conflict'});}
   if(used.size>=100)return reply(res,429,{error:'fixture_capacity'});
   const result={id:randomUUID(),status:'accepted'};used.set(key,{value,result});return reply(res,201,result);
  }
  return reply(res,404,{error:'not_found'});
 }catch{return reply(res,400,{error:'invalid_request'});}
});
server.requestTimeout=5000;
server.headersTimeout=5000;
server.maxConnections=32;
server.listen(0,'127.0.0.1',()=>{issuer='http://127.0.0.1:'+server.address().port;console.log(issuer);});
