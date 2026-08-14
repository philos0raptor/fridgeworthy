// hifi-kit.jsx — Hi-fi primitives for Fridgeworthy production polish.
// - Real iOS 18 device chrome (status bar, dynamic island, home indicator)
// - Richer SVG kid-art (pencil texture, varied subjects)
// - Higher-fidelity wallpaper SVGs (gradients, paper grain, watercolor washes)
// - SF Pro type with proper letterspacing
// - No annotations / no wireframe surfaces

const HF_W = 402;
const HF_H = 874;
const HF = {
  bg:     '#F2F2F7',
  bgDark: '#000',
  card:   '#FFFFFF',
  cardDark:'#1C1C1E',
  surface2:'#F2F2F7',
  surface2Dark:'#2C2C2E',
  ink:    '#000000',
  ink2:   'rgba(60,60,67,0.85)',
  ink3:   'rgba(60,60,67,0.6)',
  ink4:   'rgba(60,60,67,0.3)',
  inkDark:'#FFFFFF',
  ink2Dark:'rgba(235,235,245,0.85)',
  ink3Dark:'rgba(235,235,245,0.6)',
  ink4Dark:'rgba(235,235,245,0.3)',
  sep:    'rgba(60,60,67,0.12)',
  sepDark:'rgba(84,84,88,0.65)',
  accent: '#7C3AED',
  accent2:'#9F7AEA',
  hand:   '"Caveat", cursive',
  font:   '-apple-system, "SF Pro Text", BlinkMacSystemFont, system-ui, sans-serif',
  display:'-apple-system, "SF Pro Display", BlinkMacSystemFont, system-ui, sans-serif',
};

// Deterministic random
function hfRand(seed) {
  let s = seed * 9301 + 49297;
  return () => {
    s = (s * 9301 + 49297) % 233280;
    return s / 233280;
  };
}

// ─────────────────────────────────────────────────────────────
// HiFi Status Bar — real iOS 18 styling
// ─────────────────────────────────────────────────────────────
function HFStatusBar({ dark = false, time = '9:41' }) {
  const c = dark ? '#fff' : '#000';
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '21px 33px 0', height: 54, boxSizing: 'border-box',
      position: 'relative', zIndex: 20,
    }}>
      <div style={{
        fontFamily: HF.font, fontWeight: 600, fontSize: 17, color: c,
        letterSpacing: -0.4, fontVariantNumeric: 'tabular-nums',
      }}>{time}</div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
        {/* signal */}
        <svg width="18" height="11" viewBox="0 0 18 11">
          <rect x="0" y="6.5" width="3" height="4.5" rx="0.7" fill={c}/>
          <rect x="4.5" y="4" width="3" height="7" rx="0.7" fill={c}/>
          <rect x="9" y="2" width="3" height="9" rx="0.7" fill={c}/>
          <rect x="13.5" y="0" width="3" height="11" rx="0.7" fill={c}/>
        </svg>
        {/* wifi */}
        <svg width="16" height="11" viewBox="0 0 16 11">
          <path d="M8 2.8C10.1 2.8 12 3.6 13.4 4.9L14.4 4c-1.7-1.6-4-2.7-6.4-2.7S3.3 2.4 1.6 4l1 .9C4 3.6 5.9 2.8 8 2.8z" fill={c}/>
          <path d="M8 6c1.3 0 2.4.5 3.2 1.3l1-1c-1.1-1-2.6-1.6-4.2-1.6s-3.1.6-4.2 1.6l1 1C5.6 6.5 6.7 6 8 6z" fill={c}/>
          <circle cx="8" cy="9.6" r="1.3" fill={c}/>
        </svg>
        {/* battery */}
        <svg width="25" height="12" viewBox="0 0 25 12">
          <rect x="0.5" y="0.5" width="21" height="11" rx="3.2" stroke={c} strokeOpacity="0.35" fill="none"/>
          <rect x="2" y="2" width="18" height="8" rx="1.8" fill={c}/>
          <path d="M23 4v4c0.7-0.2 1.2-1 1.2-2s-0.5-1.8-1.2-2z" fill={c} fillOpacity="0.4"/>
        </svg>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// HiFi Phone — full device frame
