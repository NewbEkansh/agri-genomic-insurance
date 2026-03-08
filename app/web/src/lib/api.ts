import type { Farmer, FarmerInput, FarmHealth, Policy, Prediction, PayoutRecord } from '@/types';

const BASE = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000';
const MOCK = process.env.NEXT_PUBLIC_MOCK_MODE === 'true';

const MOCK_FARMER: Farmer = {
  farmer_id: 'demo-farmer-001', name: 'Ekansh Kumar', phone: '+919876543210',
  wallet_address: '0xC01B11d9F7631025cC4f57f8Bb7aCE8552AdB762', crop_type: 'rice',
  farm_lat: 28.6139, farm_lon: 77.209, farm_area_hectares: 3.5, language: 'hindi',
  agro_polygon_id: 'agro-demo-001', baseline_ndvi: 0.72, created_at: '2025-03-01T10:00:00Z',
};
const MOCK_HEALTH: FarmHealth = {
  farmer_id: 'demo-farmer-001', current_ndvi: 0.18, baseline_ndvi: 0.72,
  soil_data: { soil_moisture: 0.21, soil_temp_celsius: 31.2, surface_temp_celsius: 36.5 },
  ndvi_analysis: { delta: -0.54, pct_drop: 0.75, severity: 'critical', fraud_flag: false },
};
const MOCK_POLICIES: Policy[] = [{
  policy_id: 'pol-001', farmer_id: 'demo-farmer-001',
  insured_amount_usdc: 1000, status: 'triggered', created_at: '2025-03-01T10:00:00Z',
}];
const MOCK_PREDICTIONS: Prediction[] = [
  {
    prediction_id: 'pred-001', disease_type: 'rice_blast', confidence_score: 0.92,
    affected_area_percent: 0.65, payout_triggered: true, payout_multiplier: 1.0,
    regional_consensus_pct: 0.75,
    bedrock_assessment: 'High confidence detection of Magnaporthe oryzae (rice blast). Lesion patterns consistent with acute outbreak. Satellite NDVI confirms 75% vegetation collapse vs. baseline. Regional consensus (4/5 neighbouring farms affected) validates genuine disease event. Full payout approved.',
    payout_id: 'pay-001', created_at: '2025-03-06T14:22:00Z',
  },
  {
    prediction_id: 'pred-002', disease_type: 'bacterial_blight', confidence_score: 0.61,
    affected_area_percent: 0.3, payout_triggered: false, payout_multiplier: 0,
    regional_consensus_pct: 0.2,
    bedrock_assessment: 'Moderate confidence detection of bacterial blight markers. Confidence below 85% threshold. No payout triggered. Recommend continued monitoring.',
    payout_id: null, created_at: '2025-02-20T09:11:00Z',
  },
];
const MOCK_PAYOUTS: PayoutRecord[] = [{
  payout_id: 'pay-001', farm_id: 'demo-farmer-001',
  farmer_wallet: '0xC01B11d9F7631025cC4f57f8Bb7aCE8552AdB762',
  insured_amount_usdc: 1000, payout_multiplier: 1.0, final_payout_usdc: 1000,
  tx_hash: '0xdeadbeef1234567890abcdef1234567890abcdef1234567890abcdef12345678',
  status: 'confirmed', created_at: '2025-03-06T14:22:05Z',
}];

async function get<T>(path: string): Promise<T> {
  const res = await fetch(`${BASE}${path}`);
  if (!res.ok) throw new Error(`GET ${path} → ${res.status}`);
  return res.json();
}
async function post<T>(path: string, body: unknown): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`POST ${path} → ${res.status}`);
  return res.json();
}
async function patch<T>(path: string, body?: unknown): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    method: 'PATCH', headers: { 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) throw new Error(`PATCH ${path} → ${res.status}`);
  return res.json();
}

export const api = {
  healthCheck: (): Promise<{ status: string }> =>
    MOCK ? Promise.resolve({ status: 'ok' }) : get('/health/'),
  registerFarmer: (data: FarmerInput): Promise<{ farmer_id: string }> =>
    MOCK ? Promise.resolve({ farmer_id: 'demo-farmer-001' }) : post('/farmers/register', data),
  getFarmer: (id: string): Promise<Farmer> =>
    MOCK ? Promise.resolve(MOCK_FARMER) : get(`/farmers/${id}`),
  getFarmHealth: (id: string): Promise<FarmHealth> =>
    MOCK ? Promise.resolve(MOCK_HEALTH) : get(`/farmers/${id}/farm-health`),
  getFarmerPolicies: (id: string): Promise<{ policies: Policy[] }> =>
    MOCK ? Promise.resolve({ policies: MOCK_POLICIES }) : get(`/farmers/${id}/policies`),
  getFarmerPredictions: (id: string): Promise<{ predictions: Prediction[] }> =>
    MOCK ? Promise.resolve({ predictions: MOCK_PREDICTIONS }) : get(`/farmers/${id}/predictions`),
  getFarmerPayouts: (id: string): Promise<{ payouts: PayoutRecord[] }> =>
    MOCK ? Promise.resolve({ payouts: MOCK_PAYOUTS }) : get(`/farmers/${id}/payouts`),
  createPolicy: (farmerId: string, amount: number): Promise<Policy> =>
    MOCK ? Promise.resolve(MOCK_POLICIES[0]) : post('/policies/create', { farmer_id: farmerId, insured_amount_usdc: amount }),
  cancelPolicy: (policyId: string): Promise<Policy> =>
    MOCK ? Promise.resolve({ ...MOCK_POLICIES[0], status: 'cancelled' as const }) : patch(`/policies/${policyId}/cancel`),
  getPredictions: (farmId: string): Promise<{ predictions: Prediction[] }> =>
    MOCK ? Promise.resolve({ predictions: MOCK_PREDICTIONS }) : get(`/predictions/farm/${farmId}`),
  getPayoutStatus: (payoutId: string): Promise<PayoutRecord> =>
    MOCK ? Promise.resolve(MOCK_PAYOUTS[0]) : get(`/predictions/payout/${payoutId}`),
};

export function ndviColor(ndvi: number): string {
  if (ndvi >= 0.6) return '#4ade80';
  if (ndvi >= 0.4) return '#f59e0b';
  if (ndvi >= 0.2) return '#f97316';
  return '#ef4444';
}
export function formatDisease(d: string): string {
  return d.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
}
export function shortHash(hash: string): string {
  if (!hash || hash.length < 12) return hash;
  return `${hash.slice(0, 8)}…${hash.slice(-6)}`;
}
