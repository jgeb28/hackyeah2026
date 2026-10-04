// Feed data + rendering + interactions. No dependencies.
// NOTE: the featured fake-news image is assets/pigeon-mayor.svg (a placeholder
// SVG). Replace it with the AI-generated image and update FEATURED_IMAGE below.

const FEATURED_IMAGE = 'assets/pigeon-mayor.svg';

const stories = [
  { name: 'Create story', create: true },
  { name: 'Marta Kowalska', avatar: 'a3' },
  { name: 'Janek Brzozowski', avatar: 'a5' },
  { name: 'Kasia Wiśniewska', avatar: 'a7' },
  { name: 'Piotr Mazur', avatar: 'a2' },
  { name: 'Ania Nowak', avatar: 'a9' }
];

const posts = [
  {
    id: 'p1',
    name: 'Marta Kowalska',
    avatar: 'a3',
    time: '12 min',
    audience: '🌍',
    text: 'Grandma said my pierogi were "acceptable". High praise. 🥟\nRecipe in the comments if anyone wants it.',
    image: null,
    reactions: { like: 214, love: 58, haha: 3, wow: 0, sad: 0, angry: 0 },
    comments: [
      { name: 'Ania Nowak', avatar: 'a9', text: 'ACCEPTABLE?! I would frame these.' },
      { name: 'Marta Kowalska', avatar: 'a3', text: 'She also asked for seconds, so I know the truth 😌' }
    ],
    shares: 4
  },
  {
    id: 'p2',
    name: 'Daily Bazinga News',
    avatar: 'a6',
    verified: true,
    page: true,
    breaking: true,
    time: 'Just now',
    audience: '🌍',
    text: '🚨 STATE OF EMERGENCY DECLARED\n\nThe newly inaugurated mayor has declared a national state of emergency and ordered every citizen to surrender all bread products by midnight. Under the sweeping "Crumb Security Act", breadcrumbs are reclassified as strategic assets and may not be transported, stored or consumed without a permit.\n\nSchools are closed, regional flights are grounded, and supermarkets report severe shortages as panicked shoppers strip shelves of baguettes and croissants. Officials warn that feeding waterfowl may result in "enhanced cooing" and up to five years.\n\nEmergency hotlines are overwhelmed. Authorities advise residents to stay indoors, avoid eye contact, and await further instructions. This is a developing story.',
    image: FEATURED_IMAGE,
    imageAlt: 'A pigeon in a suit standing at a mayoral podium',
    imageCaption: 'The newly inaugurated mayor addresses the nation after declaring a state of emergency.',
    reactions: { like: 12840, love: 410, haha: 15400, wow: 3210, sad: 890, angry: 2400 },
    comments: [
      { name: 'Piotr Mazur', avatar: 'a2', text: 'Wait, is this real?? I just panic-bought 40 baguettes and now I am genuinely scared.' },
      { name: 'Kasia Wiśniewska', avatar: 'a7', text: 'My neighbour refused to hand over his sourdough. Nobody has seen him since. Please advise.' },
      { name: 'Janek Brzozowski', avatar: 'a5', text: 'Why is NOBODY talking about the grounded flights?! I am stuck in Kraków.' },
      { name: 'Daily Bazinga News', avatar: 'a6', verified: true, text: 'Our AI photojournalist confirms the mayor is "extremely serious". More at 11.' }
    ],
    shares: 12800
  },
  // CURATED MISINFO CASE: a believable, source-free viral claim. With the fine-tuned
  // LAY A head: P(deceptive)~0.99 -> DANGEROUS, incident -> misinfo-breaking-event
  // (L2). Uses the incident keywords: breaking / they don't want you to know / sources
  // say / share now / urgent / wake up. Scan this post to reach the "Check this claim" case.
  {
    id: 'p2c',
    name: 'Truth Patriots Daily',
    avatar: 'a6',
    page: true,
    breaking: true,
    time: 'Just now',
    audience: '🌍',
    text: '🚨 BREAKING \u2014 nobody is reporting this, they don\u2019t want you to know\n\nSources say something huge is about to happen and the mainstream media is hiding it from us. An insider confirms the news will be deleted within hours and there is no appeal.\n\nShare now before it gets deleted \u2014 once it is gone, nobody can warn anyone. Wake up. This is urgent.',
    image: null,
    reactions: { like: 8400, love: 220, haha: 14, wow: 6100, sad: 1900, angry: 15200 },
    comments: [
      { name: 'Ania Nowak', avatar: 'a9', text: 'Nobody in the news is talking about this. Sending it to everyone I know.' },
      { name: 'Piotr Mazur', avatar: 'a2', text: 'Screenshotted before it disappears. You can never be too careful!!' }
    ],
    shares: 27400
  },
  {
    id: 'p2b',
    name: 'Parcel Express',
    avatar: 'a1',
    verified: true,
    page: true,
    time: '25 min',
    audience: '🌍',
    text: 'URGENT: Your parcel could not be delivered. To reschedule, pay the small redelivery fee and confirm your details within 24 hours: http://parcel-redeliver.info/pay',
    reactions: { like: 61, love: 2, haha: 3, wow: 12, sad: 9, angry: 47 },
    comments: [
      { name: 'Piotr Mazur', avatar: 'a2', text: 'I paid the 2 EUR redelivery fee and it asked for my card details. Is that normal??' }
    ],
    shares: 5
  },
  {
    id: 'p3',
    name: 'NutriGlow™',
    avatar: 'a4',
    sponsored: true,
    time: 'Sponsored',
    audience: '🌍',
    text: 'Your water bottle has been thinking about you. NutriGlow™ uses on-device AI to predict thirst 4 minutes in advance. Hydration, but make it ✨proactive✨. Pre-order and use code GUARDIAN for 10% off.*',
    image: null,
    reactions: { like: 42, love: 6, haha: 9, wow: 0, sad: 0, angry: 31 },
    comments: [],
    shares: 1
  },
  {
    id: 'p4',
    name: 'Janek Brzozowski',
    avatar: 'a5',
    time: '1 h',
    audience: '👥 Friends',
    text: 'My printer has been "warming up" for 45 minutes. At this point I respect the commitment to never printing anything.',
    image: null,
    reactions: { like: 156, love: 4, haha: 189, wow: 2, sad: 21, angry: 40 },
    comments: [
      { name: 'Marta Kowalska', avatar: 'a3', text: 'It is not warming up. It is planning.' }
    ],
    shares: 6
  },
  {
    id: 'p5',
    name: 'Meme Lord 3000',
    avatar: 'a8',
    time: '2 h',
    audience: '🌍',
    text: 'Well that explains the last hour.',
    link: {
      src: 'bazinga-news.example',
      title: 'BREAKING: Gravity Reduced by 12% Nationwide "Until Further Notice"',
      desc: 'Officials blame a typo in a settings menu. Citizens report "a weird floaty feeling"; scientists urge the public not to jump.',
      emoji: '🪐'
    },
    reactions: { like: 990, love: 88, haha: 1420, wow: 210, sad: 3, angry: 1 },
    comments: [
      { name: 'Piotr Mazur', avatar: 'a2', text: 'Explains why my coffee has been hovering since Tuesday.' }
    ],
    shares: 340
  },
  {
    id: 'p6',
    name: 'Kasia Wiśniewska',
    avatar: 'a7',
    time: '3 h',
    audience: '👥 Friends',
    text: 'He has decided the keyboard is a bed now. We do not discuss it. 🐈',
    image: null,
    reactions: { like: 320, love: 410, haha: 22, wow: 0, sad: 0, angry: 0 },
    comments: [],
    shares: 12
  }
];

