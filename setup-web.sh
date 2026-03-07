#!/bin/bash
# YieldShield — Web App Setup Script
# Run from your project root: bash setup-web.sh

set -e

echo "🌿 YieldShield Web App Setup"
echo "================================"

# ── Create directory structure ─────────────────────────────────────────────
mkdir -p app/web/src/app/dashboard
mkdir -p app/web/src/app/alerts
mkdir -p app/web/src/app/payouts
mkdir -p app/web/src/components
mkdir -p app/web/src/lib
mkdir -p app/web/src/types

cd app/web

# ── package.json ──────────────────────────────────────────────────────────
cat > package.json << 'EOF'
{
  "name": "yieldshield-web",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "14.2.3",
    "react": "^18",
    "react-dom": "^18",
    "ethers": "^6.11.1",
    "lucide-react": "^0.378.0",
    "clsx": "^2.1.1"
  },
  "devDependencies": {
    "typescript": "^5",
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "tailwindcss": "^3.4.1",
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.38"
  }
}
EOF

# ── tailwind.config.js ────────────────────────────────────────────────────
cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        display: ['var(--font-display)', 'Georgia', 'serif'],
        mono: ['var(--font-mono)', 'monospace'],
        body: ['var(--font-body)', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
EOF

# ── postcss.config.js ─────────────────────────────────────────────────────
cat > postcss.config.js << 'EOF'
module.exports = { plugins: { tailwindcss: {}, autoprefixer: {} } }
EOF

# ── next.config.js ────────────────────────────────────────────────────────
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  webpack: (config) => {
    config.resolve.fallback = { fs: false, net: false, tls: false };
    return config;
  },
};
module.exports = nextConfig;
EOF

# ── tsconfig.json ─────────────────────────────────────────────────────────
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

# ── .env.local ────────────────────────────────────────────────────────────
cat > .env.local << 'EOF'
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_MOCK_MODE=true
NEXT_PUBLIC_CONTRACT_ADDRESS=0x722bEC25d44dEED2F720ebee6415854A039DDA9C
NEXT_PUBLIC_SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/demo
EOF

# ── .gitignore ────────────────────────────────────────────────────────────
cat > .gitignore << 'EOF'
node_modules/
.next/
.env.local
.DS_Store
EOF

# ── src/types/index.ts ────────────────────────────────────────────────────
cat > src/types/index.ts << 'EOF'
export interface Farmer {
  farmer_id: string; name: string; phone: string; wallet_address: string;
  crop_type: string; farm_lat: number; farm_lon: number;
  farm_area_hectares: number; language: string;
  agro_polygon_id: string; baseline_ndvi: number; created_at: string;
}
export interface FarmerInput {
  name: string; phone: string; wallet_address: string; crop_type: string;
  farm_lat: number; farm_lon: number; farm_area_hectares: number; language: string;
}
export interface SoilData {
  soil_moisture: number; soil_temp_celsius: number; surface_temp_celsius: number;
}
export interface NdviAnalysis {
  delta: number; pct_drop: number;
  severity: 'healthy' | 'stressed' | 'severe' | 'critical'; fraud_flag: boolean;
}
export interface FarmHealth {
  farmer_id: string; current_ndvi: number; baseline_ndvi: number;
  soil_data: SoilData; ndvi_analysis: NdviAnalysis;
}
export interface Policy {
  policy_id: string; farmer_id: string; insured_amount_usdc: number;
  status: 'active' | 'triggered' | 'paid' | 'cancelled'; created_at: string;
}
export interface Prediction {
  prediction_id: string; disease_type: string; confidence_score: number;
  affected_area_percent: number; payout_triggered: boolean; payout_multiplier: number;
  regional_consensus_pct: number; bedrock_assessment: string;
  payout_id: string | null; created_at: string;
}
export interface PayoutRecord {
  payout_id: string; farm_id: string; farmer_wallet: string;
  insured_amount_usdc: number; payout_multiplier: number; final_payout_usdc: number;
  tx_hash: string; status: 'pending' | 'submitted' | 'confirmed' | 'failed'; created_at: string;
}
EOF

# ── src/lib/api.ts ────────────────────────────────────────────────────────
cat > src/lib/api.ts << 'APIEOF'
import type { Farmer, FarmerInput, FarmHealth, Policy, Prediction, PayoutRecord } from '@/types';

const BASE = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000';
const MOCK = process.env.NEXT_PUBLIC_MOCK_MODE === 'true';

const MOCK_FARMER: Farmer = {
  farmer_id: 'demo-farmer-001', name: 'Ekansh', phone: '+919876543210',
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
APIEOF

# ── src/lib/contract.ts ───────────────────────────────────────────────────
cat > src/lib/contract.ts << 'EOF'
import { ethers } from 'ethers';

const CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_CONTRACT_ADDRESS ?? '0x722bEC25d44dEED2F720ebee6415854A039DDA9C';
const RPC_URL = process.env.NEXT_PUBLIC_SEPOLIA_RPC_URL ?? 'https://eth-sepolia.g.alchemy.com/v2/demo';

const ABI = [
  'function getPoolBalance() external view returns (uint256)',
  'function getFarmer(string calldata farmId) external view returns (tuple(address wallet, uint256 insuredAmountWei, bool active, uint256 registeredAt))',
];

let contract: ethers.Contract | null = null;

function getContract(): ethers.Contract {
  if (!contract) {
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, provider);
  }
  return contract;
}

export async function getPoolBalanceEth(): Promise<string> {
  try {
    const bal: bigint = await getContract().getPoolBalance();
    return ethers.formatEther(bal);
  } catch { return '—'; }
}

export const ETHERSCAN_TX = (hash: string) => `https://sepolia.etherscan.io/tx/${hash}`;
export const ETHERSCAN_CONTRACT = () => `https://sepolia.etherscan.io/address/${CONTRACT_ADDRESS}`;
EOF

# ── src/app/globals.css ───────────────────────────────────────────────────
cat > src/app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --font-display: 'Playfair Display', Georgia, serif;
  --font-mono: 'JetBrains Mono', monospace;
  --font-body: 'DM Sans', system-ui, sans-serif;
  --crop: #4ade80;
  --crop-dim: #22c55e;
  --soil-950: #0a0c08;
  --soil-900: #111408;
  --soil-800: #1a1f0e;
  --soil-700: #242b12;
}

