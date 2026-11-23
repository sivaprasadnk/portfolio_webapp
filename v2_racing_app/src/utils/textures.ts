import * as THREE from 'three';

const _textureCache = new Map<string, THREE.CanvasTexture>();

function makeCanvas(w: number, h: number): [HTMLCanvasElement, CanvasRenderingContext2D] {
  const canvas = document.createElement('canvas');
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext('2d');
  if (!ctx) {
    throw new Error('Could not acquire 2D canvas context for texture generation.');
  }
  return [canvas, ctx];
}

export function getAsphaltTextures(): {
  map: THREE.CanvasTexture;
  roughnessMap: THREE.CanvasTexture;
  bumpMap: THREE.CanvasTexture;
} {
  const cachedMap = _textureCache.get('asphalt_map');
  const cachedRough = _textureCache.get('asphalt_rough');
  const cachedBump = _textureCache.get('asphalt_bump');
  if (cachedMap && cachedRough && cachedBump) {
    return { map: cachedMap, roughnessMap: cachedRough, bumpMap: cachedBump };
  }

  const size = 512;
  const [albedoC, actx] = makeCanvas(size, size);
  const [roughC, rctx] = makeCanvas(size, size);
  const [bumpC, bctx] = makeCanvas(size, size);

  actx.fillStyle = '#121624';
  actx.fillRect(0, 0, size, size);

  rctx.fillStyle = '#9c9c9c'; // ~0.61 roughness base
  rctx.fillRect(0, 0, size, size);

  bctx.fillStyle = '#808080';
  bctx.fillRect(0, 0, size, size);

  // Fine mineral tarmac speckle
  for (let i = 0; i < 6200; i++) {
    const gx = (i * 197) % size;
    const gy = (i * 313) % size;
    const v = 14 + ((i * 29) % 24);
    actx.fillStyle = `rgb(${v},${v + 3},${v + 9})`;
    actx.fillRect(gx, gy, 2, 2);

    const bv = 110 + ((i * 41) % 38);
    bctx.fillStyle = `rgb(${bv},${bv},${bv})`;
    bctx.fillRect(gx, gy, 2, 2);
  }

  // Twin glossy wet tire tracks in both lanes
  const lanes = [128, 384];
  for (const cx of lanes) {
    for (const side of [-1, 1]) {
      const tx = cx + side * 42;
      const aGrad = actx.createLinearGradient(tx - 24, 0, tx + 24, 0);
      aGrad.addColorStop(0, 'rgba(7, 9, 17, 0)');
      aGrad.addColorStop(0.5, 'rgba(6, 8, 15, 0.58)');
      aGrad.addColorStop(1, 'rgba(7, 9, 17, 0)');
      actx.fillStyle = aGrad;
      actx.fillRect(tx - 24, 0, 48, size);

      const rGrad = rctx.createLinearGradient(tx - 26, 0, tx + 26, 0);
      rGrad.addColorStop(0, 'rgba(40,40,40,0)');
      rGrad.addColorStop(0.5, 'rgba(26,26,26,0.92)');
      rGrad.addColorStop(1, 'rgba(40,40,40,0)');
      rctx.fillStyle = rGrad;
      rctx.fillRect(tx - 26, 0, 52, size);
    }
  }

  // Wet puddle specular variation patches
  for (let p = 0; p < 14; p++) {
    const px = 48 + ((p * 173) % (size - 96));
    const py = 40 + ((p * 251) % (size - 80));
    const pr = 26 + (p % 4) * 14;
    const pGrad = rctx.createRadialGradient(px, py, 2, px, py, pr);
    pGrad.addColorStop(0, 'rgba(14,14,14,0.95)');
    pGrad.addColorStop(1, 'rgba(14,14,14,0)');
    rctx.fillStyle = pGrad;
    rctx.beginPath();
    rctx.arc(px, py, pr, 0, Math.PI * 2);
    rctx.fill();
  }

  // Center dashed white/cyan racing divider + outer glowing blue/purple lane stripes
  actx.fillStyle = 'rgba(226, 232, 240, 0.85)';
  actx.fillRect(size * 0.5 - 4, 24, 8, 180);
  actx.fillRect(size * 0.5 - 4, 280, 8, 180);

  actx.fillStyle = 'rgba(56, 189, 248, 0.92)';
  actx.fillRect(10, 0, 7, size);
  actx.fillStyle = 'rgba(168, 85, 247, 0.92)';
  actx.fillRect(size - 17, 0, 7, size);

  const map = new THREE.CanvasTexture(albedoC);
  map.wrapS = THREE.RepeatWrapping;
  map.wrapT = THREE.RepeatWrapping;
  map.colorSpace = THREE.SRGBColorSpace;
  map.anisotropy = 8;

  const roughnessMap = new THREE.CanvasTexture(roughC);
  roughnessMap.wrapS = THREE.RepeatWrapping;
  roughnessMap.wrapT = THREE.RepeatWrapping;
  roughnessMap.anisotropy = 4;

  const bumpMap = new THREE.CanvasTexture(bumpC);
  bumpMap.wrapS = THREE.RepeatWrapping;
  bumpMap.wrapT = THREE.RepeatWrapping;

  _textureCache.set('asphalt_map', map);
  _textureCache.set('asphalt_rough', roughnessMap);
  _textureCache.set('asphalt_bump', bumpMap);
  return { map, roughnessMap, bumpMap };
}

