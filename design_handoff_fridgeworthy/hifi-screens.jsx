// hifi-screens.jsx — Production-fidelity Fridgeworthy screens.
// All screens 402×874, full iOS chrome, refined art + wallpapers, no annotations.

// ─────────────────────────────────────────────────────────────
// 1 · SignIn — refined "stacked deck + crayon"
// ─────────────────────────────────────────────────────────────
function HFSignIn() {
  const tilts = [-7, 4, -2];
  return (
    <HFPhone>
      {/* warm cream background w/ subtle paper noise */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'radial-gradient(120% 80% at 50% 0%, #FFF6E8 0%, #F4ECD8 60%, #E8DCC0 100%)',
      }}/>
      <svg style={{ position: 'absolute', inset: 0, opacity: 0.4 }} width="100%" height="100%">
        <filter id="signin-paper">
          <feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" seed="3"/>
          <feColorMatrix values="0 0 0 0 0.5  0 0 0 0 0.4  0 0 0 0 0.3  0 0 0 0.12 0"/>
        </filter>
        <rect width="100%" height="100%" filter="url(#signin-paper)"/>
      </svg>

      {/* content */}
      <div style={{
        position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column',
        padding: '78px 28px 44px',
      }}>
        {/* top: brand mark */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 36, height: 36, borderRadius: 10, background: HF.accent,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 2px 8px rgba(124,58,237,0.3)',
          }}>
            <HFGlyph name="heart" size={20} color="#fff" weight={2.4}/>
          </div>
          <div style={{
            fontFamily: HF.display, fontSize: 22, fontWeight: 700,
            letterSpacing: -0.5, color: '#1a1a1a',
          }}>Fridgeworthy</div>
        </div>

        {/* stacked deck */}
        <div style={{
          flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center',
          position: 'relative', paddingTop: 24,
        }}>
          <div style={{
            position: 'relative', width: 220, height: 270,
          }}>
            {[3, 1, 2].map((seed, i) => (
              <div key={i} style={{
                position: 'absolute', left: '50%', top: '50%',
                width: 200, height: 240,
                transform: `translate(-50%,-50%) rotate(${tilts[i]}deg) translateY(${(i - 1) * -4}px)`,
                background: '#fff', borderRadius: 4,
                padding: 10, boxSizing: 'border-box',
                boxShadow: '0 1px 3px rgba(0,0,0,0.08), 0 8px 24px rgba(0,0,0,0.12)',
                zIndex: i,
              }}>
                <HFKidArt seed={seed} size={180}/>
                <div style={{
                  position: 'absolute', bottom: 12, left: 0, right: 0, textAlign: 'center',
                  fontFamily: HF.hand, fontSize: 16, color: '#7a5a3a',
                }}>{['By Maya, age 5','By Theo, age 7','By Iris, age 4'][i]}</div>
              </div>
            ))}
            {/* tape pieces */}
            <div style={{
              position: 'absolute', top: -10, left: '50%', transform: 'translateX(-50%) rotate(-3deg)',
              width: 56, height: 18, background: 'rgba(255,235,150,0.85)',
              boxShadow: '0 1px 2px rgba(0,0,0,0.08)', zIndex: 10,
            }}/>
          </div>
        </div>

        {/* tagline */}
        <div style={{ textAlign: 'center', marginBottom: 28, position: 'relative' }}>
          <div style={{
            fontFamily: HF.display, fontSize: 32, fontWeight: 700, lineHeight: 1.08,
            color: '#1a1a1a', letterSpacing: -0.9, marginBottom: 8,
          }}>
            Their art,
            <br/>
            <span style={{ position: 'relative' }}>
              everywhere
              <svg width="158" height="14" viewBox="0 0 158 14" style={{
                position: 'absolute', left: 0, bottom: -6,
              }}>
                <path d="M3 9 Q40 3 80 7 T155 6" stroke={HF.accent} strokeWidth="3" fill="none" strokeLinecap="round"/>
              </svg>
            </span>.
          </div>
          <div style={{
            fontSize: 16, color: HF.ink2, lineHeight: 1.4,
            letterSpacing: -0.2, marginTop: 14,
          }}>
            Snap your kid's artwork once.<br/>
            We turn it into wallpapers, prints, and gifts.
          </div>
        </div>

        {/* CTAs */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <button style={{
            height: 54, borderRadius: 27, border: 0,
            background: '#000', color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            fontFamily: HF.font, fontSize: 17, fontWeight: 600, letterSpacing: -0.3,
            boxShadow: '0 1px 3px rgba(0,0,0,0.18), 0 8px 20px rgba(0,0,0,0.18)',
          }}>
            <HFGlyph name="apple" size={20} color="#fff"/>
            Continue with Apple
          </button>
          <button style={{
            height: 54, borderRadius: 27, border: 0,
            background: 'rgba(255,255,255,0.85)', color: '#000',
            backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
            fontFamily: HF.font, fontSize: 17, fontWeight: 600, letterSpacing: -0.3,
            boxShadow: '0 1px 2px rgba(0,0,0,0.06), inset 0 0 0 1px rgba(0,0,0,0.06)',
          }}>
            Use email
          </button>
        </div>

        <div style={{
          textAlign: 'center', marginTop: 20,
          fontSize: 12, color: HF.ink3, letterSpacing: -0.1, lineHeight: 1.5,
        }}>
          By continuing you agree to our <span style={{ color: HF.accent, fontWeight: 500 }}>Terms</span> & <span style={{ color: HF.accent, fontWeight: 500 }}>Privacy</span>
        </div>
      </div>
    </HFPhone>
  );
}

