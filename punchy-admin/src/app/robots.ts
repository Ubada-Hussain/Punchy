import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: '*',
      allow: '/',
      disallow: ['/dashboard', '/businesses', '/customers', '/analytics', '/nfc-qr', '/notifications', '/settings', '/support', '/login', '/secure-access-portal', '/punchy-control-center-7f3c9b-2026', '/administration-access-portal-a8f3e9c1-7b4d2f91-2026'],
    },
    sitemap: 'https://trypunchy.site/sitemap.xml',
    host: 'https://trypunchy.site',
  };
}
