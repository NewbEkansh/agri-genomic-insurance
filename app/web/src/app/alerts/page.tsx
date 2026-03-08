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