// ─────────────────────────────────────────────────────────────
// 2 · Home — magazine-y "featured piece this week"
// ─────────────────────────────────────────────────────────────
function HFHome() {
  return (
    <HFPhone>
      {/* Top bar with avatar + plus pill */}
      <div style={{
        position: 'absolute', top: 60, left: 0, right: 0, zIndex: 5,
        padding: '0 16px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{
          width: 40, height: 40, borderRadius: 20, background: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 1px 2px rgba(0,0,0,0.08), 0 6px 16px rgba(0,0,0,0.06)',
          fontSize: 22,
        }}>👤</div>
        <button style={{
          height: 40, paddingLeft: 14, paddingRight: 18, borderRadius: 20,
          background: HF.accent, color: '#fff', border: 0,
          display: 'flex', alignItems: 'center', gap: 6,
          fontFamily: HF.font, fontSize: 15, fontWeight: 600, letterSpacing: -0.2,
          boxShadow: '0 1px 2px rgba(124,58,237,0.2), 0 6px 16px rgba(124,58,237,0.25)',
        }}>
          <HFGlyph name="plus" size={18} color="#fff" weight={2.4}/>
          New piece
        </button>
      </div>

      {/* Scrollable content */}
      <div style={{
        position: 'absolute', top: 110, left: 0, right: 0, bottom: 0,
        overflow: 'hidden', padding: '8px 0 90px',
      }}>
        {/* Greeting */}
        <div style={{ padding: '0 20px 14px' }}>
          <div style={{
            fontFamily: HF.display, fontSize: 32, fontWeight: 700, letterSpacing: -0.8,
            color: HF.ink, lineHeight: 1.1,
          }}>Hi, Sam</div>
          <div style={{
            fontSize: 15, color: HF.ink3, marginTop: 4, letterSpacing: -0.2,
          }}>3 kids · 47 pieces</div>
        </div>

        {/* Children chip rail */}
        <div style={{
          display: 'flex', gap: 10, padding: '10px 16px 18px',
          overflow: 'hidden',
        }}>
          {HF_KIDS.map((k, i) => (
            <div key={i} style={{
              padding: '8px 14px 8px 8px',
              borderRadius: 22, background: '#fff',
              display: 'flex', alignItems: 'center', gap: 8,
              boxShadow: '0 1px 2px rgba(0,0,0,0.04), 0 4px 12px rgba(0,0,0,0.04)',
              border: i === 0 ? `1.5px solid ${HF.accent}` : 'none',
            }}>
              <div style={{
                width: 28, height: 28, borderRadius: 14,
                background: ['#FFE5A8','#C4A8E0','#FFB5C5'][i],
                display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16,
              }}>{k.e}</div>
              <span style={{ fontSize: 14, fontWeight: 600, letterSpacing: -0.2 }}>{k.name}</span>
            </div>
          ))}
        </div>

        {/* Featured piece — magazine hero */}
        <div style={{ padding: '0 16px' }}>
          <div style={{
            fontSize: 11, fontWeight: 700, letterSpacing: 1.2, textTransform: 'uppercase',
            color: HF.accent, marginBottom: 8,
          }}>Featured this week</div>
          <div style={{
            background: '#fff', borderRadius: 24, overflow: 'hidden',
            boxShadow: '0 1px 2px rgba(0,0,0,0.04), 0 12px 32px rgba(0,0,0,0.06)',
          }}>
            <div style={{
              aspectRatio: '4 / 3.5',
              background: 'linear-gradient(135deg, #FFF6E8, #F4ECD8)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              position: 'relative',
            }}>
              <HFKidArt seed={2} size={260}/>
              <div style={{
                position: 'absolute', top: 12, left: 12,
                padding: '5px 10px', borderRadius: 12,
                background: 'rgba(255,255,255,0.92)',
                backdropFilter: 'blur(12px)',
                fontSize: 11, fontWeight: 600, letterSpacing: -0.1,
              }}>
                <HFHand size={15} color="#7a5a3a">Maya, age 5</HFHand>
              </div>
            </div>
            <div style={{ padding: '16px 18px 18px' }}>
              <div style={{
                fontFamily: HF.display, fontSize: 21, fontWeight: 700, letterSpacing: -0.5,
                color: HF.ink, lineHeight: 1.2, marginBottom: 4,
              }}>The Castle on Tuesday</div>
              <div style={{ fontSize: 14, color: HF.ink3, letterSpacing: -0.2 }}>Crayon · 8.5 × 11 in · added 3 days ago</div>
              <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
                <button style={{
                  flex: 1, height: 40, borderRadius: 20, border: 0,
                  background: HF.accent, color: '#fff',
                  fontFamily: HF.font, fontSize: 15, fontWeight: 600, letterSpacing: -0.2,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                }}>
                  <HFGlyph name="wand" size={16} color="#fff" weight={2.2}/>
                  Make wallpaper
                </button>
                <button style={{
                  width: 40, height: 40, borderRadius: 20, border: 0,
                  background: 'rgba(0,0,0,0.06)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <HFGlyph name="share" size={18} color="#000" weight={2}/>
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Recent strip header */}
        <div style={{
          padding: '24px 20px 10px',
          display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
        }}>
          <div style={{
            fontFamily: HF.display, fontSize: 19, fontWeight: 700, letterSpacing: -0.4,
          }}>Recent</div>
          <div style={{ fontSize: 14, color: HF.accent, fontWeight: 500 }}>See all</div>
        </div>
        {/* Horizontal recents */}
        <div style={{
          display: 'flex', gap: 12, padding: '0 16px',
          overflow: 'hidden',
        }}>
          {[3, 4, 0, 5].map((s, i) => (
            <div key={i} style={{
              width: 130, flexShrink: 0,
              background: '#fff', borderRadius: 18, overflow: 'hidden',
              boxShadow: '0 1px 2px rgba(0,0,0,0.04), 0 4px 12px rgba(0,0,0,0.04)',
            }}>
              <div style={{ aspectRatio: '1 / 1', padding: 6, background: '#FBFAF6' }}>
                <HFKidArt seed={s} size={118}/>
              </div>
              <div style={{ padding: '8px 10px 12px' }}>
                <div style={{ fontSize: 12, fontWeight: 600, letterSpacing: -0.2 }}>
                  {['Sea Turtle','Family','Castle','Garden'][i]}
                </div>
                <div style={{ fontSize: 10, color: HF.ink3, marginTop: 1 }}>
                  {['Theo','Iris','Maya','Iris'][i]} · {['2d','3d','5d','1w'][i]}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Bottom tab bar — liquid glass */}
      <HFTabBar active="home"/>
    </HFPhone>
  );
}

function HFTabBar({ active = 'home' }) {
  const tabs = [
    { id: 'home', icon: 'heart', label: 'Home' },
    { id: 'gallery', icon: 'photo', label: 'Gallery' },
    { id: 'create', icon: 'plus', label: '', cta: true },
    { id: 'shop', icon: 'crown', label: 'Shop' },
    { id: 'me', icon: 'sparkle', label: 'Me' },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 18, left: 16, right: 16, zIndex: 40,
      height: 64, borderRadius: 32,
      background: 'rgba(255,255,255,0.78)',
      backdropFilter: 'blur(24px) saturate(180%)',
      WebkitBackdropFilter: 'blur(24px) saturate(180%)',
      boxShadow: '0 1px 2px rgba(0,0,0,0.04), 0 8px 24px rgba(0,0,0,0.10), inset 0 0 0 0.5px rgba(0,0,0,0.06)',
      display: 'flex', alignItems: 'center', justifyContent: 'space-around',
      padding: '0 8px',
    }}>
      {tabs.map(t => {
        if (t.cta) {
          return (
            <div key={t.id} style={{
              width: 48, height: 48, borderRadius: 24, background: HF.accent,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 2px 6px rgba(124,58,237,0.3), 0 8px 20px rgba(124,58,237,0.3)',
            }}>
              <HFGlyph name="plus" size={22} color="#fff" weight={2.6}/>
            </div>
          );
        }
        const isActive = t.id === active;
        return (
          <div key={t.id} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
            color: isActive ? HF.accent : HF.ink3,
          }}>
            <HFGlyph name={t.icon} size={22} color={isActive ? HF.accent : HF.ink3} weight={isActive ? 2.2 : 1.8}/>
            <span style={{ fontSize: 10, fontWeight: isActive ? 600 : 500, letterSpacing: -0.1 }}>{t.label}</span>
          </div>
        );
      })}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 3 · ChildDetail — single hero + chip stats (chosen refinement A)
// ─────────────────────────────────────────────────────────────
function HFChildDetail() {
  return (
    <HFPhone>
      {/* hero band — soft tinted gradient */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 360,
        background: 'linear-gradient(180deg, #FFE5A8 0%, #FFC67D 60%, #FFB55C 100%)',
      }}>
        <svg width="100%" height="100%" style={{ position: 'absolute', inset: 0, opacity: 0.5 }}>
          <filter id="cd-grain">
            <feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" seed="4"/>
            <feColorMatrix values="0 0 0 0 0.5  0 0 0 0 0.4  0 0 0 0 0.3  0 0 0 0.12 0"/>
          </filter>
          <rect width="100%" height="100%" filter="url(#cd-grain)"/>
        </svg>
      </div>

      {/* nav buttons — glass pills on hero */}
      <div style={{
        position: 'absolute', top: 60, left: 16, right: 16, zIndex: 10,
        display: 'flex', justifyContent: 'space-between',
      }}>
        {['chevL', 'sparkle'].map((g, i) => (
          <div key={i} style={{
            width: 40, height: 40, borderRadius: 20,
            background: 'rgba(255,255,255,0.6)',
            backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.06)',
          }}>
            <HFGlyph name={g} size={20} color="#1a1a1a" weight={2}/>
          </div>
        ))}
      </div>

      {/* hero content */}
      <div style={{
        position: 'absolute', top: 116, left: 24, right: 24, zIndex: 5,
        display: 'flex', alignItems: 'center', gap: 16,
      }}>
        <div style={{
          width: 88, height: 88, borderRadius: 44, background: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 48,
          boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
        }}>🦊</div>
        <div style={{ flex: 1 }}>
          <div style={{
            fontFamily: HF.display, fontSize: 32, fontWeight: 800, letterSpacing: -0.7,
            color: '#2a1a05', lineHeight: 1.05,
          }}>Maya</div>
          <div style={{
            fontSize: 15, color: '#5a3a10', marginTop: 2, fontWeight: 500, letterSpacing: -0.2,
          }}>5 years old · since Mar 2023</div>
        </div>
      </div>

      {/* stat chips */}
      <div style={{
        position: 'absolute', top: 232, left: 16, right: 16, zIndex: 5,
        display: 'flex', gap: 8,
      }}>
        {[
          { n: '23', l: 'pieces' },
          { n: '8', l: 'wallpapers' },
          { n: '3', l: 'prints' },
        ].map((s, i) => (
          <div key={i} style={{
            flex: 1, height: 76, borderRadius: 18,
            background: 'rgba(255,255,255,0.65)',
            backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
            boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.06)',
            display: 'flex', flexDirection: 'column',
            alignItems: 'center', justifyContent: 'center',
          }}>
            <div style={{
              fontFamily: HF.display, fontSize: 26, fontWeight: 700, letterSpacing: -0.7,
              color: '#2a1a05', lineHeight: 1,
            }}>{s.n}</div>
            <div style={{ fontSize: 12, color: '#5a3a10', marginTop: 4, fontWeight: 500, letterSpacing: -0.1 }}>{s.l}</div>
          </div>
        ))}
      </div>

      {/* white sheet */}
      <div style={{
        position: 'absolute', top: 340, left: 0, right: 0, bottom: 0,
        background: HF.bg, borderTopLeftRadius: 28, borderTopRightRadius: 28,
        padding: '20px 0 100px',
      }}>
        {/* tabs */}
        <div style={{
          display: 'flex', gap: 4, padding: '0 16px', marginBottom: 14,
          background: 'rgba(0,0,0,0.05)', borderRadius: 12, padding: 4, margin: '0 16px 16px',
        }}>
          {['All', 'Wallpapers', 'Prints'].map((t, i) => (
            <div key={i} style={{
              flex: 1, height: 32, borderRadius: 9,
              background: i === 0 ? '#fff' : 'transparent',
              boxShadow: i === 0 ? '0 1px 2px rgba(0,0,0,0.06)' : 'none',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 13, fontWeight: i === 0 ? 600 : 500, letterSpacing: -0.2,
              color: i === 0 ? HF.ink : HF.ink3,
            }}>{t}</div>
          ))}
        </div>

        {/* sectioned grid */}
        <div style={{
          padding: '0 20px 8px', fontSize: 13, fontWeight: 600,
          color: HF.ink3, textTransform: 'uppercase', letterSpacing: 0.6,
        }}>This week</div>
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 6,
          padding: '0 16px',
        }}>
          {[2, 3, 0, 4, 1, 5].slice(0, 3).map((s, i) => (
            <div key={i} style={{
              aspectRatio: '1 / 1', borderRadius: 14, overflow: 'hidden',
              background: '#fff', padding: 4,
              boxShadow: '0 1px 2px rgba(0,0,0,0.04), 0 4px 8px rgba(0,0,0,0.04)',
            }}>
              <HFKidArt seed={s} size={110}/>
            </div>
          ))}
        </div>

        <div style={{
          padding: '20px 20px 8px', fontSize: 13, fontWeight: 600,
          color: HF.ink3, textTransform: 'uppercase', letterSpacing: 0.6,
        }}>Last week</div>
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 6,
          padding: '0 16px',
        }}>
          {[5, 1, 4].map((s, i) => (
            <div key={i} style={{
              aspectRatio: '1 / 1', borderRadius: 14, overflow: 'hidden',
              background: '#fff', padding: 4,
              boxShadow: '0 1px 2px rgba(0,0,0,0.04), 0 4px 8px rgba(0,0,0,0.04)',
            }}>
              <HFKidArt seed={s} size={110}/>
            </div>
          ))}
        </div>
      </div>

      <HFTabBar active="home"/>
    </HFPhone>
  );
}

