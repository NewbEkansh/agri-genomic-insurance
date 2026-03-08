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