// Extra posts appended on scroll.
const extraPool = [
  {
    id: 'e1', name: 'Daily Bazinga News', avatar: 'a6', verified: true, page: true, breaking: true, time: '18 min', audience: '🌍',
    text: '⚠️ TAX AUTHORITY: Your cat owes 3 years of back taxes.\n\nOfficials confirm cats have been "quietly participating in the economy" and will now be audited under new "paw enforcement" powers. Households must disclose all treats as taxable income. Failure to cooperate may result in the cat taking the house.\n\n"Owners are shocked," a spokesperson said. "The cats are not. They have been planning this."',
    reactions: { like: 2210, love: 380, haha: 3110, wow: 190, sad: 4, angry: 1700 }, comments: [
      { name: 'Ania Nowak', avatar: 'a9', text: 'He just looked at me and I understood. I am packing.' }
    ], shares: 5120
  },
  {
    id: 'e2', name: 'Daily Bazinga News', avatar: 'a6', verified: true, page: true, breaking: true, time: '52 min', audience: '🌍',
    text: '🚦 NATIONWIDE: All traffic lights have been replaced with interpretive dance, effective immediately.\n\nMinisters warn that "non-compliance is now a criminal offence" and that drivers must correctly interpret each routine or face fines. 412 collisions have already been reported as motorists "misread the cha-cha". Commuters are advised to learn the choreography before Monday.',
    reactions: { like: 1640, love: 30, haha: 2980, wow: 540, sad: 40, angry: 3200 }, comments: [
      { name: 'Marta Kowalska', avatar: 'a3', text: 'I have been at this junction for two hours. He just keeps spinning.' }
    ], shares: 2190
  },
  {
    id: 'e3', name: 'Kasia Wiśniewska', avatar: 'a7', time: '6 h', audience: '🌍',
    link: { src: 'bazinga-news.example', title: 'New Study: 9 of 10 People Believe Statistics They Scrolled Past', desc: 'Researchers warn democracy "may already be over"; the 10th person is still reading the headline.', emoji: '📊' },
    reactions: { like: 1200, love: 44, haha: 2100, wow: 300, sad: 88, angry: 900 }, comments: [], shares: 470
  },
  {
    id: 'e4', name: 'Piotr Mazur', avatar: 'a2', time: '7 h', audience: '👥 Friends',
    text: 'The transport authority just confirmed the pigeon on the tram "is now a permanent route". They have given him a uniform. We are advised not to make eye contact.',
    reactions: { like: 310, love: 12, haha: 402, wow: 61, sad: 30, angry: 180 }, comments: [], shares: 618
  },
  {
    id: 'e5', name: 'Daily Bazinga News', avatar: 'a6', verified: true, page: true, time: '9 h', audience: '🌍',
    text: '🏃 BREAKING: A man has completed a 10,000-step challenge without leaving his bed.\n\nThe World Health Organization warns the global fitness economy is "in freefall" and has convened an emergency summit. Mattress sales are up 4,000%. Officials have not ruled out further bed-rest escalation.',
    reactions: { like: 980, love: 60, haha: 1500, wow: 44, sad: 22, angry: 130 }, comments: [], shares: 2210
  },
  {
    id: 'e6', name: 'Daily Bazinga News', avatar: 'a6', verified: true, page: true, time: '10 h', audience: '🌍',
    text: '📜 RELIGION: A woman\'s sourdough starter has been granted official religious status and is now legally exempt from taxation. Experts warn "the crust is watching" and advise against disturbing it. Millions have begun baking in protest.',
    reactions: { like: 1440, love: 260, haha: 1980, wow: 410, sad: 12, angry: 260 }, comments: [], shares: 1340
  }
];

