import Link from 'next/link';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Punchy — Your loyalty cards, all in one app',
  description: 'Ditch the paper cards. Collect stamps at your favorite cafés, salons and gyms with a tap or scan — and never miss a free reward again.',
};

export default function LandingPage() {
  return (
    <>
      {/* SVG Defs */}
      <svg width="0" height="0" style={{ position: 'absolute' }}>
        <defs>
          <symbol id="i-star" viewBox="0 0 24 24">
            <path d="M12 3.5l2.6 5.4 5.9.8-4.3 4.2 1 5.9-5.2-2.8-5.2 2.8 1-5.9-4.3-4.2 5.9-.8Z" strokeLinejoin="round"/>
          </symbol>
          <symbol id="i-check" viewBox="0 0 24 24">
            <path d="M5 12.5 10 17 19 7" strokeLinecap="round" strokeLinejoin="round"/>
          </symbol>
          <symbol id="i-scan" viewBox="0 0 24 24">
            <rect x="3" y="3" width="7" height="7" rx="1.2"/><rect x="14" y="3" width="7" height="7" rx="1.2"/>
            <rect x="3" y="14" width="7" height="7" rx="1.2"/><path d="M14 14h3v3h-3zM19 14h2M14 19h2M19 19h2" strokeLinecap="round"/>
          </symbol>
          <symbol id="i-nfc" viewBox="0 0 24 24">
            <path d="M6 16a8 8 0 0 1 0-8" strokeLinecap="round"/><path d="M9 13.5a3.5 3.5 0 0 1 0-3" strokeLinecap="round"/>
            <circle cx="13" cy="12" r="1.3" fill="currentColor" stroke="none"/><path d="M17 8a8 8 0 0 1 0 8" strokeLinecap="round"/>
          </symbol>
          <symbol id="i-gift" viewBox="0 0 24 24">
            <rect x="4" y="9" width="16" height="10" rx="1"/><path d="M4 9h16v3H4z"/><path d="M12 9v10"/>
            <path d="M12 9c-1-3-5-3-5-.5S9 9 12 9Zm0 0c1-3 5-3 5-.5S15 9 12 9Z" strokeLinejoin="round"/>
          </symbol>
          <symbol id="i-bell" viewBox="0 0 24 24">
            <path d="M6 9a6 6 0 0 1 12 0c0 4 1.5 5.5 1.5 5.5H4.5S6 13 6 9Z" strokeLinejoin="round"/>
            <path d="M9.5 19a2.5 2.5 0 0 0 5 0"/>
          </symbol>
          <symbol id="i-apple" viewBox="0 0 24 24">
            <path d="M16.4 12.7c0-2.2 1.8-3.3 1.9-3.4-1-1.5-2.6-1.7-3.2-1.7-1.4-.1-2.6.8-3.3.8s-1.8-.8-2.9-.8c-1.5 0-2.9.9-3.6 2.2-1.6 2.7-.4 6.7 1.1 8.9.7 1.1 1.6 2.3 2.8 2.2 1.1 0 1.5-.7 2.9-.7s1.7.7 2.9.7c1.2 0 2-1.1 2.7-2.2.8-1.2 1.2-2.4 1.2-2.5-.1 0-2.4-.9-2.5-3.5Z" fill="currentColor" stroke="none"/>
          </symbol>
          <symbol id="i-play" viewBox="0 0 24 24">
            <path d="M4 3.5v17l14-8.5-14-8.5Z" fill="currentColor" stroke="none"/>
          </symbol>
        </defs>
      </svg>

      {/* NAV */}
      <div className="nav">
        <div className="nav-inner">
          <div className="brand">
            <div className="brand-mark">
              <svg className="icon" style={{ color:'#fff', strokeWidth:0, fill:'currentColor', width:17, height:17 }}>
                <use href="#i-star"/>
              </svg>
            </div>
            Punchy
          </div>
          <div className="nav-links">
            <a href="#features">Features</a>
            <a href="#how">How it works</a>
            <a href="#business">For Business</a>
            <a href="#reviews">Reviews</a>
          </div>
          <div className="nav-cta">
            <Link href="/login" className="lbtn lbtn-outline lbtn-sm">Log In</Link>
            <a href="#download" className="lbtn lbtn-coral lbtn-sm">Get the App</a>
          </div>
        </div>
      </div>

      {/* HERO */}
      <section className="hero">
        <div className="wrap hero-inner">
          <div className="hero-copy">
            <div className="eyebrow">⭐ Loyalty made simple</div>
            <h1>Every punch card<br/>you love, <span>in one app.</span></h1>
            <p className="lead">Ditch the paper cards. Collect stamps at your favorite cafés, salons and gyms with a tap or scan — and never miss a free reward again.</p>
            <div className="store-row">
              <a href="#" className="store-btn">
                <svg className="icon" style={{ width:22, height:22 }}><use href="#i-apple"/></svg>
                <span><small>Download on the</small><b>App Store</b></span>
              </a>
              <a href="#" className="store-btn">
                <svg className="icon" style={{ width:20, height:20 }}><use href="#i-play"/></svg>
                <span><small>Get it on</small><b>Google Play</b></span>
              </a>
            </div>
            <div className="trust-row">
              <div className="trust-avatars">
                <div style={{ background:'var(--grad-teal)' }}/>
                <div style={{ background:'var(--grad-coral)' }}/>
                <div style={{ background:'var(--grad-purple)' }}/>
                <div style={{ background:'var(--grad-gold)' }}/>
              </div>
              <span>Loved by 6,000+ customers &amp; 180+ local businesses</span>
            </div>
          </div>
          <div className="hero-visual">
            <div className="glow"/>
            <div className="float-card fc1">
              <div className="fc-ic" style={{ background:'var(--grad-coral)', color:'#fff' }}>🎁</div>
              <div><b>Reward ready!</b><span>Free coffee unlocked</span></div>
            </div>
            <div className="float-card fc2">
              <div className="fc-ic" style={{ background:'var(--grad-purple)', color:'#fff' }}>
                <svg className="icon" style={{ width:15, height:15, color:'#fff' }}><use href="#i-nfc"/></svg>
              </div>
              <div><b>Tap to punch</b><span>Instant &amp; contactless</span></div>
            </div>
            <div className="phone">
              <div className="phone-screen">
                <p style={{ fontSize:11, fontWeight:800, color:'var(--ink-faint)', margin:'2px 0 0' }}>YOUR CARDS</p>
                <div className="wallet-card" style={{ background:'var(--grad-teal)' }}>
                  <div className="wc-top"><div><div className="wc-name">Brew &amp; Co.</div><div className="wc-cat">☕ Café</div></div><div className="wc-logo">☕</div></div>
                  <div style={{ display:'flex', alignItems:'center' }}>
                    <div className="wc-dots">
                      {[true,true,true,true,true,true,false,false].map((on,i) => <div key={i} className={`wc-dot${on?' on':''}`}/>)}
                    </div>
                    <div className="wc-count">6/8</div>
                  </div>
                </div>
                <div className="wallet-card" style={{ background:'var(--grad-coral)' }}>
                  <div className="wc-top"><div><div className="wc-name">Glow Salon</div><div className="wc-cat">💇 Salon</div></div><div className="wc-logo">💇</div></div>
                  <div style={{ display:'flex', alignItems:'center' }}>
                    <div className="wc-dots">
                      {[true,true,false,false,false].map((on,i) => <div key={i} className={`wc-dot${on?' on':''}`}/>)}
                    </div>
                    <div className="wc-count">2/5</div>
                  </div>
                </div>
                <div className="wallet-card" style={{ background:'var(--grad-purple)' }}>
                  <div className="wc-top"><div><div className="wc-name">FitZone Gym</div><div className="wc-cat">🏋️ Fitness</div></div><div className="wc-logo">🏋️</div></div>
                  <div style={{ display:'flex', alignItems:'center' }}>
                    <div className="wc-dots">
                      {[true,true,true,true,true,true,true,true].map((on,i) => <div key={i} className={`wc-dot${on?' on':''}`}/>)}
                    </div>
                    <div className="wc-count">8/8 🎉</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* LOGO STRIP */}
      <div className="logo-strip">
        <div className="wrap">
          <span className="lbl">Trusted by local favorites</span>
          <div className="logo-row">
            <div>Brew &amp; Co.</div><div>Glow Salon</div><div>FitZone</div><div>Slice House</div><div>Bloom Studio</div>
          </div>
        </div>
      </div>

      {/* FEATURES */}
      <section id="features">
        <div className="wrap">
          <div className="sec-head">
            <div className="sec-eyebrow">Why Punchy</div>
            <h2>Loyalty, without the clutter</h2>
            <p>No more lost paper cards. Everything lives in your pocket, updates instantly, and works with a tap.</p>
          </div>
          <div className="feat-grid">
            <div className="feat-card">
              <div className="feat-ic" style={{ background:'rgba(14,168,147,.14)' }}>
                <svg className="icon" style={{ color:'var(--teal-dark)' }}><use href="#i-scan"/></svg>
              </div>
              <h3>Scan or tap — your choice</h3>
              <p>Earn a punch instantly by scanning the counter QR code or tapping your phone on the NFC tag. No app-switching, no waiting on staff.</p>
            </div>
            <div className="feat-card">
              <div className="feat-ic" style={{ background:'rgba(124,111,240,.14)' }}>
                <svg className="icon" style={{ color:'var(--purple)' }}><use href="#i-gift"/></svg>
              </div>
              <h3>Rewards you&apos;ll actually use</h3>
              <p>Track exactly how many punches you need until your next free coffee, haircut or class — and get notified the moment it&apos;s ready.</p>
            </div>
            <div className="feat-card">
              <div className="feat-ic" style={{ background:'rgba(255,107,87,.14)' }}>
                <svg className="icon" style={{ color:'var(--coral-dark)' }}><use href="#i-bell"/></svg>
              </div>
              <h3>Never miss an offer</h3>
              <p>Get gentle reminders when a reward is close, plus occasional perks from businesses you love — nothing spammy.</p>
            </div>
          </div>
        </div>
      </section>

      {/* HOW IT WORKS */}
      <section id="how" style={{ background:'var(--surface-alt)' }}>
        <div className="wrap">
          <div className="sec-head">
            <div className="sec-eyebrow">Getting started</div>
            <h2>Three steps to your first reward</h2>
          </div>
          <div className="steps">
            <div className="step">
              <div className="step-num">1</div>
              <h3>Download &amp; sign up</h3>
              <p>Grab Punchy from the App Store or Google Play and create your free account in seconds.</p>
            </div>
            <div className="step">
              <div className="step-num">2</div>
              <h3>Add your first card</h3>
              <p>Scan a business&apos;s QR code in-store, or browse Explore to add cards from anywhere.</p>
            </div>
            <div className="step">
              <div className="step-num">3</div>
              <h3>Punch &amp; redeem</h3>
              <p>Scan or tap on every visit. Watch your progress fill up, then redeem your reward in-store.</p>
            </div>
          </div>
        </div>
      </section>

      {/* FOR BUSINESS */}
      <section id="business">
        <div className="wrap">
          <div className="biz-band">
            <div className="biz-copy">
              <div className="sec-eyebrow">For businesses</div>
              <h2>Turn first-time visitors into regulars</h2>
              <p>Set up your own digital loyalty program in minutes — no hardware required to start, no manual bookkeeping, ever.</p>
              <div className="biz-list">
                <div>
                  <svg className="icon" style={{ width:18, height:18 }}><use href="#i-check"/></svg>
                  Free to get started, live in under 10 minutes
                </div>
                <div>
                  <svg className="icon" style={{ width:18, height:18 }}><use href="#i-check"/></svg>
                  Design your own card, punches &amp; reward
                </div>
                <div>
                  <svg className="icon" style={{ width:18, height:18 }}><use href="#i-check"/></svg>
                  QR and NFC punching, fully self-serve for customers
                </div>
                <div>
                  <svg className="icon" style={{ width:18, height:18 }}><use href="#i-check"/></svg>
                  Real-time dashboard of customers &amp; activity
                </div>
              </div>
              <a href="#download" className="lbtn lbtn-coral">Get Punchy for Business</a>
            </div>
            <div className="biz-visual">
              <div className="biz-mock">
                <p style={{ fontSize:11, fontWeight:800, color:'var(--ink-soft)', margin:'0 0 10px' }}>☕ Brew &amp; Co. — Dashboard</p>
                <div className="stat-row">
                  <div className="stat"><span>Customers</span><b>312</b></div>
                  <div className="stat"><span>Today</span><b>48</b></div>
                  <div className="stat"><span>Redeemed</span><b>19</b></div>
                </div>
                <div className="wallet-card" style={{ background:'var(--grad-teal)' }}>
                  <div className="wc-top">
                    <div><div className="wc-name">Coffee Lovers Card</div><div className="wc-cat">10 punches → Free Coffee</div></div>
                    <div className="wc-logo">☕</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* TESTIMONIALS */}
      <section id="reviews">
        <div className="wrap">
          <div className="sec-head">
            <div className="sec-eyebrow">Loved by our community</div>
            <h2>What people are saying</h2>
          </div>
          <div className="quote-grid">
            {[
              { text: "I used to lose my paper punch cards constantly. Now everything's in one app and I actually earn my free coffee.", name: 'Ayesha Khan', role: 'Customer', initials: 'AK', grad: 'var(--grad-purple)' },
              { text: "Setup took ten minutes and customers started tapping in on day one. Repeat visits are noticeably up.", name: 'Brew & Co.', role: 'Business owner', initials: 'BC', grad: 'var(--grad-teal)' },
              { text: "The NFC tap is so fast — no camera fumbling, just tap and go. My favorite loyalty app by far.", name: 'Bilal Raza', role: 'Customer', initials: 'BR', grad: 'var(--grad-coral)' },
            ].map((q, i) => (
              <div key={i} className="quote-card">
                <div className="stars">
                  {[...Array(5)].map((_, j) => (
                    <svg key={j} className="icon" style={{ fill:'currentColor', stroke:'none', width:15, height:15 }}>
                      <use href="#i-star"/>
                    </svg>
                  ))}
                </div>
                <p>{q.text}</p>
                <div className="quote-who">
                  <div className="av" style={{ background: q.grad }}>{q.initials}</div>
                  <div><b>{q.name}</b><span>{q.role}</span></div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* DOWNLOAD BANNER */}
      <section id="download">
        <div className="wrap">
          <div className="download-band">
            <div className="download-copy">
              <h2>Get Punchy today</h2>
              <p>Free to download, free to join. Scan the code or tap a button below to get started on your phone.</p>
              <div className="download-store-row">
                <a href="#" className="store-btn">
                  <svg className="icon" style={{ width:22, height:22 }}><use href="#i-apple"/></svg>
                  <span><small>Download on the</small><b>App Store</b></span>
                </a>
                <a href="#" className="store-btn">
                  <svg className="icon" style={{ width:20, height:20 }}><use href="#i-play"/></svg>
                  <span><small>Get it on</small><b>Google Play</b></span>
                </a>
              </div>
            </div>
            <div className="qr-box">
              <div className="qr-graphic">
                <svg className="icon" style={{ width:60, height:60, color:'#fff' }}><use href="#i-scan"/></svg>
              </div>
              <span>Scan to download</span>
            </div>
          </div>
        </div>
      </section>

      {/* FOOTER */}
      <footer>
        <div className="wrap">
          <div className="foot-top">
            <div className="foot-brand">
              <div className="brand">
                <div className="brand-mark">
                  <svg className="icon" style={{ color:'#fff', strokeWidth:0, fill:'currentColor', width:17, height:17 }}>
                    <use href="#i-star"/>
                  </svg>
                </div>
                Punchy
              </div>
              <p>The simplest way to collect loyalty punches from every business you love — all in one wallet.</p>
            </div>
            <div className="foot-cols">
              <div className="foot-col">
                <h4>Product</h4>
                <a href="#features">Features</a>
                <a href="#how">How it works</a>
                <a href="#business">For Business</a>
              </div>
              <div className="foot-col">
                <h4>Company</h4>
                <a href="#">About</a>
                <a href="#">Careers</a>
                <a href="#">Contact</a>
              </div>
              <div className="foot-col">
                <h4>Legal</h4>
                <a href="#">Terms &amp; Conditions</a>
                <a href="#">Privacy Policy</a>
                <a href="#">Support</a>
              </div>
            </div>
          </div>
          <div className="foot-bottom">
            <span>© 2026 Punchy. All rights reserved.</span>
            <div className="foot-social">
              <div>𝕏</div><div>◎</div><div>in</div>
            </div>
          </div>
        </div>
      </footer>
    </>
  );
}