export function getCarbonTextures(): {
  map: THREE.CanvasTexture;
  roughnessMap: THREE.CanvasTexture;
} {
  const cm = _textureCache.get('carbon_map');
  const cr = _textureCache.get('carbon_rough');
  if (cm && cr) return { map: cm, roughnessMap: cr };

  const size = 64;
  const [c, ctx] = makeCanvas(size, size);
  const [rc, rctx] = makeCanvas(size, size);

  ctx.fillStyle = '#0d1018';
  ctx.fillRect(0, 0, size, size);
  rctx.fillStyle = '#484848';
  rctx.fillRect(0, 0, size, size);

  for (let y = 0; y < size; y += 8) {
    for (let x = 0; x < size; x += 8) {
      const even = ((x + y) / 8) % 2 === 0;
      ctx.fillStyle = even ? '#1a2030' : '#090b12';
      ctx.fillRect(x, y, 7, 7);
      rctx.fillStyle = even ? '#262626' : '#585858';
      rctx.fillRect(x, y, 7, 7);
    }
  }

  const map = new THREE.CanvasTexture(c);
  map.wrapS = THREE.RepeatWrapping;
  map.wrapT = THREE.RepeatWrapping;
  map.repeat.set(6, 6);
  map.colorSpace = THREE.SRGBColorSpace;

  const roughnessMap = new THREE.CanvasTexture(rc);
  roughnessMap.wrapS = THREE.RepeatWrapping;
  roughnessMap.wrapT = THREE.RepeatWrapping;
  roughnessMap.repeat.set(6, 6);

  _textureCache.set('carbon_map', map);
  _textureCache.set('carbon_rough', roughnessMap);
  return { map, roughnessMap };
}

export function getSkyscraperTextures(variant: 0 | 1 | 2): {
  map: THREE.CanvasTexture;
  emissiveMap: THREE.CanvasTexture;
} {
  const mKey = `tower_map_${variant}`;
  const eKey = `tower_em_${variant}`;
  const cm = _textureCache.get(mKey);
  const ce = _textureCache.get(eKey);
  if (cm && ce) return { map: cm, emissiveMap: ce };

  const w = 128;
  const h = 256;
  const [c, ctx] = makeCanvas(w, h);
  const [ec, ectx] = makeCanvas(w, h);

  ctx.fillStyle =
    variant === 0 ? '#090f20' : variant === 1 ? '#120a24' : '#0a1226';
  ctx.fillRect(0, 0, w, h);

  ectx.fillStyle = '#000000';
  ectx.fillRect(0, 0, w, h);

  const primary =
    variant === 0 ? '#38bdf8' : variant === 1 ? '#c084fc' : '#60a5fa';
  const secondary =
    variant === 0 ? '#818cf8' : variant === 1 ? '#f472b6' : '#f8fafc';

  for (let y = 10; y < h - 10; y += 14) {
    // Structural floor rib
    ctx.fillStyle = '#04060d';
    ctx.fillRect(0, y - 3, w, 2);

    for (let x = 8; x < w - 12; x += 16) {
      const seed = (x * 37 + y * 19 + variant * 13) % 13;
      if (seed < 4) {
        const col = seed === 0 ? primary : seed === 1 ? secondary : '#bae6fd';
        ctx.fillStyle = col;
        ctx.fillRect(x, y, 10, 8);
        ectx.fillStyle = col;
        ectx.fillRect(x, y, 10, 8);
      } else {
        ctx.fillStyle = 'rgba(30, 41, 59, 0.55)';
        ctx.fillRect(x, y, 10, 8);
      }
    }
  }

  // Rooftop glowing neon cornice stripe
  ectx.fillStyle = primary;
  ectx.fillRect(0, 0, w, 6);

  const map = new THREE.CanvasTexture(c);
  map.wrapS = THREE.RepeatWrapping;
  map.wrapT = THREE.RepeatWrapping;
  map.colorSpace = THREE.SRGBColorSpace;

  const emissiveMap = new THREE.CanvasTexture(ec);
  emissiveMap.wrapS = THREE.RepeatWrapping;
  emissiveMap.wrapT = THREE.RepeatWrapping;
  emissiveMap.colorSpace = THREE.SRGBColorSpace;

  _textureCache.set(mKey, map);
  _textureCache.set(eKey, emissiveMap);
  return { map, emissiveMap };
}

