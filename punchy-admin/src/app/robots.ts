import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: '*',
      allow: '/',
      disallow: ['/dashboard', '/businesses', '/customers', '/analytics', '/nfc-qr', '/notifications', '/settings', '/support', '/login'],
    },
    sitemap: 'https://trypunchy.site/sitemap.xml',
    host: 'https://trypunchy.site',
  };
}
