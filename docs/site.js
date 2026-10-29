import { loadDisplayImage } from "./scripts/progressive-images.js?v=display-2";
(() => {
  'use strict';
  const imagePreviews = JSON.parse(document.getElementById('image-previews')?.textContent || '{}');
  const revealed = new WeakSet();
  const observer = typeof IntersectionObserver === 'undefined' ? null : new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return;
      revealed.add(entry.target);
      observer.unobserve(entry.target);
      setImage(entry.target, entry.target.dataset.source);
    });
  }, { rootMargin: '240px' });
  function setImage(node, source) {
    node.dataset.source = source;
    node.decoding = 'async';
    if (node.loading !== 'lazy' || revealed.has(node) || !observer) {
      node.loading = 'eager';
      loadDisplayImage(node, source, imagePreviews, { priority: node.fetchPriority, zoom: true });
    } else observer.observe(node);
  }
  const pdf = document.title.startsWith('PDF Librarian');
  const captions = pdf ? {
    overview: ['01 / 导入文件', '01 / Import PDFs'],
    search: ['02 / 检索书目', '02 / Find Metadata'],
    edit: ['03 / 编辑写入', '03 / Edit & Write'],
    rename: ['04 / 另存命名', '04 / Save & Rename']
  } : {
    'eat-overview': ['KeepFit 饮食记录界面', 'KeepFit food overview'],
    'move-overview': ['KeepFit 运动记录界面', 'KeepFit exercise overview'],
    'lose-overview': ['KeepFit 热量平衡与身体记录界面', 'KeepFit calorie balance and body records']
  };
  let lang = document.documentElement.dataset.productLanguage || 'zh';
  const video = document.querySelector('#app-preview');
  let videoVisible = false;
  function renderVideo() {
    if (!video || !videoVisible || video.dataset.locale === lang) return;
    video.dataset.locale = lang;
    const poster = imagePreviews[`assets/${lang}-overview.webp`];
    const required = Math.ceil(video.clientWidth * (window.devicePixelRatio || 1));
    video.poster = poster?.variants.find(item => item.width >= required)?.src || poster?.src || `assets/${lang}-overview.webp?v=native-lossless`;
    video.querySelector('source').src = `assets/${lang}-preview.mp4`;
    video.preload = 'metadata';
    video.load();
  }
  if (video) {
    if (typeof IntersectionObserver === 'undefined') videoVisible = true;
    else {
      const videoObserver = new IntersectionObserver(entries => {
        if (!entries.some(entry => entry.isIntersecting)) return;
        videoVisible = true;
        videoObserver.disconnect();
        renderVideo();
      }, { rootMargin: '240px' });
      videoObserver.observe(video);
    }
  }
  const toggle = document.querySelector('.language');
  function render() {
    document.querySelectorAll('img[data-icon-progressive]').forEach(node => setImage(node, node.dataset.source));
    document.documentElement.lang = lang === 'zh' ? 'zh-CN' : 'en';
    document.querySelectorAll('[data-zh]').forEach(node => { node.textContent = node.dataset[lang]; });
    document.querySelectorAll('[data-image]').forEach(node => {
      const next = `assets/${lang}-${node.dataset.image}.webp?v=native-lossless`;
      setImage(node, next);
      if (node.dataset.altZh) node.alt = lang === 'zh' ? node.dataset.altZh : node.dataset.altEn;
    });
    renderVideo();
    const preview = document.querySelector('#preview-image');
    const selected = document.querySelector('[data-preview][aria-pressed="true"]');
    const label = captions[selected.dataset.preview][lang === 'zh' ? 0 : 1];
    preview.alt = label;
    const caption = document.querySelector('#preview-caption');
    if (caption) caption.textContent = label;
    toggle.textContent = lang === 'zh' ? 'EN' : '中文';
    toggle.setAttribute('aria-label', lang === 'zh' ? 'Switch to English' : '切换到中文');
    document.title = pdf ? (lang === 'zh' ? 'PDF Librarian · 让每份 PDF，都有清楚的来处。' : 'PDF Librarian · A proper place for every PDF.') : (lang === 'zh' ? 'KeepFit · 管住嘴，迈开腿。' : 'KeepFit · Eat well. Move more.');
  }
  toggle.addEventListener('click', () => {
    lang = lang === 'zh' ? 'en' : 'zh';
    try { localStorage.setItem('larry-product-language', lang); } catch {}
    render();
  });
  document.querySelectorAll('[data-preview]').forEach(button => button.addEventListener('click', () => {
    document.querySelectorAll('[data-preview]').forEach(item => item.setAttribute('aria-pressed', String(item === button)));
    document.querySelector('#preview-image').dataset.image = button.dataset.preview;
    render();
  }));
  render();
})();
