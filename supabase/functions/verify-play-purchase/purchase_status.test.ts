import {test} from 'node:test'
import assert from 'node:assert/strict'
import {purchaseStatus} from './purchase_status.ts'

const uid = 'account-a'
const now = Date.parse('2026-09-05T12:00:00Z')
test('only purchased lifetime transactions unlock Premium', () => {
  for (const state of [1, 2, undefined, '0']) {
    assert.equal(purchaseStatus('studiary_premium_lifetime', {purchaseState: state}, uid, now).active, false)
  }
  assert.equal(purchaseStatus('studiary_premium_lifetime', {purchaseState: 0}, uid, now).active, true)
})
test('rejects another account and another SKU', () => {
  assert.equal(purchaseStatus('studiary_premium_lifetime', {purchaseState: 0, obfuscatedExternalAccountId: 'account-b'}, uid, now).active, false)
  assert.equal(purchaseStatus('studiary_premium_lifetime', {purchaseState: 0, productId: 'other'}, uid, now).active, false)
})
test('legacy subscription keeps access until cancellation expiry', () => {
  const data = {subscriptionState: 'SUBSCRIPTION_STATE_CANCELED', lineItems: [{productId: 'studiary_premium_monthly', expiryTime: '2026-10-01T00:00:00Z'}]}
  assert.equal(purchaseStatus('studiary_premium_monthly', data, uid, now).active, true)
  assert.equal(purchaseStatus('studiary_premium_monthly', data, uid, now + 90 * 86400000).active, false)
})
test('pending, expired, paused and held subscriptions never unlock', () => {
  for (const state of ['SUBSCRIPTION_STATE_PENDING', 'SUBSCRIPTION_STATE_EXPIRED', 'SUBSCRIPTION_STATE_PAUSED', 'SUBSCRIPTION_STATE_ON_HOLD']) {
    assert.equal(purchaseStatus('studiary_premium_yearly', {subscriptionState: state,
      lineItems: [{productId: 'studiary_premium_yearly', expiryTime: '2027-01-01T00:00:00Z'}]}, uid, now).active, false)
  }
})
