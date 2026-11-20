(function () {
  'use strict';

  var ROAD_HALF_W = 9.0;
  var KERB_W = 1.15;
  var WALL_H = 1.05;
  var SHOULDER_W = 24.0;
  var SEG_LEN_DART = 200.0;
  var SLICE_BACK = 3;
  var SLICE_AHEAD = 88;
  var TOTAL_SLICES = SLICE_BACK + SLICE_AHEAD + 1; // 92 slices
  var PADDOCK_SCALE = 0.085;

  var _instances = {};
  var _nextId = 1;

  function clamp(v, min, max) {
    return v < min ? min : (v > max ? max : v);
  }

  function lerp(a, b, t) {
    return a + (b - a) * t;
  }

  function parseHexColor(hexInt) {
    return new THREE.Color((hexInt || 0) & 0xffffff);
  }

  window.spnk3dIsAvailable = function () {
    if (typeof window.THREE === 'undefined') return false;
    try {
      var testCanvas = document.createElement('canvas');
      var gl =
        testCanvas.getContext('webgl2') ||
        testCanvas.getContext('webgl') ||
        testCanvas.getContext('experimental-webgl');
      return !!gl;
    } catch (e) {
      return false;
    }
  };

  function makeTextTexture(cache, key, width, height, drawFn) {
    if (cache[key]) return cache[key];
    var canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    var ctx = canvas.getContext('2d');
    drawFn(ctx, width, height);
    var tex = new THREE.CanvasTexture(canvas);
    tex.anisotropy = 4;
    tex.needsUpdate = true;
    cache[key] = tex;
    return tex;
  }

  // =========================================================================
  // PROCEDURAL PBR TEXTURES (WET ROCKPORT ASPHALT, ROUGHNESS, M3 GTR VINYL, SKY)
  // =========================================================================
  function createWetAsphaltTextures() {
    var albedoCanvas = document.createElement('canvas');
    albedoCanvas.width = 512;
    albedoCanvas.height = 512;
    var actx = albedoCanvas.getContext('2d');

    var roughCanvas = document.createElement('canvas');
    roughCanvas.width = 512;
    roughCanvas.height = 512;
    var rctx = roughCanvas.getContext('2d');

    actx.fillStyle = '#24262b';
    actx.fillRect(0, 0, 512, 512);
    rctx.fillStyle = '#8c8c8c';
    rctx.fillRect(0, 0, 512, 512);

    // Fine mineral aggregate speckle & rubber wear tracks
    for (var i = 0; i < 4200; i++) {
      var gx = (i * 197) % 512;
      var gy = (i * 313) % 512;
      var shade = 26 + ((i * 29) % 24);
      actx.fillStyle = 'rgb(' + shade + ',' + (shade + 1) + ',' + (shade + 4) + ')';
      actx.fillRect(gx, gy, 2, 2);
    }

    // Polished tire wear tracks in each of 3 lanes
    var laneCenters = [88, 256, 424];
    for (var li = 0; li < laneCenters.length; li++) {
      var lx = laneCenters[li];
      for (var t = -1; t <= 1; t += 2) {
        var grad = actx.createLinearGradient(lx + t * 28 - 18, 0, lx + t * 28 + 18, 0);
        grad.addColorStop(0, 'rgba(12,13,16,0)');
        grad.addColorStop(0.5, 'rgba(12,13,16,0.42)');
        grad.addColorStop(1, 'rgba(12,13,16,0)');
        actx.fillStyle = grad;
        actx.fillRect(lx + t * 28 - 18, 0, 36, 512);

        // Glossy wet tire sheen in roughness map (darker = glossier!)
        var rGrad = rctx.createLinearGradient(lx + t * 28 - 22, 0, lx + t * 28 + 22, 0);
        rGrad.addColorStop(0, 'rgba(40,40,40,0)');
        rGrad.addColorStop(0.5, 'rgba(32,32,32,0.85)');
        rGrad.addColorStop(1, 'rgba(40,40,40,0)');
        rctx.fillStyle = rGrad;
        rctx.fillRect(lx + t * 28 - 22, 0, 44, 512);
      }
    }

    // Subtle damp puddle patches & tar cracks
    for (var p = 0; p < 16; p++) {
      var px = (p * 173 + 60) % 420 + 46;
      var py = (p * 251 + 40) % 440 + 36;
      var pr = 26 + (p % 4) * 14;
      var pGrad = rctx.createRadialGradient(px, py, 2, px, py, pr);
      pGrad.addColorStop(0, 'rgba(18,18,18,0.92)');
      pGrad.addColorStop(1, 'rgba(18,18,18,0)');
      rctx.fillStyle = pGrad;
      rctx.beginPath();
      rctx.arc(px, py, pr, 0, Math.PI * 2);
      rctx.fill();
    }

    actx.strokeStyle = 'rgba(10,11,14,0.55)';
    actx.lineWidth = 1.5;
    for (var c = 0; c < 6; c++) {
      actx.beginPath();
      actx.moveTo(40 + c * 78, 0);
      actx.bezierCurveTo(65 + c * 72, 160, 22 + c * 80, 340, 44 + c * 76, 512);
      actx.stroke();
    }

    // Solid outer road shoulder lines
    actx.fillStyle = 'rgba(245, 185, 66, 0.85)';
    actx.fillRect(10, 0, 7, 512);
    actx.fillStyle = 'rgba(241, 245, 249, 0.80)';
    actx.fillRect(495, 0, 7, 512);

    var albedoTex = new THREE.CanvasTexture(albedoCanvas);
    albedoTex.wrapS = THREE.RepeatWrapping;
    albedoTex.wrapT = THREE.RepeatWrapping;
    albedoTex.anisotropy = 8;

    var roughTex = new THREE.CanvasTexture(roughCanvas);
    roughTex.wrapS = THREE.RepeatWrapping;
    roughTex.wrapT = THREE.RepeatWrapping;
    roughTex.anisotropy = 4;

    return { map: albedoTex, roughnessMap: roughTex };
  }

  function createM3GtrLiveryTexture() {
    var canvas = document.createElement('canvas');
    canvas.width = 512;
    canvas.height = 512;
    var ctx = canvas.getContext('2d');

    // Metallic silver-grey base
    var baseGrad = ctx.createLinearGradient(0, 0, 512, 512);
    baseGrad.addColorStop(0, '#d8dde6');
    baseGrad.addColorStop(0.5, '#c4cad4');
    baseGrad.addColorStop(1, '#9ca3af');
    ctx.fillStyle = baseGrad;
    ctx.fillRect(0, 0, 512, 512);

    // Iconic NFS Most Wanted Royal Blue & Slate Racing Stripes
    ctx.fillStyle = '#1e40af';
    ctx.beginPath();
    ctx.moveTo(0, 145);
    ctx.lineTo(290, 60);
    ctx.lineTo(512, 155);
    ctx.lineTo(512, 310);
    ctx.lineTo(270, 240);
    ctx.lineTo(0, 345);
    ctx.closePath();
    ctx.fill();

    // Crisp silver-white pinstripe accents
    ctx.strokeStyle = '#f8fafc';
    ctx.lineWidth = 8;
    ctx.beginPath();
    ctx.moveTo(0, 145);
    ctx.lineTo(290, 60);
    ctx.lineTo(512, 155);
    ctx.stroke();

    ctx.fillStyle = '#0f172a';
    ctx.fillRect(195, 360, 122, 42);

    var tex = new THREE.CanvasTexture(canvas);
    tex.anisotropy = 4;
    return tex;
  }

  function createSmokeTexture() {
    var canvas = document.createElement('canvas');
    canvas.width = 128;
    canvas.height = 128;
    var ctx = canvas.getContext('2d');
    var grad = ctx.createRadialGradient(64, 64, 6, 64, 64, 60);
    grad.addColorStop(0, 'rgba(235, 226, 212, 0.72)');
    grad.addColorStop(0.45, 'rgba(205, 195, 182, 0.36)');
    grad.addColorStop(1, 'rgba(180, 170, 160, 0.0)');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, 128, 128);
    return new THREE.CanvasTexture(canvas);
  }

  function createSunGlowTexture() {
    var canvas = document.createElement('canvas');
    canvas.width = 256;
    canvas.height = 256;
    var ctx = canvas.getContext('2d');
    var grad = ctx.createRadialGradient(128, 128, 8, 128, 128, 124);
    grad.addColorStop(0, 'rgba(255, 252, 232, 1.0)');
    grad.addColorStop(0.18, 'rgba(255, 214, 120, 0.92)');
    grad.addColorStop(0.45, 'rgba(245, 145, 45, 0.42)');
    grad.addColorStop(1, 'rgba(245, 120, 25, 0.0)');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, 256, 256);
    return new THREE.CanvasTexture(canvas);
  }

  function createSkyDomeTexture(themeId, isDark) {
    var canvas = document.createElement('canvas');
    canvas.width = 512;
    canvas.height = 256;
    var ctx = canvas.getContext('2d');
    var grad = ctx.createLinearGradient(0, 0, 0, 256);

    if (themeId === 'nfsMostWanted') {
      if (isDark) {
        grad.addColorStop(0.0, '#181920');
        grad.addColorStop(0.32, '#423124');
        grad.addColorStop(0.50, '#9c5c25');
        grad.addColorStop(0.62, '#e29840');
        grad.addColorStop(0.75, '#473624');
        grad.addColorStop(1.0, '#14110d');
      } else {
        grad.addColorStop(0.0, '#2c4159');
        grad.addColorStop(0.36, '#7a5c3d');
        grad.addColorStop(0.55, '#e8a64d');
        grad.addColorStop(0.68, '#f7cd7c');
        grad.addColorStop(1.0, '#30271b');
      }
    } else if (themeId === 'f1PitWall') {
      grad.addColorStop(0.0, isDark ? '#090d16' : '#38bdf8');
      grad.addColorStop(0.52, isDark ? '#1e293b' : '#bae6fd');
      grad.addColorStop(0.66, isDark ? '#334155' : '#f1f5f9');
      grad.addColorStop(1.0, isDark ? '#0b1410' : '#166534');
    } else if (themeId === 'retroSynthwave') {
      grad.addColorStop(0.0, '#0d0221');
      grad.addColorStop(0.42, '#3b0764');
      grad.addColorStop(0.60, '#be185d');
      grad.addColorStop(0.72, '#fb7185');
      grad.addColorStop(1.0, '#090117');
    } else {
      grad.addColorStop(0.0, isDark ? '#030612' : '#93c5fd');
      grad.addColorStop(0.48, isDark ? '#0b142c' : '#cbd5e1');
      grad.addColorStop(0.64, isDark ? '#172554' : '#e2e8f0');
      grad.addColorStop(1.0, '#040611');
    }

    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, 512, 256);

    // Atmospheric sunlit clouds in upper hemisphere
    if (themeId === 'nfsMostWanted' || themeId === 'f1PitWall') {
      for (var c = 0; c < 18; c++) {
        var cx = (c * 83) % 512;
        var cy = 58 + ((c * 17) % 62);
        var cw = 64 + (c % 4) * 28;
        var ch = 12 + (c % 3) * 6;
        var cGrad = ctx.createRadialGradient(cx, cy, 4, cx, cy, cw);
        cGrad.addColorStop(
          0,
          themeId === 'nfsMostWanted'
            ? 'rgba(255, 204, 130, 0.30)'
            : 'rgba(255, 255, 255, 0.24)'
        );
        cGrad.addColorStop(1, 'rgba(255, 190, 110, 0.0)');
        ctx.fillStyle = cGrad;
        ctx.fillRect(cx - cw, cy - ch, cw * 2, ch * 2);
      }
    }

    var tex = new THREE.CanvasTexture(canvas);
    tex.needsUpdate = true;
    return tex;
  }

  function createBuildingFacadeTexture(accentHex, secondaryHex, isDark, themeId) {
    var canvas = document.createElement('canvas');
    canvas.width = 128;
    canvas.height = 256;
    var ctx = canvas.getContext('2d');

    if (themeId === 'nfsMostWanted') {
      ctx.fillStyle = isDark ? '#272320' : '#4a423b';
      ctx.fillRect(0, 0, 128, 256);
      // Horizontal concrete floor slabs
      ctx.fillStyle = 'rgba(20,18,16,0.55)';
      for (var fy = 0; fy < 256; fy += 18) {
        ctx.fillRect(0, fy, 128, 3);
      }
      for (var y = 6; y < 250; y += 18) {
        for (var x = 8; x < 118; x += 18) {
          var seed = (x * 31 + y * 17) % 10;
          if (seed < 3) {
            ctx.fillStyle = seed === 0 ? '#f6b252' : '#ffe2a8';
          } else if (seed < 6) {
            ctx.fillStyle = '#5a4e42';
          } else {
            ctx.fillStyle = '#1d1b1a';
          }
          ctx.fillRect(x, y, 12, 11);
        }
      }
    } else {
      ctx.fillStyle = isDark ? '#080e1f' : '#1e293b';
      ctx.fillRect(0, 0, 128, 256);
      var aCol = '#' + (accentHex & 0xffffff).toString(16).padStart(6, '0');
      var sCol = '#' + (secondaryHex & 0xffffff).toString(16).padStart(6, '0');
      for (var wy = 10; wy < 246; wy += 14) {
        for (var wx = 8; wx < 120; wx += 16) {
          var s2 = (wx * 37 + wy * 13) % 11;
          if (s2 < 4) {
            ctx.fillStyle = s2 === 0 ? aCol : (s2 === 1 ? sCol : 'rgba(224,242,254,0.65)');
            ctx.fillRect(wx, wy, 10, 8);
          } else {
            ctx.fillStyle = 'rgba(255,255,255,0.05)';
            ctx.fillRect(wx, wy, 10, 8);
          }
        }
      }
    }

    var tex = new THREE.CanvasTexture(canvas);
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    return tex;
  }

  function buildPMREMEnvironment(renderer, skyTex) {
    var pmrem = new THREE.PMREMGenerator(renderer);
    pmrem.compileEquirectangularShader();
    var envScene = new THREE.Scene();
    var dome = new THREE.Mesh(
      new THREE.SphereGeometry(50, 24, 16),
      new THREE.MeshBasicMaterial({ map: skyTex, side: THREE.BackSide })
    );
    envScene.add(dome);
    var sunPatch = new THREE.Mesh(
      new THREE.CircleGeometry(9, 16),
      new THREE.MeshBasicMaterial({ color: 0xffd584 })
    );
    sunPatch.position.set(0, 8, -42);
    envScene.add(sunPatch);
    var rt = pmrem.fromScene(envScene, 0.04);
    pmrem.dispose();
    return rt.texture;
  }

  // =========================================================================
  // 5 SCULPTED 3D USER VEHICLES (BMW M3 GTR E46 HERO + 4 CLASSES)
  // =========================================================================
  function createSculptedCoupeGeo(length, width, hoodH, roofH, trunkH) {
    var halfL = length * 0.5;
    var shape = new THREE.Shape();
    shape.moveTo(-halfL, 0.24);
    shape.lineTo(-halfL + 0.14, hoodH * 0.72);
    shape.lineTo(-halfL * 0.42, hoodH);
    shape.lineTo(-halfL * 0.14, roofH);
    shape.lineTo(halfL * 0.34, roofH);
    shape.lineTo(halfL * 0.76, trunkH);
    shape.lineTo(halfL, trunkH * 0.92);
    shape.lineTo(halfL - 0.10, 0.24);
    shape.closePath();

    var geo = new THREE.ExtrudeGeometry(shape, {
      depth: width,
      bevelEnabled: true,
      bevelThickness: 0.12,
      bevelSize: 0.10,
      bevelSegments: 2,
    });
    geo.translate(0, 0, -width * 0.5);
    geo.rotateY(-Math.PI * 0.5);
    geo.computeVertexNormals();
    return geo;
  }

  function buildPlayerVehicleGroup(typeIndex, accentColor, secondaryColor, bodyColor, m3LiveryTex) {
    var root = new THREE.Group();
    var bodyMat = new THREE.MeshStandardMaterial({
      color: bodyColor,
      metalness: 0.82,
      roughness: 0.20,
      envMapIntensity: 1.45,
    });
    var trimMat = new THREE.MeshStandardMaterial({
      color: accentColor,
      emissive: accentColor,
      emissiveIntensity: 0.45,
      metalness: 0.5,
      roughness: 0.25,
    });
    var secMat = new THREE.MeshStandardMaterial({
      color: secondaryColor,
      emissive: secondaryColor,
      emissiveIntensity: 0.45,
      metalness: 0.5,
      roughness: 0.25,
    });
    var glassMat = new THREE.MeshStandardMaterial({
      color: 0x05080f,
      metalness: 0.96,
      roughness: 0.06,
      envMapIntensity: 1.8,
    });
    var tireMat = new THREE.MeshStandardMaterial({
      color: 0x0d1016,
      roughness: 0.88,
      metalness: 0.10,
    });
    var alloyMat = new THREE.MeshStandardMaterial({
      color: 0xe2e8f0,
      metalness: 0.92,
      roughness: 0.16,
      envMapIntensity: 1.6,
    });
    var tailMat = new THREE.MeshBasicMaterial({ color: 0xff1e42 });
    var flameMat = new THREE.MeshBasicMaterial({
      color: 0xff8a1f,
      transparent: true,
      opacity: 0.90,
    });

    var wheels = [];
    var flames = [];
    var wingMesh = null;
    var shieldRing = null;
    var policeBar = null;
    var m3BodyMat = null;

    function addWheel(x, y, z, r, w, showCaliper) {
      var wg = new THREE.Group();
      wg.position.set(x, y, z);
      var tire = new THREE.Mesh(new THREE.CylinderGeometry(r, r, w, 20), tireMat);
      tire.rotation.z = Math.PI * 0.5;
      tire.castShadow = true;
      wg.add(tire);

      var rim = new THREE.Mesh(new THREE.CylinderGeometry(r * 0.64, r * 0.64, w + 0.03, 14), alloyMat);
      rim.rotation.z = Math.PI * 0.5;
      wg.add(rim);

      var hub = new THREE.Mesh(new THREE.CylinderGeometry(r * 0.22, r * 0.22, w + 0.06, 10), trimMat);
      hub.rotation.z = Math.PI * 0.5;
      wg.add(hub);

      if (showCaliper) {
        var cal = new THREE.Mesh(
          new THREE.BoxGeometry(w * 0.4, r * 0.44, r * 0.36),
          new THREE.MeshBasicMaterial({ color: 0xef4444 })
        );
        cal.position.set(x < 0 ? -w * 0.35 : w * 0.35, 0, r * 0.28);
        wg.add(cal);
      }

      root.add(wg);
      wheels.push(wg);
      return wg;
    }

    function addFlame(x, y, z, radius, len) {
      var coneGeo = new THREE.ConeGeometry(radius, len, 10);
      coneGeo.rotateX(Math.PI * 0.5);
      coneGeo.translate(0, 0, len * 0.5);
      var cone = new THREE.Mesh(coneGeo, flameMat);
      cone.position.set(x, y, z);
      root.add(cone);
      flames.push(cone);
    }

    function addHeadlightBeams(y, zFront) {
      for (var hs = -1; hs <= 1; hs += 2) {
        var coneGeo = new THREE.ConeGeometry(1.75, 11.5, 12, 1, true);
        coneGeo.rotateX(-Math.PI * 0.5);
        coneGeo.translate(0, 0, -5.75);
        var coneMat = new THREE.MeshBasicMaterial({
          color: 0xfff0c8,
          transparent: true,
          opacity: 0.08,
          depthWrite: false,
          side: THREE.DoubleSide,
        });
        var cone = new THREE.Mesh(coneGeo, coneMat);
        cone.position.set(hs * 1.15, y, zFront);
        root.add(cone);
      }
    }

    // Contact shadow plane under car
    var glowDisc = new THREE.Mesh(
      new THREE.PlaneGeometry(3.8, 6.4),
      new THREE.MeshBasicMaterial({
        color: 0x000000,
        transparent: true,
        opacity: 0.48,
        depthWrite: false,
      })
    );
    glowDisc.rotation.x = -Math.PI * 0.5;
    glowDisc.position.y = 0.03;
    root.add(glowDisc);

    if (typeIndex === 1) {
      // 1: FORMULA-X (Carbon Open-Wheel F1 Racer)
      var monocoque = new THREE.Mesh(new THREE.BoxGeometry(1.15, 0.55, 5.8), bodyMat);
      monocoque.position.set(0, 0.45, 0);
      monocoque.castShadow = true;
      root.add(monocoque);

      var sidepods = new THREE.Mesh(new THREE.BoxGeometry(2.35, 0.42, 2.9), bodyMat);
      sidepods.position.set(0, 0.40, 0.35);
      sidepods.castShadow = true;
      root.add(sidepods);

      var nose = new THREE.Mesh(new THREE.BoxGeometry(0.65, 0.30, 1.8), trimMat);
      nose.position.set(0, 0.32, -2.5);
      root.add(nose);

      var frontWing = new THREE.Mesh(new THREE.BoxGeometry(3.05, 0.12, 0.72), trimMat);
      frontWing.position.set(0, 0.18, -3.0);
      root.add(frontWing);

      var airbox = new THREE.Mesh(new THREE.BoxGeometry(0.65, 0.52, 1.5), secMat);
      airbox.position.set(0, 0.92, 0.5);
      root.add(airbox);

      var helmet = new THREE.Mesh(new THREE.SphereGeometry(0.28, 12, 12), secMat);
      helmet.position.set(0, 0.88, -0.35);
      root.add(helmet);

      wingMesh = new THREE.Mesh(new THREE.BoxGeometry(2.8, 0.14, 0.65), trimMat);
      wingMesh.position.set(0, 1.25, 2.75);
      root.add(wingMesh);

      for (var s = -1; s <= 1; s += 2) {
        var endplate = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.75, 0.75), bodyMat);
        endplate.position.set(s * 1.4, 0.95, 2.75);
        root.add(endplate);
        var wishbone = new THREE.Mesh(new THREE.BoxGeometry(1.1, 0.08, 0.16), secMat);
        wishbone.position.set(s * 0.95, 0.42, -1.9);
        root.add(wishbone);
        var wishboneR = new THREE.Mesh(new THREE.BoxGeometry(1.1, 0.08, 0.16), secMat);
        wishboneR.position.set(s * 0.95, 0.42, 1.9);
        root.add(wishboneR);
      }

      addWheel(-1.38, 0.46, -1.95, 0.46, 0.46, true);
      addWheel(1.38, 0.46, -1.95, 0.46, 0.46, true);
      addWheel(-1.42, 0.50, 1.95, 0.50, 0.58, true);
      addWheel(1.42, 0.50, 1.95, 0.50, 0.58, true);

      var rainLight = new THREE.Mesh(new THREE.BoxGeometry(0.24, 0.24, 0.12), tailMat);
      rainLight.position.set(0, 0.42, 2.95);
      root.add(rainLight);

      addFlame(0, 0.48, 2.95, 0.22, 1.25);
    } else if (typeIndex === 2) {
      // 2: CYBER-BIKE (Streetfighter Superbike)
      var bikeFrame = new THREE.Mesh(new THREE.BoxGeometry(0.74, 0.65, 3.3), bodyMat);
      bikeFrame.position.set(0, 0.65, 0);
      bikeFrame.castShadow = true;
      root.add(bikeFrame);

      var cowl = new THREE.Mesh(new THREE.BoxGeometry(0.86, 0.48, 1.65), trimMat);
      cowl.position.set(0, 0.95, -0.55);
      cowl.rotation.x = 0.25;
      root.add(cowl);

      var windscreen = new THREE.Mesh(new THREE.BoxGeometry(0.65, 0.40, 0.55), glassMat);
      windscreen.position.set(0, 1.28, -0.95);
      windscreen.rotation.x = -0.65;
      root.add(windscreen);

      var handle = new THREE.Mesh(new THREE.BoxGeometry(1.45, 0.09, 0.12), alloyMat);
      handle.position.set(0, 1.15, -0.95);
      root.add(handle);

      var rider = new THREE.Mesh(new THREE.BoxGeometry(0.62, 0.60, 0.95), new THREE.MeshStandardMaterial({ color: 0x111827, roughness: 0.7 }));
      rider.position.set(0, 1.28, 0.05);
      rider.rotation.x = 0.48;
      root.add(rider);

      var visorHelmet = new THREE.Mesh(new THREE.SphereGeometry(0.28, 12, 12), secMat);
      visorHelmet.position.set(0, 1.56, -0.35);
      root.add(visorHelmet);

      addWheel(0, 0.52, -1.55, 0.52, 0.34, true);
      addWheel(0, 0.56, 1.55, 0.56, 0.44, true);

      var tailStrip = new THREE.Mesh(new THREE.BoxGeometry(0.62, 0.14, 0.12), tailMat);
      tailStrip.position.set(0, 0.85, 1.72);
      root.add(tailStrip);

      addHeadlightBeams(0.95, -1.4);
      addFlame(0, 0.52, 1.95, 0.20, 1.3);
    } else if (typeIndex === 3) {
      // 3: TITAN-6X (NFS MW Heavy Rhino Enforcer SUV with flashing Police Lightbar)
      var suvMat = new THREE.MeshStandardMaterial({
        color: 0x181b22,
        metalness: 0.75,
        roughness: 0.28,
        envMapIntensity: 1.3,
      });
      var chassis = new THREE.Mesh(new THREE.BoxGeometry(3.55, 1.08, 6.2), suvMat);
      chassis.position.set(0, 0.92, 0);
      chassis.castShadow = true;
      root.add(chassis);

      var cab = new THREE.Mesh(new THREE.BoxGeometry(3.05, 0.86, 3.3), suvMat);
      cab.position.set(0, 1.84, -0.25);
      cab.castShadow = true;
      root.add(cab);

      // Steel Police Ramming Bull-Bar
      var bullBar = new THREE.Mesh(new THREE.BoxGeometry(3.35, 0.72, 0.32), alloyMat);
      bullBar.position.set(0, 0.88, -3.22);
      root.add(bullBar);

      var bumper = new THREE.Mesh(new THREE.BoxGeometry(3.75, 0.32, 0.35), alloyMat);
      bumper.position.set(0, 0.52, 3.12);
      root.add(bumper);

      var windshield = new THREE.Mesh(new THREE.BoxGeometry(2.85, 0.62, 0.14), glassMat);
      windshield.position.set(0, 1.80, -1.92);
      windshield.rotation.x = -0.35;
      root.add(windshield);

      // Alternating Red & Blue Police Lightbar
      var barBase = new THREE.Mesh(new THREE.BoxGeometry(2.4, 0.14, 0.38), new THREE.MeshStandardMaterial({ color: 0x090d16 }));
      barBase.position.set(0, 2.34, -0.35);
      root.add(barBase);
      var barLMat = new THREE.MeshBasicMaterial({ color: 0xff1e42 });
      var barRMat = new THREE.MeshBasicMaterial({ color: 0x2563eb });
      var barL = new THREE.Mesh(new THREE.BoxGeometry(1.05, 0.16, 0.36), barLMat);
      barL.position.set(-0.62, 2.36, -0.35);
      var barR = new THREE.Mesh(new THREE.BoxGeometry(1.05, 0.16, 0.36), barRMat);
      barR.position.set(0.62, 2.36, -0.35);
      root.add(barL, barR);
      policeBar = { left: barLMat, right: barRMat };

      for (var ts = -1; ts <= 1; ts += 2) {
        var tLight = new THREE.Mesh(new THREE.BoxGeometry(0.28, 0.58, 0.12), tailMat);
        tLight.position.set(ts * 1.48, 1.02, 3.12);
        root.add(tLight);
      }

      addWheel(-1.82, 0.62, -2.05, 0.62, 0.52, false);
      addWheel(1.82, 0.62, -2.05, 0.62, 0.52, false);
      addWheel(-1.82, 0.62, 2.05, 0.62, 0.52, false);
      addWheel(1.82, 0.62, 2.05, 0.62, 0.52, false);

      addHeadlightBeams(1.0, -3.1);
      addFlame(-1.05, 0.55, 3.15, 0.16, 0.95);
      addFlame(1.05, 0.55, 3.15, 0.16, 0.95);
    } else if (typeIndex === 4) {
      // 4: AERO-HOVER (Titanium Street-Jet Prototype)
      var hull = new THREE.Mesh(new THREE.BoxGeometry(1.75, 0.52, 5.2), bodyMat);
      hull.position.set(0, 0.95, 0);
      hull.castShadow = true;
      root.add(hull);

      for (var hs = -1; hs <= 1; hs += 2) {
        var wing = new THREE.Mesh(new THREE.BoxGeometry(1.9, 0.16, 3.4), bodyMat);
        wing.position.set(hs * 1.35, 0.88, 0.55);
        wing.rotation.y = hs * -0.28;
        wing.castShadow = true;
        root.add(wing);

        var wingTrim = new THREE.Mesh(new THREE.BoxGeometry(1.92, 0.10, 0.14), secMat);
        wingTrim.position.set(hs * 1.35, 0.88, 2.22);
        wingTrim.rotation.y = hs * -0.28;
        root.add(wingTrim);

        var fin = new THREE.Mesh(new THREE.BoxGeometry(0.10, 0.82, 1.25), trimMat);
        fin.position.set(hs * 1.65, 1.28, 1.55);
        fin.rotation.z = hs * -0.22;
        root.add(fin);

        var repulsor = new THREE.Mesh(
          new THREE.TorusGeometry(0.75, 0.10, 8, 20),
          new THREE.MeshBasicMaterial({ color: 0x00f0ff })
        );
        repulsor.rotation.x = Math.PI * 0.5;
        repulsor.position.set(hs * 1.05, 0.25, 0.2);
        root.add(repulsor);
      }

      var canopy = new THREE.Mesh(new THREE.SphereGeometry(0.78, 14, 12), glassMat);
      canopy.scale.set(1.0, 0.65, 2.2);
      canopy.position.set(0, 1.25, -0.35);
      root.add(canopy);

      addHeadlightBeams(0.95, -2.5);
      addFlame(-0.55, 0.92, 2.65, 0.26, 1.55);
      addFlame(0.55, 0.92, 2.65, 0.26, 1.55);
    } else {
      // 0: HERO BMW M3 GTR E46 (NFS MOST WANTED LEGEND)
      m3BodyMat = new THREE.MeshStandardMaterial({
        map: m3LiveryTex,
        color: 0xe5e7eb,
        metalness: 0.82,
        roughness: 0.20,
        envMapIntensity: 1.55,
      });

      var coupeGeo = createSculptedCoupeGeo(5.3, 2.75, 0.92, 1.46, 1.08);
      var coupeMesh = new THREE.Mesh(coupeGeo, m3BodyMat);
      coupeMesh.castShadow = true;
      root.add(coupeMesh);

      // Flared M3 GTR Widebody Fenders & Side Skirts
      for (var fs = -1; fs <= 1; fs += 2) {
        var skirt = new THREE.Mesh(new THREE.BoxGeometry(0.28, 0.26, 5.2), m3BodyMat);
        skirt.position.set(fs * 1.48, 0.34, 0);
        root.add(skirt);

        var archF = new THREE.Mesh(new THREE.BoxGeometry(0.32, 0.52, 1.25), m3BodyMat);
        archF.position.set(fs * 1.50, 0.58, -1.65);
        root.add(archF);

        var archR = new THREE.Mesh(new THREE.BoxGeometry(0.34, 0.54, 1.35), m3BodyMat);
        archR.position.set(fs * 1.52, 0.60, 1.65);
        root.add(archR);

        // Carbon side mirror
        var mirror = new THREE.Mesh(new THREE.BoxGeometry(0.24, 0.14, 0.20), glassMat);
        mirror.position.set(fs * 1.44, 1.06, -0.75);
        root.add(mirror);
      }

      // Smoked Reflective Glass Cabin (Windshield + Side Windows + Rear Glass)
      var windGlass = new THREE.Mesh(new THREE.BoxGeometry(2.38, 0.52, 0.08), glassMat);
      windGlass.position.set(0, 1.22, -0.78);
      windGlass.rotation.x = -0.82;
      root.add(windGlass);

      var rearGlass = new THREE.Mesh(new THREE.BoxGeometry(2.34, 0.54, 0.08), glassMat);
      rearGlass.position.set(0, 1.26, 1.36);
      rearGlass.rotation.x = 0.86;
      root.add(rearGlass);

      // Hood Vents (M3 GTR signature)
      var hoodVentMat = new THREE.MeshStandardMaterial({ color: 0x111827, roughness: 0.9 });
      for (var vs = -1; vs <= 1; vs += 2) {
        var vent = new THREE.Mesh(new THREE.BoxGeometry(0.55, 0.06, 0.95), hoodVentMat);
        vent.position.set(vs * 0.62, 0.98, -1.55);
        vent.rotation.y = vs * 0.12;
        root.add(vent);
      }

      // Royal Blue Racing Roof/Hood Center Stripe Accent
      var hoodStripe = new THREE.Mesh(
        new THREE.BoxGeometry(0.86, 0.04, 1.85),
        new THREE.MeshStandardMaterial({ color: 0x1d4ed8, metalness: 0.7, roughness: 0.22 })
      );
      hoodStripe.position.set(0, 0.96, -1.62);
      root.add(hoodStripe);

      // Dual Angel-Eye Halo Headlights + Front Splitters
      for (var as = -1; as <= 1; as += 2) {
        var halo = new THREE.Mesh(
          new THREE.TorusGeometry(0.18, 0.04, 6, 14),
          new THREE.MeshBasicMaterial({ color: 0xfff3d1 })
        );
        halo.position.set(as * 1.05, 0.65, -2.72);
        root.add(halo);
      }
      var frontSplitter = new THREE.Mesh(new THREE.BoxGeometry(3.15, 0.10, 0.45), hoodVentMat);
      frontSplitter.position.set(0, 0.22, -2.62);
      root.add(frontSplitter);

      // Tall M3 GTR Carbon GT Rear Wing + Brushed Aluminum Endplates
      wingMesh = new THREE.Mesh(new THREE.BoxGeometry(2.98, 0.09, 0.56), hoodVentMat);
      wingMesh.position.set(0, 1.56, 2.38);
      root.add(wingMesh);

      for (var ws = -1; ws <= 1; ws += 2) {
        var strut = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.52, 0.34), alloyMat);
        strut.position.set(ws * 0.85, 1.30, 2.38);
        root.add(strut);

        var endp = new THREE.Mesh(new THREE.BoxGeometry(0.07, 0.36, 0.66), alloyMat);
        endp.position.set(ws * 1.49, 1.56, 2.38);
        root.add(endp);
      }

      // Twin L-Shaped Smoked Red Tail-Lights + License Plate
      for (var tls = -1; tls <= 1; tls += 2) {
        var tl = new THREE.Mesh(new THREE.BoxGeometry(0.86, 0.20, 0.12), tailMat);
        tl.position.set(tls * 0.96, 0.84, 2.73);
        root.add(tl);
      }
      var plate = new THREE.Mesh(
        new THREE.BoxGeometry(0.76, 0.22, 0.08),
        new THREE.MeshBasicMaterial({ color: 0xfef3c7 })
      );
      plate.position.set(0, 0.68, 2.74);
      root.add(plate);

      // Rear Diffuser
      var diffuser = new THREE.Mesh(new THREE.BoxGeometry(2.6, 0.22, 0.25), hoodVentMat);
      diffuser.position.set(0, 0.30, 2.68);
      root.add(diffuser);

      addWheel(-1.56, 0.45, -1.65, 0.45, 0.38, true);
      addWheel(1.56, 0.45, -1.65, 0.45, 0.38, true);
      addWheel(-1.58, 0.47, 1.65, 0.47, 0.44, true);
      addWheel(1.58, 0.47, 1.65, 0.47, 0.44, true);

      addHeadlightBeams(0.65, -2.72);
      addFlame(-0.74, 0.38, 2.78, 0.21, 1.35);
      addFlame(0.74, 0.38, 2.78, 0.21, 1.35);
    }

    shieldRing = new THREE.Mesh(
      new THREE.TorusGeometry(2.55, 0.08, 8, 28),
      new THREE.MeshBasicMaterial({ color: 0xff3b5c, transparent: true, opacity: 0.0 })
    );
    shieldRing.rotation.x = Math.PI * 0.5;
    shieldRing.position.y = 0.8;
    root.add(shieldRing);

    return {
      root: root,
      wheels: wheels,
      flames: flames,
      flameMat: flameMat,
      tailMat: tailMat,
      wingMesh: wingMesh,
      shieldRing: shieldRing,
      glowDisc: glowDisc,
      bodyMat: bodyMat,
      trimMat: trimMat,
      policeBar: policeBar,
      m3BodyMat: m3BodyMat,
    };
  }

  // =========================================================================
  // OPPONENTS: CLEARCOAT TRAFFIC, FREIGHT SEMI-TRUCK, & RPD POLICE CRUISER
  // =========================================================================
  function buildOpponentGroup(kind, streetColorHex) {
    var g = new THREE.Group();
    var tireMat = new THREE.MeshStandardMaterial({ color: 0x090d16, roughness: 0.85 });
    var glassMat = new THREE.MeshStandardMaterial({ color: 0x050914, metalness: 0.92, roughness: 0.08 });
    var alloyMat = new THREE.MeshStandardMaterial({ color: 0xd1d5db, metalness: 0.9, roughness: 0.2 });

    var bodyMat;
    var policeLights = null;

    if (kind === 1) {
      // Freight Semi Box Truck
      bodyMat = new THREE.MeshStandardMaterial({ color: 0x334155, metalness: 0.55, roughness: 0.45 });
      var cargoMat = new THREE.MeshStandardMaterial({ color: 0xe2e8f0, metalness: 0.25, roughness: 0.55 });
      var cab = new THREE.Mesh(new THREE.BoxGeometry(3.2, 1.9, 2.1), bodyMat);
      cab.position.set(0, 1.15, -2.5);
      cab.castShadow = true;
      var trailer = new THREE.Mesh(new THREE.BoxGeometry(3.4, 2.45, 4.9), cargoMat);
      trailer.position.set(0, 1.58, 0.9);
      trailer.castShadow = true;
      var dotStripe = new THREE.Mesh(
        new THREE.BoxGeometry(3.42, 0.20, 0.10),
        new THREE.MeshBasicMaterial({ color: 0xef4444 })
      );
      dotStripe.position.set(0, 0.62, 3.36);
      var tail = new THREE.Mesh(
        new THREE.BoxGeometry(2.9, 0.20, 0.12),
        new THREE.MeshBasicMaterial({ color: 0xff2a5f })
      );
      tail.position.set(0, 0.82, 3.36);
      g.add(cab, trailer, dotStripe, tail);
    } else if (kind === 2) {
      // Rockport Police Department (RPD) Black & White Interceptor Cruiser
      bodyMat = new THREE.MeshStandardMaterial({
        color: 0x0e1118,
        metalness: 0.78,
        roughness: 0.20,
        envMapIntensity: 1.4,
      });
      var whiteDoorMat = new THREE.MeshStandardMaterial({
        color: 0xf8fafc,
        metalness: 0.35,
        roughness: 0.28,
      });

      var sedanGeo = createSculptedCoupeGeo(5.1, 2.55, 0.88, 1.42, 0.98);
      var sedanMesh = new THREE.Mesh(sedanGeo, bodyMat);
      sedanMesh.castShadow = true;
      g.add(sedanMesh);

      var whiteSides = new THREE.Mesh(new THREE.BoxGeometry(2.68, 0.54, 2.15), whiteDoorMat);
      whiteSides.position.set(0, 0.62, 0.05);
      g.add(whiteSides);

      var roofWhite = new THREE.Mesh(new THREE.BoxGeometry(2.25, 0.06, 1.65), whiteDoorMat);
      roofWhite.position.set(0, 1.46, 0.12);
      g.add(roofWhite);

      var pushBumper = new THREE.Mesh(new THREE.BoxGeometry(2.4, 0.45, 0.24), alloyMat);
      pushBumper.position.set(0, 0.56, -2.65);
      g.add(pushBumper);

      // Flashing Red & Blue Roof Lightbar
      var barRedMat = new THREE.MeshBasicMaterial({ color: 0xff1e42 });
      var barBlueMat = new THREE.MeshBasicMaterial({ color: 0x3b82f6 });
      var barR = new THREE.Mesh(new THREE.BoxGeometry(0.95, 0.18, 0.34), barRedMat);
      barR.position.set(-0.52, 1.56, 0.15);
      var barB = new THREE.Mesh(new THREE.BoxGeometry(0.95, 0.18, 0.34), barBlueMat);
      barB.position.set(0.52, 1.56, 0.15);
      g.add(barR, barB);
      policeLights = { red: barRedMat, blue: barBlueMat };

      var rTail = new THREE.Mesh(
        new THREE.BoxGeometry(2.4, 0.16, 0.10),
        new THREE.MeshBasicMaterial({ color: 0xff2a5f })
      );
      rTail.position.set(0, 0.72, 2.60);
      g.add(rTail);
    } else {
      // Sculpted Metallic Street Coupe
      bodyMat = new THREE.MeshStandardMaterial({
        color: streetColorHex,
        metalness: 0.78,
        roughness: 0.22,
        envMapIntensity: 1.4,
      });
      var cGeo = createSculptedCoupeGeo(5.1, 2.6, 0.88, 1.40, 0.98);
      var cMesh = new THREE.Mesh(cGeo, bodyMat);
      cMesh.castShadow = true;
      g.add(cMesh);

      var cGlass = new THREE.Mesh(new THREE.BoxGeometry(2.22, 0.46, 0.08), glassMat);
      cGlass.position.set(0, 1.20, 1.24);
      cGlass.rotation.x = 0.85;
      g.add(cGlass);

      var cTail = new THREE.Mesh(
        new THREE.BoxGeometry(2.45, 0.15, 0.10),
        new THREE.MeshBasicMaterial({ color: 0xff2a5f })
      );
      cTail.position.set(0, 0.72, 2.60);
      g.add(cTail);
    }

    for (var wx = -1; wx <= 1; wx += 2) {
      for (var wz = -1; wz <= 1; wz += 2) {
        var tire = new THREE.Mesh(new THREE.CylinderGeometry(0.42, 0.42, 0.34, 12), tireMat);
        tire.rotation.z = Math.PI * 0.5;
        tire.position.set(wx * (kind === 1 ? 1.62 : 1.38), 0.42, wz * 1.65);
        g.add(tire);
      }
    }

    g.userData = { bodyMat: bodyMat, policeLights: policeLights };
    return g;
  }

  // =========================================================================
  // MAIN MOUNTED 3D SCENE INSTANCE
  // =========================================================================
  window.spnk3dMount = function (container) {
    if (!window.spnk3dIsAvailable()) return -1;

    var id = _nextId++;
    var width = Math.max(container.clientWidth || 800, 1);
    var height = Math.max(container.clientHeight || 600, 1);

    var renderer = new THREE.WebGLRenderer({
      antialias: true,
      powerPreference: 'high-performance',
      alpha: false,
    });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    renderer.setSize(width, height);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.18;
    renderer.domElement.style.pointerEvents = 'none';
    renderer.domElement.style.display = 'block';
    renderer.domElement.style.width = '100%';
    renderer.domElement.style.height = '100%';

    container.innerHTML = '';
    container.appendChild(renderer.domElement);

    var scene = new THREE.Scene();
    scene.background = new THREE.Color(0x282420);
    scene.fog = new THREE.FogExp2(0xb87635, 0.0020);

    var camera = new THREE.PerspectiveCamera(62, width / height, 0.5, 1800);
    camera.position.set(0, 4.5, 10.0);

    // Golden-Hour Rockport Lighting
    var hemiLight = new THREE.HemisphereLight(0xf6b252, 0x2a1f16, 0.95);
    scene.add(hemiLight);

    var dirLight = new THREE.DirectionalLight(0xffcf88, 1.55);
    dirLight.position.set(18, 28, -45);
    dirLight.castShadow = true;
    dirLight.shadow.mapSize.width = 1024;
    dirLight.shadow.mapSize.height = 1024;
    dirLight.shadow.camera.near = 5;
    dirLight.shadow.camera.far = 240;
    dirLight.shadow.camera.left = -45;
    dirLight.shadow.camera.right = 45;
    dirLight.shadow.camera.top = 45;
    dirLight.shadow.camera.bottom = -95;
    scene.add(dirLight);

    var underGlowLight = new THREE.PointLight(0xffb84d, 1.4, 22);
    underGlowLight.position.set(0, 1.0, 0);
    scene.add(underGlowLight);

    var policeFlashLight = new THREE.PointLight(0xef4444, 0.0, 32);
    policeFlashLight.position.set(0, 2.5, -18);
    scene.add(policeFlashLight);

    var driverTexture = null;
    try {
      new THREE.TextureLoader().load(
        'assets/assets/images/propic3.png',
        function (tex) {
          driverTexture = tex;
        },
        undefined,
        function () {}
      );
    } catch (e) {}

    var texCache = {};
    var envCache = {};
    var wetAsphalt = createWetAsphaltTextures();
    var m3LiveryTex = createM3GtrLiveryTexture();
    var smokeTex = createSmokeTexture();
    var sunGlowTex = createSunGlowTexture();

    // 3D Atmospheric Sky Dome + Volumetric Golden Sun Sprite + Distant Mountains
    var skyDomeMat = new THREE.MeshBasicMaterial({
      map: createSkyDomeTexture('nfsMostWanted', true),
      side: THREE.BackSide,
      fog: false,
      depthWrite: false,
    });
    var skyDome = new THREE.Mesh(new THREE.SphereGeometry(1200, 32, 20), skyDomeMat);
    scene.add(skyDome);

    var starGeo = new THREE.BufferGeometry();
    var starCount = 220;
    var starPos = new Float32Array(starCount * 3);
    for (var si = 0; si < starCount; si++) {
      var sa = (si * 2.39996) % (Math.PI * 2);
      var sr = 540 + ((si * 53) % 240);
      starPos[si * 3] = Math.cos(sa) * sr;
      starPos[si * 3 + 1] = 65 + ((si * 29) % 220);
      starPos[si * 3 + 2] = Math.sin(sa) * sr;
    }
    starGeo.setAttribute('position', new THREE.BufferAttribute(starPos, 3));
    var starMat = new THREE.PointsMaterial({ color: 0xffffff, size: 2.0, transparent: true, opacity: 0.72 });
    var starField = new THREE.Points(starGeo, starMat);
    scene.add(starField);

    var sunSprite = new THREE.Sprite(
      new THREE.SpriteMaterial({
        map: sunGlowTex,
        color: 0xffd584,
        transparent: true,
        blending: THREE.AdditiveBlending,
        fog: false,
      })
    );
    sunSprite.scale.set(220, 220, 1);
    sunSprite.position.set(20, 62, -620);
    scene.add(sunSprite);

    var mtnGroup = new THREE.Group();
    var mtnMat = new THREE.MeshStandardMaterial({ color: 0x261d14, roughness: 0.92, metalness: 0.1 });
    for (var mi = 0; mi < 32; mi++) {
      var ma = (mi / 32) * Math.PI * 2;
      var mh = 36 + ((mi * 37) % 52);
      var cone = new THREE.Mesh(new THREE.ConeGeometry(48, mh, 5), mtnMat);
      cone.position.set(Math.cos(ma) * 580, mh * 0.40 - 8, Math.sin(ma) * 580);
      cone.rotation.y = ma;
      mtnGroup.add(cone);
    }
    scene.add(mtnGroup);

    // =========================================================================
    // CIRCUIT GROUP (WET ROAD RIBBON + CONCRETE JERSEY WALLS + SHOULDER TERRAIN)
    // =========================================================================
    var circuitGroup = new THREE.Group();
    scene.add(circuitGroup);

    var groundMat = new THREE.MeshStandardMaterial({ color: 0x1c1711, roughness: 0.96 });
    var groundPlane = new THREE.Mesh(new THREE.PlaneGeometry(1600, 1600), groundMat);
    groundPlane.rotation.x = -Math.PI * 0.5;
    groundPlane.position.set(0, -14, -320);
    groundPlane.receiveShadow = true;
    circuitGroup.add(groundPlane);

    var gridHelper = new THREE.GridHelper(1200, 60, 0x38bdf8, 0x1e293b);
    gridHelper.position.set(0, -13.9, -320);
    gridHelper.material.transparent = true;
    gridHelper.material.opacity = 0.25;
    circuitGroup.add(gridHelper);

    function createRibbonMesh(material, yBias, hasUvs) {
      var geo = new THREE.BufferGeometry();
      var verts = new Float32Array(TOTAL_SLICES * 2 * 3);
      var colors = new Float32Array(TOTAL_SLICES * 2 * 3);
      var uvs = hasUvs ? new Float32Array(TOTAL_SLICES * 2 * 2) : null;
      var indices = [];
      for (var i = 0; i < TOTAL_SLICES - 1; i++) {
        var a = i * 2;
        var b = a + 1;
        var c = a + 2;
        var d = a + 3;
        indices.push(a, c, b);
        indices.push(b, c, d);
      }
      geo.setAttribute('position', new THREE.BufferAttribute(verts, 3));
      geo.setAttribute('color', new THREE.BufferAttribute(colors, 3));
      if (hasUvs) {
        geo.setAttribute('uv', new THREE.BufferAttribute(uvs, 2));
      }
      geo.setIndex(indices);
      var mesh = new THREE.Mesh(geo, material);
      mesh.receiveShadow = true;
      mesh.frustumCulled = false;
      mesh.position.y = yBias || 0;
      return { mesh: mesh, verts: verts, colors: colors, uvs: uvs, geo: geo };
    }

    var roadRibbonMat = new THREE.MeshStandardMaterial({
      map: wetAsphalt.map,
      roughnessMap: wetAsphalt.roughnessMap,
      vertexColors: true,
      roughness: 0.44,
      metalness: 0.30,
      envMapIntensity: 1.35,
    });
    var roadRibbon = createRibbonMesh(roadRibbonMat, 0.0, true);
    circuitGroup.add(roadRibbon.mesh);

    var leftKerbRibbon = createRibbonMesh(
      new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.65 }),
      0.03,
      false
    );
    var rightKerbRibbon = createRibbonMesh(
      new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.65 }),
      0.03,
      false
    );
    circuitGroup.add(leftKerbRibbon.mesh);
    circuitGroup.add(rightKerbRibbon.mesh);

    // Concrete Jersey Side Walls & Autumn Shoulder Embankments
    var wallMat = new THREE.MeshStandardMaterial({
      vertexColors: true,
      roughness: 0.78,
      metalness: 0.15,
      side: THREE.DoubleSide,
    });
    var leftWallRibbon = createRibbonMesh(wallMat, 0.0, false);
    var rightWallRibbon = createRibbonMesh(wallMat, 0.0, false);
    circuitGroup.add(leftWallRibbon.mesh);
    circuitGroup.add(rightWallRibbon.mesh);

    var shoulderMat = new THREE.MeshStandardMaterial({
      vertexColors: true,
      roughness: 0.94,
      metalness: 0.04,
      side: THREE.DoubleSide,
    });
    var leftShoulderRibbon = createRibbonMesh(shoulderMat, -0.02, false);
    var rightShoulderRibbon = createRibbonMesh(shoulderMat, -0.02, false);
    circuitGroup.add(leftShoulderRibbon.mesh);
    circuitGroup.add(rightShoulderRibbon.mesh);

    // Pooled lane dashes & boost pads
    var dashPool = [];
    var dashMat = new THREE.MeshBasicMaterial({ color: 0xf8fafc, transparent: true, opacity: 0.78 });
    var dashGeo = new THREE.PlaneGeometry(0.28, 3.6);
    dashGeo.rotateX(-Math.PI * 0.5);
    for (var di = 0; di < 90; di++) {
      var dm = new THREE.Mesh(dashGeo, dashMat);
      dm.visible = false;
      circuitGroup.add(dm);
      dashPool.push(dm);
    }

    var boostPadPool = [];
    var boostGeo = new THREE.PlaneGeometry(3.2, 6.8);
    boostGeo.rotateX(-Math.PI * 0.5);
    var boostMat = new THREE.MeshBasicMaterial({ color: 0x00f0ff, transparent: true, opacity: 0.85 });
    for (var bi = 0; bi < 10; bi++) {
      var bm = new THREE.Mesh(boostGeo, boostMat);
      bm.visible = false;
      circuitGroup.add(bm);
      boostPadPool.push(bm);
    }

    // Tunnel Arches pool (Concrete ribbed tunnel + glowing ceiling strip light!)
    var archPool = [];
    var archConcreteMat = new THREE.MeshStandardMaterial({ color: 0x262930, roughness: 0.85 });
    var archGlowMat = new THREE.MeshBasicMaterial({ color: 0xffd590 });
    var archGeo = new THREE.TorusGeometry(ROAD_HALF_W + 1.8, 0.45, 6, 18, Math.PI);
    var archStripGeo = new THREE.BoxGeometry(5.5, 0.18, 0.9);
    for (var ai = 0; ai < 18; ai++) {
      var ag = new THREE.Group();
      var am = new THREE.Mesh(archGeo, archConcreteMat);
      var aLight = new THREE.Mesh(archStripGeo, archGlowMat);
      aLight.position.y = ROAD_HALF_W + 1.25;
      ag.add(am, aLight);
      ag.visible = false;
      circuitGroup.add(ag);
      archPool.push({ group: ag, lightMesh: aLight });
    }

    // Roadside Scenery Pool (Autumn Foliage Trees, Downtown Buildings, Sodium Streetlamps, Palms)
    var propPool = [];
    var poleGeo = new THREE.CylinderGeometry(0.11, 0.16, 7.2, 6);
    var armGeo = new THREE.BoxGeometry(2.6, 0.12, 0.12);
    var lampGeo = new THREE.SphereGeometry(0.36, 8, 8);
    var bldgGeo = new THREE.BoxGeometry(11, 34, 11);
    var facadeTex = createBuildingFacadeTexture(0xf59e0b, 0x38bdf8, true, 'nfsMostWanted');
    var bldgMat = new THREE.MeshStandardMaterial({ map: facadeTex, roughness: 0.6 });
    var trunkGeo = new THREE.CylinderGeometry(0.24, 0.38, 6.2, 6);
    var autumnTrunkMat = new THREE.MeshStandardMaterial({ color: 0x3b281c, roughness: 0.95 });
    var autumnLeafMats = [
      new THREE.MeshStandardMaterial({ color: 0xd97706, roughness: 0.85 }), // amber gold
      new THREE.MeshStandardMaterial({ color: 0xb45309, roughness: 0.85 }), // burnt orange
      new THREE.MeshStandardMaterial({ color: 0x991b1b, roughness: 0.88 }), // crimson maple
      new THREE.MeshStandardMaterial({ color: 0x2d4a22, roughness: 0.88 }), // deep forest pine
    ];
    var synthCrownMat = new THREE.MeshStandardMaterial({ color: 0x00f5d4, emissive: 0x00f5d4, emissiveIntensity: 0.28 });

    for (var pi = 0; pi < 32; pi++) {
      var pg = new THREE.Group();
      var poleMat = new THREE.MeshStandardMaterial({ color: 0x475569, metalness: 0.6, roughness: 0.4 });
      var lampMat = new THREE.MeshBasicMaterial({ color: 0xffb347 });
      var pole = new THREE.Mesh(poleGeo, poleMat);
      pole.position.y = 3.6;
      var arm = new THREE.Mesh(armGeo, poleMat);
      arm.position.set(1.2, 7.1, 0);
      var lamp = new THREE.Mesh(lampGeo, lampMat);
      lamp.position.set(2.3, 6.95, 0);

      var bldg = new THREE.Mesh(bldgGeo, bldgMat);
      bldg.position.set(16, 17, 0);

      // Multi-tiered Autumn Foliage Tree
      var tree = new THREE.Group();
      var tTrunk = new THREE.Mesh(trunkGeo, autumnTrunkMat);
      tTrunk.position.y = 3.1;
      var lMat = autumnLeafMats[pi % autumnLeafMats.length];
      var c1 = new THREE.Mesh(new THREE.DodecahedronGeometry(2.6, 1), lMat);
      c1.position.set(0, 6.2, 0);
      var c2 = new THREE.Mesh(new THREE.DodecahedronGeometry(2.0, 1), lMat);
      c2.position.set(1.1, 7.5, 0.5);
      var c3 = new THREE.Mesh(new THREE.DodecahedronGeometry(1.7, 1), lMat);
      c3.position.set(-1.0, 7.2, -0.4);
      tree.add(tTrunk, c1, c2, c3);
      tree.visible = false;

      // Synthwave Palm Tree
      var palm = new THREE.Group();
      var pTr = new THREE.Mesh(trunkGeo, new THREE.MeshStandardMaterial({ color: 0x1e0b36 }));
      pTr.position.y = 3.1;
      var pCr = new THREE.Mesh(new THREE.ConeGeometry(2.8, 2.2, 7), synthCrownMat);
      pCr.position.y = 7.0;
      palm.add(pTr, pCr);
      palm.visible = false;

      pg.add(pole, arm, lamp, bldg, tree, palm);
      pg.visible = false;
      circuitGroup.add(pg);
      propPool.push({
        group: pg,
        pole: pole,
        arm: arm,
        lamp: lamp,
        lampMat: lampMat,
        bldg: bldg,
        tree: tree,
        palm: palm,
      });
    }

    // Billboard Pool (Steel highway truss + CanvasTexture sign)
    var billboardPool = [];
    for (var bbi = 0; bbi < 10; bbi++) {
      var bg = new THREE.Group();
      var bMat = new THREE.MeshBasicMaterial({ color: 0xffffff });
      var frameMat = new THREE.MeshBasicMaterial({ color: 0xf59e0b });
      var bSign = new THREE.Mesh(new THREE.PlaneGeometry(10.5, 5.2), bMat);
      bSign.position.set(0, 6.4, 0.12);
      var bBack = new THREE.Mesh(new THREE.BoxGeometry(10.8, 5.5, 0.22), new THREE.MeshStandardMaterial({ color: 0x18181b }));
      bBack.position.set(0, 6.4, 0);
      var bBorder = new THREE.Mesh(new THREE.BoxGeometry(11.1, 5.8, 0.10), frameMat);
      bBorder.position.set(0, 6.4, -0.08);
      var legL = new THREE.Mesh(new THREE.CylinderGeometry(0.22, 0.22, 4.0, 6), frameMat);
      legL.position.set(-3.2, 2.0, 0);
      var legR = new THREE.Mesh(new THREE.CylinderGeometry(0.22, 0.22, 4.0, 6), frameMat);
      legR.position.set(3.2, 2.0, 0);
      bg.add(bBorder, bBack, bSign, legL, legR);
      bg.visible = false;
      circuitGroup.add(bg);
      billboardPool.push({ group: bg, sign: bSign, bMat: bMat, frameMat: frameMat });
    }

    // Interstate Highway Truss Gantries + Hologram Destination Gates
    var gantryPool = [];
    for (var gi = 0; gi < 4; gi++) {
      var gg = new THREE.Group();
      var steelMat = new THREE.MeshStandardMaterial({ color: 0x475569, metalness: 0.72, roughness: 0.35 });
      var beamMat = new THREE.MeshBasicMaterial({ color: 0x00f0ff, transparent: true, opacity: 0.22, side: THREE.DoubleSide });
      var signMat = new THREE.MeshBasicMaterial({ color: 0xffffff });

      var pL = new THREE.Mesh(new THREE.BoxGeometry(1.1, 9.8, 1.1), steelMat);
      pL.position.set(-ROAD_HALF_W - 1.5, 4.9, 0);
      var pR = new THREE.Mesh(new THREE.BoxGeometry(1.1, 9.8, 1.1), steelMat);
      pR.position.set(ROAD_HALF_W + 1.5, 4.9, 0);
      var beamL = new THREE.Mesh(new THREE.PlaneGeometry(1.4, 24), beamMat);
      beamL.position.set(-ROAD_HALF_W - 1.5, 12, 0);
      var beamR = new THREE.Mesh(new THREE.PlaneGeometry(1.4, 24), beamMat);
      beamR.position.set(ROAD_HALF_W + 1.5, 12, 0);

      var banner = new THREE.Mesh(new THREE.BoxGeometry(ROAD_HALF_W * 2 + 3.6, 3.4, 0.55), steelMat);
      banner.position.set(0, 9.8, 0);
      var signFace = new THREE.Mesh(new THREE.PlaneGeometry(ROAD_HALF_W * 2 + 3.0, 3.0), signMat);
      signFace.position.set(0, 9.8, 0.30);

      var holoPad = new THREE.Mesh(
        new THREE.PlaneGeometry(ROAD_HALF_W * 2, 3.4),
        new THREE.MeshBasicMaterial({ color: 0x00f0ff, transparent: true, opacity: 0.32 })
      );
      holoPad.rotation.x = -Math.PI * 0.5;
      holoPad.position.y = 0.08;

      var holoDiamond = new THREE.Mesh(
        new THREE.OctahedronGeometry(1.85, 0),
        new THREE.MeshBasicMaterial({ color: 0x00f0ff, wireframe: true })
      );
      holoDiamond.position.set(0, 13.8, 0);

      gg.add(pL, pR, beamL, beamR, banner, signFace, holoPad, holoDiamond);
      gg.visible = false;
      circuitGroup.add(gg);
      gantryPool.push({
        group: gg,
        signFace: signFace,
        signMat: signMat,
        holoDiamond: holoDiamond,
      });
    }

    var finishGroup = new THREE.Group();
    for (var fi = 0; fi < 10; fi++) {
      var fw = (ROAD_HALF_W * 2) / 10;
      var tile = new THREE.Mesh(
        new THREE.PlaneGeometry(fw, 2.6),
        new THREE.MeshBasicMaterial({ color: fi % 2 === 0 ? 0xffffff : 0x090d16 })
      );
      tile.rotation.x = -Math.PI * 0.5;
      tile.position.set(-ROAD_HALF_W + fw * (fi + 0.5), 0.06, 0);
      finishGroup.add(tile);
    }
    finishGroup.visible = false;
    circuitGroup.add(finishGroup);

    // Opponent Pool (coupe=0, truck=1, RPD police cruiser=2)
    var streetPalette = [0x991b1b, 0x334155, 0x0f766e, 0xb45309];
    var opponentPool = [];
    for (var oi = 0; oi < 12; oi++) {
      var variants = {};
      for (var vk = 0; vk < 3; vk++) {
        var mesh = buildOpponentGroup(vk, streetPalette[oi % streetPalette.length]);
        mesh.visible = false;
        scene.add(mesh);
        variants[vk] = mesh;
      }
      opponentPool.push(variants);
    }

    // Concrete & Orange Police Roadblock Obstacles
    var obstaclePool = [];
    var obsBodyGeo = new THREE.BoxGeometry(2.85, 1.05, 0.95);
    var obsBeaconGeo = new THREE.SphereGeometry(0.22, 8, 8);
    for (var obi = 0; obi < 14; obi++) {
      var og = new THREE.Group();
      var obsBodyMat = new THREE.MeshStandardMaterial({ color: 0x6b7280, roughness: 0.85 });
      var obsStripeMat = new THREE.MeshBasicMaterial({ color: 0xf97316 });
      var obsBeaconMat = new THREE.MeshBasicMaterial({ color: 0xff3b5c });

      var obBody = new THREE.Mesh(obsBodyGeo, obsBodyMat);
      obBody.position.y = 0.55;
      obBody.castShadow = true;
      var stripeBar = new THREE.Mesh(new THREE.BoxGeometry(2.90, 0.28, 0.98), obsStripeMat);
      stripeBar.position.y = 0.65;
      var beaconL = new THREE.Mesh(obsBeaconGeo, obsBeaconMat);
      beaconL.position.set(-1.05, 1.22, 0);
      var beaconR = new THREE.Mesh(obsBeaconGeo, obsBeaconMat);
      beaconR.position.set(1.05, 1.22, 0);

      og.add(obBody, stripeBar, beaconL, beaconR);
      og.visible = false;
      circuitGroup.add(og);
      obstaclePool.push({ group: og, bodyMat: obsBodyMat, beaconMat: obsBeaconMat });
    }

    // Collectible Data Crystal / N2O Orbs
    var orbPool = [];
    var orbGeo = new THREE.OctahedronGeometry(0.68, 0);
    for (var cri = 0; cri < 28; cri++) {
      var orbMat = new THREE.MeshStandardMaterial({
        color: 0x00f0ff,
        emissive: 0x00f0ff,
        emissiveIntensity: 0.75,
        metalness: 0.3,
        roughness: 0.2,
      });
      var orbMesh = new THREE.Mesh(orbGeo, orbMat);
      orbMesh.visible = false;
      scene.add(orbMesh);
      orbPool.push(orbMesh);
    }

    // 5 Player Vehicle Models
    var playerVehicles = {};
    for (var vt = 0; vt < 5; vt++) {
      var pv = buildPlayerVehicleGroup(vt, 0xf59e0b, 0x38bdf8, 0xd1d5db, m3LiveryTex);
      pv.root.visible = vt === 0;
      scene.add(pv.root);
      playerVehicles[vt] = pv;
    }

    var arrivalWaveMat = new THREE.MeshBasicMaterial({
      color: 0x00f0ff,
      transparent: true,
      opacity: 0.0,
      side: THREE.DoubleSide,
    });
    var arrivalWave = new THREE.Mesh(new THREE.RingGeometry(1.8, 2.5, 36), arrivalWaveMat);
    arrivalWave.rotation.x = -Math.PI * 0.5;
    arrivalWave.position.y = 0.14;
    scene.add(arrivalWave);

    // 3D Impact Sparks
    var sparkPool = [];
    var sparkGeo = new THREE.SphereGeometry(0.14, 6, 6);
    for (var spi = 0; spi < 48; spi++) {
      var spMat = new THREE.MeshBasicMaterial({
        color: spi % 2 === 0 ? 0xfbbf24 : 0xff3b5c,
        transparent: true,
        opacity: 0,
      });
      var spMesh = new THREE.Mesh(sparkGeo, spMat);
      spMesh.visible = false;
      scene.add(spMesh);
      sparkPool.push({ mesh: spMesh, mat: spMat, vx: 0, vy: 0, vz: 0, life: 0, maxLife: 0.5 });
    }

    // Drifting Autumn Leaves Pool (NFS Most Wanted Rockport atmosphere!)
    var leafPool = [];
    var leafGeo = new THREE.PlaneGeometry(0.32, 0.18);
    var leafColors = [0xd97706, 0xea580c, 0xb91c1c, 0xf59e0b];
    for (var lfi = 0; lfi < 36; lfi++) {
      var lfMat = new THREE.MeshBasicMaterial({
        color: leafColors[lfi % leafColors.length],
        side: THREE.DoubleSide,
      });
      var lfMesh = new THREE.Mesh(leafGeo, lfMat);
      lfMesh.position.set(
        (Math.random() - 0.5) * 32,
        1.2 + Math.random() * 5.0,
        -10 - Math.random() * 75
      );
      scene.add(lfMesh);
      leafPool.push({
        mesh: lfMesh,
        vx: (Math.random() - 0.5) * 3.5,
        vy: -0.6 - Math.random() * 0.9,
        spin: 3.0 + Math.random() * 4.0,
      });
    }

    // Tire Drift Smoke Sprite Pool
    var smokePool = [];
    for (var smi = 0; smi < 24; smi++) {
      var smMat = new THREE.SpriteMaterial({
        map: smokeTex,
        transparent: true,
        opacity: 0.0,
        depthWrite: false,
      });
      var smSprite = new THREE.Sprite(smMat);
      smSprite.visible = false;
      scene.add(smSprite);
      smokePool.push({ sprite: smSprite, mat: smMat, vx: 0, vy: 0, vz: 0, life: 0, maxLife: 0.55 });
    }

    // N2O Radial Speed Streaks
    var streakPool = [];
    var streakMat = new THREE.MeshBasicMaterial({ color: 0xe0f2fe, transparent: true, opacity: 0.0 });
    var streakGeo = new THREE.BoxGeometry(0.05, 0.05, 6.5);
    for (var sti = 0; sti < 22; sti++) {
      var stMesh = new THREE.Mesh(streakGeo, streakMat);
      var sa2 = (sti / 22) * Math.PI * 2;
      stMesh.userData = { angle: sa2, r: 4.5 + (sti % 3) * 1.4, zOff: -(sti * 1.8) % 30 };
      stMesh.visible = false;
      scene.add(stMesh);
      streakPool.push(stMesh);
    }

    // =========================================================================
    // OPEN-WORLD 3D PADDOCK STADIUM (ROCKPORT INDUSTRIAL YARD)
    // =========================================================================
    var paddockGroup = new THREE.Group();
    paddockGroup.visible = false;
    scene.add(paddockGroup);

    var paddockAsphaltTex = wetAsphalt.map.clone();
    paddockAsphaltTex.repeat.set(20, 14);
    paddockAsphaltTex.needsUpdate = true;
    var paddockRoughTex = wetAsphalt.roughnessMap.clone();
    paddockRoughTex.repeat.set(20, 14);
    paddockRoughTex.needsUpdate = true;

    var paddockFloor = new THREE.Mesh(
      new THREE.PlaneGeometry(340, 240),
      new THREE.MeshStandardMaterial({
        map: paddockAsphaltTex,
        roughnessMap: paddockRoughTex,
        color: 0x524d47,
        roughness: 0.48,
        metalness: 0.28,
      })
    );
    paddockFloor.rotation.x = -Math.PI * 0.5;
    paddockFloor.receiveShadow = true;
    paddockGroup.add(paddockFloor);

    var paddockGrid = new THREE.GridHelper(320, 40, 0xf59e0b, 0x3f3426);
    paddockGrid.position.y = 0.02;
    paddockGrid.material.transparent = true;
    paddockGrid.material.opacity = 0.22;
    paddockGroup.add(paddockGrid);

    var ovalPts = [];
    for (var ovi = 0; ovi <= 72; ovi++) {
      var oa = (ovi / 72) * Math.PI * 2;
      ovalPts.push(new THREE.Vector3(Math.cos(oa) * 900 * PADDOCK_SCALE, 0.06, Math.sin(oa) * 535 * PADDOCK_SCALE));
    }
    var ovalCurve = new THREE.CatmullRomCurve3(ovalPts, true);
    var ovalTube = new THREE.Mesh(
      new THREE.TubeGeometry(ovalCurve, 96, 5.6, 4, true),
      new THREE.MeshStandardMaterial({ color: 0x1b1e24, roughness: 0.6, metalness: 0.2 })
    );
    ovalTube.scale.y = 0.025;
    ovalTube.position.y = 0.05;
    paddockGroup.add(ovalTube);

    var arenaBorder = new THREE.Mesh(
      new THREE.BoxGeometry(3300 * PADDOCK_SCALE, 2.2, 2300 * PADDOCK_SCALE),
      new THREE.MeshBasicMaterial({ color: 0xf59e0b, wireframe: true, transparent: true, opacity: 0.18 })
    );
    arenaBorder.position.y = 1.1;
    paddockGroup.add(arenaBorder);

    var monGroup = new THREE.Group();
    var monRadius = 168.0 * PADDOCK_SCALE;
    var monPedestal = new THREE.Mesh(
      new THREE.CylinderGeometry(monRadius, monRadius * 1.04, 1.6, 36),
      new THREE.MeshStandardMaterial({ color: 0x18181b, metalness: 0.7, roughness: 0.3 })
    );
    monPedestal.position.y = 0.8;
    monGroup.add(monPedestal);

    var monHalo = new THREE.Mesh(
      new THREE.TorusGeometry(monRadius + 0.4, 0.25, 8, 40),
      new THREE.MeshBasicMaterial({ color: 0x00f0ff })
    );
    monHalo.rotation.x = Math.PI * 0.5;
    monHalo.position.y = 1.65;
    monGroup.add(monHalo);

    var monPortraitMat = new THREE.MeshBasicMaterial({ color: 0xffffff, side: THREE.DoubleSide });
    var monPortraitDisc = new THREE.Mesh(new THREE.CircleGeometry(5.6, 32), monPortraitMat);
    monPortraitDisc.position.set(0, 8.2, 0);
    monGroup.add(monPortraitDisc);
    paddockGroup.add(monGroup);

    var paddockSectorMeshes = [];
    var paddockPortalMeshes = [];

    var gpsBeacon = new THREE.Mesh(
      new THREE.CylinderGeometry(0.4, 2.2, 26, 16, 1, true),
      new THREE.MeshBasicMaterial({ color: 0x00f0ff, transparent: true, opacity: 0.42, side: THREE.DoubleSide })
    );
    gpsBeacon.position.y = 13;
    gpsBeacon.visible = false;
    paddockGroup.add(gpsBeacon);

    var state = {
      id: id,
      renderer: renderer,
      scene: scene,
      camera: camera,
      hemiLight: hemiLight,
      dirLight: dirLight,
      underGlowLight: underGlowLight,
      policeFlashLight: policeFlashLight,
      skyDomeMat: skyDomeMat,
      starField: starField,
      sunSprite: sunSprite,
      mtnGroup: mtnGroup,
      mtnMat: mtnMat,
      circuitGroup: circuitGroup,
      paddockGroup: paddockGroup,
      groundMat: groundMat,
      gridHelper: gridHelper,
      roadRibbon: roadRibbon,
      leftKerbRibbon: leftKerbRibbon,
      rightKerbRibbon: rightKerbRibbon,
      leftWallRibbon: leftWallRibbon,
      rightWallRibbon: rightWallRibbon,
      leftShoulderRibbon: leftShoulderRibbon,
      rightShoulderRibbon: rightShoulderRibbon,
      dashPool: dashPool,
      boostPadPool: boostPadPool,
      archPool: archPool,
      propPool: propPool,
      bldgMat: bldgMat,
      billboardPool: billboardPool,
      gantryPool: gantryPool,
      finishGroup: finishGroup,
      opponentPool: opponentPool,
      obstaclePool: obstaclePool,
      orbPool: orbPool,
      playerVehicles: playerVehicles,
      arrivalWave: arrivalWave,
      arrivalWaveMat: arrivalWaveMat,
      sparkPool: sparkPool,
      leafPool: leafPool,
      smokePool: smokePool,
      streakPool: streakPool,
      streakMat: streakMat,
      monPortraitDisc: monPortraitDisc,
      monPortraitMat: monPortraitMat,
      paddockSectorMeshes: paddockSectorMeshes,
      paddockPortalMeshes: paddockPortalMeshes,
      gpsBeacon: gpsBeacon,
      texCache: texCache,
      envCache: envCache,
      segments: [],
      trackLen: 720 * SEG_LEN_DART,
      lastThemeKey: '',
      lastCollisionSeq: 0,
      lastArrivalSeq: 0,
      arrivalWaveTimer: 0,
      lastTimeSec: 0,
      smokeSpawnTimer: 0,
      camPos: new THREE.Vector3(0, 4.4, 9.8),
      camLook: new THREE.Vector3(0, 1.3, -34),
      lastSyncMode: 0,
    };

    var ro = new ResizeObserver(function () {
      var w = Math.max(container.clientWidth || 1, 1);
      var h = Math.max(container.clientHeight || 1, 1);
      camera.aspect = w / h;
      camera.updateProjectionMatrix();
      renderer.setSize(w, h);
    });
    ro.observe(container);
    state.resizeObserver = ro;

    _instances[id] = state;
    return id;
  };

  // =========================================================================
  // TRACK & PADDOCK STATIC DATA INGESTION
  // =========================================================================
  window.spnk3dSetTrackData = function (id, jsonStr) {
    var st = _instances[id];
    if (!st) return;
    var data = JSON.parse(jsonStr);
    st.segments = data.segments || [];
    st.trackLen = (st.segments.length || 720) * SEG_LEN_DART;

    for (var i = 0; i < st.paddockSectorMeshes.length; i++) {
      st.paddockGroup.remove(st.paddockSectorMeshes[i]);
    }
    st.paddockSectorMeshes.length = 0;

    var sectors = data.sectors || [];
    for (var si = 0; si < sectors.length; si++) {
      var sec = sectors[si];
      var sg = new THREE.Group();
      sg.position.set(sec.px * PADDOCK_SCALE, 0, sec.py * PADDOCK_SCALE);

      var pad = new THREE.Mesh(
        new THREE.BoxGeometry(370 * PADDOCK_SCALE, 0.4, 230 * PADDOCK_SCALE),
        new THREE.MeshStandardMaterial({ color: 0x161920, roughness: 0.65 })
      );
      pad.position.y = 0.2;
      sg.add(pad);

      var holoRing = new THREE.Mesh(
        new THREE.TorusGeometry(9.0, 0.25, 8, 32),
        new THREE.MeshBasicMaterial({ color: 0x00f0ff })
      );
      holoRing.rotation.x = Math.PI * 0.5;
      holoRing.position.y = 0.55;
      sg.add(holoRing);

      var beam = new THREE.Mesh(
        new THREE.CylinderGeometry(3.8, 6.2, 16, 20, 1, true),
        new THREE.MeshBasicMaterial({ color: 0x00f0ff, transparent: true, opacity: 0.14, side: THREE.DoubleSide })
      );
      beam.position.y = 8.2;
      sg.add(beam);

      var signTex = makeTextTexture(
        st.texCache,
        'psec_' + sec.code + '_' + sec.dest,
        512,
        192,
        function (ctx, w, h) {
          ctx.fillStyle = '#0c111d';
          ctx.fillRect(0, 0, w, h);
          ctx.strokeStyle = '#00f0ff';
          ctx.lineWidth = 8;
          ctx.strokeRect(4, 4, w - 8, h - 8);
          ctx.fillStyle = '#00f0ff';
          ctx.font = 'bold 34px Rajdhani, sans-serif';
          ctx.textAlign = 'center';
          ctx.fillText(sec.code + ' // HOLOGRAM BAY', w / 2, 60);
          ctx.fillStyle = '#ffffff';
          ctx.font = 'bold 58px Rajdhani, sans-serif';
          ctx.fillText(sec.dest, w / 2, 134);
        }
      );
      var signBoard = new THREE.Mesh(
        new THREE.PlaneGeometry(20, 7.5),
        new THREE.MeshBasicMaterial({ map: signTex, side: THREE.DoubleSide })
      );
      signBoard.position.set(0, 12.0, 0);
      sg.add(signBoard);

      st.paddockGroup.add(sg);
      st.paddockSectorMeshes.push(sg);
    }

    for (var pi = 0; pi < st.paddockPortalMeshes.length; pi++) {
      st.paddockGroup.remove(st.paddockPortalMeshes[pi]);
    }
    st.paddockPortalMeshes.length = 0;

    var portals = data.portals || [];
    for (var lpi = 0; lpi < portals.length; lpi++) {
      var pt = portals[lpi];
      var pg = new THREE.Group();
      pg.position.set(pt.px * PADDOCK_SCALE, 0.25, pt.py * PADDOCK_SCALE);
      var col = parseHexColor(pt.color);
      var ring = new THREE.Mesh(
        new THREE.TorusGeometry(pt.r * PADDOCK_SCALE, 0.22, 8, 24),
        new THREE.MeshBasicMaterial({ color: col })
      );
      ring.rotation.x = Math.PI * 0.5;
      pg.add(ring);

      var pTex = makeTextTexture(
        st.texCache,
        'pl_' + pt.shortCode,
        256,
        128,
        function (ctx, w, h) {
          ctx.fillStyle = 'rgba(10, 14, 24, 0.92)';
          ctx.fillRect(0, 0, w, h);
          ctx.fillStyle = '#ffffff';
          ctx.font = 'bold 52px Rajdhani, sans-serif';
          ctx.textAlign = 'center';
          ctx.fillText(pt.shortCode, w / 2, 68);
          ctx.fillStyle = '#f59e0b';
          ctx.font = 'bold 26px Rajdhani, sans-serif';
          ctx.fillText(pt.label.toUpperCase(), w / 2, 108);
        }
      );
      var pSign = new THREE.Mesh(
        new THREE.PlaneGeometry(6.8, 3.4),
        new THREE.MeshBasicMaterial({ map: pTex, side: THREE.DoubleSide })
      );
      pSign.position.set(0, 3.8, 0);
      pg.add(pSign);

      st.paddockGroup.add(pg);
      st.paddockPortalMeshes.push(pg);
    }
  };

  function spawnSparks(st, x, y, z, pushDir) {
    var spawned = 0;
    for (var i = 0; i < st.sparkPool.length && spawned < 18; i++) {
      var sp = st.sparkPool[i];
      if (sp.life <= 0) {
        sp.life = 0.45 + Math.random() * 0.25;
        sp.maxLife = sp.life;
        sp.mesh.position.set(x, y, z);
        sp.vx = pushDir * (5 + Math.random() * 10) + (Math.random() - 0.5) * 9;
        sp.vy = 4 + Math.random() * 8;
        sp.vz = (Math.random() - 0.5) * 10;
        sp.mesh.visible = true;
        spawned++;
      }
    }
  }

  function spawnSmoke(st, x, y, z) {
    for (var i = 0; i < st.smokePool.length; i++) {
      var sm = st.smokePool[i];
      if (sm.life <= 0) {
        sm.life = 0.55;
        sm.maxLife = 0.55;
        sm.sprite.position.set(x + (Math.random() - 0.5) * 0.4, y, z);
        sm.sprite.scale.set(1.2, 1.2, 1);
        sm.vx = (Math.random() - 0.5) * 2.4;
        sm.vy = 1.6 + Math.random() * 1.4;
        sm.vz = 4.5 + Math.random() * 2.5;
        sm.sprite.visible = true;
        break;
      }
    }
  }

  // =========================================================================
  // 60 FPS FRAME SYNC FROM DART STATE
  // =========================================================================
  window.spnk3dSyncState = function (id, jsonStr) {
    var st = _instances[id];
    if (!st) return;

    var d = JSON.parse(jsonStr);
    var timeSec = d.timeSeconds || 0;
    var dt = st.lastTimeSec > 0 ? clamp(timeSec - st.lastTimeSec, 0.0, 0.05) : 0.016;
    st.lastTimeSec = timeSec;

    var mode = d.gameMode || 0;
    var themeNames = ['nfsMostWanted', 'neonCyber', 'f1PitWall', 'retroSynthwave'];
    var themeId = d.themeId || themeNames[d.visualTheme || 0] || 'nfsMostWanted';
    var isDark = d.isDark !== false;
    var vehicleType = d.vehicleType || 0;
    var cameraPreset = d.cameraPreset || 0;
    var speedKmh = d.speedKmh || 0;
    var steer = d.steerVisual || 0;
    var nitroActive = !!d.nitroActive;
    var isBraking = !!d.isBraking;
    var isGarageOpen = !!d.isGarageOpen;
    var playerX = d.playerX || 0;
    var playerZ = d.playerZ || 0;

    st.lastSyncMode = mode;

    var accentCol = parseHexColor(d.accentHex || 0xf59e0b);
    var secCol = parseHexColor(d.secondaryHex || 0x38bdf8);
    var skyTopCol = parseHexColor(d.skyTopHex || 0x282420);
    var groundCol = parseHexColor(d.groundNearHex || 0x14110d);
    var aspACol = parseHexColor(d.asphaltAHex || 0x222428);
    var aspBCol = parseHexColor(d.asphaltBHex || 0x282b30);
    var kerbACol = parseHexColor(d.kerbAHex || 0xd97706);
    var kerbBCol = parseHexColor(d.kerbBHex || 0xe5e7eb);
    var carBodyCol = parseHexColor(d.carBodyHex || 0xd1d5db);

    var isMw = themeId === 'nfsMostWanted';
    var isF1 = themeId === 'f1PitWall';
    var isSynth = themeId === 'retroSynthwave';
    var isNeon = themeId === 'neonCyber';

    // Rebuild theme atmosphere & PMREM specular reflections when theme changes
    var themeKey = themeId + '_' + isDark + '_' + d.accentHex + '_' + d.secondaryHex;
    if (st.lastThemeKey !== themeKey) {
      st.lastThemeKey = themeKey;
      var skyTex = createSkyDomeTexture(themeId, isDark);
      st.skyDomeMat.map = skyTex;
      st.skyDomeMat.needsUpdate = true;

      if (!st.envCache[themeId + '_' + isDark]) {
        st.envCache[themeId + '_' + isDark] = buildPMREMEnvironment(st.renderer, skyTex);
      }
      st.scene.environment = st.envCache[themeId + '_' + isDark];

      var fogCol = isMw
        ? (isDark ? 0xa96528 : 0xdba052)
        : (isSynth ? 0x3b0764 : d.skyTopHex);
      st.scene.background.setHex(fogCol);
      st.scene.fog.color.setHex(fogCol);
      st.scene.fog.density = isMw ? 0.0018 : (mode === 1 ? 0.0014 : 0.0020);
      st.groundMat.color.copy(groundCol);
      st.gridHelper.visible = isSynth || isNeon;

      if (isMw) {
        st.hemiLight.color.setHex(0xffcb7d);
        st.hemiLight.groundColor.setHex(0x2d2217);
        st.dirLight.color.setHex(0xffcf88);
        st.dirLight.intensity = 1.65;
        st.sunSprite.material.color.setHex(0xffd27d);
      } else {
        st.hemiLight.color.copy(secCol);
        st.hemiLight.groundColor.copy(groundCol);
        st.dirLight.color.setHex(0xffffff);
        st.dirLight.intensity = 1.15;
        st.sunSprite.material.color.copy(isSynth ? new THREE.Color(0xfde047) : accentCol);
      }

      st.sunSprite.visible = !isF1;
      st.starField.visible = isDark && (isNeon || isSynth);
      st.mtnMat.color.setHex(isMw ? 0x2c2016 : (isDark ? 0x070b19 : 0x64748b));
      st.bldgMat.map = createBuildingFacadeTexture(d.accentHex, d.secondaryHex, isDark, themeId);
      st.bldgMat.needsUpdate = true;

      for (var vk = 0; vk < 5; vk++) {
        var pv = st.playerVehicles[vk];
        if (vk !== 3) {
          pv.bodyMat.color.copy(carBodyCol);
        }
        pv.trimMat.color.copy(accentCol);
        pv.trimMat.emissive.copy(accentCol);
      }
    }

    // Update impact sparks
    for (var spi = 0; spi < st.sparkPool.length; spi++) {
      var sp = st.sparkPool[spi];
      if (sp.life > 0) {
        sp.life -= dt;
        sp.vy -= 26.0 * dt;
        sp.mesh.position.x += sp.vx * dt;
        sp.mesh.position.y += sp.vy * dt;
        sp.mesh.position.z += sp.vz * dt;
        if (sp.mesh.position.y < 0.1) {
          sp.mesh.position.y = 0.1;
          sp.vy = Math.abs(sp.vy) * 0.4;
        }
        sp.mat.opacity = clamp(sp.life / sp.maxLife, 0, 1);
        if (sp.life <= 0) sp.mesh.visible = false;
      }
    }

    // Update tire drift smoke sprites
    for (var smi = 0; smi < st.smokePool.length; smi++) {
      var sm = st.smokePool[smi];
      if (sm.life > 0) {
        sm.life -= dt;
        sm.sprite.position.x += sm.vx * dt;
        sm.sprite.position.y += sm.vy * dt;
        sm.sprite.position.z += sm.vz * dt;
        var prog = 1.0 - sm.life / sm.maxLife;
        var sScale = 1.2 + prog * 3.4;
        sm.sprite.scale.set(sScale, sScale, 1);
        sm.mat.opacity = (1.0 - prog) * 0.45;
        if (sm.life <= 0) sm.sprite.visible = false;
      }
    }

    // Update autumn leaves (visible in NFS Most Wanted mode!)
    var showLeaves = isMw && mode !== 1;
    for (var lfi = 0; lfi < st.leafPool.length; lfi++) {
      var lf = st.leafPool[lfi];
      lf.mesh.visible = showLeaves;
      if (showLeaves) {
        lf.mesh.position.x += lf.vx * dt;
        lf.mesh.position.y += lf.vy * dt;
        lf.mesh.position.z += (speedKmh * 0.16 + 4.0) * dt;
        lf.mesh.rotation.x += lf.spin * dt;
        lf.mesh.rotation.y += lf.spin * 0.7 * dt;
        if (lf.mesh.position.z > 12 || lf.mesh.position.y < 0.1) {
          lf.mesh.position.set(
            playerX * ROAD_HALF_W + (Math.random() - 0.5) * 28,
            1.8 + Math.random() * 5.2,
            -25 - Math.random() * 65
          );
        }
      }
    }

    // Update N2O Speed Tunnel Streaks
    var showStreaks = (nitroActive || speedKmh > 245) && mode === 0;
    st.streakMat.opacity = nitroActive ? 0.55 : 0.25;
    for (var sti = 0; sti < st.streakPool.length; sti++) {
      var strk = st.streakPool[sti];
      strk.visible = showStreaks;
      if (showStreaks) {
        strk.userData.zOff += (speedKmh * 0.35 + 35) * dt;
        if (strk.userData.zOff > 12) strk.userData.zOff = -32;
        var ang = strk.userData.angle;
        var rad = strk.userData.r;
        strk.position.set(
          st.camera.position.x + Math.cos(ang) * rad,
          st.camera.position.y + Math.sin(ang) * (rad * 0.55),
          strk.userData.zOff
        );
      }
    }

    // Arrival wave animation
    if ((d.arrivalEventSeq || 0) !== st.lastArrivalSeq) {
      st.lastArrivalSeq = d.arrivalEventSeq || 0;
      st.arrivalWaveTimer = 1.1;
    }
    if (st.arrivalWaveTimer > 0) {
      st.arrivalWaveTimer = Math.max(0, st.arrivalWaveTimer - dt);
      var wp = 1.0 - st.arrivalWaveTimer / 1.1;
      var sc = 1.0 + wp * 9.5;
      st.arrivalWave.scale.set(sc, sc, 1);
      st.arrivalWaveMat.opacity = (1.0 - wp) * 0.78;
      st.arrivalWave.visible = true;
    } else {
      st.arrivalWave.visible = false;
    }

    // Activate selected 3D player vehicle
    var activePV = st.playerVehicles[vehicleType] || st.playerVehicles[0];
    for (var pvi = 0; pvi < 5; pvi++) {
      st.playerVehicles[pvi].root.visible = pvi === vehicleType;
    }

    // Animate player vehicle parts
    var wheelSpin = speedKmh * 0.12 * dt;
    for (var wi = 0; wi < activePV.wheels.length; wi++) {
      activePV.wheels[wi].rotation.x -= wheelSpin;
    }
    activePV.tailMat.color.setHex(isBraking ? 0xff1e42 : 0x991b1b);
    activePV.flameMat.color.setHex(nitroActive ? 0x00f0ff : 0xff8a1f);
    var showFlame = speedKmh > 25 || nitroActive;
    for (var fli = 0; fli < activePV.flames.length; fli++) {
      var fl = activePV.flames[fli];
      fl.visible = showFlame;
      if (showFlame) {
        var fScale = (nitroActive ? 1.65 : 0.72) + 0.32 * Math.sin(timeSec * 62 + fli);
        fl.scale.set(1, 1, fScale);
      }
    }
    if (activePV.wingMesh) {
      activePV.wingMesh.rotation.x = speedKmh > 220 || nitroActive ? -0.22 : 0.0;
    }
    if (activePV.policeBar) {
      var pFlip = Math.floor(timeSec * 12) % 2 === 0;
      activePV.policeBar.left.color.setHex(pFlip ? 0xff1e42 : 0x450a0a);
      activePV.policeBar.right.color.setHex(pFlip ? 0x172554 : 0x3b82f6);
    }

    var flashHit = !!d.collisionFlash;
    activePV.shieldRing.material.opacity = flashHit ? 0.75 : 0.0;
    activePV.shieldRing.scale.setScalar(flashHit ? 1.08 : 1.0);
    st.underGlowLight.color.setHex(flashHit ? 0xff3b5c : (nitroActive ? 0x00f0ff : d.accentHex));

    // Spawn drift tire smoke when cornering hard or braking hard
    st.smokeSpawnTimer -= dt;
    if ((Math.abs(steer) > 0.38 || isBraking) && speedKmh > 85 && vehicleType !== 4 && st.smokeSpawnTimer <= 0) {
      st.smokeSpawnTimer = 0.045;
      var pxBase = mode === 1 ? (d.paddockX || 0) * PADDOCK_SCALE : playerX * ROAD_HALF_W;
      var pzBase = mode === 1 ? (d.paddockY || 0) * PADDOCK_SCALE : 1.8;
      spawnSmoke(st, pxBase - 1.2, 0.35, pzBase);
      spawnSmoke(st, pxBase + 1.2, 0.35, pzBase);
    }

    // =========================================================================
    // MODE 1: OPEN-WORLD 3D PADDOCK (ROCKPORT INDUSTRIAL YARD)
    // =========================================================================
    if (mode === 1) {
      st.circuitGroup.visible = false;
      st.paddockGroup.visible = true;
      st.sunSprite.visible = false;
      st.mtnGroup.visible = false;
      st.policeFlashLight.intensity = 0;

      var px = (d.paddockX || 0) * PADDOCK_SCALE;
      var pz = (d.paddockY || 0) * PADDOCK_SCALE;
      var heading = d.paddockHeading || 0;
      var hoverY = vehicleType === 4 ? 0.35 + Math.sin(timeSec * 6.0) * 0.14 : 0.0;

      activePV.root.position.set(px, hoverY, pz);
      activePV.root.rotation.set(0, -heading, vehicleType === 2 ? -steer * 0.35 : -steer * 0.05);
      st.underGlowLight.position.set(px, 1.2, pz);
      st.arrivalWave.position.set(px, 0.14, pz);

      if (driverTexture && st.monPortraitMat.map !== driverTexture) {
        st.monPortraitMat.map = driverTexture;
        st.monPortraitMat.needsUpdate = true;
      }
      st.monPortraitDisc.rotation.y = timeSec * 0.55;

      for (var si = 0; si < st.paddockSectorMeshes.length; si++) {
        var sm2 = st.paddockSectorMeshes[si];
        var signChild = sm2.children[3];
        if (signChild) {
          signChild.lookAt(
            st.camera.position.x,
            signChild.getWorldPosition(new THREE.Vector3()).y,
            st.camera.position.z
          );
        }
      }
      for (var pi = 0; pi < st.paddockPortalMeshes.length; pi++) {
        var pm = st.paddockPortalMeshes[pi];
        if (pm.children[1]) pm.children[1].lookAt(st.camera.position);
      }

      if (d.gpsX != null && d.gpsY != null) {
        st.gpsBeacon.visible = true;
        st.gpsBeacon.position.set(d.gpsX * PADDOCK_SCALE, 13, d.gpsY * PADDOCK_SCALE);
      } else {
        st.gpsBeacon.visible = false;
      }

      var pRivals = d.paddockRivals || [];
      for (var ri = 0; ri < st.opponentPool.length; ri++) {
        var variants = st.opponentPool[ri];
        for (var k = 0; k < 3; k++) variants[k].visible = false;
        if (ri < pRivals.length) {
          var rv = pRivals[ri];
          var rMesh = variants[rv.kind || 0];
          rMesh.visible = true;
          rMesh.position.set(rv.x * PADDOCK_SCALE, 0, rv.y * PADDOCK_SCALE);
          rMesh.rotation.set(0, -(rv.heading || 0), 0);
          rMesh.userData.bodyMat.emissive.setHex(rv.hit ? 0xff1e42 : 0x000000);
          rMesh.userData.bodyMat.emissiveIntensity = rv.hit ? 0.75 : 0.0;
          if (rMesh.userData.policeLights) {
            var pFl = Math.floor(timeSec * 12 + ri) % 2 === 0;
            rMesh.userData.policeLights.red.color.setHex(pFl ? 0xff1e42 : 0x450a0a);
            rMesh.userData.policeLights.blue.color.setHex(pFl ? 0x172554 : 0x3b82f6);
          }
        }
      }

      for (var ci = 0; ci < st.orbPool.length; ci++) {
        st.orbPool[ci].visible = false;
      }

      if ((d.collisionEventSeq || 0) !== st.lastCollisionSeq) {
        st.lastCollisionSeq = d.collisionEventSeq || 0;
        var sx = d.impactWorldX != null ? d.impactWorldX * PADDOCK_SCALE : px;
        var sz = d.impactWorldY != null ? d.impactWorldY * PADDOCK_SCALE : pz;
        spawnSparks(st, sx, 0.9, sz, 1.0);
      }

      var fwdX = Math.sin(heading);
      var fwdZ = -Math.cos(heading);
      if (isGarageOpen) {
        var ga = timeSec * 0.85;
        st.camPos.set(px + Math.cos(ga) * 9.5, 3.6, pz + Math.sin(ga) * 9.5);
        st.camLook.set(px, 1.0, pz);
      } else {
        var desiredCam = new THREE.Vector3(px - fwdX * 19.0, 14.5, pz - fwdZ * 19.0);
        st.camPos.lerp(desiredCam, 0.14);
        st.camLook.set(px + fwdX * 10.0, 1.0, pz + fwdZ * 10.0);
      }
      st.camera.position.copy(st.camPos);
      st.camera.lookAt(st.camLook);
      st.camera.fov = lerp(st.camera.fov, nitroActive ? 68 : 60, 0.1);
      st.camera.updateProjectionMatrix();

      st.dirLight.position.set(px + 25, 45, pz - 35);
      st.dirLight.target.position.set(px, 0, pz);
      st.dirLight.target.updateMatrixWorld();

      st.renderer.render(st.scene, st.camera);
      return;
    }

    // =========================================================================
    // MODE 0 (3D HORIZON) & MODE 2 (HIGHWAY)
    // =========================================================================
    st.circuitGroup.visible = true;
    st.paddockGroup.visible = false;
    st.sunSprite.visible = mode === 0 && !isF1;
    st.mtnGroup.visible = mode === 0;

    var segs = st.segments;
    var totalSegs = segs.length;
    if (totalSegs === 0) return;

    var normZ = ((playerZ % st.trackLen) + st.trackLen) % st.trackLen;
    var baseIdx = Math.floor(normZ / SEG_LEN_DART) % totalSegs;
    var basePct = (normZ % SEG_LEN_DART) / SEG_LEN_DART;

    var baseSeg = segs[baseIdx];
    var nextSeg = segs[(baseIdx + 1) % totalSegs];
    var isHighway = mode === 2;
    var curveScale = isHighway ? 0.0 : 0.16;
    var hillScale = isHighway ? 0.0 : 0.0085;
    var zStepMeters = isHighway ? 2.716 : 8.0;
    var carRefZOffset = isHighway ? 0.0 : 110.0;

    var playerElevY = (baseSeg.y + (nextSeg.y - baseSeg.y) * basePct) * hillScale;

    var sliceX = new Float32Array(TOTAL_SLICES);
    var sliceY = new Float32Array(TOTAL_SLICES);
    var sliceZ = new Float32Array(TOTAL_SLICES);
    var sliceHeading = new Float32Array(TOTAL_SLICES);
    var sliceSegIdx = new Int32Array(TOTAL_SLICES);

    var fSlope = 0.0;
    var fX = 0.0;
    var bSlope = 0.0;
    var bX = 0.0;

    var seg0Curve = baseSeg.curve * curveScale;
    bSlope -= seg0Curve * basePct * 0.5;
    bX -= bSlope * basePct;
    bSlope -= seg0Curve * basePct * 0.5;

    sliceX[SLICE_BACK] = bX;
    sliceY[SLICE_BACK] = baseSeg.y * hillScale - playerElevY;
    sliceZ[SLICE_BACK] = -((-basePct * SEG_LEN_DART - carRefZOffset) * (zStepMeters / SEG_LEN_DART));
    sliceSegIdx[SLICE_BACK] = baseIdx;

    for (var bi2 = 1; bi2 <= SLICE_BACK; bi2++) {
      var bSegIdx = (baseIdx - bi2 + totalSegs) % totalSegs;
      var bSeg = segs[bSegIdx];
      var bc = bSeg.curve * curveScale;
      bSlope -= bc * 0.5;
      bX -= bSlope;
      bSlope -= bc * 0.5;
      var arrI = SLICE_BACK - bi2;
      sliceX[arrI] = bX;
      sliceY[arrI] = bSeg.y * hillScale - playerElevY;
      sliceZ[arrI] = -(((-bi2 - basePct) * SEG_LEN_DART - carRefZOffset) * (zStepMeters / SEG_LEN_DART));
      sliceSegIdx[arrI] = bSegIdx;
    }

    var fFrac = 1.0 - basePct;
    fSlope += seg0Curve * fFrac * 0.5;
    fX += fSlope * fFrac;
    fSlope += seg0Curve * fFrac * 0.5;
    var idx1 = (baseIdx + 1) % totalSegs;
    sliceX[SLICE_BACK + 1] = fX;
    sliceY[SLICE_BACK + 1] = nextSeg.y * hillScale - playerElevY;
    sliceZ[SLICE_BACK + 1] = -(((1.0 - basePct) * SEG_LEN_DART - carRefZOffset) * (zStepMeters / SEG_LEN_DART));
    sliceSegIdx[SLICE_BACK + 1] = idx1;

    for (var fi2 = 2; fi2 <= SLICE_AHEAD; fi2++) {
      var prevFIdx = (baseIdx + fi2 - 1) % totalSegs;
      var fIdx = (baseIdx + fi2) % totalSegs;
      var prevFSeg = segs[prevFIdx];
      var fSeg = segs[fIdx];
      var fc = prevFSeg.curve * curveScale;
      fSlope += fc * 0.5;
      fX += fSlope;
      fSlope += fc * 0.5;
      var sIdx = SLICE_BACK + fi2;
      sliceX[sIdx] = fX;
      sliceY[sIdx] = fSeg.y * hillScale - playerElevY;
      sliceZ[sIdx] = -(((fi2 - basePct) * SEG_LEN_DART - carRefZOffset) * (zStepMeters / SEG_LEN_DART));
      sliceSegIdx[sIdx] = fIdx;
    }

    for (var ti = 0; ti < TOTAL_SLICES; ti++) {
      var tiA = Math.max(0, ti - 1);
      var tiB = Math.min(TOTAL_SLICES - 1, ti + 1);
      sliceHeading[ti] = Math.atan2(-(sliceX[tiB] - sliceX[tiA]), -(sliceZ[tiB] - sliceZ[tiA]));
    }

    function sampleRoad(relZ) {
      var relSegPos = relZ / SEG_LEN_DART + basePct + SLICE_BACK;
      var idx = Math.floor(relSegPos);
      if (idx < 0) idx = 0;
      if (idx >= TOTAL_SLICES - 1) idx = TOTAL_SLICES - 2;
      var frac = clamp(relSegPos - idx, 0, 1);
      return {
        x: lerp(sliceX[idx], sliceX[idx + 1], frac),
        y: lerp(sliceY[idx], sliceY[idx + 1], frac),
        z: lerp(sliceZ[idx], sliceZ[idx + 1], frac),
        yaw: lerp(sliceHeading[idx], sliceHeading[idx + 1], frac),
      };
    }

    // Update Road, Kerb, Concrete Wall, & Valley Shoulder Vertex Buffers
    var rVerts = st.roadRibbon.verts;
    var rCols = st.roadRibbon.colors;
    var rUvs = st.roadRibbon.uvs;
    var lkVerts = st.leftKerbRibbon.verts;
    var lkCols = st.leftKerbRibbon.colors;
    var rkVerts = st.rightKerbRibbon.verts;
    var rkCols = st.rightKerbRibbon.colors;
    var lwVerts = st.leftWallRibbon.verts;
    var lwCols = st.leftWallRibbon.colors;
    var rwVerts = st.rightWallRibbon.verts;
    var rwCols = st.rightWallRibbon.colors;
    var lsVerts = st.leftShoulderRibbon.verts;
    var lsCols = st.leftShoulderRibbon.colors;
    var rsVerts = st.rightShoulderRibbon.verts;
    var rsCols = st.rightShoulderRibbon.colors;

    var wallColA = isMw ? new THREE.Color(0x52525b) : new THREE.Color(0x1e293b);
    var wallColB = isMw ? new THREE.Color(0x3f3f46) : new THREE.Color(0x0f172a);
    var shoulderCol = isMw ? new THREE.Color(0x3a2c1d) : groundCol;

    for (var si2 = 0; si2 < TOTAL_SLICES; si2++) {
      var sx = sliceX[si2];
      var sy = sliceY[si2];
      var sz = sliceZ[si2];
      var segI = sliceSegIdx[si2];
      var band = Math.floor(segI / 3) % 2 === 0;
      var rc = isMw ? new THREE.Color(0xffffff) : (band ? aspACol : aspBCol);
      var kBand = Math.floor(segI / 2) % 2 === 0;
      var kc = kBand ? kerbACol : kerbBCol;
      var wc = kBand ? wallColA : wallColB;

      var vOff = si2 * 6;
      var uOff = si2 * 4;

      rVerts[vOff] = sx - ROAD_HALF_W;
      rVerts[vOff + 1] = sy;
      rVerts[vOff + 2] = sz;
      rVerts[vOff + 3] = sx + ROAD_HALF_W;
      rVerts[vOff + 4] = sy;
      rVerts[vOff + 5] = sz;

      // Seamless periodic UV scrolling tied directly to segment index!
      var vCoord = ((baseIdx % 2) + (si2 - SLICE_BACK)) * 0.5;
      rUvs[uOff] = 0.0;
      rUvs[uOff + 1] = vCoord;
      rUvs[uOff + 2] = 1.0;
      rUvs[uOff + 3] = vCoord;

      rCols[vOff] = rc.r;
      rCols[vOff + 1] = rc.g;
      rCols[vOff + 2] = rc.b;
      rCols[vOff + 3] = rc.r;
      rCols[vOff + 4] = rc.g;
      rCols[vOff + 5] = rc.b;

      lkVerts[vOff] = sx - ROAD_HALF_W - KERB_W;
      lkVerts[vOff + 1] = sy;
      lkVerts[vOff + 2] = sz;
      lkVerts[vOff + 3] = sx - ROAD_HALF_W;
      lkVerts[vOff + 4] = sy;
      lkVerts[vOff + 5] = sz;

      rkVerts[vOff] = sx + ROAD_HALF_W;
      rkVerts[vOff + 1] = sy;
      rkVerts[vOff + 2] = sz;
      rkVerts[vOff + 3] = sx + ROAD_HALF_W + KERB_W;
      rkVerts[vOff + 4] = sy;
      rkVerts[vOff + 5] = sz;

      // Raised Concrete Jersey Side Walls
      var wallX = ROAD_HALF_W + KERB_W + 0.15;
      lwVerts[vOff] = sx - wallX;
      lwVerts[vOff + 1] = sy + WALL_H;
      lwVerts[vOff + 2] = sz;
      lwVerts[vOff + 3] = sx - wallX;
      lwVerts[vOff + 4] = sy;
      lwVerts[vOff + 5] = sz;

      rwVerts[vOff] = sx + wallX;
      rwVerts[vOff + 1] = sy;
      rwVerts[vOff + 2] = sz;
      rwVerts[vOff + 3] = sx + wallX;
      rwVerts[vOff + 4] = sy + WALL_H;
      rwVerts[vOff + 5] = sz;

      // Grounded Autumn / Terrain Shoulders
      lsVerts[vOff] = sx - wallX - SHOULDER_W;
      lsVerts[vOff + 1] = sy - 1.2;
      lsVerts[vOff + 2] = sz;
      lsVerts[vOff + 3] = sx - wallX;
      lsVerts[vOff + 4] = sy;
      lsVerts[vOff + 5] = sz;

      rsVerts[vOff] = sx + wallX;
      rsVerts[vOff + 1] = sy;
      rsVerts[vOff + 2] = sz;
      rsVerts[vOff + 3] = sx + wallX + SHOULDER_W;
      rsVerts[vOff + 4] = sy - 1.2;
      rsVerts[vOff + 5] = sz;

      for (var cOff = 0; cOff < 6; cOff += 3) {
        lkCols[vOff + cOff] = kc.r;
        lkCols[vOff + cOff + 1] = kc.g;
        lkCols[vOff + cOff + 2] = kc.b;
        rkCols[vOff + cOff] = kc.r;
        rkCols[vOff + cOff + 1] = kc.g;
        rkCols[vOff + cOff + 2] = kc.b;

        lwCols[vOff + cOff] = wc.r;
        lwCols[vOff + cOff + 1] = wc.g;
        lwCols[vOff + cOff + 2] = wc.b;
        rwCols[vOff + cOff] = wc.r;
        rwCols[vOff + cOff + 1] = wc.g;
        rwCols[vOff + cOff + 2] = wc.b;

        lsCols[vOff + cOff] = shoulderCol.r;
        lsCols[vOff + cOff + 1] = shoulderCol.g;
        lsCols[vOff + cOff + 2] = shoulderCol.b;
        rsCols[vOff + cOff] = shoulderCol.r;
        rsCols[vOff + cOff + 1] = shoulderCol.g;
        rsCols[vOff + cOff + 2] = shoulderCol.b;
      }
    }

    st.roadRibbon.geo.attributes.position.needsUpdate = true;
    st.roadRibbon.geo.attributes.color.needsUpdate = true;
    st.roadRibbon.geo.attributes.uv.needsUpdate = true;
    st.leftKerbRibbon.geo.attributes.position.needsUpdate = true;
    st.leftKerbRibbon.geo.attributes.color.needsUpdate = true;
    st.rightKerbRibbon.geo.attributes.position.needsUpdate = true;
    st.rightKerbRibbon.geo.attributes.color.needsUpdate = true;
    st.leftWallRibbon.geo.attributes.position.needsUpdate = true;
    st.leftWallRibbon.geo.attributes.color.needsUpdate = true;
    st.rightWallRibbon.geo.attributes.position.needsUpdate = true;
    st.rightWallRibbon.geo.attributes.color.needsUpdate = true;
    st.leftShoulderRibbon.geo.attributes.position.needsUpdate = true;
    st.leftShoulderRibbon.geo.attributes.color.needsUpdate = true;
    st.rightShoulderRibbon.geo.attributes.position.needsUpdate = true;
    st.rightShoulderRibbon.geo.attributes.color.needsUpdate = true;

    // Place Lane Dashes, Boost Pads, Tunnel Arches, Roadside Props, Billboards, Gantries
    var dashIdx = 0;
    var boostIdx = 0;
    var archIdx = 0;
    var propIdx = 0;
    var bbIdx = 0;
    var ganIdx = 0;
    st.finishGroup.visible = false;

    for (var sLoop = 1; sLoop < TOTAL_SLICES - 2; sLoop++) {
      var segObj = segs[sliceSegIdx[sLoop]];
      var xC = sliceX[sLoop];
      var yC = sliceY[sLoop];
      var zC = sliceZ[sLoop];
      var yawC = sliceHeading[sLoop];

      if (segObj.isCheckered && segObj.index === 0) {
        st.finishGroup.visible = true;
        st.finishGroup.position.set(xC, yC + 0.04, zC);
        st.finishGroup.rotation.y = yawC;
      }

      if (Math.floor(segObj.index / 2) % 2 === 0 && dashIdx + 1 < st.dashPool.length) {
        for (var lLane = -1; lLane <= 1; lLane += 2) {
          var dm = st.dashPool[dashIdx++];
          dm.visible = true;
          dm.position.set(xC + lLane * ROAD_HALF_W * 0.33, yC + 0.04, zC);
          dm.rotation.y = yawC;
        }
      }

      if (segObj.boostLane != null && boostIdx < st.boostPadPool.length) {
        var bm = st.boostPadPool[boostIdx++];
        bm.visible = true;
        bm.position.set(xC + segObj.boostLane * ROAD_HALF_W, yC + 0.06, zC);
        bm.rotation.y = yawC;
      }

      if (segObj.isTunnelZone && segObj.index % 4 === 0 && archIdx < st.archPool.length) {
        var agItem = st.archPool[archIdx++];
        agItem.group.visible = true;
        agItem.group.position.set(xC, yC, zC);
        agItem.group.rotation.y = yawC;
      }

      if (segObj.hasLightPylon && !isHighway && propIdx + 1 < st.propPool.length) {
        for (var side = -1; side <= 1; side += 2) {
          var pr = st.propPool[propIdx++];
          pr.group.visible = true;
          pr.group.position.set(xC + side * (ROAD_HALF_W + 2.8), yC, zC);
          pr.group.rotation.y = yawC;

          pr.palm.visible = isSynth;
          pr.tree.visible = isMw || isF1;
          pr.tree.position.x = side * 4.5;
          pr.pole.visible = !isSynth;
          pr.arm.visible = !isSynth;
          pr.arm.position.x = side * -1.2;
          pr.lamp.visible = !isSynth;
          pr.lamp.position.x = side * -2.3;
          pr.lampMat.color.setHex(isMw ? 0xffb347 : (segObj.index % 16 === 0 ? d.accentHex : d.secondaryHex));

          var showTower = (isMw || isNeon) && (segObj.index % 16 === 0);
          pr.bldg.visible = showTower;
          pr.bldg.position.x = side * 16.0;
          pr.bldg.scale.y = 0.7 + ((segObj.index * 7 + (side > 0 ? 3 : 1)) % 5) * 0.25;
        }
      }

      if (!isHighway && (segObj.leftBillboard || segObj.rightBillboard) && bbIdx < st.billboardPool.length) {
        var specs = [];
        if (segObj.leftBillboard) specs.push({ spec: segObj.leftBillboard, side: -1 });
        if (segObj.rightBillboard) specs.push({ spec: segObj.rightBillboard, side: 1 });
        for (var bsi = 0; bsi < specs.length && bbIdx < st.billboardPool.length; bsi++) {
          var item = specs[bsi];
          var bPool = st.billboardPool[bbIdx++];
          bPool.group.visible = true;
          bPool.group.position.set(xC + item.side * (ROAD_HALF_W + 7.2), yC, zC);
          bPool.group.rotation.y = yawC + item.side * -0.18;
          bPool.frameMat.color.copy(item.spec.sec ? secCol : accentCol);
          var hasPhoto = !!(item.spec.photo && driverTexture && driverTexture.image);
          bPool.bMat.map = makeTextTexture(
            st.texCache,
            'bb_' + themeId + '_' + item.spec.title + '_' + item.spec.tag + '_' + (hasPhoto ? 'p1' : 'p0'),
            512,
            256,
            function (ctx, w, h) {
              ctx.fillStyle = isMw ? '#141311' : '#070c1c';
              ctx.fillRect(0, 0, w, h);
              ctx.fillStyle = isMw ? 'rgba(245, 158, 11, 0.25)' : 'rgba(0, 240, 255, 0.20)';
              ctx.fillRect(0, 0, w, 58);
              ctx.fillStyle = isMw ? '#f59e0b' : '#00f0ff';
              ctx.font = 'bold 26px Rajdhani, sans-serif';
              ctx.fillText(item.spec.tag, 26, 40);
              var tx = 26;
              if (hasPhoto) {
                ctx.save();
                ctx.beginPath();
                ctx.arc(82, 154, 54, 0, Math.PI * 2);
                ctx.closePath();
                ctx.clip();
                ctx.drawImage(driverTexture.image, 28, 100, 108, 108);
                ctx.restore();
                ctx.strokeStyle = isMw ? '#f59e0b' : '#00f0ff';
                ctx.lineWidth = 4;
                ctx.beginPath();
                ctx.arc(82, 154, 54, 0, Math.PI * 2);
                ctx.stroke();
                tx = 154;
              }
              ctx.fillStyle = '#ffffff';
              ctx.font = 'bold 42px Rajdhani, sans-serif';
              ctx.fillText(item.spec.title, tx, 134);
              ctx.fillStyle = '#cbd5e1';
              ctx.font = 'bold 24px Rajdhani, sans-serif';
              ctx.fillText(item.spec.sub, tx, 192);
            }
          );
          bPool.bMat.needsUpdate = true;
        }
      }

      if (segObj.gantryTitle && ganIdx < st.gantryPool.length) {
        var gObj = st.gantryPool[ganIdx++];
        gObj.group.visible = true;
        gObj.group.position.set(xC, yC, zC);
        gObj.group.rotation.y = yawC;
        gObj.holoDiamond.rotation.y = timeSec * 1.8;
        gObj.holoDiamond.position.y = 13.8 + Math.sin(timeSec * 3.5) * 0.65;
        var gDest = segObj.gantryDest || segObj.gantryCode || 'SECTOR';
        gObj.signMat.map = makeTextTexture(
          st.texCache,
          'gan_' + themeId + '_' + gDest + '_' + segObj.gantryTitle,
          768,
          160,
          function (ctx, w, h) {
            ctx.fillStyle = isMw ? '#064e3b' : '#071022';
            ctx.fillRect(0, 0, w, h);
            ctx.strokeStyle = isMw ? '#f8fafc' : '#00f0ff';
            ctx.lineWidth = 6;
            ctx.strokeRect(4, 4, w - 8, h - 8);
            ctx.fillStyle = isMw ? '#fde047' : '#00f0ff';
            ctx.font = 'bold 34px Rajdhani, sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText((isMw ? 'ROCKPORT EXIT // ' : 'HOLO-GATE // ') + gDest, w / 2, 54);
            ctx.fillStyle = '#ffffff';
            ctx.font = 'bold 48px Rajdhani, sans-serif';
            ctx.fillText(segObj.gantryTitle, w / 2, 122);
          }
        );
        gObj.signMat.needsUpdate = true;
      }
    }

    while (dashIdx < st.dashPool.length) st.dashPool[dashIdx++].visible = false;
    while (boostIdx < st.boostPadPool.length) st.boostPadPool[boostIdx++].visible = false;
    while (archIdx < st.archPool.length) st.archPool[archIdx++].group.visible = false;
    while (propIdx < st.propPool.length) st.propPool[propIdx++].group.visible = false;
    while (bbIdx < st.billboardPool.length) st.billboardPool[bbIdx++].group.visible = false;
    while (ganIdx < st.gantryPool.length) st.gantryPool[ganIdx++].group.visible = false;

    // Position Player Vehicle
    var playerWorldX = playerX * ROAD_HALF_W;
    var hoverOffset = vehicleType === 4 ? 0.35 + Math.sin(timeSec * 6.0) * 0.14 : 0.0;
    activePV.root.position.set(playerWorldX, hoverOffset, 0);
    var rollAngle = vehicleType === 2 ? -steer * 0.48 : -steer * 0.07;
    activePV.root.rotation.set(0, -steer * 0.16, rollAngle);
    st.underGlowLight.position.set(playerWorldX, 1.0, 0);
    st.arrivalWave.position.set(playerWorldX, 0.14, 0);

    // Position Opponents + Update Nearest Police Cruiser Light Reflection
    var cars = d.trafficCars || [];
    var nearestPoliceDist = 99999;
    var nearestPolicePos = null;

    for (var oci = 0; oci < st.opponentPool.length; oci++) {
      var oVariants = st.opponentPool[oci];
      for (var ok = 0; ok < 3; ok++) oVariants[ok].visible = false;
      if (oci < cars.length) {
        var c = cars[oci];
        var relZ = c.z - normZ;
        if (relZ < -st.trackLen * 0.5) relZ += st.trackLen;
        if (relZ > st.trackLen * 0.5) relZ -= st.trackLen;
        if (relZ > -450 && relZ < 17000) {
          var pose = sampleRoad(relZ);
          var cMesh = oVariants[c.kind || 0];
          cMesh.visible = true;
          cMesh.position.set(pose.x + c.lane * ROAD_HALF_W, pose.y, pose.z);
          cMesh.rotation.set(0, pose.yaw, -(c.recoil || 0) * 0.35);
          cMesh.userData.bodyMat.emissive.setHex(c.hit ? 0xff1e42 : 0x000000);
          cMesh.userData.bodyMat.emissiveIntensity = c.hit ? 0.78 : 0.0;

          if (cMesh.userData.policeLights) {
            var cFlip = Math.floor(timeSec * 12 + oci) % 2 === 0;
            cMesh.userData.policeLights.red.color.setHex(cFlip ? 0xff1e42 : 0x450a0a);
            cMesh.userData.policeLights.blue.color.setHex(cFlip ? 0x172554 : 0x3b82f6);
            if (relZ > -100 && relZ < nearestPoliceDist) {
              nearestPoliceDist = relZ;
              nearestPolicePos = cMesh.position;
            }
          }
        }
      }
    }

    if (nearestPolicePos && nearestPoliceDist < 4200) {
      var pBeat = Math.floor(timeSec * 12) % 2 === 0;
      st.policeFlashLight.position.set(nearestPolicePos.x, nearestPolicePos.y + 2.2, nearestPolicePos.z);
      st.policeFlashLight.color.setHex(pBeat ? 0xff1e42 : 0x3b82f6);
      st.policeFlashLight.intensity = 2.8;
    } else {
      st.policeFlashLight.intensity = 0;
    }

    // Position Static Roadblock Obstacles
    var obstacles = d.obstacles || [];
    for (var obsi = 0; obsi < st.obstaclePool.length; obsi++) {
      var obItem = st.obstaclePool[obsi];
      obItem.group.visible = false;
      if (obsi < obstacles.length) {
        var ob = obstacles[obsi];
        var oRelZ = ob.z - normZ;
        if (oRelZ < -st.trackLen * 0.5) oRelZ += st.trackLen;
        if (oRelZ > st.trackLen * 0.5) oRelZ -= st.trackLen;
        if (oRelZ > -350 && oRelZ < 15000) {
          var obPose = sampleRoad(oRelZ);
          obItem.group.visible = true;
          obItem.group.position.set(obPose.x + ob.lane * ROAD_HALF_W, obPose.y, obPose.z);
          obItem.group.rotation.y = obPose.yaw;
          var blinkEven = Math.floor(timeSec * 8) % 2 === 0;
          obItem.beaconMat.color.setHex(ob.hit ? 0xffffff : (blinkEven ? 0xff3b5c : 0xf59e0b));
          obItem.bodyMat.emissive.setHex(ob.hit ? 0xff3b5c : 0x000000);
          obItem.bodyMat.emissiveIntensity = ob.hit ? 0.8 : 0.0;
        }
      }
    }

    // Position Data Crystal Orbs
    var orbs = d.orbs || [];
    for (var ori = 0; ori < st.orbPool.length; ori++) {
      var om = st.orbPool[ori];
      om.visible = false;
      if (ori < orbs.length && !orbs[ori].collected) {
        var orb = orbs[ori];
        var orbRelZ = orb.z - normZ;
        if (orbRelZ < -st.trackLen * 0.5) orbRelZ += st.trackLen;
        if (orbRelZ > st.trackLen * 0.5) orbRelZ -= st.trackLen;
        if (orbRelZ > -250 && orbRelZ < 15000) {
          var orbPose = sampleRoad(orbRelZ);
          om.visible = true;
          om.position.set(
            orbPose.x + orb.lane * ROAD_HALF_W,
            orbPose.y + 1.05 + Math.sin(timeSec * 4.5 + ori) * 0.25,
            orbPose.z
          );
          om.rotation.y = timeSec * 2.6 + ori;
        }
      }
    }

    if ((d.collisionEventSeq || 0) !== st.lastCollisionSeq) {
      st.lastCollisionSeq = d.collisionEventSeq || 0;
      var ix = (d.impactLaneX != null ? d.impactLaneX : playerX) * ROAD_HALF_W;
      spawnSparks(st, ix, 0.9, -1.6, d.impactPushDir || 1.0);
    }

    // Dynamic NFS Camera Controller (Low-Slung Chase Cam + FOV Warp on Nitro!)
    var shakeX = d.shakeX || 0;
    var shakeY = d.shakeY || 0;
    var targetCamPos = new THREE.Vector3();
    var targetLook = new THREE.Vector3();
    var targetFov = nitroActive ? 78 : clamp(60 + (speedKmh / 350) * 7, 60, 68);

    if (isGarageOpen) {
      var gAng = timeSec * 0.85;
      targetCamPos.set(playerWorldX + Math.cos(gAng) * 8.4, 2.9, Math.sin(gAng) * 8.4);
      targetLook.set(playerWorldX, 0.85, 0);
      targetFov = 54;
    } else if (isHighway) {
      targetCamPos.set(0, 29.0, 9.5);
      targetLook.set(0, 0, -4.5);
      targetFov = 58;
    } else if (cameraPreset === 1) {
      var hoodPose = sampleRoad(1400);
      targetCamPos.set(playerWorldX, 1.72 + hoverOffset, -0.55);
      targetLook.set(lerp(playerWorldX, hoodPose.x, 0.35), 1.38 + hoodPose.y * 0.2, -32);
      targetFov = nitroActive ? 82 : 70;
    } else if (cameraPreset === 2) {
      var cAngle = steer * 0.45;
      targetCamPos.set(playerWorldX + Math.sin(cAngle) * 7.2, 3.0, Math.cos(cAngle) * 8.2);
      targetLook.set(playerWorldX * 0.6, 1.05, -24);
      targetFov = nitroActive ? 74 : 62;
    } else {
      // Iconic NFS Most Wanted Low-Slung Chase Cam
      var aheadPose = sampleRoad(1800);
      targetCamPos.set(playerWorldX * 0.80 - steer * 0.75, 3.35, 8.6);
      targetLook.set(lerp(playerWorldX * 0.55, aheadPose.x * 0.28, 0.5), 1.25 + aheadPose.y * 0.14, -36);
    }

    st.camPos.lerp(targetCamPos, isGarageOpen ? 0.14 : 0.24);
    st.camLook.lerp(targetLook, isGarageOpen ? 0.14 : 0.28);

    st.camera.position.set(
      st.camPos.x + shakeX * 0.055,
      st.camPos.y + shakeY * 0.055,
      st.camPos.z
    );
    st.camera.lookAt(st.camLook);
    st.camera.fov = lerp(st.camera.fov, targetFov, 0.12);
    st.camera.updateProjectionMatrix();

    st.sunSprite.position.set(sliceX[SLICE_AHEAD - 4] * 0.10 + 18, 56, -580);
    st.mtnGroup.rotation.y = (d.skyParallax || 0) * 0.03;

    st.dirLight.position.set(playerWorldX + 20, 32, -45);
    st.dirLight.target.position.set(playerWorldX, 0, -10);
    st.dirLight.target.updateMatrixWorld();

    st.renderer.render(st.scene, st.camera);
  };

  window.spnk3dRaycastPaddock = function (id, normX, normY) {
    var st = _instances[id];
    if (!st || st.lastSyncMode !== 1) return '';
    var raycaster = new THREE.Raycaster();
    var ndc = new THREE.Vector2(normX * 2 - 1, -(normY * 2 - 1));
    raycaster.setFromCamera(ndc, st.camera);
    var ground = new THREE.Plane(new THREE.Vector3(0, 1, 0), 0);
    var hitPt = new THREE.Vector3();
    if (raycaster.ray.intersectPlane(ground, hitPt)) {
      return (hitPt.x / PADDOCK_SCALE).toFixed(2) + ',' + (hitPt.z / PADDOCK_SCALE).toFixed(2);
    }
    return '';
  };

  window.spnk3dDispose = function (id) {
    var st = _instances[id];
    if (!st) return;
    if (st.resizeObserver) {
      try {
        st.resizeObserver.disconnect();
      } catch (e) {}
    }
    try {
      st.renderer.dispose();
    } catch (e) {}
    delete _instances[id];
  };
})();
