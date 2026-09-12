import type { Metadata } from 'next';
import Link from 'next/link';
import Image from 'next/image';

export const metadata: Metadata = {
  title: 'Delete Account | Punchy',
  description: 'Request deletion of your Punchy account and associated data.',
};

export default function DeleteAccountPage() {
  return (
    <main className="legal-page">
      <nav className="legal-nav">
        <Link className="legal-brand" href="/"><Image src="/punchy-mark.png" alt="Punchy" width={38} height={38} />Punchy</Link>
        <div className="legal-nav-links"><Link href="/">Home</Link><Link href="/privacy-policy">Privacy</Link><Link href="/terms">Terms</Link></div>
      </nav>
      <article className="legal-card">
        <header className="legal-hero">
          <div className="legal-hero-copy"><p className="legal-eyebrow">🔒 Account and data deletion</p><h1>Delete your <span>Punchy account</span></h1><p>You are in control of your data. Follow the steps below to request permanent deletion of your account and associated information.</p></div>
          <div className="legal-hero-art">🗑️</div>
        </header>
        <div className="legal-sections">
          <section className="legal-section"><div className="legal-section-icon">1</div><div><h2>How to request deletion</h2><p>Send an email from your registered address to <a className="legal-link" href="mailto:support.punchy@gmail.com?subject=Punchy%20account%20deletion%20request">support.punchy@gmail.com</a> with the subject “Punchy account deletion request”. Include your account email and, if available, your six-digit public ID.</p></div></section>
          <section className="legal-section"><div className="legal-section-icon">✓</div><div><h2>What will be deleted</h2><p>Your account profile, public ID, loyalty cards or memberships, punch history, notification tokens, and associated personal data will be removed. Business accounts also include the business profile, staff links, cards, and uploaded logo.</p></div></section>
          <section className="legal-section"><div className="legal-section-icon">30</div><div><h2>Processing and retention</h2><p>We normally process requests within 30 days. A limited record may be retained when required for fraud prevention, accounting, legal compliance, or dispute resolution.</p></div></section>
          <section className="legal-section"><div className="legal-section-icon">?</div><div><h2>Need help?</h2><p>If you cannot access your account, contact <a className="legal-link" href="mailto:support.punchy@gmail.com">support.punchy@gmail.com</a> and we will help verify your request.</p></div></section>
        </div>
        <footer><a className="legal-link" href="/privacy-policy">Read our Privacy Policy</a> · <a className="legal-link" href="/terms">Terms &amp; Conditions</a></footer>
      </article>
    </main>
  );
}
