const states = new WeakMap();
const originals = new Map();
const ready = new Set();
const queue = [];
let running = 0;
let timer;
let visibility;

export function previewFor(source, manifest = {}, thumbnail = false) {
  const item = manifest[source.split('?')[0]];
  return (thumbnail ? item?.thumbnail?.src : undefined) || item?.src || source;
}

function pump() {
  queue.sort((a, b) => rank(a) - rank(b));
  while (running < 2 && queue.length) {
    const job = queue.shift();
    if (![...job.clients].some(client => client.current() && client.visible())) {
      originals.delete(job.source);
      continue;
    }
    running++;
    const image = new Image();
    job.image = image;
    image.decoding = 'async';
    image.fetchPriority = 'low';
    image.src = job.source;
    image.decode().then(() => {
      ready.add(job.source);
      for (const client of job.clients) if (client.current()) client.success();
    }, () => {
      ready.delete(job.source);
      for (const client of job.clients) if (client.current()) client.failure();
    }).finally(() => {
      if (originals.get(job.source) === job) originals.delete(job.source);
      running--;
      pump();
    });
  }
}

function detach(source, client) {
  const job = originals.get(source);
  if (!job) return;
  job.clients.delete(client);
  if (!job.clients.size && job.image) job.image.src = 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg"/>';
}

function rank(job) {
  return Math.min(...[...job.clients].map(client => client.priority === 'high' ? 0 : client.priority === 'low' ? 2 : 1));
}

function original(source, client, priority) {
  client.priority = priority;
  let job = originals.get(source);
  if (!job) {
    job = { source, clients: new Set() };
    originals.set(source, job);
    if (priority === 'high') queue.unshift(job);
    else queue.push(job);
  }
  job.clients.add(client);
  if (priority === 'high' || ready.has(source)) queueMicrotask(pump);
  // Batch background work without letting later arrivals postpone the main image.
  else timer ??= setTimeout(() => { timer = undefined; pump(); }, 120);
}

/**
 * @param {HTMLImageElement} node
 * @param {string} source
 * @param {string} preview
 * @param {{priority?: string, onReady?: (url: string, stage: string) => void, onError?: () => void}} options
 */
export function loadProgressiveImage(node, source, preview, options = {}) {
  const previous = states.get(node);
  if (previous?.source === source && previous.preview === preview) return previous.dispose;
  previous?.dispose();
  const state = { source, preview, visible: typeof IntersectionObserver === 'undefined', previewReady: ready.has(source), request: () => {}, dispose: () => {} };
  states.set(node, state);
  const current = () => states.get(node) === state && node.isConnected && node.dataset.originalSrc === source;
  node.dataset.originalSrc = source;
  node.dataset.previewSrc = preview;
  node.dataset.imageStage = 'loading';
  delete node.dataset.originalError;

  const full = {
    current,
    visible: () => state.visible,
    success: () => {
      if (!current()) return;
      ready.add(source);
      if (node.getAttribute('src') !== source) node.src = source;
      node.dataset.imageStage = 'full';
      delete node.dataset.originalError;
      options.onReady?.(source, 'full');
    },
    failure: () => {
      if (!current()) return;
      node.dataset.originalError = 'true';
      options.onError?.();
    },
  };
  let previewReady = false;
  const requestFull = () => { if (state.visible && current()) original(source, full, options.priority); };
  state.request = requestFull;
  const onLoad = () => {
    if (!current() || node.getAttribute('src') !== preview || previewReady) return;
    previewReady = true;
    state.previewReady = true;
    node.dataset.imageStage = preview === source ? 'full' : 'preview';
    options.onReady?.(preview, preview === source ? 'full' : 'preview');
    if (preview === source) ready.add(source);
    else requestFull();
  };
  const onError = () => {
    if (!current() || node.getAttribute('src') !== preview) return;
    options.onError?.();
    if (preview === source) full.failure();
    else {
      node.src = source;
      node.dataset.imageStage = 'loading-original';
      const fallback = new Image();
      fallback.src = source;
      fallback.decode().then(full.success, full.failure);
    }
  };
  const retry = () => { if (current() && node.dataset.originalError) requestFull(); };
  node.addEventListener('load', onLoad);
  node.addEventListener('error', onError);
  window.addEventListener('online', retry);
  if (typeof IntersectionObserver !== 'undefined') {
    visibility ||= new IntersectionObserver(entries => {
      for (const entry of entries) {
        const active = states.get(entry.target);
        if (!active) continue;
        active.visible = entry.isIntersecting;
        if (active.visible && active.previewReady !== false && entry.target.dataset.imageStage !== 'full') active.request();
      }
    }, { rootMargin: '200px' });
    visibility.observe(node);
  }
  state.dispose = () => {
    if (states.get(node) !== state) return;
    states.delete(node);
    node.removeEventListener('load', onLoad);
    node.removeEventListener('error', onError);
    window.removeEventListener('online', retry);
    visibility?.unobserve(node);
    detach(source, full);
  };
  if (ready.has(source)) requestFull();
  else {
    if (node.getAttribute('src') !== preview) node.src = preview;
    if (node.complete) {
      if (node.naturalWidth) onLoad();
      else onError();
    }
  }
  return state.dispose;
}

