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
