import { NextRequest, NextResponse } from 'next/server';

const BACKEND = 'http://51.20.64.136:8000';

async function handler(req: NextRequest, { params }: { params: { path: string[] } }) {
  const path = params.path.join('/');
  const url = `${BACKEND}/${path}`;
  const body = req.method !== 'GET' ? await req.text() : undefined;
  const res = await fetch(url, {
    method: req.method,
    headers: { 'Content-Type': 'application/json', 'X-API-Key': 'yieldshield-dev-key' },
    body,
  });
  const data = await res.text();
  return new NextResponse(data, { status: res.status, headers: { 'Content-Type': 'application/json' } });
}

export const GET = handler;
export const POST = handler;
export const PUT = handler;
export const DELETE = handler;