export function createNeonSignTexture(
  title: string,
  subtitle: string,
  primaryColor: string,
  secondaryColor: string
): THREE.CanvasTexture {
  const key = `sign_${title}_${subtitle}_${primaryColor}`;
  const existing = _textureCache.get(key);
  if (existing) return existing;

  const w = 1024;
  const h = 256;
  const [c, ctx] = makeCanvas(w, h);

  const bgGrad = ctx.createLinearGradient(0, 0, w, h);
  bgGrad.addColorStop(0, '#040817');
  bgGrad.addColorStop(0.5, '#0b122c');
  bgGrad.addColorStop(1, '#120828');
  ctx.fillStyle = bgGrad;
  ctx.fillRect(0, 0, w, h);

  // Subtle scanlines
  ctx.fillStyle = 'rgba(255,255,255,0.03)';
  for (let y = 0; y < h; y += 6) {
    ctx.fillRect(0, y, w, 2);
  }

  // Glowing dual neon border
  ctx.strokeStyle = primaryColor;
  ctx.lineWidth = 10;
  ctx.strokeRect(10, 10, w - 20, h - 20);

  ctx.strokeStyle = secondaryColor;
  ctx.lineWidth = 3;
  ctx.strokeRect(24, 24, w - 48, h - 48);

  // Title
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.shadowColor = primaryColor;
  ctx.shadowBlur = 24;
  ctx.fillStyle = '#ffffff';
  ctx.font = '900 84px Orbitron, Inter, sans-serif';
  ctx.fillText(title.toUpperCase(), w * 0.5, h * 0.42);

  // Subtitle
  ctx.shadowColor = secondaryColor;
  ctx.shadowBlur = 12;
  ctx.fillStyle = '#e0f2fe';
  ctx.font = '600 30px Rajdhani, Inter, sans-serif';
  ctx.fillText(subtitle.toUpperCase(), w * 0.5, h * 0.76);

  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.anisotropy = 4;
  _textureCache.set(key, tex);
  return tex;
}

export function createCheckeredFinishTexture(): THREE.CanvasTexture {
  const key = 'checkered_finish';
  const existing = _textureCache.get(key);
  if (existing) return existing;

  const w = 512;
  const h = 128;
  const [c, ctx] = makeCanvas(w, h);
  const cols = 16;
  const rows = 4;
  const cw = w / cols;
  const ch = h / rows;

  for (let r = 0; r < rows; r++) {
    for (let col = 0; col < cols; col++) {
      const white = (r + col) % 2 === 0;
      ctx.fillStyle = white ? '#e0f2fe' : '#1e1038';
      ctx.fillRect(col * cw, r * ch, cw, ch);
    }
  }

  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  _textureCache.set(key, tex);
  return tex;
}

export function createRadialGlowTexture(): THREE.CanvasTexture {
  const key = 'radial_glow';
  const existing = _textureCache.get(key);
  if (existing) return existing;

  const size = 128;
  const [c, ctx] = makeCanvas(size, size);
  const grad = ctx.createRadialGradient(
    size * 0.5,
    size * 0.5,
    2,
    size * 0.5,
    size * 0.5,
    size * 0.5
  );
  grad.addColorStop(0, 'rgba(255,255,255,1)');
  grad.addColorStop(0.32, 'rgba(255,255,255,0.65)');
  grad.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, size, size);

  const tex = new THREE.CanvasTexture(c);
  _textureCache.set(key, tex);
  return tex;
}
