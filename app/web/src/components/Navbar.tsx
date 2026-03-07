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
