'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { api } from '@/lib/api';
import { Leaf, ShieldCheck, Zap, Globe, ArrowRight, Loader2, Phone, ChevronLeft } from 'lucide-react';

type Step = 'phone' | 'otp' | 'register';
const CROPS = ['rice','wheat','maize','cotton','soybean'];
const LANGS = [['hindi','Hindi'],['telugu','Telugu'],['tamil','Tamil'],['marathi','Marathi'],['english','English']];

const S: Record<string, React.CSSProperties> = {
  input: { width:'100%',background:'#1a1f0e',border:'1px solid #242b12',borderRadius:12,
    padding:'10px 14px',fontSize:13,fontFamily:'var(--font-mono)',color:'#e5e7eb',
    outline:'none',boxSizing:'border-box' as const },
  btn: { width:'100%',background:'#4ade80',color:'#0a0c08',fontFamily:'var(--font-mono)',
    fontWeight:600,fontSize:14,padding:'11px 20px',borderRadius:12,border:'none',cursor:'pointer',
    display:'flex',alignItems:'center',justifyContent:'center',gap:8 },
  label: { fontSize:11,fontFamily:'var(--font-mono)',textTransform:'uppercase' as const,
    letterSpacing:'0.1em',color:'#6b7280',display:'block',marginBottom:6 },
};

