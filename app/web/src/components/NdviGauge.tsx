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