export function responsiveFor(source, manifest = {}, sizes = 'auto, 100vw') {
  const item = manifest[source.split('?')[0]];
  if (!item?.variants?.length) return { src: previewFor(source, manifest) };
  return { src: item.variants[0].src, srcSet: item.variants.map(v => `${v.src} ${v.width}w`).join(', '), sizes };
}

export function displayWidth(node, nativeWidth, nativeHeight, density = (window.devicePixelRatio || 1) * (window.visualViewport?.scale || 1)) {
  const bounds = node.getBoundingClientRect();
  const width = Math.max(node.clientWidth, bounds.width);
  const height = Math.max(node.clientHeight, bounds.height);
  const ratio = nativeWidth / nativeHeight;
  const fit = getComputedStyle(node).objectFit;
  const rendered = fit === 'contain' ? Math.min(width, height * ratio) : fit === 'cover' ? Math.max(width, height * ratio) : width;
  return Math.min(nativeWidth, Math.max(1, Math.ceil(rendered * density)));
}

const displays = new Set();
let displayResize;
let displayFrame;
let densityQuery;

function refreshDisplays() {
  if (displayFrame) return;
  displayFrame = requestAnimationFrame(() => {
    displayFrame = undefined;
    for (const state of displays) state.request();
  });
}

function watchDensity() {
  densityQuery?.removeEventListener('change', changedDensity);
  densityQuery = window.matchMedia(`(resolution: ${window.devicePixelRatio || 1}dppx)`);
  densityQuery.addEventListener('change', changedDensity);
}

function changedDensity() { watchDensity(); refreshDisplays(); }

function originalView(node, source) {
  if (node.closest('a, button')) return () => {};
  const old = Object.fromEntries(['role', 'tabindex', 'title'].map(name => [name, node.getAttribute(name)]));
  const cursor = node.style.cursor;
  node.setAttribute('role', 'button');
  node.tabIndex = 0;
  node.title = '查看高清原图 / View original';
  node.style.cursor = 'zoom-in';
  node.dataset.originalView = 'true';
  const open = () => window.open(new URL(source, document.baseURI).href, '_blank', 'noopener,noreferrer');
  const key = event => { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); open(); } };
  node.addEventListener('click', open);
  node.addEventListener('keydown', key);
  return () => {
    node.removeEventListener('click', open); node.removeEventListener('keydown', key);
    for (const [name, value] of Object.entries(old)) {
      if (value === null) node.removeAttribute(name); else node.setAttribute(name, value);
    }
    node.style.cursor = cursor;
    delete node.dataset.originalView;
  };
}