* { box-sizing: border-box; }
body { background: var(--soil-950); color: #f3f4f6; font-family: var(--font-body); }

::-webkit-scrollbar { width: 6px; }
::-webkit-scrollbar-track { background: var(--soil-900); }
::-webkit-scrollbar-thumb { background: var(--soil-700); border-radius: 3px; }

/* grain */
body::before {
  content: ''; position: fixed; inset: 0; pointer-events: none; z-index: 9999; opacity: 0.025;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
}

@keyframes fadeUp {
  from { opacity: 0; transform: translateY(14px); }
  to   { opacity: 1; transform: translateY(0); }
}
@keyframes shimmer {
  0%   { background-position: -200% 0; }
  100% { background-position:  200% 0; }
}
@keyframes pulse-slow { 0%,100% { opacity: 1; } 50% { opacity: 0.4; } }

.fade-up { animation: fadeUp 0.45s ease forwards; }
.s1 { animation-delay: 0.05s; } .s2 { animation-delay: 0.1s; }
.s3 { animation-delay: 0.15s; } .s4 { animation-delay: 0.2s; }

.skeleton {
  background: linear-gradient(90deg, #1a1f0e 25%, #242b12 50%, #1a1f0e 75%);
  background-size: 200% 100%; animation: shimmer 1.5s infinite; border-radius: 8px;
}

.card { background: var(--soil-900); border: 1px solid var(--soil-700); border-radius: 16px; }
.card-inner { background: var(--soil-800); border: 1px solid var(--soil-700); border-radius: 12px; }
.label { font-size: 11px; font-family: var(--font-mono); text-transform: uppercase; letter-spacing: 0.1em; color: #6b7280; }

.ndvi-ring { stroke-linecap: round; transition: stroke-dashoffset 1s cubic-bezier(0.4,0,0.2,1), stroke 0.5s ease; }
EOF

# ── src/app/layout.tsx ────────────────────────────────────────────────────
cat > src/app/layout.tsx << 'EOF'
import type { Metadata } from 'next';
import { Playfair_Display, JetBrains_Mono, DM_Sans } from 'next/font/google';
import './globals.css';

const display = Playfair_Display({ subsets: ['latin'], variable: '--font-display', weight: ['400','600','700'] });
const mono = JetBrains_Mono({ subsets: ['latin'], variable: '--font-mono', weight: ['400','500','600'] });
const body = DM_Sans({ subsets: ['latin'], variable: '--font-body', weight: ['400','500','600'] });

export const metadata: Metadata = {
  title: 'YieldShield — Automated Crop Insurance',
  description: 'AI-powered parametric crop insurance on the blockchain.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${display.variable} ${mono.variable} ${body.variable}`}>
      <body>{children}</body>
    </html>
  );
}
EOF

# ── src/components/Navbar.tsx ─────────────────────────────────────────────
cat > src/components/Navbar.tsx << 'EOF'
'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Leaf, LayoutDashboard, Bell, Wallet, ExternalLink } from 'lucide-react';
import { ETHERSCAN_CONTRACT } from '@/lib/contract';

const NAV = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/alerts',    label: 'Alerts',    icon: Bell },
  { href: '/payouts',   label: 'Payouts',   icon: Wallet },
];

export default function Navbar() {
  const path = usePathname();
  return (
    <header style={{ position:'fixed',top:0,inset:'0 0 auto',zIndex:50,borderBottom:'1px solid #242b12',background:'rgba(10,12,8,0.92)',backdropFilter:'blur(8px)' }}>
      <div style={{ maxWidth:1200,margin:'0 auto',padding:'0 24px',height:56,display:'flex',alignItems:'center',justifyContent:'space-between' }}>
        <Link href="/dashboard" style={{ display:'flex',alignItems:'center',gap:10,textDecoration:'none' }}>
          <span style={{ display:'flex',alignItems:'center',justifyContent:'center',width:28,height:28,borderRadius:8,background:'#14532d',border:'1px solid #16a34a' }}>
            <Leaf size={13} color="#4ade80" />
          </span>
          <span style={{ fontFamily:'var(--font-display)',fontSize:16,fontWeight:600,color:'#f3f4f6' }}>
            Yield<span style={{ color:'#4ade80' }}>Shield</span>
          </span>
          <span style={{ fontSize:10,fontFamily:'var(--font-mono)',color:'#4b5563',border:'1px solid #242b12',padding:'2px 6px',borderRadius:4 }}>SEPOLIA</span>
        </Link>
        <nav style={{ display:'flex',gap:4 }}>
          {NAV.map(({ href, label, icon: Icon }) => (
            <Link key={href} href={href} style={{
              display:'flex',alignItems:'center',gap:6,fontSize:13,fontFamily:'var(--font-mono)',
              padding:'6px 12px',borderRadius:8,textDecoration:'none',transition:'all 0.15s',
              color: path === href ? '#4ade80' : '#6b7280',
              background: path === href ? '#1a1f0e' : 'transparent',
            }}>
              <Icon size={13} />{label}
            </Link>
          ))}
        </nav>
        <a href={ETHERSCAN_CONTRACT()} target="_blank" rel="noopener noreferrer"
          style={{ display:'flex',alignItems:'center',gap:6,fontSize:11,fontFamily:'var(--font-mono)',color:'#6b7280',textDecoration:'none' }}>
          <span style={{ width:6,height:6,borderRadius:'50%',background:'#4ade80',animation:'pulse-slow 3s infinite' }} />
          Contract <ExternalLink size={11} />
        </a>
      </div>
    </header>
  );
}
EOF

# ── src/components/NdviGauge.tsx ──────────────────────────────────────────
cat > src/components/NdviGauge.tsx << 'EOF'
'use client';
import { useEffect, useState } from 'react';

function ndviColor(ndvi: number) {
  if (ndvi >= 0.6) return '#4ade80';
  if (ndvi >= 0.4) return '#f59e0b';
  if (ndvi >= 0.2) return '#f97316';
  return '#ef4444';
}

export default function NdviGauge({ current, baseline, severity, size = 160 }: {
  current: number; baseline: number; severity: string; size?: number;
}) {
  const [anim, setAnim] = useState(0);
  useEffect(() => { const t = setTimeout(() => setAnim(current), 100); return () => clearTimeout(t); }, [current]);

  const r = (size / 2) * 0.78;
  const circ = 2 * Math.PI * r;
  const color = ndviColor(current);
  const LABELS: Record<string,string> = { healthy:'Healthy', stressed:'Stressed', severe:'Severe', critical:'Critical' };

  return (
    <div style={{ display:'flex',flexDirection:'column',alignItems:'center',gap:8 }}>
      <div style={{ position:'relative',width:size,height:size }}>
        <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ transform:'rotate(-90deg)' }}>
          <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="#242b12" strokeWidth={10} />
          <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="#4ade8030" strokeWidth={10}
            strokeDasharray={circ} strokeDashoffset={circ - baseline * circ} className="ndvi-ring" />
          <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={color} strokeWidth={10}
            strokeDasharray={circ} strokeDashoffset={circ - anim * circ} className="ndvi-ring"
            style={{ filter:`drop-shadow(0 0 6px ${color}88)` }} />
        </svg>
        <div style={{ position:'absolute',inset:0,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center' }}>
          <span style={{ fontSize:28,fontFamily:'var(--font-display)',fontWeight:700,color,lineHeight:1 }}>
            {(current*100).toFixed(0)}
          </span>
          <span style={{ fontSize:10,fontFamily:'var(--font-mono)',color:'#6b7280' }}>NDVI</span>
        </div>
      </div>
      <div style={{ display:'flex',gap:12,fontSize:11,fontFamily:'var(--font-mono)' }}>
        <span style={{ color:'#6b7280',display:'flex',alignItems:'center',gap:4 }}>
          <span style={{ width:10,height:10,borderRadius:'50%',background:'#4ade8030',border:'1px solid #4ade8060',display:'inline-block' }} />
          Base {(baseline*100).toFixed(0)}
        </span>
        <span style={{ color,display:'flex',alignItems:'center',gap:4 }}>
          <span style={{ width:10,height:10,borderRadius:'50%',background:`${color}40`,border:`1px solid ${color}`,display:'inline-block' }} />
          Now {(current*100).toFixed(0)}
        </span>
      </div>
      <span style={{ fontSize:10,fontFamily:'var(--font-mono)',textTransform:'uppercase',letterSpacing:'0.1em',
        padding:'2px 10px',borderRadius:20,color,background:`${color}15`,border:`1px solid ${color}40` }}>
        {LABELS[severity] ?? severity}
      </span>
    </div>
  );
}
EOF

# ── src/components/PoolBalance.tsx ────────────────────────────────────────
cat > src/components/PoolBalance.tsx << 'EOF'
'use client';
import { useEffect, useState } from 'react';
import { getPoolBalanceEth, ETHERSCAN_CONTRACT } from '@/lib/contract';
import { ExternalLink, RefreshCw } from 'lucide-react';

export default function PoolBalance() {
  const [balance, setBalance] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [updated, setUpdated] = useState<Date | null>(null);

  async function refresh() {
    setLoading(true);
    const bal = await getPoolBalanceEth();
    setBalance(bal); setUpdated(new Date()); setLoading(false);
  }

  useEffect(() => { refresh(); const i = setInterval(refresh, 30000); return () => clearInterval(i); }, []);

  return (
    <div className="card" style={{ padding:16,display:'flex',alignItems:'center',justifyContent:'space-between',gap:16 }}>
      <div>
        <p className="label" style={{ marginBottom:4 }}>Insurance Pool</p>
        <div style={{ display:'flex',alignItems:'baseline',gap:8 }}>
          {loading ? <div className="skeleton" style={{ width:96,height:28 }} /> : (
            <>
              <span style={{ fontSize:24,fontFamily:'var(--font-display)',fontWeight:700,color:'#4ade80' }}>
                {balance !== '—' ? parseFloat(balance ?? '0').toFixed(4) : '—'}
              </span>
              <span style={{ fontSize:12,fontFamily:'var(--font-mono)',color:'#6b7280' }}>ETH (Sepolia)</span>
            </>
          )}
        </div>
        {updated && <p style={{ fontSize:11,fontFamily:'var(--font-mono)',color:'#4b5563',marginTop:2 }}>
          Updated {updated.toLocaleTimeString()}</p>}
      </div>
      <div style={{ display:'flex',gap:8 }}>
        <button onClick={refresh} disabled={loading} style={{ padding:8,borderRadius:8,border:'1px solid #242b12',background:'none',color:'#6b7280',cursor:'pointer' }}>
          <RefreshCw size={13} style={{ animation: loading ? 'spin 1s linear infinite' : 'none' }} />
        </button>
        <a href={ETHERSCAN_CONTRACT()} target="_blank" rel="noopener noreferrer"
          style={{ padding:8,borderRadius:8,border:'1px solid #242b12',color:'#6b7280',display:'flex',alignItems:'center' }}>
          <ExternalLink size={13} />
        </a>
      </div>
    </div>
  );
}
EOF

# ── src/app/page.tsx ──────────────────────────────────────────────────────
cat > src/app/page.tsx << 'PAGEEOF'
'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { api } from '@/lib/api';
import { Leaf, ShieldCheck, Zap, Globe, ArrowRight, Loader2 } from 'lucide-react';
import type { FarmerInput } from '@/types';

type Mode = 'login' | 'register';
const CROPS = ['rice','wheat','maize','cotton','soybean'];
const LANGS = [['hindi','Hindi'],['telugu','Telugu'],['tamil','Tamil'],['marathi','Marathi'],['english','English']];

const S: Record<string, React.CSSProperties> = {
  input: { width:'100%',background:'#1a1f0e',border:'1px solid #242b12',borderRadius:12,padding:'10px 14px',
    fontSize:13,fontFamily:'var(--font-mono)',color:'#e5e7eb',outline:'none' },
  btn: { width:'100%',background:'#4ade80',color:'#0a0c08',fontFamily:'var(--font-mono)',fontWeight:600,
    fontSize:14,padding:'11px 20px',borderRadius:12,border:'none',cursor:'pointer',
    display:'flex',alignItems:'center',justifyContent:'center',gap:8 },
  label: { fontSize:11,fontFamily:'var(--font-mono)',textTransform:'uppercase' as const,
    letterSpacing:'0.1em',color:'#6b7280',display:'block',marginBottom:6 },
};

export default function LandingPage() {
  const router = useRouter();
  const [mode, setMode] = useState<Mode>('login');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [loginId, setLoginId] = useState('');
  const [form, setForm] = useState<FarmerInput>({
    name:'',phone:'',wallet_address:'',crop_type:'rice',
    farm_lat:0,farm_lon:0,farm_area_hectares:0,language:'hindi',
  });

  function set(k: keyof FarmerInput, v: string | number) { setForm(f => ({ ...f, [k]: v })); }

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault(); if (!loginId.trim()) return;
    setLoading(true); setError('');
    try {
      await api.getFarmer(loginId.trim());
      localStorage.setItem('farmer_id', loginId.trim());
      router.push('/dashboard');
    } catch { setError('Farmer ID not found. Check your ID and try again.'); }
    finally { setLoading(false); }
  }

  async function handleRegister(e: React.FormEvent) {
    e.preventDefault(); setLoading(true); setError('');
    try {
      const res = await api.registerFarmer(form);
      localStorage.setItem('farmer_id', res.farmer_id);
      router.push('/dashboard');
    } catch { setError('Registration failed. Please check your details.'); }
    finally { setLoading(false); }
  }

  return (
    <div style={{ minHeight:'100vh',display:'flex',flexDirection:'row' as const }}>
      {/* Hero */}
      <div style={{ flex:1,display:'flex',flexDirection:'column' as const,justifyContent:'space-between',
        padding:64,background:'#111408',borderRight:'1px solid #242b12',position:'relative',overflow:'hidden' }}>
        <div style={{ position:'absolute',inset:0,opacity:0.05,backgroundImage:
          'linear-gradient(#4ade8022 1px,transparent 1px),linear-gradient(90deg,#4ade8022 1px,transparent 1px)',
          backgroundSize:'40px 40px' }} />
        <div style={{ position:'absolute',top:'30%',left:'20%',width:384,height:384,
          borderRadius:'50%',background:'rgba(74,222,128,0.04)',filter:'blur(64px)',pointerEvents:'none' }} />
        <div style={{ position:'relative',display:'flex',alignItems:'center',gap:12 }}>
          <span style={{ display:'flex',alignItems:'center',justifyContent:'center',width:40,height:40,
            borderRadius:12,background:'#14532d',border:'1px solid #16a34a' }}>
            <Leaf size={20} color="#4ade80" />
          </span>
          <span style={{ fontFamily:'var(--font-display)',fontSize:20,fontWeight:600,color:'#f3f4f6' }}>
            Yield<span style={{ color:'#4ade80' }}>Shield</span>
          </span>
        </div>
        <div style={{ position:'relative' }}>
          <p style={{ fontSize:11,fontFamily:'var(--font-mono)',textTransform:'uppercase',letterSpacing:'0.1em',color:'#16a34a',marginBottom:16 }}>
            AWS AI for Bharat Hackathon
          </p>
          <h1 style={{ fontFamily:'var(--font-display)',fontSize:44,fontWeight:700,lineHeight:1.2,color:'#f3f4f6',margin:'0 0 20px' }}>
            Crop insurance that pays<br /><span style={{ color:'#4ade80' }}>before you ask.</span>
          </h1>
          <p style={{ color:'#9ca3af',fontSize:15,maxWidth:380,lineHeight:1.7,marginBottom:28 }}>
            AI detects disease. Satellite confirms damage. Your wallet receives ETH — automatically, in seconds.
          </p>
          <div style={{ display:'flex',flexDirection:'column' as const,gap:12 }}>
            {[[Zap,'Instant payouts — no paperwork'],[ShieldCheck,'Fraud detection via satellite NDVI'],[Globe,'On-chain transparency on Sepolia']].map(([Icon, label]: any) => (
              <div key={label} style={{ display:'flex',alignItems:'center',gap:12,fontSize:14,color:'#9ca3af' }}>
                <span style={{ display:'flex',alignItems:'center',justifyContent:'center',width:28,height:28,
                  borderRadius:8,background:'#14532d',border:'1px solid #16a34a',flexShrink:0 }}>
                  <Icon size={13} color="#4ade80" />
                </span>
                {label}
              </div>
            ))}
          </div>
        </div>
        <p style={{ position:'relative',fontSize:11,fontFamily:'var(--font-mono)',color:'#4b5563' }}>
          Contract:{' '}
          <a href="https://sepolia.etherscan.io/address/0x722bEC25d44dEED2F720ebee6415854A039DDA9C"
            target="_blank" rel="noopener noreferrer" style={{ color:'#6b7280',textDecoration:'none' }}>
            0x722b…DA9C ↗
          </a>
        </p>
      </div>

      {/* Form panel */}
      <div style={{ width:460,display:'flex',flexDirection:'column' as const,justifyContent:'center',padding:64 }}>
        <div style={{ display:'flex',borderRadius:12,overflow:'hidden',border:'1px solid #242b12',marginBottom:32,alignSelf:'flex-start' }}>
          {(['login','register'] as Mode[]).map(m => (
            <button key={m} onClick={() => { setMode(m); setError(''); }}
              style={{ padding:'8px 20px',fontSize:13,fontFamily:'var(--font-mono)',
                background: mode===m ? '#14532d' : 'none',
                color: mode===m ? '#4ade80' : '#6b7280',border:'none',cursor:'pointer',
                textTransform:'capitalize' as const }}>
              {m === 'login' ? 'Sign In' : 'Register'}
            </button>
          ))}
        </div>

        {mode === 'login' ? (
          <form onSubmit={handleLogin} style={{ display:'flex',flexDirection:'column' as const,gap:20 }}>
            <div>
              <h2 style={{ fontFamily:'var(--font-display)',fontSize:26,fontWeight:600,marginBottom:6 }}>Welcome back</h2>
              <p style={{ fontSize:14,color:'#9ca3af' }}>Enter your Farmer ID to access your dashboard.</p>
            </div>
            <div>
              <label style={S.label}>Farmer ID</label>
              <input style={S.input} value={loginId} onChange={e => setLoginId(e.target.value)} placeholder="e.g. demo-farmer-001" />
            </div>
            {error && <p style={{ fontSize:12,fontFamily:'var(--font-mono)',color:'#f87171',background:'rgba(239,68,68,0.1)',border:'1px solid rgba(239,68,68,0.3)',padding:'8px 12px',borderRadius:8 }}>{error}</p>}
            <button type="submit" disabled={loading} style={S.btn}>
              {loading ? <Loader2 size={15} style={{ animation:'spin 1s linear infinite' }} /> : <ArrowRight size={15} />}
              {loading ? 'Signing in…' : 'Go to Dashboard'}
            </button>
            <p style={{ fontSize:12,fontFamily:'var(--font-mono)',color:'#4b5563',textAlign:'center' as const }}>
              Demo ID:{' '}
              <button type="button" onClick={() => setLoginId('demo-farmer-001')}
                style={{ background:'none',border:'none',color:'#16a34a',cursor:'pointer',textDecoration:'underline',fontFamily:'var(--font-mono)',fontSize:12 }}>
                demo-farmer-001
              </button>
            </p>
          </form>
        ) : (
          <form onSubmit={handleRegister} style={{ display:'flex',flexDirection:'column' as const,gap:14 }}>
            <div>
              <h2 style={{ fontFamily:'var(--font-display)',fontSize:26,fontWeight:600,marginBottom:6 }}>Register your farm</h2>
              <p style={{ fontSize:14,color:'#9ca3af' }}>We'll set up your insurance policy on-chain.</p>
            </div>
            {[['name','Full Name','Rajan Kumar'],['phone','Phone','+919876543210'],['wallet_address','MetaMask Wallet','0xYour…Wallet']].map(([k,l,ph]) => (
              <div key={k}>
                <label style={S.label}>{l}</label>
                <input required style={S.input} value={(form as any)[k]} onChange={e => set(k as any, e.target.value)} placeholder={ph} />
              </div>
            ))}
            <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr',gap:12 }}>
              <div>
                <label style={S.label}>Crop Type</label>
                <select style={S.input} value={form.crop_type} onChange={e => set('crop_type', e.target.value)}>
                  {CROPS.map(c => <option key={c} value={c}>{c.charAt(0).toUpperCase()+c.slice(1)}</option>)}
                </select>
              </div>
              <div>
                <label style={S.label}>Language</label>
                <select style={S.input} value={form.language} onChange={e => set('language', e.target.value)}>
                  {LANGS.map(([c,l]) => <option key={c} value={c}>{l}</option>)}
                </select>
              </div>
            </div>
            <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr',gap:12 }}>
              <div>
                <label style={S.label}>Latitude</label>
                <input required type="number" step="0.0001" style={S.input} value={form.farm_lat||''} onChange={e => set('farm_lat',parseFloat(e.target.value))} placeholder="28.6139" />
              </div>
              <div>
                <label style={S.label}>Longitude</label>
                <input required type="number" step="0.0001" style={S.input} value={form.farm_lon||''} onChange={e => set('farm_lon',parseFloat(e.target.value))} placeholder="77.2090" />
              </div>
            </div>
            <div>
              <label style={S.label}>Farm Area (hectares)</label>
              <input required type="number" step="0.1" min="0.1" style={S.input} value={form.farm_area_hectares||''} onChange={e => set('farm_area_hectares',parseFloat(e.target.value))} placeholder="3.5" />
            </div>
            {error && <p style={{ fontSize:12,fontFamily:'var(--font-mono)',color:'#f87171',background:'rgba(239,68,68,0.1)',border:'1px solid rgba(239,68,68,0.3)',padding:'8px 12px',borderRadius:8 }}>{error}</p>}
            <button type="submit" disabled={loading} style={S.btn}>
              {loading ? <Loader2 size={15} style={{ animation:'spin 1s linear infinite' }} /> : <ArrowRight size={15} />}
              {loading ? 'Registering…' : 'Register & Continue'}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
PAGEEOF

# ── src/app/dashboard/page.tsx ────────────────────────────────────────────
cat > src/app/dashboard/page.tsx << 'EOF'
'use client';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { api, ndviColor, formatDisease } from '@/lib/api';
import Navbar from '@/components/Navbar';
import NdviGauge from '@/components/NdviGauge';
import PoolBalance from '@/components/PoolBalance';
import type { Farmer, FarmHealth, Policy, Prediction } from '@/types';
import { AlertTriangle, CheckCircle2, Clock, Droplets, Thermometer, MapPin, Sprout, Wallet, BarChart3 } from 'lucide-react';

function Sk({ w, h }: { w: number | string; h: number }) {
  return <div className="skeleton" style={{ width:w, height:h }} />;
}

export default function DashboardPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [farmer, setFarmer] = useState<Farmer | null>(null);
  const [health, setHealth] = useState<FarmHealth | null>(null);
  const [policy, setPolicy] = useState<Policy | null>(null);
  const [latestPred, setLatestPred] = useState<Prediction | null>(null);

  useEffect(() => {
    const id = localStorage.getItem('farmer_id');
    if (!id) { router.push('/'); return; }
    Promise.all([api.getFarmer(id), api.getFarmHealth(id), api.getFarmerPolicies(id), api.getFarmerPredictions(id)])
      .then(([f, h, pol, preds]) => {
        setFarmer(f); setHealth(h); setPolicy(pol.policies?.[0] ?? null);
        setLatestPred(preds.predictions?.[0] ?? null);
      }).finally(() => setLoading(false));
  }, [router]);

  const STATUS_COLOR: Record<string,string> = { active:'#4ade80', triggered:'#f59e0b', paid:'#22c55e', cancelled:'#6b7280' };

  return (
    <div style={{ minHeight:'100vh' }}>
      <Navbar />
      <main style={{ maxWidth:1200, margin:'0 auto', padding:'76px 24px 64px' }}>
        {/* Header */}
        <div className="fade-up" style={{ marginBottom:32 }}>
          <p className="label" style={{ marginBottom:4 }}>Farm Dashboard</p>
          <h1 style={{ fontFamily:'var(--font-display)',fontSize:30,fontWeight:600,margin:0 }}>
            {loading ? <Sk w={200} h={32} /> : farmer?.name}
          </h1>
          {farmer && (
            <div style={{ display:'flex',gap:20,marginTop:8,fontSize:13,fontFamily:'var(--font-mono)',color:'#6b7280',flexWrap:'wrap' as const }}>
              <span style={{ display:'flex',alignItems:'center',gap:6 }}><MapPin size={12}/>{farmer.farm_lat.toFixed(4)}, {farmer.farm_lon.toFixed(4)}</span>
              <span style={{ display:'flex',alignItems:'center',gap:6 }}><Sprout size={12}/>{farmer.crop_type.charAt(0).toUpperCase()+farmer.crop_type.slice(1)} · {farmer.farm_area_hectares} ha</span>
              <span style={{ display:'flex',alignItems:'center',gap:6 }}><Wallet size={12}/>{farmer.wallet_address.slice(0,10)}…{farmer.wallet_address.slice(-6)}</span>
            </div>
          )}
        </div>

        {/* Alert banner */}
        {latestPred?.payout_triggered && (
          <div className="fade-up s1" style={{ marginBottom:24,display:'flex',alignItems:'flex-start',gap:12,padding:16,
            borderRadius:16,border:'1px solid rgba(217,119,6,0.4)',background:'rgba(217,119,6,0.08)' }}>
            <AlertTriangle size={18} color="#f59e0b" style={{ flexShrink:0,marginTop:2 }} />
            <div>
              <p style={{ fontSize:13,fontFamily:'var(--font-mono)',fontWeight:600,color:'#f59e0b',marginBottom:4 }}>
                {formatDisease(latestPred.disease_type)} detected — payout triggered
              </p>
              <p style={{ fontSize:12,color:'#9ca3af' }}>{latestPred.bedrock_assessment.slice(0,120)}…</p>
            </div>
          </div>
        )}

        {/* Top 3-col grid */}
        <div style={{ display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:16,marginBottom:16 }}>
          {/* NDVI */}
          <div className="card fade-up s1" style={{ padding:24,display:'flex',flexDirection:'column' as const,alignItems:'center',gap:16 }}>
            <p className="label" style={{ alignSelf:'flex-start' }}>Crop Health</p>
            {loading || !health ? <Sk w={160} h={160} /> : (
              <NdviGauge current={health.current_ndvi} baseline={health.baseline_ndvi} severity={health.ndvi_analysis.severity} />
            )}
            {health && (
              <div style={{ width:'100%',fontSize:12,fontFamily:'var(--font-mono)' }}>
                <div style={{ display:'flex',justifyContent:'space-between',color:'#6b7280' }}>
                  <span>NDVI drop</span>
                  <span style={{ color:'#f87171' }}>{(health.ndvi_analysis.pct_drop*100).toFixed(0)}% from baseline</span>
                </div>
              </div>
            )}
          </div>

          {/* Soil */}
          <div className="card fade-up s2" style={{ padding:24 }}>
            <p className="label" style={{ marginBottom:16 }}>Soil Conditions</p>
            {loading || !health ? (
              <div style={{ display:'flex',flexDirection:'column' as const,gap:12 }}>
                {[0,1,2].map(i => <Sk key={i} w="100%" h={56} />)}
              </div>
            ) : (
              <div style={{ display:'flex',flexDirection:'column' as const,gap:12 }}>
                {[
                  { icon:Droplets, label:'Soil Moisture', value:`${(health.soil_data.soil_moisture*100).toFixed(1)}%`, bar:health.soil_data.soil_moisture, color:'#60a5fa' },
                  { icon:Thermometer, label:'Soil Temp', value:`${health.soil_data.soil_temp_celsius.toFixed(1)}°C`, bar:Math.min(health.soil_data.soil_temp_celsius/50,1), color:'#f97316' },
                  { icon:Thermometer, label:'Surface Temp', value:`${health.soil_data.surface_temp_celsius.toFixed(1)}°C`, bar:Math.min(health.soil_data.surface_temp_celsius/60,1), color:'#ef4444' },
                ].map(({ icon:Icon,label,value,bar,color }) => (
                  <div key={label} className="card-inner" style={{ padding:12 }}>
                    <div style={{ display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:8 }}>
                      <span style={{ display:'flex',alignItems:'center',gap:6,fontSize:12,fontFamily:'var(--font-mono)',color:'#9ca3af' }}>
                        <Icon size={12} color={color} />{label}
                      </span>
                      <span style={{ fontSize:13,fontFamily:'var(--font-mono)',fontWeight:600,color:'#e5e7eb' }}>{value}</span>
                    </div>
                    <div style={{ height:6,borderRadius:3,background:'#242b12',overflow:'hidden' }}>
                      <div style={{ height:'100%',borderRadius:3,background:color,width:`${bar*100}%`,transition:'width 1s ease' }} />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Policy + Pool */}
          <div className="fade-up s3" style={{ display:'flex',flexDirection:'column' as const,gap:16 }}>
            <div className="card" style={{ padding:20,flex:1 }}>
              <p className="label" style={{ marginBottom:16 }}>Insurance Policy</p>
              {loading || !policy ? <Sk w="100%" h={64} /> : (
                <div>
                  <div style={{ display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:12 }}>
                    <div>
                      <p style={{ fontFamily:'var(--font-display)',fontSize:24,fontWeight:700,margin:0 }}>${policy.insured_amount_usdc.toLocaleString()}</p>
                      <p style={{ fontSize:11,fontFamily:'var(--font-mono)',color:'#6b7280',marginTop:2 }}>Insured (USDC)</p>
                    </div>
                    <span style={{ fontSize:11,fontFamily:'var(--font-mono)',padding:'3px 10px',borderRadius:20,
                      color:STATUS_COLOR[policy.status],background:`${STATUS_COLOR[policy.status]}15`,
                      border:`1px solid ${STATUS_COLOR[policy.status]}40`,display:'flex',alignItems:'center',gap:4 }}>
                      {policy.status === 'active' ? <CheckCircle2 size={10}/> : <Clock size={10}/>}
                      {policy.status.charAt(0).toUpperCase()+policy.status.slice(1)}
                    </span>
                  </div>
                  <p style={{ fontSize:11,fontFamily:'var(--font-mono)',color:'#4b5563' }}>ID: {policy.policy_id.slice(0,18)}…</p>
                </div>
              )}
            </div>
            <PoolBalance />
          </div>
        </div>

        {/* Latest AI prediction */}
        <div className="card fade-up s4" style={{ padding:24 }}>
          <div style={{ display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:20 }}>
            <p className="label" style={{ margin:0 }}>Latest AI Assessment</p>
            <a href="/alerts" style={{ fontSize:12,fontFamily:'var(--font-mono)',color:'#6b7280',textDecoration:'none' }}>View all →</a>
          </div>
          {loading || !latestPred ? (
            <div style={{ display:'flex',flexDirection:'column' as const,gap:12 }}>
              <Sk w={200} h={24} /><Sk w="100%" h={16} /><Sk w="75%" h={16} />
            </div>
          ) : (
            <div style={{ display:'flex',flexDirection:'column' as const,gap:16 }}>
              <div style={{ display:'flex',alignItems:'center',gap:12,flexWrap:'wrap' as const }}>
                <span style={{ fontFamily:'var(--font-display)',fontSize:18,fontWeight:600 }}>{formatDisease(latestPred.disease_type)}</span>
                <span style={{ fontSize:11,fontFamily:'var(--font-mono)',padding:'2px 10px',borderRadius:20,
                  color:latestPred.payout_triggered?'#4ade80':'#6b7280',
                  background:latestPred.payout_triggered?'#4ade8015':'#6b728015',
                  border:`1px solid ${latestPred.payout_triggered?'#4ade8040':'#6b728040'}`,
                  display:'flex',alignItems:'center',gap:4 }}>
                  {latestPred.payout_triggered ? <><CheckCircle2 size={10}/>Payout triggered</> : <><Clock size={10}/>Monitoring</>}
                </span>
              </div>
              <div>
                <div style={{ display:'flex',justifyContent:'space-between',fontSize:12,fontFamily:'var(--font-mono)',color:'#6b7280',marginBottom:6 }}>
                  <span style={{ display:'flex',alignItems:'center',gap:4 }}><BarChart3 size={11}/>Confidence</span>
                  <span style={{ color:ndviColor(latestPred.confidence_score) }}>
                    {(latestPred.confidence_score*100).toFixed(0)}% {latestPred.confidence_score>=0.85?'— threshold exceeded':'— below threshold'}
                  </span>
                </div>
                <div style={{ height:10,borderRadius:5,background:'#242b12',overflow:'hidden',position:'relative' }}>
                  <div style={{ height:'100%',borderRadius:5,background:ndviColor(latestPred.confidence_score),width:`${latestPred.confidence_score*100}%`,transition:'width 1s ease' }} />
                  <div style={{ position:'absolute',top:0,bottom:0,left:'85%',width:1,background:'rgba(255,255,255,0.2)' }} />
                </div>
              </div>
              <div style={{ display:'flex',gap:24,fontSize:12,fontFamily:'var(--font-mono)' }}>
                {[
                  ['Affected area',`${(latestPred.affected_area_percent*100).toFixed(0)}%`],
                  ['Regional consensus',`${(latestPred.regional_consensus_pct*100).toFixed(0)}% of nearby farms`],
                  ['Payout',latestPred.payout_multiplier===1?'100% (full)':`${(latestPred.payout_multiplier*100).toFixed(0)}% adjusted`],
                ].map(([l,v]) => (
                  <div key={l}><p style={{ color:'#6b7280',marginBottom:2 }}>{l}</p><p style={{ color:'#d1d5db' }}>{v}</p></div>
                ))}
              </div>
              <div className="card-inner" style={{ padding:16 }}>
                <p style={{ fontSize:11,fontFamily:'var(--font-mono)',color:'#6b7280',marginBottom:8 }}>Amazon Bedrock Assessment</p>
                <p style={{ fontSize:14,color:'#d1d5db',lineHeight:1.7 }}>{latestPred.bedrock_assessment}</p>
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
EOF

# ── src/app/alerts/page.tsx ───────────────────────────────────────────────
cat > src/app/alerts/page.tsx << 'EOF'
'use client';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { api, ndviColor, formatDisease } from '@/lib/api';
import Navbar from '@/components/Navbar';
import type { Prediction } from '@/types';
import { AlertTriangle, CheckCircle2, Clock, BarChart3, Users, Layers, Zap, RefreshCw } from 'lucide-react';

export default function AlertsPage() {
  const router = useRouter();
  const [preds, setPreds] = useState<Prediction[]>([]);
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState<string | null>(null);

  async function load() {
    const id = localStorage.getItem('farmer_id');
    if (!id) { router.push('/'); return; }
    setLoading(true);
    try { const r = await api.getPredictions(id); setPreds(r.predictions ?? []); }
    finally { setLoading(false); }
  }

  useEffect(() => { load(); }, []);

  const triggered = preds.filter(p => p.payout_triggered).length;

  return (
    <div style={{ minHeight:'100vh' }}>
      <Navbar />
      <main style={{ maxWidth:900,margin:'0 auto',padding:'76px 24px 64px' }}>
        <div className="fade-up" style={{ display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:32 }}>
          <div>
            <p className="label" style={{ marginBottom:4 }}>Disease Alerts</p>
            <h1 style={{ fontFamily:'var(--font-display)',fontSize:30,fontWeight:600,margin:0 }}>AI Predictions</h1>
            <p style={{ fontSize:13,fontFamily:'var(--font-mono)',color:'#6b7280',marginTop:6 }}>
              {preds.length} scan{preds.length!==1?'s':''} · {triggered} payout{triggered!==1?'s':''} triggered
            </p>
          </div>
          <button onClick={load} disabled={loading}
            style={{ display:'flex',alignItems:'center',gap:8,padding:'8px 16px',borderRadius:10,
              border:'1px solid #242b12',background:'none',color:'#9ca3af',cursor:'pointer',fontSize:13,fontFamily:'var(--font-mono)' }}>
            <RefreshCw size={13} style={{ animation:loading?'spin 1s linear infinite':'none' }}/>Refresh
          </button>
        </div>

        {/* Stats */}
        <div className="fade-up s1" style={{ display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:12,marginBottom:32 }}>
          {[
            { icon:Zap, label:'Triggered', value:triggered, color:'#4ade80' },
            { icon:Clock, label:'Monitoring', value:preds.length-triggered, color:'#f59e0b' },
            { icon:BarChart3, label:'Avg Confidence', color:'#60a5fa',
              value: preds.length ? `${(preds.reduce((a,p)=>a+p.confidence_score,0)/preds.length*100).toFixed(0)}%` : '—' },
          ].map(({ icon:Icon,label,value,color }) => (
            <div key={label} className="card" style={{ padding:16,textAlign:'center' as const }}>
              <Icon size={16} color={color} style={{ margin:'0 auto 8px' }}/>
              <p style={{ fontFamily:'var(--font-display)',fontSize:24,fontWeight:700,margin:'0 0 4px' }}>{value}</p>
              <p style={{ fontSize:11,fontFamily:'var(--font-mono)',color:'#6b7280' }}>{label}</p>
            </div>
          ))}
        </div>

        {/* Cards */}
        {loading ? (
          <div style={{ display:'flex',flexDirection:'column' as const,gap:16 }}>
            {[0,1,2].map(i => <div key={i} className="skeleton" style={{ height:140,borderRadius:16 }}/>)}
          </div>
        ) : preds.length === 0 ? (
          <div className="card" style={{ padding:64,textAlign:'center' as const }}>
            <CheckCircle2 size={40} color="#16a34a" style={{ margin:'0 auto 16px' }}/>
            <p style={{ fontFamily:'var(--font-display)',fontSize:20,color:'#d1d5db' }}>No disease events recorded</p>
          </div>
        ) : (
          <div style={{ display:'flex',flexDirection:'column' as const,gap:16 }}>
            {preds.map((pred, i) => {
              const isExp = expanded === pred.prediction_id;
              const isTrig = pred.payout_triggered;
              const confColor = ndviColor(pred.confidence_score);
              const pct = pred.confidence_score * 100;
              const risk = pct>=85?{l:'CRITICAL',c:'#ef4444'}:pct>=70?{l:'HIGH',c:'#f97316'}:pct>=50?{l:'MEDIUM',c:'#f59e0b'}:{l:'LOW',c:'#4ade80'};

              return (
                <div key={pred.prediction_id} className="card fade-up" style={{ overflow:'hidden',animationDelay:`${i*0.06}s` }}>
                  <div style={{ height:2,background:isTrig?'linear-gradient(90deg,#f59e0b,#ef4444)':'linear-gradient(90deg,#4ade8040,transparent)' }}/>
                  <div style={{ padding:20 }}>
                    <div style={{ display:'flex',justifyContent:'space-between',alignItems:'flex-start',gap:16,marginBottom:16 }}>
                      <div style={{ display:'flex',alignItems:'center',gap:12 }}>
                        <span style={{ display:'flex',alignItems:'center',justifyContent:'center',width:36,height:36,borderRadius:10,
                          background:isTrig?'#f59e0b15':'#4ade8010',border:`1px solid ${isTrig?'#f59e0b40':'#4ade8030'}` }}>
                          {isTrig ? <AlertTriangle size={14} color="#f59e0b"/> : <Clock size={14} color="#4ade80"/>}
                        </span>
                        <div>
                          <p style={{ fontFamily:'var(--font-display)',fontSize:16,fontWeight:600,margin:0 }}>{formatDisease(pred.disease_type)}</p>
                          <p style={{ fontSize:11,fontFamily:'var(--font-mono)',color:'#6b7280',marginTop:2 }}>{new Date(pred.created_at).toLocaleString()}</p>
                        </div>
                      </div>
                      <span style={{ fontSize:11,fontFamily:'var(--font-mono)',padding:'3px 10px',borderRadius:20,flexShrink:0,
                        color:isTrig?'#f59e0b':'#6b7280',background:isTrig?'#f59e0b10':'#6b728010',
                        border:`1px solid ${isTrig?'#f59e0b40':'#6b728040'}`,display:'flex',alignItems:'center',gap:4 }}>
                        {isTrig?<Zap size={10}/>:<Clock size={10}/>}
                        {isTrig?'Payout triggered':'Monitoring'}
                      </span>
                    </div>
                    {/* Confidence bar */}
                    <div style={{ marginBottom:12 }}>
                      <div style={{ display:'flex',justifyContent:'space-between',fontSize:12,fontFamily:'var(--font-mono)',color:'#6b7280',marginBottom:6 }}>
                        <span style={{ display:'flex',alignItems:'center',gap:4 }}><BarChart3 size={11}/>Confidence</span>
                        <span style={{ color:risk.c,fontWeight:600 }}>{pct.toFixed(0)}% — {risk.l}</span>
                      </div>
                      <div style={{ height:8,borderRadius:4,background:'#242b12',overflow:'hidden',position:'relative' }}>
                        <div style={{ position:'absolute',top:0,bottom:0,left:'85%',width:1,background:'rgba(255,255,255,0.15)',zIndex:2 }}/>
                        <div style={{ height:'100%',borderRadius:4,background:confColor,width:`${pct}%`,transition:'width 1s ease' }}/>
                      </div>
                    </div>
                    <div style={{ display:'flex',gap:16,fontSize:11,fontFamily:'var(--font-mono)',color:'#6b7280',flexWrap:'wrap' as const }}>
                      <span style={{ display:'flex',alignItems:'center',gap:4 }}><Layers size={10}/>{(pred.affected_area_percent*100).toFixed(0)}% area affected</span>
                      <span style={{ display:'flex',alignItems:'center',gap:4 }}><Users size={10}/>{(pred.regional_consensus_pct*100).toFixed(0)}% regional consensus</span>
                      {isTrig && <span style={{ color:'rgba(245,158,11,0.8)' }}>Payout: {pred.payout_multiplier===1?'100%':`${(pred.payout_multiplier*100).toFixed(0)}% adjusted`}</span>}
                    </div>
                    <button onClick={() => setExpanded(isExp ? null : pred.prediction_id)}
                      style={{ marginTop:12,fontSize:11,fontFamily:'var(--font-mono)',color:'#6b7280',background:'none',border:'none',cursor:'pointer',padding:0 }}>
                      {isExp?'▲ Hide assessment':'▼ Show AI assessment'}
                    </button>
                    {isExp && (
                      <div className="card-inner fade-up" style={{ marginTop:12,padding:16 }}>
                        <p style={{ fontSize:11,fontFamily:'var(--font-mono)',color:'#6b7280',marginBottom:8 }}>Amazon Bedrock Assessment</p>
                        <p style={{ fontSize:14,color:'#d1d5db',lineHeight:1.7 }}>{pred.bedrock_assessment}</p>
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </main>
    </div>
  );
}
EOF

# ── src/app/payouts/page.tsx ──────────────────────────────────────────────
cat > src/app/payouts/page.tsx << 'EOF'
'use client';
import { useEffect, useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { api, shortHash } from '@/lib/api';
import { ETHERSCAN_TX } from '@/lib/contract';
import Navbar from '@/components/Navbar';
import PoolBalance from '@/components/PoolBalance';
import type { PayoutRecord } from '@/types';
import { ExternalLink, Copy, CheckCheck, RefreshCw, TrendingUp, DollarSign, Clock, CheckCircle2, XCircle, AlertCircle } from 'lucide-react';

const SC: Record<string,{icon:any,color:string,label:string}> = {
  pending:   { icon:Clock,       color:'#f59e0b', label:'Pending' },
  submitted: { icon:AlertCircle, color:'#60a5fa', label:'Submitted' },
  confirmed: { icon:CheckCircle2,color:'#4ade80', label:'Confirmed' },
  failed:    { icon:XCircle,     color:'#ef4444', label:'Failed' },
};

function CopyBtn({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);
  return (
    <button onClick={async () => { await navigator.clipboard.writeText(text); setCopied(true); setTimeout(()=>setCopied(false),2000); }}
      style={{ padding:6,borderRadius:6,border:'1px solid #242b12',background:'none',color:'#6b7280',cursor:'pointer',display:'flex',alignItems:'center' }}>
      {copied ? <CheckCheck size={11} color="#4ade80"/> : <Copy size={11}/>}
    </button>
  );
}

export default function PayoutsPage() {
  const router = useRouter();
  const [payouts, setPayouts] = useState<PayoutRecord[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    const id = localStorage.getItem('farmer_id');
    if (!id) { router.push('/'); return; }
    setLoading(true);
    try { const r = await api.getFarmerPayouts(id); setPayouts(r.payouts ?? []); }
    finally { setLoading(false); }
  }, [router]);

  useEffect(() => { load(); }, [load]);

  async function pollOne(payoutId: string) {
    try { const u = await api.getPayoutStatus(payoutId); setPayouts(p => p.map(x => x.payout_id===payoutId?u:x)); }
    catch {}
  }

  useEffect(() => {
    const pending = payouts.filter(p => p.status==='pending'||p.status==='submitted');
    if (!pending.length) return;
    const i = setInterval(() => pending.forEach(p => pollOne(p.payout_id)), 10000);
    return () => clearInterval(i);
  }, [payouts]);

  const totalPaid = payouts.filter(p=>p.status==='confirmed').reduce((s,p)=>s+p.final_payout_usdc,0);
  const confirmed = payouts.filter(p=>p.status==='confirmed').length;
  const pending = payouts.filter(p=>p.status==='pending'||p.status==='submitted').length;

  return (
    <div style={{ minHeight:'100vh' }}>
      <Navbar />
      <main style={{ maxWidth:900,margin:'0 auto',padding:'76px 24px 64px' }}>
        <div className="fade-up" style={{ display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:32 }}>
          <div>
            <p className="label" style={{ marginBottom:4 }}>Blockchain Payouts</p>
            <h1 style={{ fontFamily:'var(--font-display)',fontSize:30,fontWeight:600,margin:0 }}>Payout History</h1>
            <p style={{ fontSize:13,fontFamily:'var(--font-mono)',color:'#6b7280',marginTop:6 }}>Sepolia Testnet · Verified on-chain</p>
          </div>
          <button onClick={load} disabled={loading}
            style={{ display:'flex',alignItems:'center',gap:8,padding:'8px 16px',borderRadius:10,
              border:'1px solid #242b12',background:'none',color:'#9ca3af',cursor:'pointer',fontSize:13,fontFamily:'var(--font-mono)' }}>
            <RefreshCw size={13} style={{ animation:loading?'spin 1s linear infinite':'none' }}/>Refresh
          </button>
        </div>

        <div className="fade-up s1" style={{ display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:12,marginBottom:16 }}>
          {[
            { icon:DollarSign, label:'Total Received', value:`$${totalPaid.toLocaleString()}`, sub:'USDC', color:'#4ade80' },
            { icon:CheckCircle2, label:'Confirmed', value:confirmed, sub:'on-chain', color:'#4ade80' },
            { icon:Clock, label:'Pending', value:pending, sub:'auto-polling 10s', color:'#f59e0b' },
          ].map(({ icon:Icon,label,value,sub,color }) => (
            <div key={label} className="card" style={{ padding:16 }}>
              <div style={{ display:'flex',alignItems:'center',gap:8,marginBottom:8 }}>
                <Icon size={14} color={color}/><p className="label" style={{ margin:0 }}>{label}</p>
              </div>
              <p style={{ fontFamily:'var(--font-display)',fontSize:24,fontWeight:700,margin:'0 0 2px' }}>{value}</p>
              <p style={{ fontSize:11,fontFamily:'var(--font-mono)',color:'#4b5563' }}>{sub}</p>
            </div>
          ))}
        </div>

        <div className="fade-up s2" style={{ marginBottom:24 }}><PoolBalance /></div>

        {loading ? (
          <div style={{ display:'flex',flexDirection:'column' as const,gap:16 }}>
            {[0,1].map(i => <div key={i} className="skeleton" style={{ height:180,borderRadius:16 }}/>)}
          </div>
        ) : payouts.length === 0 ? (
          <div className="card" style={{ padding:64,textAlign:'center' as const }}>
            <TrendingUp size={40} color="#16a34a" style={{ margin:'0 auto 16px' }}/>
            <p style={{ fontFamily:'var(--font-display)',fontSize:20,color:'#d1d5db' }}>No payouts yet</p>
            <p style={{ fontSize:13,fontFamily:'var(--font-mono)',color:'#6b7280',marginTop:6 }}>
              Payouts fire automatically when AI confidence ≥ 85%.
            </p>
          </div>
        ) : (
          <div style={{ display:'flex',flexDirection:'column' as const,gap:16 }}>
            {payouts.map((p, i) => {
              const st = SC[p.status] ?? SC.pending;
              const StIcon = st.icon;
              const isPending = p.status==='pending'||p.status==='submitted';
              return (
                <div key={p.payout_id} className="card fade-up" style={{ overflow:'hidden',animationDelay:`${i*0.06+0.2}s` }}>
                  <div style={{ height:2,background:st.color }}/>
                  <div style={{ padding:20 }}>
                    <div style={{ display:'flex',justifyContent:'space-between',alignItems:'flex-start',gap:16,marginBottom:16 }}>
                      <div>
                        <p style={{ fontFamily:'var(--font-display)',fontSize:22,fontWeight:700,margin:0 }}>
                          ${p.final_payout_usdc.toLocaleString()}
                          <span style={{ fontSize:13,fontFamily:'var(--font-mono)',fontWeight:400,color:'#6b7280',marginLeft:6 }}>USDC</span>
                        </p>
                        <p style={{ fontSize:12,fontFamily:'var(--font-mono)',color:'#6b7280',marginTop:4 }}>
                          Insured: ${p.insured_amount_usdc.toLocaleString()} · {p.payout_multiplier<1?`${(p.payout_multiplier*100).toFixed(0)}% (fraud-adjusted)`:'Full payout'}
                        </p>
                      </div>
                      <span style={{ fontSize:11,fontFamily:'var(--font-mono)',padding:'3px 10px',borderRadius:20,flexShrink:0,
                        color:st.color,background:`${st.color}10`,border:`1px solid ${st.color}40`,display:'flex',alignItems:'center',gap:4 }}>
                        <StIcon size={10} style={{ animation:isPending?'pulse-slow 1.5s infinite':'none' }}/>{st.label}
                      </span>
                    </div>
                    <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:16,fontSize:12,fontFamily:'var(--font-mono)' }}>
                      <div><p style={{ color:'#6b7280',marginBottom:2 }}>Wallet</p><p style={{ color:'#9ca3af' }}>{p.farmer_wallet.slice(0,10)}…{p.farmer_wallet.slice(-6)}</p></div>
                      <div><p style={{ color:'#6b7280',marginBottom:2 }}>Created</p><p style={{ color:'#9ca3af' }}>{new Date(p.created_at).toLocaleString()}</p></div>
                    </div>
                    <div className="card-inner" style={{ padding:12 }}>
                      <p style={{ fontSize:11,fontFamily:'var(--font-mono)',color:'#6b7280',marginBottom:8 }}>Transaction Hash</p>
                      {p.tx_hash ? (
                        <div style={{ display:'flex',alignItems:'center',gap:8 }}>
                          <span style={{ fontSize:12,fontFamily:'var(--font-mono)',color:'#d1d5db',flex:1,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap' as const }}>
                            {shortHash(p.tx_hash)}
                          </span>
                          <CopyBtn text={p.tx_hash}/>
                          <a href={ETHERSCAN_TX(p.tx_hash)} target="_blank" rel="noopener noreferrer"
                            style={{ padding:6,borderRadius:6,border:'1px solid #242b12',color:'#6b7280',display:'flex',alignItems:'center' }}>
                            <ExternalLink size={11}/>
                          </a>
                        </div>
                      ) : (
                        <p style={{ fontSize:12,fontFamily:'var(--font-mono)',color:'#6b7280',fontStyle:'italic' }}>Processing…</p>
                      )}
                    </div>
                    {isPending && (
                      <button onClick={() => pollOne(p.payout_id)}
                        style={{ marginTop:10,fontSize:11,fontFamily:'var(--font-mono)',color:'#6b7280',background:'none',border:'none',cursor:'pointer',display:'flex',alignItems:'center',gap:4,padding:0 }}>
                        <RefreshCw size={11}/>Check status
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}

        <div className="card fade-up" style={{ marginTop:40,padding:24 }}>
          <p className="label" style={{ marginBottom:16 }}>How YieldShield Payouts Work</p>
          <ol style={{ listStyle:'none',padding:0,margin:0,display:'flex',flexDirection:'column' as const,gap:12 }}>
            {[
              'Farmer uploads crop image → AI model runs disease inference',
              'AI confidence ≥ 85% → backend runs fraud check (NDVI + regional consensus)',
              'Fraud check passes → backend calls triggerPayout() on Sepolia smart contract',
              'Smart contract transfers ETH directly to farmer wallet — no intermediary',
              'Transaction is immutable and publicly verifiable on Etherscan',
            ].map((step, i) => (
              <li key={i} style={{ display:'flex',alignItems:'flex-start',gap:12,fontSize:13,fontFamily:'var(--font-mono)',color:'#9ca3af' }}>
                <span style={{ flexShrink:0,display:'flex',alignItems:'center',justifyContent:'center',width:20,height:20,borderRadius:'50%',
                  fontSize:10,color:'#4ade80',background:'#4ade8010',border:'1px solid #4ade8040' }}>{i+1}</span>
                {step}
              </li>
            ))}
          </ol>
        </div>
      </main>
    </div>
  );
}
EOF

# ── Install & first run ────────────────────────────────────────────────────
echo ""
echo "✅ Files created in app/web/"
echo ""
echo "Installing dependencies..."
npm install

echo ""
echo "================================"
echo "✅ Done! To start:"
echo ""
echo "  cd app/web"
echo "  npm run dev"
echo ""
echo "Then open: http://localhost:3000"
echo ""
echo "Sign in with demo ID: demo-farmer-001"
echo "To use real backend: set NEXT_PUBLIC_MOCK_MODE=false in .env.local"
echo "================================"