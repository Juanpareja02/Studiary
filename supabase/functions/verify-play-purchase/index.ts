import { createClient } from 'npm:@supabase/supabase-js@2'
import { purchaseStatus } from './purchase_status.ts'

const headers = {'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Content-Type': 'application/json'}
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {status, headers})
const lifetime = 'studiary_premium_lifetime'
const products = new Set([lifetime, 'studiary_premium_monthly', 'studiary_premium_yearly'])
const packageName = 'com.studiary.app'
let oauth: {token: string, until: number} | undefined
let purchaseApiReadyUntil = 0
function key(current: string, legacy: string) {
  const raw = Deno.env.get(current)
  return raw ? JSON.parse(raw).default : Deno.env.get(legacy)
}
const encode = (bytes: Uint8Array) => btoa(String.fromCharCode(...bytes)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
const utf8 = (text: string) => new TextEncoder().encode(text)

async function accessToken() {
  if (oauth && oauth.until > Date.now()) return oauth.token
  const credentials = JSON.parse(Deno.env.get('PLAY_SERVICE_ACCOUNT_JSON') ?? '{}')
  if (!credentials.client_email || !credentials.private_key) throw new Error('verification_not_configured')
  const seconds = Math.floor(Date.now() / 1000)
  const payload = {iss: credentials.client_email, scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token', iat: seconds, exp: seconds + 3600}
  const data = encode(utf8(JSON.stringify({alg: 'RS256', typ: 'JWT'}))) + '.' + encode(utf8(JSON.stringify(payload)))
  const der = Uint8Array.from(atob(credentials.private_key.replace(/-----[^-]+-----|\s/g, '')), ch => ch.charCodeAt(0))
  const signingKey = await crypto.subtle.importKey('pkcs8', der, {name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256'}, false, ['sign'])
  const signature = new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', signingKey, utf8(data)))
  const response = await fetch('https://oauth2.googleapis.com/token', {method: 'POST',
    signal: AbortSignal.timeout(10000), body: new URLSearchParams({grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: data + '.' + encode(signature)})})
  if (!response.ok) throw new Error('google_auth_unavailable')
  const result = await response.json()
  oauth = {token: result.access_token, until: Date.now() + 3300000}
  return oauth.token
}

async function verify(product: string, token: string, uid: string) {
  const path = product === lifetime ? 'products/' + encodeURIComponent(product) + '/tokens/' + encodeURIComponent(token)
    : 'subscriptionsv2/tokens/' + encodeURIComponent(token)
  const response = await fetch('https://androidpublisher.googleapis.com/androidpublisher/v3/applications/' + packageName + '/purchases/' + path,
    {headers: {Authorization: 'Bearer ' + await accessToken()}, signal: AbortSignal.timeout(10000)})
  if (response.status === 404 || response.status === 410) return {active: false, expiresAt: null}
  if (!response.ok) throw new Error('google_verification_unavailable')
  return purchaseStatus(product, await response.json(), uid, Date.now())
}

async function checkPurchaseApi() {
  if (purchaseApiReadyUntil > Date.now()) return
  // OAuth alone does not prove this account has Play purchase permissions.
  // A deliberately invalid receipt checks access without buying anything.
  const response = await fetch('https://androidpublisher.googleapis.com/androidpublisher/v3/applications/' + packageName +
    '/purchases/products/' + lifetime + '/tokens/studiary-connectivity-check-invalid-token', {
    headers: {Authorization: 'Bearer ' + await accessToken()}, signal: AbortSignal.timeout(10000),
  })
  const result = await response.json()
  const invalidReceipt = response.status === 400 && result.error?.errors?.some(
    (error: {reason: string}) => ['invalid', 'purchaseTokenInvalid', 'invalidValue'].includes(error.reason))
  if (response.status !== 404 && !invalidReceipt) throw new Error('play_permissions_unavailable')
  purchaseApiReadyUntil = Date.now() + 60000
}

Deno.serve(async request => {
  if (request.method === 'OPTIONS') return new Response('ok', {headers})
  if (request.method !== 'POST') return json({error: 'method_not_allowed'}, 405)
  const authorization = request.headers.get('Authorization') ?? ''
  if (!authorization.startsWith('Bearer ')) return json({error: 'unauthorized'}, 401)
  try {
    const client = createClient(Deno.env.get('SUPABASE_URL')!, key('SUPABASE_PUBLISHABLE_KEYS', 'SUPABASE_ANON_KEY'),
      {global: {headers: {Authorization: authorization}}, auth: {persistSession: false}})
    const {data: {user}, error: authError} = await client.auth.getUser()
    if (authError || !user) return json({error: 'unauthorized'}, 401)
    if (Number(request.headers.get('content-length') ?? 0) > 16384) return json({error: 'too_large'}, 413)
    const text = await request.text()
    if (text.length > 16384) return json({error: 'too_large'}, 413)
    let body: Record<string, unknown>
    try { body = JSON.parse(text) } catch { return json({error: 'invalid_json'}, 400) }
    if (!body || typeof body !== 'object') return json({error: 'invalid_request'}, 400)
    const admin = createClient(Deno.env.get('SUPABASE_URL')!, key('SUPABASE_SECRET_KEYS', 'SUPABASE_SERVICE_ROLE_KEY'), {auth: {persistSession: false}})
    await checkPurchaseApi() // Fail closed before enabling a purchase button.
    const entries: {product_id: string, purchase_token: string, token_hash: string}[] = []
    if (body.action === 'verify') {
      const product = body.productId, token = body.purchaseToken
      if (typeof product !== 'string' || !products.has(product) || typeof token !== 'string' || token.length < 10 || token.length > 8192) {
        return json({error: 'invalid_purchase'}, 400)
      }
      const hash = encode(new Uint8Array(await crypto.subtle.digest('SHA-256', utf8(token))))
      const initialStatus = await verify(product, token, user.id)
      if (!initialStatus.active) {
        const {error} = await admin.from('play_purchases').update({active: false, verified_at: new Date().toISOString()})
          .eq('token_hash', hash).eq('user_id', user.id)
        if (error) throw new Error('purchase_storage_unavailable')
        return json({ready: true, verified: false, error: 'purchase_not_active'})
      }
      // Inserting, not upserting ownership: concurrent claims cannot steal a token.
      const {error: insertError} = await admin.from('play_purchases').insert({token_hash: hash, user_id: user.id, product_id: product, purchase_token: token})
      if (insertError && insertError.code !== '23505') throw new Error('purchase_storage_unavailable')
      const {data: stored, error} = await admin.from('play_purchases').select('user_id,product_id').eq('token_hash', hash).single()
      if (error) throw new Error('purchase_storage_unavailable')
      if (stored.user_id !== user.id || stored.product_id !== product) return json({error: 'purchase_belongs_to_another_account'}, 409)
      entries.push({product_id: product, purchase_token: token, token_hash: hash})
    } else if (body.action === 'check') {
      const {data, error} = await admin.from('play_purchases').select('product_id,purchase_token,token_hash').eq('user_id', user.id).eq('active', true).limit(20)
      if (error) throw new Error('purchase_storage_unavailable')
      entries.push(...(data ?? []))
    } else { return json({error: 'invalid_action'}, 400) }
    let verified = false
    for (const entry of entries) {
      const result = await verify(entry.product_id, entry.purchase_token, user.id)
      const {error} = await admin.from('play_purchases').update({active: result.active, expires_at: result.expiresAt,
        verified_at: new Date().toISOString()}).eq('token_hash', entry.token_hash).eq('user_id', user.id)
      if (error) throw new Error('purchase_storage_unavailable')
      verified ||= result.active
    }
    const {data: valid, error: validError} = await admin.from('play_purchases').select('product_id,expires_at').eq('user_id', user.id)
      .eq('active', true).or('expires_at.is.null,expires_at.gt.' + new Date().toISOString())
    if (validError) throw new Error('purchase_storage_unavailable')
    const best = valid?.find(p => p.expires_at === null) ?? valid?.sort((a, b) => Date.parse(b.expires_at) - Date.parse(a.expires_at))[0]
    const {error} = await admin.from('premium_entitlements').upsert({user_id: user.id, active: !!best,
      product_id: best?.product_id ?? null, expires_at: best?.expires_at ?? null, verified_at: new Date().toISOString()})
    if (error) throw new Error('entitlement_storage_unavailable')
    return json({ready: true, premium: !!best, verified})
  } catch (error) {
    // Never log bearer tokens, receipts, private keys, or Google's response body.
    console.error(error instanceof Error ? error.name : 'verification_error')
    return json({ready: false, error: 'verification_temporarily_unavailable'}, 503)
  }
})
