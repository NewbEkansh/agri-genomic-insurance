// lib/api.ts — YieldShield Web API Client

const BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://13.60.58.137:8000';
const MOCK_MODE = process.env.NEXT_PUBLIC_MOCK_MODE !== 'false';

export const DEFAULT_FARMER_ID =
  process.env.NEXT_PUBLIC_FARMER_ID || '487b3114-80ba-4e64-8731-283be03f998e';

// ── Fetch helpers ─────────────────────────────────────────────────────────────

function getHeaders(token?: string) {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  // API key for AI teammate endpoints
  headers['X-API-Key'] = 'yieldshield-dev-key';
  // JWT for auth-protected endpoints
  const jwt = token || (typeof window !== 'undefined' ? localStorage.getItem('token') : null);
  if (jwt) headers['Authorization'] = `Bearer ${jwt}`;
  return headers;
}

async function apiFetch(path: string, options: RequestInit = {}, token?: string) {
  const res = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: { ...getHeaders(token), ...(options.headers || {}) },
  });
  if (!res.ok) throw new Error(`${path} → ${res.status}`);
  return res.json();
}

// ── Utility exports ───────────────────────────────────────────────────────────

export function ndviColor(value: number): string {
  if (value >= 0.6) return '#4ade80';
  if (value >= 0.4) return '#f59e0b';
  if (value >= 0.2) return '#f97316';
  return '#ef4444';
}

