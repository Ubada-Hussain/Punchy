import type { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: 'https://trypunchy.site', changeFrequency: 'weekly', priority: 1 },
    { url: 'https://trypunchy.site/privacy-policy', changeFrequency: 'yearly', priority: 0.5 },
    { url: 'https://trypunchy.site/delete-account', changeFrequency: 'yearly', priority: 0.5 },
  ];
}
