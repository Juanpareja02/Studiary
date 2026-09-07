export function purchaseStatus(product: string, purchase: Record<string, any>, uid: string, now: number) {
  const linked = purchase.obfuscatedExternalAccountId ?? purchase.externalAccountIdentifiers?.obfuscatedExternalAccountId
  if (linked && linked !== uid) return {active: false, expiresAt: null}
  if (product === 'studiary_premium_lifetime') {
    return {active: purchase.purchaseState === 0 && (purchase.productId == null || purchase.productId === product), expiresAt: null}
  }
  const line = purchase.lineItems?.find((item: any) => item.productId === product && Date.parse(item.expiryTime) > now)
  const allowed = ['SUBSCRIPTION_STATE_ACTIVE', 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD', 'SUBSCRIPTION_STATE_CANCELED']
  return {active: !!line && allowed.includes(purchase.subscriptionState), expiresAt: line?.expiryTime ?? null}
}
