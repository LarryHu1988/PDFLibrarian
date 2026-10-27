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
  while (running < 2 && queue.length) {
    const job = queue.shift();
    if (![...job.clients].some(client => client.current() && client.visible())) {
      originals.delete(job.source);
      continue;
    }
    running++;
    const image = new Image();
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
      originals.delete(job.source);
      running--;
      pump();
    });
  }
}

function original(source, client, priority) {
  let job = originals.get(source);
  if (!job) {
    job = { source, clients: new Set() };
    originals.set(source, job);
    if (priority === 'high') queue.unshift(job);
    else queue.push(job);
  }
  job.clients.add(client);
  clearTimeout(timer);
  // Give newly revealed previews a chance to paint before starting large originals.
  timer = setTimeout(pump, ready.has(source) ? 0 : 120);
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
        if (active.visible && active.previewReady && entry.target.dataset.imageStage !== 'full') active.request();
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
    originals.get(source)?.clients.delete(full);
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
