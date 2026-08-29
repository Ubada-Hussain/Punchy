import type { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: 'https://trypunchy.site', changeFrequency: 'weekly', priority: 1 },
    { url: 'https://trypunchy.site/login', changeFrequency: 'monthly', priority: 0.3 },
  ];
}