/** Load only the resolution needed for the actual image slot and current display density. */
export function loadDisplayImage(node, source, manifest = {}, options = {}) {
  states.get(node)?.dispose();
  const item = manifest[source.split('?')[0]];
  if (!item?.variants?.length) return loadProgressiveImage(node, source, previewFor(source, manifest), options);
  const state = { source, visible: typeof IntersectionObserver === 'undefined', request: () => {}, dispose: () => {} };
  states.set(node, state);
  node.dataset.originalSrc = source;
  node.dataset.imageMode = 'display';
  node.dataset.imageStage = 'loading';
  delete node.dataset.originalError;
  let selected;
  let loadedWidth = 0;
  let loadedSource;
  let client;
  const current = () => states.get(node) === state && node.isConnected && node.dataset.originalSrc === source;
  const request = () => {
    if (!current() || !state.visible) return;
    const required = displayWidth(node, item.nativeWidth, item.nativeHeight);
    node.dataset.requiredWidth = String(required);
    if (loadedWidth >= required) {
      if (node.getAttribute('src') === loadedSource) {
        if (client && selected !== loadedSource) detach(selected, client);
        selected = loadedSource;
        node.dataset.displaySrc = loadedSource;
        node.dataset.displayWidth = String(loadedWidth);
        node.dataset.imageStage = 'display';
      }
      return;
    }
    const candidate = item.variants.find(v => v.width >= required) || item.variants.at(-1);
    if (selected === candidate.src && originals.has(selected)) return;
    if (client) detach(selected, client);
    selected = candidate.src;
    node.dataset.displaySrc = candidate.src;
    node.dataset.previewSrc = candidate.src;
    node.dataset.displayWidth = String(candidate.width);
    node.dataset.imageStage = 'loading-display';
    client = {
      current: () => current() && selected === candidate.src,
      visible: () => state.visible,
      success: () => {
        if (!current() || selected !== candidate.src) return;
        // Keep the last clear frame while a larger candidate is decoded off-DOM.
        node.srcset = `${candidate.src} 1x`;
        node.removeAttribute('sizes');
        node.loading = 'eager';
        node.src = candidate.src;
        node.decode().then(() => {
          if (!current() || selected !== candidate.src) return;
          loadedWidth = candidate.width;
          loadedSource = candidate.src;
          node.dataset.imageStage = 'display';
          delete node.dataset.originalError;
          options.onReady?.(candidate.src, 'display');
        }, () => { if (current() && selected === candidate.src) client.failure(); });
      },
      failure: () => {
        if (!current() || selected !== candidate.src) return;
        selected = undefined;
        node.dataset.originalError = 'true';
        if (!loadedWidth) {
          node.srcset = `${item.src} 1x`;
          node.removeAttribute('sizes');
          node.src = item.src;
          node.dataset.imageStage = 'preview';
        }
        options.onError?.();
      },
    };
    if (node.complete && node.naturalWidth && node.currentSrc === new URL(candidate.src, document.baseURI).href) client.success();
    else original(candidate.src, client, options.priority);
  };
  state.request = request;
  if (!displayResize) {
    if (typeof ResizeObserver !== 'undefined') displayResize = new ResizeObserver(refreshDisplays);
    window.addEventListener('resize', refreshDisplays);
    document.addEventListener('transitionend', refreshDisplays);
    window.visualViewport?.addEventListener('resize', refreshDisplays);
    watchDensity();
  }
  displays.add(state);
  displayResize?.observe(node);
  if (typeof IntersectionObserver !== 'undefined') {
    visibility ||= new IntersectionObserver(entries => {
      for (const entry of entries) {
        const active = states.get(entry.target);
        if (!active) continue;
        active.visible = entry.isIntersecting;
        if (active.visible && active.previewReady !== false && entry.target.dataset.imageStage !== 'full') active.request();
      }
    }, { rootMargin: '120px' });
    visibility.observe(node);
  }
  const removeView = options.zoom && item.nativeWidth !== item.nativeHeight ? originalView(node, source) : () => {};
  window.addEventListener('online', request);
  state.dispose = () => {
    if (states.get(node) !== state) return;
    states.delete(node); displays.delete(state);
    displayResize?.unobserve(node); visibility?.unobserve(node);
    if (client) detach(selected, client);
    window.removeEventListener('online', request);
    removeView();
  };
  request();
  return state.dispose;
}
