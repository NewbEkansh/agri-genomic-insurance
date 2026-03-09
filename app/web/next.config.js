/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: { ignoreBuildErrors: true },
  turbopack: {},
  async rewrites() {
    return [
      { source: '/auth/:path*', destination: 'http://51.20.64.136:8000/auth/:path*' },
      { source: '/farmers/:path*', destination: 'http://51.20.64.136:8000/farmers/:path*' },
      { source: '/predictions/:path*', destination: 'http://51.20.64.136:8000/predictions/:path*' },
      { source: '/images/:path*', destination: 'http://51.20.64.136:8000/images/:path*' },
    ];
  },
};
module.exports = nextConfig;
