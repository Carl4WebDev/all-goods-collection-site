/* All Goods Collection: site interactions */
{
  const doc = document.documentElement;
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const fine = matchMedia('(pointer: fine)').matches;

  /* Page curtain: reveal on load, cover on internal navigation */
  const curtain = document.querySelector('.curtain');
  if (curtain && !reduce) {
    let seen = false;
    try { seen = sessionStorage.getItem('ag-in') === '1'; } catch (e) {}
    if (seen) {
      curtain.classList.add('on');
      requestAnimationFrame(() => requestAnimationFrame(() => {
        curtain.classList.remove('on'); curtain.classList.add('off');
      }));
    }
    document.addEventListener('click', e => {
      const a = e.target.closest('a[href]');
      if (!a || e.metaKey || e.ctrlKey || e.shiftKey || a.target === '_blank') return;
      const href = a.getAttribute('href');
      if (!/^[\w-]+\.html(#[\w-]+)?$/.test(href)) return;
      if (a.pathname === location.pathname && a.hash) return;
      e.preventDefault();
      try { sessionStorage.setItem('ag-in', '1'); } catch (err) {}
      curtain.classList.remove('off'); curtain.classList.add('on');
      setTimeout(() => { location.href = href; }, 480);
    });
    addEventListener('pageshow', ev => { if (ev.persisted) { curtain.classList.remove('on'); curtain.classList.add('off'); } });
  }

  /* Mobile menu */
  const burger = document.querySelector('.burger');
  if (burger) burger.addEventListener('click', () => {
    const open = document.body.classList.toggle('menu-open');
    burger.setAttribute('aria-expanded', open);
  });

  /* Scroll progress bar */
  const bar = document.querySelector('.progress');
  const onScroll = () => {
    const max = doc.scrollHeight - innerHeight;
    if (bar) bar.style.transform = `scaleX(${max > 0 ? scrollY / max : 0})`;
  };
  addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  /* Reveal on scroll, with stagger inside groups */
  document.querySelectorAll('[data-stagger]').forEach(g => {
    [...g.children].forEach((c, i) => { c.classList.add('rv'); c.style.setProperty('--d', (i * 0.09) + 's'); });
  });
  const items = document.querySelectorAll('.rv');
  if (reduce || !('IntersectionObserver' in window)) {
    items.forEach(el => el.classList.add('in'));
  } else {
    const revealer = new IntersectionObserver(entries => {
      entries.forEach(en => { if (en.isIntersecting) { en.target.classList.add('in'); revealer.unobserve(en.target); } });
    }, { threshold: 0.14, rootMargin: '0px 0px -40px 0px' });
    items.forEach(el => revealer.observe(el));
  }

  /* Custom cursor */
  const cur = document.querySelector('.cursor');
  if (cur && fine && !reduce) {
    let x = innerWidth / 2, y = innerHeight / 2, cx = x, cy = y;
    addEventListener('mousemove', e => { x = e.clientX; y = e.clientY; });
    const loop = () => {
      cx += (x - cx) * 0.2; cy += (y - cy) * 0.2;
      cur.style.transform = `translate(${cx}px,${cy}px)`;
      requestAnimationFrame(loop);
    };
    loop();
    document.querySelectorAll('a,button,summary,.card').forEach(el => {
      el.addEventListener('mouseenter', () => cur.classList.add('big'));
      el.addEventListener('mouseleave', () => cur.classList.remove('big'));
    });
  }

  /* 3D tilt + spotlight on cards */
  if (fine && !reduce) {
    document.querySelectorAll('.card').forEach(card => {
      card.addEventListener('mousemove', e => {
        const r = card.getBoundingClientRect();
        const px = (e.clientX - r.left) / r.width, py = (e.clientY - r.top) / r.height;
        card.style.setProperty('--mx', px * 100 + '%');
        card.style.setProperty('--my', py * 100 + '%');
        card.style.transform = `perspective(800px) rotateX(${(0.5 - py) * 8}deg) rotateY(${(px - 0.5) * 10}deg) translateY(-4px)`;
      });
      card.addEventListener('mouseleave', () => { card.style.transform = ''; });
    });

    /* Magnetic buttons */
    document.querySelectorAll('.btn,.fab').forEach(b => {
      b.addEventListener('mousemove', e => {
        const r = b.getBoundingClientRect();
        b.style.transform = `translate(${(e.clientX - r.left - r.width / 2) * 0.18}px,${(e.clientY - r.top - r.height / 2) * 0.3}px)`;
      });
      b.addEventListener('mouseleave', () => { b.style.transform = ''; });
    });

    /* Hero parallax */
    const scene = document.querySelector('.scene, .bigicon');
    if (scene) addEventListener('mousemove', e => {
      const dx = e.clientX / innerWidth - 0.5, dy = e.clientY / innerHeight - 0.5;
      scene.style.transform = `translate(${dx * -16}px,${dy * -12}px)`;
    });
  }

  /* Count-up numbers */
  const counters = document.querySelectorAll('[data-count]');
  if (counters.length && !reduce && 'IntersectionObserver' in window) {
    const counterObs = new IntersectionObserver(entries => {
      entries.forEach(en => {
        if (!en.isIntersecting) return;
        const el = en.target, end = +el.dataset.count, t0 = performance.now();
        const tick = t => {
          const p = Math.min((t - t0) / 1200, 1);
          el.textContent = Math.round(end * (1 - Math.pow(1 - p, 3)));
          if (p < 1) requestAnimationFrame(tick);
        };
        requestAnimationFrame(tick);
        counterObs.unobserve(el);
      });
    });
    counters.forEach(c => counterObs.observe(c));
  }

  /* Order request form: builds a message to paste into Messenger */
  const form = document.getElementById('order-form');
  if (form) {
    const out = document.getElementById('order-out');
    const pre = out.querySelector('pre');
    const copyBtn = document.getElementById('copy-order');
    form.addEventListener('submit', e => {
      e.preventDefault();
      const f = new FormData(form);
      const lines = [
        'Hi All Goods! I want to order.',
        'Name: ' + (f.get('name') || '-'),
        'Looking for: ' + (f.get('cat') || '-'),
        'Size(s): ' + (f.get('size') || '-'),
        'Pickup: ' + (f.get('pickup') || '-'),
        f.get('msg') ? 'Notes: ' + f.get('msg') : ''
      ].filter(Boolean);
      pre.textContent = lines.join('\n');
      out.classList.add('show');
      out.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth', block: 'nearest' });
    });
    copyBtn.addEventListener('click', async () => {
      try {
        await navigator.clipboard.writeText(pre.textContent);
        copyBtn.textContent = 'Copied! Paste it in Messenger';
      } catch (err) {
        copyBtn.textContent = 'Select the text above to copy';
      }
    });
  }

  /* Footer year */
  document.querySelectorAll('[data-year]').forEach(el => { el.textContent = new Date().getFullYear(); });
}