// ─────────────────────────────────────────────────────────────
function HFPhone({ children, dark = false, bg, time = '9:41', noChrome = false, noBezel = false }) {
  const inner = (
    <>
      {/* status bar */}
      {!noChrome && (
        <div style={{ position: 'absolute', top: 0, left: 0, right: 0, zIndex: 30 }}>
          <HFStatusBar dark={dark} time={time}/>
        </div>
      )}
      {/* dynamic island */}
      {!noChrome && (
        <div style={{
          position: 'absolute', top: 11, left: '50%', transform: 'translateX(-50%)',
          width: 124, height: 36, borderRadius: 22, background: '#000', zIndex: 50,
        }}/>
      )}
      {/* content */}
      <div style={{
        position: 'absolute', inset: 0,
        background: bg || (dark ? HF.bgDark : HF.bg),
        overflow: 'hidden',
        fontFamily: HF.font,
      }}>
        {children}
      </div>
      {/* home indicator */}
      {!noChrome && (
        <div style={{
          position: 'absolute', bottom: 8, left: '50%', transform: 'translateX(-50%)',
          width: 134, height: 5, borderRadius: 100,
          background: dark ? 'rgba(255,255,255,0.5)' : 'rgba(0,0,0,0.35)',
          zIndex: 60,
        }}/>
      )}
    </>
  );

  if (noBezel) {
    return (
      <div style={{
        width: HF_W, height: HF_H, borderRadius: 48, position: 'relative', overflow: 'hidden',
        background: dark ? HF.bgDark : HF.bg,
      }}>
        {inner}
      </div>
    );
  }

  return (
    <div style={{
      width: HF_W, height: HF_H, borderRadius: 52, position: 'relative',
      background: '#0a0a0a', padding: 11, boxSizing: 'border-box',
      boxShadow: '0 30px 60px rgba(0,0,0,0.18), 0 0 0 1px rgba(0,0,0,0.18), inset 0 0 0 1.5px rgba(255,255,255,0.06)',
    }}>
      <div style={{
        width: '100%', height: '100%', borderRadius: 42,
        position: 'relative', overflow: 'hidden',
        background: dark ? HF.bgDark : HF.bg,
        WebkitFontSmoothing: 'antialiased',
      }}>
        {inner}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// HiFi kid art — varied SVG drawings with paper grain + crayon strokes
// ─────────────────────────────────────────────────────────────
const KID_PALETTES = [
  ['#E63946', '#F4A261', '#F6C453', '#2A9D8F', '#457B9D', '#7C3AED'],
  ['#EE6C4D', '#F2CC8F', '#81B29A', '#3D5A80', '#293241'],
  ['#FFB4A2', '#E5989B', '#B5838D', '#6D6875', '#FFCDB2'],
  ['#06AED5', '#086788', '#F0C808', '#FFF1D0', '#DD1C1A'],
];

function HFKidArt({ seed = 1, size = 200, palette }) {
  const subject = seed % 6;
  const pal = palette || KID_PALETTES[seed % KID_PALETTES.length];
  const id = `kart-${seed}`;
  const grain = `kgrain-${seed}`;

  const subjects = [
    // 0 — house with sun
    <g key="house">
      <circle cx="160" cy="50" r="22" fill={pal[2]} opacity="0.9"/>
      {Array.from({length: 8}).map((_, i) => {
        const a = (i / 8) * Math.PI * 2;
        return <line key={i} x1={160 + Math.cos(a) * 28} y1={50 + Math.sin(a) * 28}
          x2={160 + Math.cos(a) * 38} y2={50 + Math.sin(a) * 38}
          stroke={pal[2]} strokeWidth="2.5" strokeLinecap="round"/>;
      })}
      <path d="M40 110 L100 60 L160 110 L160 180 L40 180 Z" fill={pal[1]} stroke={pal[4]} strokeWidth="2.5" strokeLinejoin="round" opacity="0.95"/>
      <rect x="80" y="130" width="40" height="50" fill={pal[3]} stroke={pal[4]} strokeWidth="2"/>
      <rect x="50" y="125" width="20" height="20" fill={pal[0]} opacity="0.7"/>
      <rect x="130" y="125" width="20" height="20" fill={pal[0]} opacity="0.7"/>
      <line x1="20" y1="180" x2="180" y2="180" stroke={pal[2]} strokeWidth="3" strokeLinecap="round"/>
      <path d="M20 188 Q40 184 60 188 T100 188 T140 188 T180 188" stroke={pal[3]} strokeWidth="2" fill="none"/>
    </g>,
    // 1 — fish/ocean
    <g key="fish">
      <path d="M0 30 Q40 22 80 30 T160 30 T240 30" stroke={pal[3]} strokeWidth="2" fill="none" opacity="0.5"/>
      <path d="M0 60 Q40 52 80 60 T160 60 T240 60" stroke={pal[3]} strokeWidth="2" fill="none" opacity="0.4"/>
      <ellipse cx="100" cy="110" rx="50" ry="32" fill={pal[3]} stroke={pal[4]} strokeWidth="2.5"/>
      <path d="M150 110 L185 80 L185 140 Z" fill={pal[3]} stroke={pal[4]} strokeWidth="2.5" strokeLinejoin="round"/>
      <circle cx="80" cy="105" r="6" fill="#fff"/>
      <circle cx="80" cy="105" r="3" fill={pal[4]}/>
      <path d="M70 130 Q90 138 105 130" stroke={pal[4]} strokeWidth="2" fill="none" strokeLinecap="round"/>
      <circle cx="125" cy="100" r="3" fill={pal[1]}/>
      <circle cx="115" cy="120" r="2.5" fill={pal[2]}/>
      <circle cx="135" cy="115" r="2.5" fill={pal[0]}/>
      {/* bubbles */}
      <circle cx="40" cy="60" r="6" fill="none" stroke={pal[3]} strokeWidth="1.5"/>
      <circle cx="55" cy="40" r="4" fill="none" stroke={pal[3]} strokeWidth="1.5"/>
      <circle cx="30" cy="80" r="3" fill="none" stroke={pal[3]} strokeWidth="1.5"/>
    </g>,
    // 2 — tree with apples
    <g key="tree">
      <line x1="100" y1="80" x2="100" y2="170" stroke={pal[4]} strokeWidth="14" strokeLinecap="round"/>
      <circle cx="100" cy="70" r="60" fill={pal[3]} opacity="0.92"/>
      <circle cx="65" cy="90" r="35" fill={pal[3]} opacity="0.85"/>
      <circle cx="135" cy="90" r="35" fill={pal[3]} opacity="0.85"/>
      <circle cx="80" cy="55" r="6" fill={pal[0]}/>
      <circle cx="115" cy="65" r="6" fill={pal[0]}/>
      <circle cx="100" cy="90" r="6" fill={pal[0]}/>
      <circle cx="55" cy="100" r="5" fill={pal[0]}/>
      <circle cx="140" cy="100" r="5" fill={pal[0]}/>
      <line x1="20" y1="170" x2="180" y2="170" stroke={pal[2]} strokeWidth="3" strokeLinecap="round"/>
    </g>,
    // 3 — princess/castle
    <g key="castle">
      <rect x="40" y="80" width="120" height="100" fill={pal[2]} stroke={pal[4]} strokeWidth="2.5"/>
      <rect x="30" y="60" width="30" height="120" fill={pal[2]} stroke={pal[4]} strokeWidth="2.5"/>
      <rect x="140" y="60" width="30" height="120" fill={pal[2]} stroke={pal[4]} strokeWidth="2.5"/>
      <path d="M30 60 L35 50 L40 60 L45 50 L50 60 L55 50 L60 60" fill={pal[2]} stroke={pal[4]} strokeWidth="2"/>
      <path d="M140 60 L145 50 L150 60 L155 50 L160 60 L165 50 L170 60" fill={pal[2]} stroke={pal[4]} strokeWidth="2"/>
      <rect x="85" y="120" width="30" height="60" fill={pal[3]} stroke={pal[4]} strokeWidth="2"/>
      <path d="M85 120 Q100 110 115 120" fill={pal[3]} stroke={pal[4]} strokeWidth="2"/>
      <circle cx="40" cy="50" r="3" fill={pal[0]}/>
      <circle cx="160" cy="50" r="3" fill={pal[0]}/>
      <path d="M100 25 L105 35 L115 35 L107 42 L110 52 L100 46 L90 52 L93 42 L85 35 L95 35 Z" fill={pal[1]}/>
    </g>,
    // 4 — flower garden
    <g key="garden">
      {[40, 80, 120, 160].map((x, i) => (
        <g key={x}>
          <line x1={x} y1="180" x2={x} y2="120" stroke={pal[3]} strokeWidth="3"/>
          <ellipse cx={x - 10} cy="140" rx="8" ry="4" fill={pal[3]} transform={`rotate(-30 ${x - 10} 140)`}/>
          {[0, 1, 2, 3, 4].map(k => {
            const a = (k / 5) * Math.PI * 2;
            return <ellipse key={k}
              cx={x + Math.cos(a) * 12} cy={120 + Math.sin(a) * 12}
              rx="9" ry="14" fill={pal[i % 3]} opacity="0.92"
              transform={`rotate(${(a * 180/Math.PI) + 90} ${x + Math.cos(a) * 12} ${120 + Math.sin(a) * 12})`}/>;
          })}
          <circle cx={x} cy="120" r="6" fill={pal[2]}/>
        </g>
      ))}
      <line x1="10" y1="180" x2="190" y2="180" stroke={pal[2]} strokeWidth="3"/>
      <circle cx="170" cy="40" r="20" fill={pal[2]} opacity="0.85"/>
    </g>,
    // 5 — abstract shapes
    <g key="abstract">
      <circle cx="60" cy="60" r="40" fill={pal[0]} opacity="0.85"/>
      <rect x="100" y="40" width="70" height="70" fill={pal[1]} opacity="0.85" transform="rotate(15 135 75)"/>
      <path d="M30 120 L100 130 L80 180 L20 170 Z" fill={pal[3]} opacity="0.85"/>
      <circle cx="150" cy="150" r="28" fill={pal[2]} opacity="0.85"/>
      <path d="M0 100 Q100 80 200 100" stroke={pal[4]} strokeWidth="3" fill="none"/>
    </g>,
  ];

  return (
    <svg width={size} height={size} viewBox="0 0 200 200" style={{ display: 'block' }}>
      <defs>
        <filter id={grain}>
          <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed={seed}/>
          <feColorMatrix values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0.08 0"/>
          <feComposite in2="SourceGraphic" operator="in"/>
        </filter>
        <filter id={id}>
          <feTurbulence type="fractalNoise" baseFrequency="2" numOctaves="2" seed={seed * 7}/>
          <feDisplacementMap in="SourceGraphic" scale="0.8"/>
        </filter>
      </defs>
      <rect width="200" height="200" fill="#FBFAF6"/>
      {/* paper texture */}
      <rect width="200" height="200" filter={`url(#${grain})`} opacity="0.7"/>
      <g filter={`url(#${id})`}>{subjects[subject]}</g>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// HiFi wallpaper preview — richer per-style art
// ─────────────────────────────────────────────────────────────
function HFWallpaper({ style = 'watercolor', seed = 1, w = 160, h = 200, radius = 16 }) {
  const id = `wp-${style}-${seed}`;
  const r = hfRand(seed * 31 + style.length);

  const renders = {
    watercolor: () => (
      <>
        <defs>
          <radialGradient id={`${id}-g1`} cx="35%" cy="40%" r="60%">
            <stop offset="0%" stopColor="#FCD2D2"/>
            <stop offset="100%" stopColor="#F19BB6"/>
          </radialGradient>
          <radialGradient id={`${id}-g2`} cx="70%" cy="65%" r="50%">
            <stop offset="0%" stopColor="#FFE5A8"/>
            <stop offset="100%" stopColor="#F4A261"/>
          </radialGradient>
          <filter id={`${id}-paper`}>
            <feTurbulence type="fractalNoise" baseFrequency="0.6" numOctaves="3" seed={seed}/>
            <feColorMatrix values="0 0 0 0 0.55  0 0 0 0 0.45  0 0 0 0 0.4  0 0 0 0.18 0"/>
            <feComposite in2="SourceGraphic" operator="in"/>
          </filter>
          <filter id={`${id}-blur`}><feGaussianBlur stdDeviation="3"/></filter>
        </defs>
        <rect width="200" height="280" fill="#FFFAF0"/>
        <g filter={`url(#${id}-blur)`} opacity="0.92">
          <ellipse cx="80" cy="100" rx="80" ry="70" fill={`url(#${id}-g1)`}/>
          <ellipse cx="140" cy="180" rx="70" ry="60" fill={`url(#${id}-g2)`}/>
          <ellipse cx="50" cy="220" rx="60" ry="40" fill="#A4C5E5" opacity="0.7"/>
          <ellipse cx="170" cy="60" rx="40" ry="30" fill="#C4A8E0" opacity="0.6"/>
        </g>
        {/* watercolor splatters */}
        {Array.from({length: 12}).map((_, i) => {
          const cx = r() * 200, cy = r() * 280, rad = 2 + r() * 4;
          return <circle key={i} cx={cx} cy={cy} r={rad} fill={['#E63946','#7C3AED','#F4A261'][i % 3]} opacity={0.3 + r() * 0.3}/>;
        })}
        <rect width="200" height="280" filter={`url(#${id}-paper)`}/>
      </>
    ),
    storybook: () => (
      <>
        <defs>
          <linearGradient id={`${id}-sky`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#FFC4A8"/>
            <stop offset="50%" stopColor="#FFB5C5"/>
            <stop offset="100%" stopColor="#C4A8E0"/>
          </linearGradient>
          <filter id={`${id}-paper`}>
            <feTurbulence type="fractalNoise" baseFrequency="0.7" numOctaves="2" seed={seed}/>
            <feColorMatrix values="0 0 0 0 0.4  0 0 0 0 0.3  0 0 0 0 0.2  0 0 0 0.12 0"/>
            <feComposite in2="SourceGraphic" operator="in"/>
          </filter>
        </defs>
        <rect width="200" height="280" fill={`url(#${id}-sky)`}/>
        {/* moon */}
        <circle cx="155" cy="60" r="22" fill="#FFF5DC" opacity="0.95"/>
        <circle cx="148" cy="55" r="20" fill={`url(#${id}-sky)`} opacity="0.4"/>
        {/* hills */}
        <path d="M0 220 Q50 180 100 200 T200 195 L200 280 L0 280 Z" fill="#5D7B6F"/>
        <path d="M0 240 Q60 215 130 230 T200 235 L200 280 L0 280 Z" fill="#3E5C50"/>
        {/* tree silhouette */}
        <line x1="40" y1="240" x2="40" y2="200" stroke="#2C3E50" strokeWidth="3"/>
        <circle cx="40" cy="190" r="14" fill="#2C3E50"/>
        <line x1="160" y1="245" x2="160" y2="210" stroke="#2C3E50" strokeWidth="3"/>
        <circle cx="160" cy="200" r="11" fill="#2C3E50"/>
        {/* stars */}
        {Array.from({length: 18}).map((_, i) => {
          const cx = r() * 200, cy = r() * 160;
          return <circle key={i} cx={cx} cy={cy} r={r() * 1.2 + 0.3} fill="#FFF" opacity={0.5 + r() * 0.5}/>;
        })}
        <rect width="200" height="280" filter={`url(#${id}-paper)`}/>
      </>
    ),
    cutpaper: () => (
      <>
        <defs>
          <filter id={`${id}-paper`}>
            <feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" seed={seed}/>
            <feColorMatrix values="0 0 0 0 0.3  0 0 0 0 0.25  0 0 0 0 0.2  0 0 0 0.16 0"/>
            <feComposite in2="SourceGraphic" operator="in"/>
          </filter>
        </defs>
        <rect width="200" height="280" fill="#F4ECD8"/>
        {/* cut shapes with offset shadows */}
        <path d="M-20 240 Q40 210 100 230 T220 225 L220 320 L-20 320 Z" fill="#E63946" filter={`url(#${id}-paper)`}/>
        <path d="M30 130 L100 100 L160 130 L160 220 L30 220 Z" fill="#F4A261" stroke="#C36A2D" strokeWidth="0.5"/>
        <path d="M30 130 L100 100 L160 130 L100 110 Z" fill="#E89A4B"/>
        <rect x="80" y="160" width="32" height="60" fill="#6D4C41"/>
        <circle cx="155" cy="50" r="22" fill="#FFD93D"/>
        {[0,1,2,3,4,5,6,7].map(i => {
          const a = (i / 8) * Math.PI * 2;
          return <line key={i} x1={155 + Math.cos(a) * 26} y1={50 + Math.sin(a) * 26}
            x2={155 + Math.cos(a) * 34} y2={50 + Math.sin(a) * 34}
            stroke="#FFD93D" strokeWidth="3" strokeLinecap="round"/>;
        })}
        {/* clouds */}
        <ellipse cx="50" cy="55" rx="22" ry="10" fill="#FFFAF0"/>
        <ellipse cx="60" cy="48" rx="14" ry="8" fill="#FFFAF0"/>
        {/* tree */}
        <line x1="170" y1="200" x2="170" y2="170" stroke="#6D4C41" strokeWidth="4"/>
        <circle cx="170" cy="160" r="14" fill="#5D7B6F"/>
        <rect width="200" height="280" filter={`url(#${id}-paper)`}/>
      </>
    ),
    popart: () => (
      <>
        <defs>
          <pattern id={`${id}-dots`} x="0" y="0" width="10" height="10" patternUnits="userSpaceOnUse">
            <circle cx="5" cy="5" r="1.5" fill="#E63946" opacity="0.6"/>
          </pattern>
          <filter id={`${id}-paper`}>
            <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed={seed}/>
            <feColorMatrix values="0 0 0 0 0.5  0 0 0 0 0.4  0 0 0 0 0.3  0 0 0 0.1 0"/>
            <feComposite in2="SourceGraphic" operator="in"/>
          </filter>
        </defs>
        <rect width="200" height="280" fill="#FFD93D"/>
        <rect width="200" height="280" fill={`url(#${id}-dots)`}/>
        <circle cx="100" cy="120" r="60" fill="#06AED5" stroke="#000" strokeWidth="3"/>
        <circle cx="100" cy="120" r="40" fill="#FFD93D"/>
        <circle cx="100" cy="120" r="22" fill="#E63946" stroke="#000" strokeWidth="3"/>
        {/* zap lines */}
        {[0, 60, 120, 180, 240, 300].map(deg => (
          <line key={deg} x1={100 + Math.cos(deg * Math.PI/180) * 70} y1={120 + Math.sin(deg * Math.PI/180) * 70}
            x2={100 + Math.cos(deg * Math.PI/180) * 95} y2={120 + Math.sin(deg * Math.PI/180) * 95}
            stroke="#000" strokeWidth="3" strokeLinecap="round"/>
        ))}
        <rect width="200" height="280" filter={`url(#${id}-paper)`}/>
      </>
    ),
    pencil: () => (
      <>
        <defs>
          <filter id={`${id}-paper`}>
            <feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="3" seed={seed}/>
            <feColorMatrix values="0 0 0 0 0.4  0 0 0 0 0.35  0 0 0 0 0.3  0 0 0 0.18 0"/>
            <feComposite in2="SourceGraphic" operator="in"/>
          </filter>
          <filter id={`${id}-rough`}>
            <feTurbulence type="fractalNoise" baseFrequency="3" numOctaves="2" seed={seed * 5}/>
            <feDisplacementMap in="SourceGraphic" scale="1"/>
          </filter>
        </defs>
        <rect width="200" height="280" fill="#FAF6E8"/>
        <g filter={`url(#${id}-rough)`} stroke="#3D3D3D" fill="none" strokeWidth="1.2" strokeLinecap="round">
          {/* crosshatching */}
          {Array.from({length: 50}).map((_, i) => {
            const x = r() * 200, y = r() * 280, len = 8 + r() * 14, ang = r() * Math.PI;
            return <line key={i}
              x1={x - Math.cos(ang) * len / 2} y1={y - Math.sin(ang) * len / 2}
              x2={x + Math.cos(ang) * len / 2} y2={y + Math.sin(ang) * len / 2}
              opacity={0.4 + r() * 0.4}/>;
          })}
          <ellipse cx="100" cy="140" rx="60" ry="80" strokeWidth="1.4"/>
          <ellipse cx="100" cy="140" rx="50" ry="68" strokeWidth="1.4"/>
          <ellipse cx="100" cy="140" rx="40" ry="56" strokeWidth="1.4"/>
        </g>
        <rect width="200" height="280" filter={`url(#${id}-paper)`}/>
      </>
    ),
    embroidery: () => (
      <>
        <defs>
          <pattern id={`${id}-fab`} x="0" y="0" width="3" height="3" patternUnits="userSpaceOnUse">
            <rect width="3" height="3" fill="#E8DCC8"/>
            <line x1="0" y1="1.5" x2="3" y2="1.5" stroke="#D4C5A8" strokeWidth="0.4"/>
            <line x1="1.5" y1="0" x2="1.5" y2="3" stroke="#D4C5A8" strokeWidth="0.4"/>
          </pattern>
          <filter id={`${id}-paper`}>
            <feTurbulence type="fractalNoise" baseFrequency="1" numOctaves="2" seed={seed}/>
            <feColorMatrix values="0 0 0 0 0.3  0 0 0 0 0.25  0 0 0 0 0.2  0 0 0 0.12 0"/>
            <feComposite in2="SourceGraphic" operator="in"/>
          </filter>
        </defs>
        <rect width="200" height="280" fill={`url(#${id}-fab)`}/>
        {/* embroidered flower */}
        <g transform="translate(100,140)">
          {[0,1,2,3,4].map(i => {
            const a = (i / 5) * Math.PI * 2;
            const cx = Math.cos(a) * 30, cy = Math.sin(a) * 30;
            return (
              <g key={i}>
                <ellipse cx={cx} cy={cy} rx="20" ry="32" fill="#E63946"
                  transform={`rotate(${(a * 180/Math.PI) + 90} ${cx} ${cy})`}/>
                {Array.from({length: 8}).map((_, j) => (
                  <line key={j}
                    x1={cx - 12 + j * 3} y1={cy - 25}
                    x2={cx - 12 + j * 3} y2={cy + 25}
                    stroke="#A02030" strokeWidth="0.6"
                    transform={`rotate(${(a * 180/Math.PI) + 90} ${cx} ${cy})`}/>
                ))}
              </g>
            );
          })}
          <circle r="14" fill="#F6C453"/>
          {Array.from({length: 12}).map((_, j) => (
            <line key={j} x1="0" y1="0" x2={Math.cos(j * Math.PI/6) * 14} y2={Math.sin(j * Math.PI/6) * 14}
              stroke="#C09038" strokeWidth="0.8"/>
          ))}
        </g>
        <rect width="200" height="280" filter={`url(#${id}-paper)`}/>
      </>
    ),
  };

  const render = renders[style] || renders.watercolor;

  return (
    <div style={{ width: w, height: h, borderRadius: radius, overflow: 'hidden', position: 'relative' }}>
      <svg width={w} height={h} viewBox="0 0 200 280" preserveAspectRatio="xMidYMid slice"
        style={{ display: 'block', width: '100%', height: '100%' }}>
        {render()}
      </svg>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// HiFi glyphs — refined, SF-Symbols-flavored
// ─────────────────────────────────────────────────────────────
function HFGlyph({ name, size = 22, color = 'currentColor', weight = 1.8 }) {
  const p = { fill: 'none', stroke: color, strokeWidth: weight, strokeLinecap: 'round', strokeLinejoin: 'round' };
  const fp = { fill: color };
  const paths = {
    plus: <path d="M12 5v14M5 12h14" {...p}/>,
    chevR: <path d="M9 5l7 7-7 7" {...p}/>,
    chevL: <path d="M15 5l-7 7 7 7" {...p}/>,
    close: <path d="M6 6l12 12M6 18L18 6" {...p}/>,
    apple: <path d="M16.6 13.5c0-2.7 2.2-4 2.3-4.1-1.3-1.8-3.2-2.1-3.9-2.1-1.7-.2-3.2 1-4.1 1-.8 0-2.1-1-3.5-1-1.8 0-3.4 1.1-4.4 2.7-1.9 3.2-.5 8 1.3 10.6.9 1.3 2 2.8 3.4 2.7 1.4-.1 1.9-.9 3.5-.9s2.1.9 3.5.9c1.5 0 2.4-1.3 3.3-2.6.7-1 1.3-2.1 1.7-3.3-1.4-.5-3.1-1.7-3.1-3.9zm-2.7-7.3c.7-.9 1.2-2.1 1.1-3.3-1 .1-2.3.7-3.1 1.6-.7.8-1.3 2-1.1 3.2 1.2.1 2.4-.6 3.1-1.5z" {...fp}/>,
    wand: <><path d="M3 21l9-9" {...p}/><path d="M14 7l3 3" {...p}/><path d="M16 4l1 1.5M19.5 7l1.5 1.5M21 11l-1.5-1M13 4l1 1.5" {...p}/><circle cx="14.5" cy="6.5" r="0.6" {...fp}/></>,
    palette: <path d="M12 3a9 9 0 100 18c1.5 0 2-1 2-2s-.8-1.5-.8-2.5.8-1.5 2-1.5h1.8c1.7 0 3-1.3 3-3 0-5-3.6-9-8-9z" {...p}/>,
    check: <path d="M5 12l5 5L20 7" {...p}/>,
    lock: <><rect x="5" y="11" width="14" height="10" rx="2" {...p}/><path d="M8 11V7a4 4 0 018 0v4" {...p}/></>,
    sparkle: <path d="M12 3l1.5 5L18 9.5l-4.5 1.5L12 16l-1.5-5L6 9.5 10.5 8z" {...p}/>,
    photo: <><rect x="3" y="5" width="18" height="14" rx="2.5" {...p}/><circle cx="9" cy="10" r="1.5" {...p}/><path d="M3 17l5-4 5 3 3-2 5 4" {...p}/></>,
    camera: <><path d="M4 8h3l2-3h6l2 3h3v11H4z" {...p}/><circle cx="12" cy="13.5" r="3.5" {...p}/></>,
    share: <><path d="M12 3v12M8 7l4-4 4 4M5 14v6h14v-6" {...p}/></>,
    heart: <path d="M12 20s-7-4.4-7-10a4 4 0 017-2.6A4 4 0 0119 10c0 5.6-7 10-7 10z" {...p}/>,
    crown: <path d="M3 18h18M5 18l-2-9 5 4 4-7 4 7 5-4-2 9" {...p}/>,
    chevD: <path d="M5 9l7 7 7-7" {...p}/>,
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ display: 'inline-block' }}>
      {paths[name]}
    </svg>
  );
}

// Small handwritten label
function HFHand({ children, color = HF.accent, size = 20, style = {} }) {
  return (
    <span style={{
      fontFamily: HF.hand, fontSize: size, color, fontWeight: 600,
      lineHeight: 1.2, ...style,
    }}>{children}</span>
  );
}

// Small primary button
function HFBtn({ children, kind = 'primary', size = 'md', icon, full = false, style = {} }) {
  const sizes = {
    sm: { h: 34, fs: 14, px: 14, gap: 6, iconSize: 14 },
    md: { h: 44, fs: 15, px: 18, gap: 8, iconSize: 16 },
    lg: { h: 52, fs: 17, px: 22, gap: 8, iconSize: 18 },
  };
  const s = sizes[size];
  const colors = {
    primary: { bg: HF.accent, fg: '#fff', shadow: '0 1px 2px rgba(124,58,237,0.2), 0 4px 12px rgba(124,58,237,0.25)' },
    dark:    { bg: '#000', fg: '#fff', shadow: '0 1px 2px rgba(0,0,0,0.15), 0 4px 12px rgba(0,0,0,0.18)' },
    secondary:{ bg: 'rgba(0,0,0,0.06)', fg: '#000', shadow: 'none' },
    ghost:   { bg: 'transparent', fg: HF.accent, shadow: 'none' },
  };
  const c = colors[kind];
  return (
    <button style={{
      height: s.h, padding: `0 ${s.px}px`, borderRadius: s.h / 2,
      background: c.bg, color: c.fg, border: 0, outline: 0, boxShadow: c.shadow,
      fontFamily: HF.font, fontSize: s.fs, fontWeight: 600, letterSpacing: -0.2,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: s.gap,
      width: full ? '100%' : 'auto', cursor: 'pointer',
      ...style,
    }}>
      {icon && <HFGlyph name={icon} size={s.iconSize} color={c.fg} weight={2}/>}
      {children}
    </button>
  );
}

// Sample children data
const HF_KIDS = [
  { name: 'Maya',  e: '🦊' },
  { name: 'Theo',  e: '🐻' },
  { name: 'Iris',  e: '🦋' },
];

const HF_STYLES = [
  { style: 'watercolor',  name: 'Watercolor Garden',  pro: false, sub: 'Soft, dreamy washes' },
  { style: 'storybook',   name: 'Storybook Adventure',pro: true,  sub: 'Twilight illustration' },
  { style: 'cutpaper',    name: 'Cut-Paper Collage',  pro: true,  sub: 'Layered, dimensional' },
  { style: 'popart',      name: 'Pop Art Burst',      pro: false, sub: 'Bold, graphic, fun' },
  { style: 'pencil',      name: 'Pencil Sketch',      pro: true,  sub: 'Hand-drawn, textured' },
  { style: 'embroidery',  name: 'Embroidered',        pro: true,  sub: 'Stitched, tactile' },
];

Object.assign(window, {
  HF, HF_W, HF_H, HF_KIDS, HF_STYLES,
  HFPhone, HFStatusBar, HFKidArt, HFWallpaper, HFGlyph, HFHand, HFBtn,
});