// ─────────────────────────────────────────────────────────────
// 4 · Gallery — crayon-underline section headers
// ─────────────────────────────────────────────────────────────
function HFGallery() {
  return (
    <HFPhone>
      {/* nav */}
      <div style={{
        position: 'absolute', top: 60, left: 0, right: 0, zIndex: 10,
        padding: '0 16px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{
          width: 40, height: 40, borderRadius: 20, background: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 1px 2px rgba(0,0,0,0.06)',
        }}>
          <HFGlyph name="chevL" size={18} color="#000" weight={2.2}/>
        </div>
        <div style={{
          display: 'flex', gap: 8,
        }}>
          <div style={{
            height: 40, padding: '0 14px', borderRadius: 20, background: '#fff',
            display: 'flex', alignItems: 'center', gap: 6,
            boxShadow: '0 1px 2px rgba(0,0,0,0.06)',
            fontSize: 14, fontWeight: 600, letterSpacing: -0.2,
          }}>
            All kids
            <HFGlyph name="chevD" size={14} color={HF.ink3} weight={2}/>
          </div>
        </div>
      </div>

      {/* large title */}
      <div style={{
        position: 'absolute', top: 116, left: 20, right: 20,
        fontFamily: HF.display, fontSize: 36, fontWeight: 700, letterSpacing: -0.9,
        color: HF.ink,
      }}>
        Gallery
        <div style={{ fontSize: 15, color: HF.ink3, fontWeight: 400, marginTop: 2, letterSpacing: -0.2 }}>
          47 pieces · 3 kids
        </div>
      </div>

      {/* scroll content */}
      <div style={{
        position: 'absolute', top: 196, left: 0, right: 0, bottom: 0,
        overflow: 'hidden', padding: '8px 0 100px',
      }}>
        {[
          { month: 'October', year: '2025', count: 7, seeds: [2,3,0,4,1,5] },
          { month: 'September', year: '2025', count: 12, seeds: [5,1,4,2,3,0] },
          { month: 'August', year: '2025', count: 9, seeds: [3,4,5,0] },
        ].map((mo, mi) => (
          <div key={mi} style={{ marginBottom: 24 }}>
            {/* header w/ crayon underline */}
            <div style={{
              padding: '0 20px', marginBottom: 14, position: 'relative',
              display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
            }}>
              <div>
                <span style={{
                  fontFamily: HF.display, fontSize: 24, fontWeight: 700, letterSpacing: -0.6, color: HF.ink,
                }}>{mo.month}</span>
                <span style={{
                  fontSize: 16, color: HF.ink3, marginLeft: 8, fontWeight: 400, letterSpacing: -0.2,
                }}>{mo.year}</span>
              </div>
              <div style={{ fontSize: 13, color: HF.ink3, fontWeight: 500 }}>{mo.count} pieces</div>
              <svg width="120" height="6" viewBox="0 0 120 6" style={{ position: 'absolute', left: 20, bottom: -4 }}>
                <path d="M2 3 Q30 1 60 3 T118 3" stroke={HF.accent} strokeWidth="2.5" fill="none" strokeLinecap="round" opacity="0.85"/>
              </svg>
            </div>

            <div style={{
              display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 6,
              padding: '0 16px',
            }}>
              {mo.seeds.map((s, i) => (
                <div key={i} style={{
                  aspectRatio: '1 / 1', borderRadius: 14, overflow: 'hidden',
                  background: '#fff', padding: 5,
                  boxShadow: '0 1px 2px rgba(0,0,0,0.04), 0 4px 10px rgba(0,0,0,0.04)',
                  position: 'relative',
                }}>
                  <HFKidArt seed={s + mi} size={108}/>
                  {/* tiny kid badge */}
                  <div style={{
                    position: 'absolute', bottom: 8, left: 8,
                    width: 18, height: 18, borderRadius: 9,
                    background: ['#FFE5A8','#C4A8E0','#FFB5C5'][i % 3],
                    display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10,
                    boxShadow: '0 1px 2px rgba(0,0,0,0.1)',
                  }}>{HF_KIDS[i % 3].e}</div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      <HFTabBar active="gallery"/>
    </HFPhone>
  );
}

// ─────────────────────────────────────────────────────────────
// 5 · StylePicker — preview + grid
// ─────────────────────────────────────────────────────────────
function HFStylePicker() {
  const styles = HF_STYLES;
  const selected = 0;
  return (
    <HFPhone>
      {/* nav */}
      <div style={{
        position: 'absolute', top: 60, left: 0, right: 0, zIndex: 10,
        padding: '0 16px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{
          height: 40, padding: '0 16px 0 12px', borderRadius: 20, background: '#fff',
          display: 'flex', alignItems: 'center', gap: 4,
          boxShadow: '0 1px 2px rgba(0,0,0,0.06)',
          fontSize: 15, fontWeight: 500, letterSpacing: -0.2, color: HF.accent,
        }}>
          <HFGlyph name="chevL" size={18} color={HF.accent} weight={2.2}/>
          Cancel
        </div>
        <div style={{
          fontFamily: HF.font, fontSize: 17, fontWeight: 600, letterSpacing: -0.4,
        }}>Choose style</div>
        <div style={{ width: 80 }}/>
      </div>

      {/* preview */}
      <div style={{
        position: 'absolute', top: 116, left: 0, right: 0, height: 320,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        padding: '0 28px',
      }}>
        <div style={{
          width: 180, height: 300, borderRadius: 32, overflow: 'hidden',
          boxShadow: '0 4px 12px rgba(0,0,0,0.1), 0 20px 40px rgba(0,0,0,0.15)',
          position: 'relative',
        }}>
          <HFWallpaper style={styles[selected].style} seed={1} w={180} h={300} radius={32}/>
          <div style={{
            position: 'absolute', top: 12, left: '50%', transform: 'translateX(-50%)',
            width: 70, height: 18, borderRadius: 12, background: '#000',
          }}/>
          {/* lock screen mock */}
          <div style={{
            position: 'absolute', top: 60, left: 0, right: 0, textAlign: 'center',
            color: '#fff', textShadow: '0 2px 8px rgba(0,0,0,0.4)',
          }}>
            <div style={{ fontSize: 14, fontWeight: 500, letterSpacing: -0.2 }}>Tuesday, Oct 28</div>
            <div style={{
              fontFamily: HF.display, fontSize: 64, fontWeight: 200, letterSpacing: -2,
              lineHeight: 1, marginTop: -2,
            }}>9:41</div>
          </div>
        </div>
      </div>

      {/* style name */}
      <div style={{
        position: 'absolute', top: 444, left: 0, right: 0, textAlign: 'center',
      }}>
        <div style={{
          fontFamily: HF.display, fontSize: 22, fontWeight: 700, letterSpacing: -0.5,
          color: HF.ink,
        }}>{styles[selected].name}</div>
        <div style={{
          fontSize: 13, color: HF.ink3, marginTop: 2, letterSpacing: -0.2,
        }}>{styles[selected].sub}</div>
      </div>

      {/* style picker grid */}
      <div style={{
        position: 'absolute', top: 510, left: 0, right: 0, bottom: 0,
        padding: '0 16px 90px', overflow: 'hidden',
      }}>
        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 10,
        }}>
          {styles.map((s, i) => (
            <div key={i} style={{
              aspectRatio: '1 / 1.2', borderRadius: 12, overflow: 'hidden',
              position: 'relative',
              boxShadow: i === selected
                ? `0 0 0 2.5px ${HF.accent}, 0 4px 12px rgba(124,58,237,0.25)`
                : '0 1px 3px rgba(0,0,0,0.06), 0 2px 8px rgba(0,0,0,0.04)',
            }}>
              <HFWallpaper style={s.style} seed={i + 2} w={86} h={104} radius={0}/>
              {s.pro && (
                <div style={{
                  position: 'absolute', top: 6, right: 6,
                  padding: '2px 6px', borderRadius: 6,
                  background: 'rgba(255,255,255,0.92)',
                  fontSize: 8, fontWeight: 700, letterSpacing: 0.4,
                  color: HF.accent,
                }}>PRO</div>
              )}
              <div style={{
                position: 'absolute', bottom: 0, left: 0, right: 0,
                padding: '12px 6px 4px',
                background: 'linear-gradient(180deg, transparent, rgba(0,0,0,0.7))',
                color: '#fff', fontSize: 9.5, fontWeight: 600, textAlign: 'center',
                letterSpacing: -0.1,
              }}>{s.name.split(' ')[0]}</div>
            </div>
          ))}
        </div>

        {/* CTA */}
        <button style={{
          position: 'absolute', bottom: 18, left: 16, right: 16,
          height: 54, borderRadius: 27, border: 0,
          background: HF.accent, color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          fontFamily: HF.font, fontSize: 17, fontWeight: 600, letterSpacing: -0.3,
          boxShadow: '0 1px 3px rgba(124,58,237,0.25), 0 8px 20px rgba(124,58,237,0.3)',
        }}>
          <HFGlyph name="wand" size={18} color="#fff" weight={2.2}/>
          Generate · 3 free left
        </button>
      </div>
    </HFPhone>
  );
}

// ─────────────────────────────────────────────────────────────
// 6 · Paywall — hero + checklist (chosen baseline, polished)
// ─────────────────────────────────────────────────────────────
function HFPaywall() {
  return (
    <HFPhone>
      {/* gradient hero bg */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'radial-gradient(140% 60% at 50% 0%, #C4A8E0 0%, #9F7AEA 40%, #7C3AED 100%)',
      }}/>
      <svg style={{ position: 'absolute', inset: 0, opacity: 0.25 }} width="100%" height="100%">
        <filter id="pw-paper">
          <feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" seed="6"/>
          <feColorMatrix values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 0.18 0"/>
        </filter>
        <rect width="100%" height="100%" filter="url(#pw-paper)"/>
      </svg>

      {/* close */}
      <div style={{
        position: 'absolute', top: 60, right: 16, zIndex: 10,
        width: 36, height: 36, borderRadius: 18,
        background: 'rgba(0,0,0,0.25)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <HFGlyph name="close" size={16} color="#fff" weight={2.4}/>
      </div>

      {/* hero — wallpaper preview + crown */}
      <div style={{
        position: 'absolute', top: 80, left: 0, right: 0, height: 280,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <div style={{ position: 'relative', width: 200, height: 260 }}>
          {/* tilted secondary */}
          <div style={{
            position: 'absolute', left: -38, top: 24, width: 130, height: 200,
            transform: 'rotate(-8deg)', borderRadius: 20, overflow: 'hidden',
            boxShadow: '0 8px 24px rgba(0,0,0,0.25)',
          }}>
            <HFWallpaper style="storybook" seed={3} w={130} h={200} radius={20}/>
          </div>
          {/* tilted secondary right */}
          <div style={{
            position: 'absolute', right: -38, top: 24, width: 130, height: 200,
            transform: 'rotate(8deg)', borderRadius: 20, overflow: 'hidden',
            boxShadow: '0 8px 24px rgba(0,0,0,0.25)',
          }}>
            <HFWallpaper style="cutpaper" seed={5} w={130} h={200} radius={20}/>
          </div>
          {/* main */}
          <div style={{
            position: 'absolute', left: '50%', top: 0, transform: 'translateX(-50%)',
            width: 150, height: 240, borderRadius: 24, overflow: 'hidden',
            boxShadow: '0 12px 32px rgba(0,0,0,0.3)',
          }}>
            <HFWallpaper style="watercolor" seed={2} w={150} h={240} radius={24}/>
          </div>
          {/* crown */}
          <div style={{
            position: 'absolute', top: -22, left: '50%', transform: 'translateX(-50%) rotate(-6deg)',
            width: 50, height: 50, borderRadius: 25,
            background: '#FFD93D', display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 12px rgba(0,0,0,0.2)',
            zIndex: 10,
          }}>
            <HFGlyph name="crown" size={26} color="#A0700E" weight={2.4}/>
          </div>
        </div>
      </div>

      {/* sheet */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, top: 380,
        background: '#fff',
        borderTopLeftRadius: 32, borderTopRightRadius: 32,
        padding: '28px 24px 36px',
        boxShadow: '0 -8px 32px rgba(0,0,0,0.08)',
      }}>
        <div style={{
          fontFamily: HF.display, fontSize: 30, fontWeight: 800, letterSpacing: -0.7,
          color: HF.ink, lineHeight: 1.05, textAlign: 'center', marginBottom: 6,
        }}>
          Unlock the
          <br/>
          full studio.
        </div>
        <div style={{
          textAlign: 'center', fontSize: 15, color: HF.ink3, letterSpacing: -0.2,
          marginBottom: 22,
        }}>
          Every style. Unlimited wallpapers. Free shipping.
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 22 }}>
          {[
            'All 12 art styles, including new monthly drops',
            'Unlimited wallpaper generations',
            'Free shipping on prints & gifts',
          ].map((t, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
              <div style={{
                width: 24, height: 24, borderRadius: 12, background: HF.accent,
                display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                marginTop: 1,
              }}>
                <HFGlyph name="check" size={14} color="#fff" weight={3}/>
              </div>
              <div style={{ fontSize: 15, color: HF.ink, letterSpacing: -0.2, lineHeight: 1.35 }}>{t}</div>
            </div>
          ))}
        </div>

        {/* plan cards */}
        <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
          <div style={{
            flex: 1, padding: '14px 12px', borderRadius: 16,
            border: '1.5px solid rgba(0,0,0,0.1)',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
          }}>
            <div style={{ fontSize: 11, fontWeight: 600, color: HF.ink3, letterSpacing: 0.4, textTransform: 'uppercase' }}>Monthly</div>
            <div style={{ fontFamily: HF.display, fontSize: 22, fontWeight: 700, letterSpacing: -0.4, color: HF.ink }}>$6.99</div>
            <div style={{ fontSize: 11, color: HF.ink3 }}>per month</div>
          </div>
          <div style={{
            flex: 1, padding: '14px 12px', borderRadius: 16,
            border: `2px solid ${HF.accent}`, background: 'rgba(124,58,237,0.05)',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
            position: 'relative',
          }}>
            <div style={{
              position: 'absolute', top: -10, left: '50%', transform: 'translateX(-50%)',
              padding: '3px 8px', borderRadius: 8, background: HF.accent,
              fontSize: 9, fontWeight: 700, color: '#fff', letterSpacing: 0.4,
            }}>SAVE 40%</div>
            <div style={{ fontSize: 11, fontWeight: 600, color: HF.accent, letterSpacing: 0.4, textTransform: 'uppercase' }}>Yearly</div>
            <div style={{ fontFamily: HF.display, fontSize: 22, fontWeight: 700, letterSpacing: -0.4, color: HF.ink }}>$3.99</div>
            <div style={{ fontSize: 11, color: HF.ink3 }}>per month</div>
          </div>
        </div>

        <button style={{
          width: '100%', height: 54, borderRadius: 27, border: 0,
          background: HF.accent, color: '#fff',
          fontFamily: HF.font, fontSize: 17, fontWeight: 700, letterSpacing: -0.3,
          boxShadow: '0 1px 3px rgba(124,58,237,0.25), 0 8px 20px rgba(124,58,237,0.3)',
          marginBottom: 10,
        }}>Start 7-day free trial</button>
        <div style={{
          textAlign: 'center', fontSize: 11, color: HF.ink3, letterSpacing: -0.1, lineHeight: 1.4,
        }}>Cancel anytime · Restore purchases</div>
      </div>
    </HFPhone>
  );
}

Object.assign(window, {
  HFSignIn, HFHome, HFChildDetail, HFGallery, HFStylePicker, HFPaywall, HFTabBar,
});
