(() => {
  'use strict';
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
  let lang = 'zh';
  try { lang = localStorage.getItem('larry-product-language') === 'en' ? 'en' : 'zh'; } catch {}
  const toggle = document.querySelector('.language');
  function render() {
    document.documentElement.lang = lang === 'zh' ? 'zh-CN' : 'en';
    document.querySelectorAll('[data-zh]').forEach(node => { node.textContent = node.dataset[lang]; });
    document.querySelectorAll('[data-image]').forEach(node => {
      const next = `assets/${lang}-${node.dataset.image}.webp`;
      if (node.getAttribute('src') !== next) node.src = next;
      if (node.dataset.altZh) node.alt = lang === 'zh' ? node.dataset.altZh : node.dataset.altEn;
    });
    const video = document.querySelector('#app-preview');
    if(video && video.dataset.locale !== lang){video.dataset.locale=lang;video.poster=`assets/${lang}-overview.webp`;video.querySelector('source').src=`assets/${lang}-preview.mp4`;video.load();}
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
