import { db } from '../index';

const TIER_CONFIG_COLLECTION = 'config_merchantTiers';

export async function fetchTierConfigs() {
  try {
    const snap = await db.collection(TIER_CONFIG_COLLECTION).get();
    if (snap.empty) return {};
    const map: Record<string, any> = {};
    snap.docs.forEach(d => { map[d.id] = d.data(); });
    return map;
  } catch (e) {
    console.warn('Failed to fetch tier configs, falling back to defaults', e);
    return {};
  }
}

// Default tier configs (used if none present in DB)
export const DEFAULT_TIERS: Record<string, any> = {
  'Tier0_Unregistered': {
    id: 'Tier0_Unregistered',
    name: 'Unregistered',
    description: 'Minimal onboarding; limited volume',
    singleLimit: 5000000,
    dailyLimit: 5000000,
    monthlyLimit: 5000000,
    cumulativeReceiptCap: 5000000,
    requiredDocuments: [],
  },
  'Tier1_BusinessName': {
    id: 'Tier1_BusinessName',
    name: 'Business Name',
    description: 'Registered business name; higher limits',
    singleLimit: 10000000,
    dailyLimit: 10000000,
    monthlyLimit: 10000000,
    cumulativeReceiptCap: 10000000,
    requiredDocuments: ['business_registration_document'],
  },
  'Tier2_LimitedCompany': {
    id: 'Tier2_LimitedCompany',
    name: 'Limited Company',
    description: 'Limited Company',
    singleLimit: 50000000,
    dailyLimit: 50000000,
    monthlyLimit: 50000000,
    cumulativeReceiptCap: 50000000,
    requiredDocuments: ['cac_certificate', 'directors_list'],
  }
};

export async function sumCompletedPayments(merchantId: string, start?: Date, end?: Date) {
  let q: FirebaseFirestore.Query = db.collection('payments').where('merchantId', '==', merchantId).where('status', '==', 'completed');
  if (start) q = q.where('createdAt', '>=', start);
  if (end) q = q.where('createdAt', '<=', end);
  const snap = await q.get();
  let total = 0;
  snap.docs.forEach(d => {
    const data = d.data();
    const amt = (data.amountNgn || data.amount || 0);
    total += Number(amt || 0);
  });
  return total;
}

export async function enforceTierLimits(merchantId: string, requestedAmount?: number) {
  // Fetch merchant
  const merchantRef = db.collection('merchants').doc(merchantId);
  const mSnap = await merchantRef.get();
  if (!mSnap.exists) throw new Error('Merchant not found');
  const merchant = mSnap.data() as any;

  const tierId = merchant.merchantTier || 'Tier0_Unregistered';

  const tierConfigs = await fetchTierConfigs();
  const tier = tierConfigs[tierId] || DEFAULT_TIERS[tierId] || DEFAULT_TIERS['Tier0_Unregistered'];

  // If no requestedAmount provided, nothing to check for single limit
  if (typeof requestedAmount === 'number' && requestedAmount > 0) {
    if (tier.singleLimit && requestedAmount > tier.singleLimit) {
      throw new Error(`Requested amount ₦${requestedAmount.toLocaleString()} exceeds single-transaction limit for your tier (${tier.name}): ₦${tier.singleLimit.toLocaleString()}`);
    }
  }

  // Check cumulative caps (all-time)
  if (tier.cumulativeReceiptCap) {
    const totalSoFar = await sumCompletedPayments(merchantId);
    const willBe = totalSoFar + (requestedAmount || 0);
    if (willBe > tier.cumulativeReceiptCap) {
      throw new Error(`This action would exceed your tier's cumulative receipt cap of ₦${tier.cumulativeReceiptCap.toLocaleString()}. Current received: ₦${totalSoFar.toLocaleString()}.`);
    }
  }

  // Check daily/monthly
  if (tier.dailyLimit) {
    const startOfDay = new Date(); startOfDay.setHours(0,0,0,0);
    const dayTotal = await sumCompletedPayments(merchantId, startOfDay);
    if (typeof requestedAmount === 'number' && (dayTotal + requestedAmount) > tier.dailyLimit) {
      throw new Error(`Daily limit exceeded for your tier (${tier.name}). Daily limit: ₦${tier.dailyLimit.toLocaleString()}. Today so far: ₦${dayTotal.toLocaleString()}.`);
    }
  }

  if (tier.monthlyLimit) {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const monthTotal = await sumCompletedPayments(merchantId, startOfMonth);
    if (typeof requestedAmount === 'number' && (monthTotal + requestedAmount) > tier.monthlyLimit) {
      throw new Error(`Monthly limit exceeded for your tier (${tier.name}). Monthly limit: ₦${tier.monthlyLimit.toLocaleString()}. This month so far: ₦${monthTotal.toLocaleString()}.`);
    }
  }
  // otherwise allowed
}
