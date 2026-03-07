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
