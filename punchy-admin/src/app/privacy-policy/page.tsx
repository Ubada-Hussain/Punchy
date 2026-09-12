import type { Metadata } from 'next';
import Link from 'next/link';
import Image from 'next/image';
export const metadata: Metadata = { title: 'Privacy Policy | Punchy', description: 'Punchy privacy policy and data practices.' };

export default function PrivacyPolicyPage() {
  return <main className="legal-page">
    <nav className="legal-nav"><Link className="legal-brand" href="/"><Image src="/punchy-mark.png" alt="Punchy" width={38} height={38} />Punchy</Link><div className="legal-nav-links"><Link href="/">Home</Link><Link href="/#features">Features</Link><Link href="/terms">Terms</Link><Link href="/delete-account">Delete account</Link></div></nav>
    <article className="legal-card">
      <header className="legal-hero"><div className="legal-hero-copy"><p className="legal-eyebrow">🛡 Last updated: September 9, 2026</p><h1>Privacy <span>Policy</span></h1><p>Punchy (“we”, “us”, or “our”) provides digital loyalty cards for customers and local businesses. This policy explains what information we collect, how we use it, and the choices you have.</p></div><div className="legal-hero-art">🛡️</div></header>
      <div className="legal-sections">
        <section className="legal-section"><div className="legal-section-icon">▣</div><div><h2>Information we collect</h2><p>We collect account details such as name, email address, phone number when provided, role, business profile information, loyalty cards, punches, rewards, and notification preferences. We may collect device notification tokens when push notifications are enabled.</p></div></section>
        <section className="legal-section"><div className="legal-section-icon">♢</div><div><h2>How we use information</h2><p>We use information to create and secure accounts, provide loyalty cards and punch tracking, send requested notifications, support businesses, prevent abuse, and improve the service. We do not sell personal information.</p></div></section>
        <section className="legal-section"><div className="legal-section-icon">☁</div><div><h2>Sharing and storage</h2><p>Information is shared only with service providers needed to operate Punchy, such as hosting, database, image storage, analytics, and push-notification providers. Data is transmitted over encrypted HTTPS connections and retained only as long as needed for legitimate purposes.</p></div></section>
        <section className="legal-section"><div className="legal-section-icon">✓</div><div><h2>Your choices and contact</h2><p>You can update profile details, disable push notifications, or request deletion of your account and associated data. Contact <a className="legal-link" href="mailto:support.punchy@gmail.com">support.punchy@gmail.com</a> for privacy questions.</p></div></section>
      </div>
      <footer><a className="legal-link" href="/delete-account">Request account deletion</a> · <a className="legal-link" href="/terms">Terms &amp; Conditions</a></footer>
    </article>
  </main>;
}
