import type { Metadata } from 'next';
import Script from 'next/script';
import './globals.css';

export const metadata: Metadata = {
  metadataBase: new URL('https://trypunchy.site'),
  title: { default: 'Punchy | Digital Loyalty Rewards', template: '%s | Punchy' },
  description: 'Punchy makes customer loyalty simple. Collect digital punches, unlock rewards, and grow your favorite local businesses.',
  keywords: ['Punchy', 'loyalty rewards', 'digital punch card', 'customer loyalty app', 'local business rewards'],
  alternates: { canonical: '/' },
  openGraph: {
    type: 'website',
    url: 'https://trypunchy.site',
    siteName: 'Punchy',
    title: 'Punchy | Digital Loyalty Rewards',
    description: 'Collect digital punches, unlock rewards, and support local businesses with Punchy.',
    locale: 'en_US',
  },
  twitter: {
    card: 'summary',
    title: 'Punchy | Digital Loyalty Rewards',
    description: 'Collect digital punches and unlock rewards with Punchy.',
  },
  robots: { index: true, follow: true },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        {children}
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify({
            '@context': 'https://schema.org',
            '@type': 'Organization',
            name: 'Punchy',
            url: 'https://trypunchy.site',
            description: 'Digital loyalty rewards for customers and local businesses.',
          }) }}
        />
        <Script
          async
          src="https://www.googletagmanager.com/gtag/js?id=G-XFM821HD1Z"
          strategy="afterInteractive"
        />
        <Script id="google-analytics" strategy="afterInteractive">
          {`
            window.dataLayer = window.dataLayer || [];
            function gtag(){window.dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', 'G-XFM821HD1Z');
          `}
        </Script>
      </body>
    </html>
  );
}
