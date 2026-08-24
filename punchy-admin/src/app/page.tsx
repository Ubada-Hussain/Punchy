'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { api } from '@/lib/api';
import styles from './landing.module.css';

export default function LandingPage() {
  const router = useRouter();
  const [checkingAuth, setCheckingAuth] = useState(true);

  useEffect(() => {
    const session = api.getSession();
    if (session?.role === 'ADMIN') {
      router.push('/dashboard');
    } else {
      setCheckingAuth(false);
    }
  }, [router]);

  if (checkingAuth) {
    return <div className={styles.page} style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh', background: '#FFFAF5' }}></div>;
  }

  return (
    <div className={styles.page}>
      {/* ── Nav ─────────────────────────────────────────────────── */}
      <nav className={styles.nav}>
        <div className={styles.navInner}>
          <div className={styles.logo}>
            <div className={styles.logoMark}>P</div>
            <span className={styles.logoText}>Punchy</span>
          </div>
          <div className={styles.navLinks}>
            <a href="#how" className={styles.navLink}>How it works</a>
            <a href="#businesses" className={styles.navLink}>For businesses</a>
            <a href="#customers" className={styles.navLink}>For customers</a>
          </div>
          <div className={styles.navCta}>
            <Link href="/login" className={styles.navLoginBtn}>Admin Login</Link>
            <a href="#get-started" className={styles.navSignupBtn}>Get started</a>
          </div>
        </div>
      </nav>

      {/* ── Hero ────────────────────────────────────────────────── */}
      <section className={styles.hero}>
        <div className={styles.heroInner}>
          <div className={styles.heroEyebrow}>✦ Digital loyalty, reimagined</div>
          <h1 className={styles.heroTitle}>
            Punch cards your<br />
            <span className={styles.heroHighlight}>customers will love.</span>
          </h1>
          <p className={styles.heroSub}>
            Punchy replaces paper punch cards with a slick mobile experience.
            Customers earn rewards by scanning a QR code or tapping NFC — no app
            for your staff, no awkward manual stamping.
          </p>
          <div className={styles.heroCtas}>
            <a href="#get-started" className={styles.heroPrimary}>
              Get your business on Punchy →
            </a>
            <a
              href="https://apps.apple.com"
              target="_blank"
              rel="noopener noreferrer"
              className={styles.heroSecondary}
            >
              Download the app
            </a>
          </div>
          <div className={styles.heroMeta}>
            <span>🍎 iOS & Android</span>
            <span className={styles.dot}>·</span>
            <span>Free to start</span>
            <span className={styles.dot}>·</span>
            <span>5 min setup</span>
          </div>
        </div>

        {/* Decorative punch cards */}
        <div className={styles.heroCards} aria-hidden="true">
          <div className={styles.demoCard} style={{ '--card-color': '#FF6B35' } as React.CSSProperties}>
            <div className={styles.demoCardHeader}>
              <div className={styles.demoCardLogo}>☕</div>
              <div>
                <div className={styles.demoCardName}>The Coffee Corner</div>
                <div className={styles.demoCardCat}>Café</div>
              </div>
            </div>
            <div className={styles.demoCardPunches}>
              {Array.from({ length: 10 }, (_, i) => (
                <div key={i} className={`${styles.punch} ${i < 7 ? styles.punchFilled : ''}`}>
                  {i < 7 ? '☕' : ''}
                </div>
              ))}
            </div>
            <div className={styles.demoCardFooter}>7 / 10 — 3 more for a free coffee!</div>
          </div>

          <div className={`${styles.demoCard} ${styles.demoCardBack}`} style={{ '--card-color': '#0D9488' } as React.CSSProperties}>
            <div className={styles.demoCardHeader}>
              <div className={styles.demoCardLogo}>🍕</div>
              <div>
                <div className={styles.demoCardName}>Napoli Slices</div>
                <div className={styles.demoCardCat}>Pizza</div>
              </div>
            </div>
            <div className={styles.demoCardPunches}>
              {Array.from({ length: 8 }, (_, i) => (
                <div key={i} className={`${styles.punch} ${i < 8 ? styles.punchFilled : ''}`}>
                  {i < 8 ? '🍕' : ''}
                </div>
              ))}
            </div>
            <div className={styles.demoCardFooter}>8 / 8 — 🎉 Reward ready! Tap to redeem.</div>
          </div>
        </div>
      </section>

      {/* ── How it works ─────────────────────────────────────────── */}
      <section id="how" className={styles.section}>
        <div className={styles.sectionInner}>
          <div className={styles.sectionEyebrow}>How it works</div>
          <h2 className={styles.sectionTitle}>Up and running in minutes</h2>

          <div className={styles.stepsGrid}>
            {[
              { n: '1', icon: '🏪', title: 'Set up your business', desc: 'Create your account, build your loyalty card, choose your reward — takes under 5 minutes.' },
              { n: '2', icon: '📱', title: 'Display your QR or NFC', desc: 'Print your counter QR code or tap an NFC tag on the counter. Your customers do the rest.' },
              { n: '3', icon: '🎉', title: 'Customers earn & redeem', desc: 'Every scan adds a punch. When the card is full, the customer gets notified and redeems in-store.' },
            ].map(s => (
              <div key={s.n} className={styles.step}>
                <div className={styles.stepNum}>{s.n}</div>
                <div className={styles.stepIcon}>{s.icon}</div>
                <h3 className={styles.stepTitle}>{s.title}</h3>
                <p className={styles.stepDesc}>{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── For Businesses ───────────────────────────────────────── */}
      <section id="businesses" className={styles.altSection}>
        <div className={styles.sectionInner}>
          <div className={styles.splitLayout}>
            <div className={styles.splitText}>
              <div className={styles.sectionEyebrow}>For businesses</div>
              <h2 className={styles.sectionTitle}>Your loyalty program, your way</h2>
              <p className={styles.splitSub}>
                Customise your card design, set punch targets, track every redemption,
                and see which customers keep coming back — all from the app.
              </p>
              <ul className={styles.featureList}>
                {[
                  'QR code & NFC tag support',
                  'Custom card visual style',
                  'In-app analytics dashboard',
                  'Send offers & reminders to your customers',
                  'No hardware required to get started',
                ].map(f => (
                  <li key={f} className={styles.featureItem}>
                    <span className={styles.featureCheck}>✓</span> {f}
                  </li>
                ))}
              </ul>
              <a href="#get-started" className={styles.heroPrimary} style={{ display: 'inline-flex', marginTop: 24 }}>
                Start free →
              </a>
            </div>
            <div className={styles.splitVisual}>
              <div className={styles.dashPreview}>
                <div className={styles.dashBar}>
                  <span className={styles.dashTitle}>This month</span>
                </div>
                {[
                  { label: 'Total customers', value: '248', trend: '+12 this week' },
                  { label: 'Punches given', value: '1,342', trend: '+89 today' },
                  { label: 'Rewards redeemed', value: '67', trend: '+5 today' },
                ].map(s => (
                  <div key={s.label} className={styles.dashStat}>
                    <span className={styles.dashStatLabel}>{s.label}</span>
                    <span className={styles.dashStatValue}>{s.value}</span>
                    <span className={styles.dashStatTrend}>↑ {s.trend}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── For Customers ────────────────────────────────────────── */}
      <section id="customers" className={styles.section}>
        <div className={styles.sectionInner}>
          <div className={`${styles.splitLayout} ${styles.splitReverse}`}>
            <div className={styles.splitVisual}>
              <div className={styles.walletPreview}>
                <div className={styles.walletTitle}>My Cards</div>
                {[
                  { name: 'The Coffee Corner', emoji: '☕', punches: 7, total: 10, color: '#FF6B35' },
                  { name: 'Napoli Slices', emoji: '🍕', punches: 8, total: 8, color: '#0D9488', done: true },
                  { name: 'Bloom Bakery', emoji: '🥐', punches: 3, total: 12, color: '#7C3AED' },
                ].map(c => (
                  <div key={c.name} className={styles.walletCard} style={{ '--wc': c.color } as React.CSSProperties}>
                    <div className={styles.walletCardTop}>
                      <span className={styles.walletEmoji}>{c.emoji}</span>
                      <div>
                        <div className={styles.walletCardName}>{c.name}</div>
                        <div className={styles.walletCardCount}>{c.punches}/{c.total} punches</div>
                      </div>
                      {c.done && <span className={styles.walletReady}>Ready!</span>}
                    </div>
                    <div className={styles.walletBar}>
                      <div className={styles.walletProgress} style={{ width: `${(c.punches / c.total) * 100}%`, background: c.color }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>
            <div className={styles.splitText}>
              <div className={styles.sectionEyebrow}>For customers</div>
              <h2 className={styles.sectionTitle}>All your loyalty cards in one place</h2>
              <p className={styles.splitSub}>
                Scan, tap, earn, redeem. No more lost paper cards.
                Every business you visit is tracked in one simple app.
              </p>
              <div className={styles.appLinks}>
                <a href="https://apps.apple.com" className={styles.storeBtn} target="_blank" rel="noopener noreferrer">
                  🍎 App Store
                </a>
                <a href="https://play.google.com" className={styles.storeBtn} target="_blank" rel="noopener noreferrer">
                  ▶ Google Play
                </a>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── CTA ──────────────────────────────────────────────────── */}
      <section id="get-started" className={styles.ctaSection}>
        <div className={styles.ctaInner}>
          <h2 className={styles.ctaTitle}>Ready to punch up your loyalty game?</h2>
          <p className={styles.ctaSub}>Download the Punchy app and sign up as a business — free to start, no card required.</p>
          <div className={styles.ctaBtns}>
            <a href="https://apps.apple.com" className={styles.ctaBtn} target="_blank" rel="noopener noreferrer">
              🍎 Download on App Store
            </a>
            <a href="https://play.google.com" className={styles.ctaBtn} target="_blank" rel="noopener noreferrer">
              ▶ Get it on Google Play
            </a>
          </div>
        </div>
      </section>

      {/* ── Footer ───────────────────────────────────────────────── */}
      <footer className={styles.footer}>
        <div className={styles.footerInner}>
          <div className={styles.logo}>
            <div className={styles.logoMark}>P</div>
            <span className={styles.logoText}>Punchy</span>
          </div>
          <p className={styles.footerText}>© 2026 Punchy. Built with ☕ for local businesses everywhere.</p>
          <Link href="/login" className={styles.footerAdmin}>Admin Login →</Link>
        </div>
      </footer>
    </div>
  );
}
