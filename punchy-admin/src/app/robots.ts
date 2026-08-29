import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: '*', allow: '/' },
    sitemap: 'https://trypunchy.site/sitemap.xml',
    host: 'https://trypunchy.site',
  };
}
