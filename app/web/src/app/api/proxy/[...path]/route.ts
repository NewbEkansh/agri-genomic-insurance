import { NextRequest, NextResponse } from 'next/server';

const BACKEND = 'http://51.20.64.136:8000';

async function handler(req: NextRequest, context: any) {
  const { path } = await context.params;
  const url = `${BACKEND}/${path.join('/')}`;
  const body = req.method !== 'GET' ? await req.text() : undefined;
  try {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'X-API-Key': 'yieldshield-dev-key',
    };
    const auth = req.headers.get('Authorization');
    if (auth) headers['Authorization'] = auth;
    const res = await fetch(url, { method: req.method, headers, body });
    const data = await res.text();
    return new NextResponse(data, { status: res.status, headers: { 'Content-Type': 'application/json' } });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

export const GET = handler;
export const POST = handler;
export const PUT = handler;
export const DELETE = handler;