export function formatDisease(d: string): string {
  return d.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

export function shortHash(hash: string): string {
  if (!hash || hash.length < 12) return hash;
  return `${hash.slice(0, 8)}…${hash.slice(-6)}`;
}

// ── Mock data ─────────────────────────────────────────────────────────────────

const MOCK_FARMER = {
  name: 'Ekansh Kumar', farm_id: 'FARM_001',
  farmer_id: '487b3114-80ba-4e64-8731-283be03f998e',
  wallet_address: '0xC01B11d9F7631025cC4f57f8Bb7aCE8552AdB762',
  location: 'Punjab, India', farm_lat: 30.7333, farm_lon: 76.7794,
  farm_area_hectares: 4.2, insured_amount_usdc: 1200,
  insured_amount_eth: 1.0, crop_type: 'rice',
};
const MOCK_HEALTH = {
  farmer_id: '487b3114-80ba-4e64-8731-283be03f998e',
  current_ndvi: 0.18, baseline_ndvi: 0.72,
  ndvi_analysis: { delta: -0.54, pct_drop: 0.75, severity: 'critical', fraud_flag: false },
  soil_data: { soil_moisture: 0.21, soil_temp_celsius: 31.2, surface_temp_celsius: 36.5 },
};
const MOCK_PREDICTION = {
  prediction_id: 'pred-001', disease_type: 'rice_blast', confidence_score: 0.92,
  affected_area_percent: 0.65, payout_triggered: true, payout_multiplier: 1.0,
  regional_consensus_pct: 0.75,
  bedrock_assessment: 'High confidence detection of Magnaporthe oryzae (rice blast). Satellite NDVI confirms 75% vegetation collapse. Full payout approved.',
  payout_id: 'pay-001', created_at: new Date().toISOString(),
};
const MOCK_PAYOUTS = [{
  payout_id: 'pay-001', farm_id: 'FARM_001',
  farmer_wallet: '0xC01B11d9F7631025cC4f57f8Bb7aCE8552AdB762',
  insured_amount_usdc: 1200, payout_multiplier: 1.0, final_payout_usdc: 1200,
  tx_hash: '0x39db3dad642269c41dcca3c0f136b76637dbe18af09d85668755f734a680cbd2',
  status: 'confirmed', created_at: new Date(Date.now() - 2 * 86400000).toISOString(),
}];
const MOCK_POLICY = {
  policy_id: 'pol-001', farmer_id: '487b3114-80ba-4e64-8731-283be03f998e',
  insured_amount_usdc: 1200, status: 'active',
  created_at: new Date(Date.now() - 30 * 86400000).toISOString(),
};

// ── Auth ──────────────────────────────────────────────────────────────────────

// POST /auth/send-otp
async function sendOtp(phone: string): Promise<void> {
  if (MOCK_MODE) { await delay(600); return; }
  await apiFetch('/auth/send-otp', { method: 'POST', body: JSON.stringify({ phone }) });
}

// POST /auth/verify-otp → { token, farmer_id, is_new_farmer }
async function verifyOtp(phone: string, otp: string): Promise<{
  token: string; farmer_id: string; is_new_farmer: boolean;
}> {
  if (MOCK_MODE) {
    await delay(800);
    return { token: 'mock-jwt-token', farmer_id: DEFAULT_FARMER_ID, is_new_farmer: false };
  }
  return apiFetch('/auth/verify-otp', { method: 'POST', body: JSON.stringify({ phone, otp }) });
}

// ── Farmers ───────────────────────────────────────────────────────────────────

// POST /farmers/register  (no wallet_address — backend creates it)
async function registerFarmer(data: Record<string, unknown>, token?: string) {
  if (MOCK_MODE) { await delay(600); return MOCK_FARMER; }
  return apiFetch('/farmers/register', { method: 'POST', body: JSON.stringify(data) }, token);
}

// GET /farmers/{farmer_id}
async function getFarmer(id: string = DEFAULT_FARMER_ID) {
  if (MOCK_MODE) return MOCK_FARMER;
  return apiFetch(`/farmers/${id}`);
}

// GET /farmers/{farmer_id}/farm-health
async function getFarmHealth(id: string = DEFAULT_FARMER_ID) {
  if (MOCK_MODE) return MOCK_HEALTH;
  return apiFetch(`/farmers/${id}/farm-health`);
}

// GET /farmers/{farmer_id}/policies → { policies: [] }
async function getFarmerPolicies(id: string = DEFAULT_FARMER_ID) {
  if (MOCK_MODE) return { policies: [MOCK_POLICY] };
  try {
    const data = await apiFetch(`/farmers/${id}/policies`);
    return Array.isArray(data) ? { policies: data } : data;
  } catch { return { policies: [] }; }
}

// GET /farmers/{farmer_id}/predictions → { predictions: [] }
async function getFarmerPredictions(id: string = DEFAULT_FARMER_ID) {
  if (MOCK_MODE) return { predictions: [MOCK_PREDICTION] };
  try {
    const data = await apiFetch(`/predictions/farm/${id}`);
    return Array.isArray(data) ? { predictions: data } : data;
  } catch { return { predictions: [] }; }
}

// GET /farmers/{farmer_id}/payouts → { payouts: [] }
async function getFarmerPayouts(id: string = DEFAULT_FARMER_ID) {
  if (MOCK_MODE) return { payouts: MOCK_PAYOUTS };
  try {
    const data = await apiFetch(`/farmers/${id}/payouts`);
    return Array.isArray(data) ? { payouts: data } : data;
  } catch { return { payouts: [] }; }
}

// ── Image Upload ──────────────────────────────────────────────────────────────

// POST /images/upload/{farmer_id}  (multipart/form-data)
// Returns prediction result directly
async function uploadCropImage(farmerId: string, file: File) {
  if (MOCK_MODE) {
    await delay(2000);
    return MOCK_PREDICTION;
  }
  const formData = new FormData();
  formData.append('image', file);
  const jwt = typeof window !== 'undefined' ? localStorage.getItem('token') : null;
  const res = await fetch(`${BASE_URL}/images/upload/${farmerId}`, {
    method: 'POST',
    headers: {
      'X-API-Key': 'yieldshield-dev-key',
      ...(jwt ? { Authorization: `Bearer ${jwt}` } : {}),
    },
    body: formData,
  });
  if (!res.ok) throw new Error(`Image upload failed: ${res.status}`);
  return res.json();
}

// ── Policies ──────────────────────────────────────────────────────────────────

async function createPolicy(farmerId: string, amount: number) {
  if (MOCK_MODE) return MOCK_POLICY;
  return apiFetch('/policies/create', { method: 'POST',
    body: JSON.stringify({ farmer_id: farmerId, insured_amount_usdc: amount }) });
}

async function cancelPolicy(policyId: string) {
  if (MOCK_MODE) return { ...MOCK_POLICY, status: 'cancelled' };
  return apiFetch(`/policies/${policyId}/cancel`, { method: 'PATCH' });
}

// ── Predictions ───────────────────────────────────────────────────────────────

async function getPayoutStatus(payoutId: string) {
  if (MOCK_MODE) return MOCK_PAYOUTS[0];
  try { return await apiFetch(`/predictions/payout/${payoutId}`); }
  catch { return null; }
}

// ── Misc ──────────────────────────────────────────────────────────────────────

async function healthCheck() {
  if (MOCK_MODE) return { status: 'ok' };
  try { return await apiFetch('/health/'); } catch { return { status: 'error' }; }
}

function delay(ms: number) { return new Promise(r => setTimeout(r, ms)); }

// ── Named export ──────────────────────────────────────────────────────────────

export const api = {
  // Auth
  sendOtp,
  verifyOtp,
  // Farmers
  registerFarmer,
  getFarmer,
  getFarmHealth,
  getFarmerPolicies,
  getFarmerPredictions,
  getFarmerPayouts,
  // Image
  uploadCropImage,
  // Policies
  createPolicy,
  cancelPolicy,
  // Predictions
  getPayoutStatus,
  // Misc
  healthCheck,
};

export default api;