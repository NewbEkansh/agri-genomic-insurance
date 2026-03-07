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
