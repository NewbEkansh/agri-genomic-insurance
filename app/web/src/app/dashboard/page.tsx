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
    const id = localStorage.getItem('farmer_id') || '487b3114-80ba-4e64-8731-283be03f998e';
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