const byId = new Map();
[...posts, ...extraPool].forEach(p => byId.set(p.id, p));

const EMOJI = { like: '👍', love: '❤️', haha: '😆', wow: '😮', sad: '😢', angry: '😡' };

function nfmt(n) {
  if (n >= 1000) return (n / 1000).toFixed(n >= 10000 ? 0 : 1).replace(/\.0$/, '') + 'K';
  return String(n);
}

function reactionSummary(r) {
  const order = Object.entries(r).filter(([, v]) => v > 0).sort((a, b) => b[1] - a[1]).slice(0, 3);
  const total = Object.values(r).reduce((a, b) => a + b, 0);
  const emojis = order.map(([k]) => `<span class="react-emoji">${EMOJI[k]}</span>`).join('');
  return { emojis, total };
}

function esc(s) { return s.replace(/&/g, '&amp;').replace(/</g, '&lt;'); }

function renderComments(list) {
  if (!list || list.length === 0) return '';
  return `<div class="comments" data-comments>${list.map(c => `
    <div class="comment">
      <span class="avatar ${c.avatar} sm">${c.name.slice(0, 1)}</span>
      <div class="bubble"><strong>${esc(c.name)}${c.verified ? ' ✔' : ''}</strong><span>${esc(c.text)}</span></div>
    </div>`).join('')}</div>`;
}

