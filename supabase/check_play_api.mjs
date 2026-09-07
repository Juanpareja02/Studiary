// Read-only connectivity check. Never prints the credential, JWT or OAuth token.
import { readFile } from 'node:fs/promises';
import { createSign } from 'node:crypto';

const credentials = JSON.parse(await readFile(process.argv[2], 'utf8'));
if (credentials.client_email !== 'studiary-play-verifier@studiary-app-2026.iam.gserviceaccount.com') {
  throw new Error('Unexpected service account');
}
const encode = value => Buffer.from(JSON.stringify(value)).toString('base64url');
const now = Math.floor(Date.now() / 1000);
const unsigned = encode({ alg: 'RS256', typ: 'JWT' }) + '.' + encode({
  iss: credentials.client_email,
  scope: 'https://www.googleapis.com/auth/androidpublisher',
  aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 3600,
});
const signature = createSign('RSA-SHA256').update(unsigned).sign(credentials.private_key, 'base64url');
const auth = await fetch('https://oauth2.googleapis.com/token', {
  method: 'POST', signal: AbortSignal.timeout(15000),
  body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: unsigned + '.' + signature }),
});
console.log('OAuth HTTP', auth.status);
if (!auth.ok) process.exit(1);
const { access_token } = await auth.json();
const base = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.studiary.app/';
for (const [label, path] of [
  ['Product read', 'inappproducts/studiary_premium_lifetime'],
  ['Invalid receipt rejection (not a purchase test)', 'purchases/products/studiary_premium_lifetime/tokens/studiary-connectivity-check-invalid-token'],
]) {
  const response = await fetch(base + path, {
    headers: { Authorization: 'Bearer ' + access_token }, signal: AbortSignal.timeout(15000),
  });
  const body = await response.json();
  console.log(label, JSON.stringify({ status: response.status,
    product: body.sku, state: body.status, errorReasons: body.error?.errors?.map(e => e.reason) }));
}