export default function LandingPage() {
  const router = useRouter();
  const [step, setStep]       = useState<Step>('phone');
  const [loading, setLoading] = useState(false);
  const [error, setError]     = useState('');
  const [phone, setPhone]     = useState('');
  const [otp, setOtp]         = useState('');
  const [jwtToken, setJwtToken] = useState('');
  const [form, setForm] = useState({
    name:'', crop_type:'rice', farm_lat:0, farm_lon:0,
    farm_area_hectares:0, language:'hindi',
  });

  function setField(k: string, v: string | number) { setForm(f => ({ ...f, [k]: v })); }

  // Step 1 — POST /auth/send-otp
  async function handleSendOtp(e: React.FormEvent) {
    e.preventDefault(); setLoading(true); setError('');
    try {
      await api.sendOtp(`+91${phone.trim().replace(/^\+91/, "")}`);
      setStep('otp');
    } catch { setError('Could not send OTP. Check the number and try again.'); }
    finally { setLoading(false); }
  }

  // Step 2 — POST /auth/verify-otp → JWT + farmer_id + is_new_farmer
  async function handleVerifyOtp(e: React.FormEvent) {
    e.preventDefault(); setLoading(true); setError('');
    try {
      const res = await api.verifyOtp(`+91${phone.trim().replace(/^\+91/, "")}`, otp.trim());
      localStorage.setItem('token', res.token);
      localStorage.setItem('farmer_id', res.farmer_id);
      if (res.is_new_farmer) { setJwtToken(res.token); setStep('register'); }
      else { router.push('/dashboard'); }
    } catch { setError('Invalid OTP. Please try again.'); }
    finally { setLoading(false); }
  }

  // Step 3 — POST /farmers/register (new farmers only, no wallet needed)
  async function handleRegister(e: React.FormEvent) {
    e.preventDefault(); setLoading(true); setError('');
    try {
      const res = await api.registerFarmer({ ...form, phone: phone.trim() }, jwtToken);
      localStorage.setItem('farmer_id', res.farmer_id);
      router.push('/dashboard');
    } catch { setError('Registration failed. Please try again.'); }
    finally { setLoading(false); }
  }

  return (
    <div style={{ minHeight:'100vh',display:'flex' }}>
      {/* Hero */}
      <div style={{ flex:1,display:'flex',flexDirection:'column' as const,justifyContent:'space-between',
        padding:64,background:'#111408',borderRight:'1px solid #242b12',position:'relative',overflow:'hidden' }}>
        <div style={{ position:'absolute',inset:0,opacity:0.05,backgroundImage:
          'linear-gradient(#4ade8022 1px,transparent 1px),linear-gradient(90deg,#4ade8022 1px,transparent 1px)',
          backgroundSize:'40px 40px' }} />
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
          <p style={{ fontSize:11,fontFamily:'var(--font-mono)',textTransform:'uppercase',
            letterSpacing:'0.1em',color:'#16a34a',marginBottom:16 }}>AWS AI for Bharat Hackathon</p>
          <h1 style={{ fontFamily:'var(--font-display)',fontSize:44,fontWeight:700,
            lineHeight:1.2,color:'#f3f4f6',margin:'0 0 20px' }}>
            Crop insurance that pays<br/><span style={{ color:'#4ade80' }}>before you ask.</span>
          </h1>
          <p style={{ color:'#9ca3af',fontSize:15,maxWidth:380,lineHeight:1.7,marginBottom:28 }}>
            AI detects disease. Satellite confirms damage. Your wallet receives ETH — automatically, in seconds.
          </p>
          <div style={{ display:'flex',flexDirection:'column' as const,gap:12 }}>
            {([[Zap,'Instant payouts — no paperwork'],[ShieldCheck,'Fraud detection via satellite NDVI'],
               [Globe,'On-chain transparency on Sepolia']] as const).map(([Icon,label]:any) => (
              <div key={label} style={{ display:'flex',alignItems:'center',gap:12,fontSize:14,color:'#9ca3af' }}>
                <span style={{ display:'flex',alignItems:'center',justifyContent:'center',width:28,height:28,
                  borderRadius:8,background:'#14532d',border:'1px solid #16a34a',flexShrink:0 }}>
                  <Icon size={13} color="#4ade80"/></span>{label}
              </div>
            ))}
          </div>
        </div>
        <p style={{ position:'relative',fontSize:11,fontFamily:'var(--font-mono)',color:'#4b5563' }}>
          Contract: <a href="https://sepolia.etherscan.io/address/0x722bEC25d44dEED2F720ebee6415854A039DDA9C"
            target="_blank" rel="noopener noreferrer" style={{ color:'#6b7280',textDecoration:'none' }}>
            0x722b…DA9C ↗</a>
        </p>
      </div>

      {/* Form Panel */}
      <div style={{ width:460,display:'flex',flexDirection:'column' as const,
        justifyContent:'center',padding:64,overflowY:'auto' as const }}>

        {step === 'phone' && (
          <form onSubmit={handleSendOtp} style={{ display:'flex',flexDirection:'column' as const,gap:20 }}>
            <div>
              <h2 style={{ fontFamily:'var(--font-display)',fontSize:26,fontWeight:600,marginBottom:6 }}>Get started</h2>
              <p style={{ fontSize:14,color:'#9ca3af' }}>Enter your phone — we'll send a one-time password.</p>
            </div>
            <div>
              <label style={S.label}>Phone Number</label>
              <div style={{ position:'relative' as const }}>
                <span style={{ position:'absolute',left:12,top:'50%',transform:'translateY(-50%)' }}>
                  <Phone size={14} color="#6b7280"/></span>
                <input style={{ ...S.input,paddingLeft:36 }} value={phone}
                  onChange={e => setPhone(e.target.value)} placeholder="+91 98765 43210" type="tel" required/>
              </div>
            </div>
            {error && <Err msg={error}/>}
            <button type="submit" disabled={loading} style={S.btn}>
              {loading ? <Loader2 size={15} style={{ animation:'spin 1s linear infinite' }}/> : <ArrowRight size={15}/>}
              {loading ? 'Sending OTP…' : 'Send OTP'}
            </button>
            <p style={{ fontSize:11,fontFamily:'var(--font-mono)',color:'#4b5563',textAlign:'center' as const }}>
              New farmers are registered automatically after OTP verification.
            </p>
          </form>
        )}

        {step === 'otp' && (
          <form onSubmit={handleVerifyOtp} style={{ display:'flex',flexDirection:'column' as const,gap:20 }}>
            <div>
              <button type="button" onClick={() => { setStep('phone'); setError(''); }}
                style={{ background:'none',border:'none',color:'#6b7280',cursor:'pointer',
                  display:'flex',alignItems:'center',gap:4,fontFamily:'var(--font-mono)',fontSize:12,padding:0,marginBottom:12 }}>
                <ChevronLeft size={14}/> Back
              </button>
              <h2 style={{ fontFamily:'var(--font-display)',fontSize:26,fontWeight:600,marginBottom:6 }}>Enter OTP</h2>
              <p style={{ fontSize:14,color:'#9ca3af' }}>
                6-digit code sent to <strong style={{ color:'#e5e7eb' }}>{phone}</strong>
              </p>
            </div>
            <div>
              <label style={S.label}>One-Time Password</label>
              <input style={{ ...S.input,letterSpacing:'0.3em',fontSize:22,textAlign:'center' as const }}
                value={otp} onChange={e => setOtp(e.target.value.replace(/\D/g,'').slice(0,6))}
                placeholder="• • • • • •" maxLength={6} required/>
            </div>
            {error && <Err msg={error}/>}
            <button type="submit" disabled={loading || otp.length < 6} style={S.btn}>
              {loading ? <Loader2 size={15} style={{ animation:'spin 1s linear infinite' }}/> : <ArrowRight size={15}/>}
              {loading ? 'Verifying…' : 'Verify & Continue'}
            </button>
            <p style={{ fontSize:11,fontFamily:'var(--font-mono)',color:'#4b5563',textAlign:'center' as const }}>
              Didn't receive it?{' '}
              <button type="button" onClick={handleSendOtp}
                style={{ background:'none',border:'none',color:'#16a34a',cursor:'pointer',
                  fontFamily:'var(--font-mono)',fontSize:11,textDecoration:'underline' }}>
                Resend OTP
              </button>
            </p>
          </form>
        )}

        {step === 'register' && (
          <form onSubmit={handleRegister} style={{ display:'flex',flexDirection:'column' as const,gap:14 }}>
            <div>
              <h2 style={{ fontFamily:'var(--font-display)',fontSize:26,fontWeight:600,marginBottom:6 }}>Set up your farm</h2>
              <p style={{ fontSize:14,color:'#9ca3af' }}>First time? Takes 30 seconds.</p>
            </div>
            <div>
              <label style={S.label}>Full Name</label>
              <input required style={S.input} value={form.name}
                onChange={e => setField('name',e.target.value)} placeholder="Rajan Kumar"/>
            </div>
            <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr',gap:12 }}>
              <div>
                <label style={S.label}>Crop Type</label>
                <select style={S.input} value={form.crop_type} onChange={e => setField('crop_type',e.target.value)}>
                  {CROPS.map(c => <option key={c} value={c}>{c.charAt(0).toUpperCase()+c.slice(1)}</option>)}
                </select>
              </div>
              <div>
                <label style={S.label}>Language</label>
                <select style={S.input} value={form.language} onChange={e => setField('language',e.target.value)}>
                  {LANGS.map(([c,l]) => <option key={c} value={c}>{l}</option>)}
                </select>
              </div>
            </div>
            <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr',gap:12 }}>
              <div>
                <label style={S.label}>Latitude</label>
                <input required type="number" step="0.0001" style={S.input} value={form.farm_lat||''}
                  onChange={e => setField('farm_lat',parseFloat(e.target.value))} placeholder="28.6139"/>
              </div>
              <div>
                <label style={S.label}>Longitude</label>
                <input required type="number" step="0.0001" style={S.input} value={form.farm_lon||''}
                  onChange={e => setField('farm_lon',parseFloat(e.target.value))} placeholder="77.2090"/>
              </div>
            </div>
            <div>
              <label style={S.label}>Farm Area (hectares)</label>
              <input required type="number" step="0.1" min="0.1" style={S.input} value={form.farm_area_hectares||''}
                onChange={e => setField('farm_area_hectares',parseFloat(e.target.value))} placeholder="3.5"/>
            </div>
            {error && <Err msg={error}/>}
            <button type="submit" disabled={loading} style={S.btn}>
              {loading ? <Loader2 size={15} style={{ animation:'spin 1s linear infinite' }}/> : <ArrowRight size={15}/>}
              {loading ? 'Setting up…' : 'Complete Registration'}
            </button>
            <p style={{ fontSize:11,fontFamily:'var(--font-mono)',color:'#4b5563',textAlign:'center' as const }}>
              Your wallet is created automatically — no MetaMask needed.
            </p>
          </form>
        )}
      </div>
    </div>
  );
}

function Err({ msg }: { msg: string }) {
  return (
    <p style={{ fontSize:12,fontFamily:'var(--font-mono)',color:'#f87171',background:'rgba(239,68,68,0.1)',
      border:'1px solid rgba(239,68,68,0.3)',padding:'8px 12px',borderRadius:8,margin:0 }}>
      {msg}
    </p>
  );
}