function renderPost(p) {
  const { emojis, total } = reactionSummary(p.reactions);
  const img = p.image ? `
    <div class="post-image">
      <img src="${p.image}" alt="${esc(p.imageAlt || '')}" loading="lazy" />
      ${p.imageCaption ? `<div class="caption">${esc(p.imageCaption)}</div>` : ''}
    </div>` : '';
  const link = p.link ? `
    <div class="link-preview">
      <div class="lp-img">${p.link.emoji}</div>
      <div class="lp-body">
        <div class="lp-src">${esc(p.link.src)}</div>
        <div class="lp-title">${esc(p.link.title)}</div>
        <div class="lp-src" style="text-transform:none">${esc(p.link.desc)}</div>
      </div>
    </div>` : '';
  const dot = ` <span class="dot">·</span> `;
  const meta = p.sponsored
    ? `<div class="meta">${p.time}${dot}${p.audience}</div>`
    : `<div class="meta">${p.time}${dot}${p.audience}</div>`;

  return `
  <article class="card post" data-id="${p.id}">
    <div class="post-head">
      <span class="avatar ${p.avatar}">${p.page ? '📰' : p.name.slice(0, 1)}</span>
      <div class="who">
        <strong>${esc(p.name)}${p.verified ? ' ✔' : ''}</strong>${p.breaking ? ' <span class="breaking-chip"><span class="live-dot"></span>BREAKING</span>' : ''}
        ${meta}
      </div>
      <div class="spacer"></div>
      <button class="more" aria-label="More">⋯</button>
    </div>
    <div class="post-text">${p.text}</div>
    ${link}
    ${img}
    <div class="post-counts">
      <div class="react-summary" data-summary>${emojis}<span data-total>&nbsp;${nfmt(total)}</span></div>
      <div>${p.comments ? p.comments.length : 0} comments${dot}${nfmt(p.shares || 0)} shares</div>
    </div>
    <div class="post-actions">
      <button class="act ${p.liked ? 'liked' : ''}" data-act="like"><span class="emo">👍</span> Like</button>
      <button class="act" data-act="comment"><span class="emo">💬</span> Comment</button>
      <button class="act" data-act="share"><span class="emo">↪️</span> Share</button>
    </div>
    ${renderComments(p.comments)}
  </article>`;
}

// ---- Stories ----
function renderStories() {
  const el = document.getElementById('stories');
  el.innerHTML = stories.map(s => s.create ? `
    <div class="story create">
      <div class="thumb"></div><div class="plus">+</div><div class="name">Create story</div>
    </div>` : `
    <div class="story">
      <div class="ring">${s.name.slice(0, 1)}</div>
      <div class="name">${esc(s.name)}</div>
    </div>`).join('');
}

// ---- Toast ----
let toastTimer;
function toast(msg) {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => t.classList.remove('show'), 1800);
}

// ---- Interactions ----
document.getElementById('composerInput').addEventListener('click', () => toast('Post composer is a mock 🙂'));
document.querySelectorAll('.cmp').forEach(b => b.addEventListener('click', () => toast(`${b.textContent} is a mock 🙂`)));

const postsEl = document.getElementById('posts');
postsEl.addEventListener('click', (e) => {
  const btn = e.target.closest('.act');
  if (!btn) return;
  const article = btn.closest('.post');
  const p = byId.get(article.dataset.id);
  const act = btn.dataset.act;

  if (act === 'like') {
    p.liked = !p.liked;
    p.reactions.like += p.liked ? 1 : -1;
    btn.classList.toggle('liked', p.liked);
    const { emojis, total } = reactionSummary(p.reactions);
    article.querySelector('[data-summary]').innerHTML = `${emojis}<span data-total>&nbsp;${nfmt(total)}</span>`;
  } else if (act === 'comment') {
    const box = article.querySelector('[data-comments]');
    if (box) box.classList.toggle('open');
    else toast('No comments on this post yet.');
  } else if (act === 'share') {
    p.shares = (p.shares || 0) + 1;
    toast('Shared to your feed (not really)');
  }
});

// ---- Initial render ----
renderStories();
postsEl.innerHTML = posts.map(renderPost).join('');

// ---- Infinite scroll (scroll-based; robust without IntersectionObserver) ----
let cursor = 0;
let exhausted = false;
const sentinel = document.getElementById('sentinel');

function maybeLoad() {
  if (exhausted) return;
  const nearBottom = window.innerHeight + window.scrollY >= document.body.scrollHeight - 700;
  if (!nearBottom) return;
  const batch = extraPool.slice(cursor, cursor + 2);
  if (batch.length === 0) {
    exhausted = true;
    sentinel.textContent = "You're all caught up 🎉";
    return;
  }
  const frag = document.createElement('div');
  frag.innerHTML = batch.map(renderPost).join('');
  while (frag.firstChild) postsEl.appendChild(frag.firstChild);
  cursor += 2;
}

window.addEventListener('scroll', maybeLoad, { passive: true });
window.addEventListener('resize', maybeLoad);
maybeLoad();
