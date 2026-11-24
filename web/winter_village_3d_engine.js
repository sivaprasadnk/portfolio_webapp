(function () {
  'use strict';

  var _instances = {};
  var _nextId = 1;

  function clamp(v, min, max) {
    return v < min ? min : (v > max ? max : v);
  }

  function lerp(a, b, t) {
    return a + (b - a) * t;
  }

  function smoothstep(t) {
    t = clamp(t, 0, 1);
    return t * t * (3 - 2 * t);
  }

  function seededRand(seed) {
    var x = Math.sin(seed * 127.1 + 311.7) * 43758.5453123;
    return x - Math.floor(x);
  }

  function noise3(x, y, z, seed) {
    var s = seed || 1.0;
    return (
      Math.sin(x * 1.7 + s) * Math.cos(y * 1.9 - s * 0.7) * 0.5 +
      Math.sin(y * 2.3 + z * 1.6 + s * 1.3) * 0.3 +
      Math.cos(z * 2.9 - x * 1.4 + s * 2.1) * 0.2
    );
  }

  function displaceGeometry(geo, amp, freq, seed, biasTopSnow) {
    var pos = geo.attributes.position;
    for (var i = 0; i < pos.count; i++) {
      var vx = pos.getX(i);
      var vy = pos.getY(i);
      var vz = pos.getZ(i);
      var n = noise3(vx * freq, vy * freq, vz * freq, seed);
      var scale = 1.0 + n * amp;
      if (biasTopSnow && vy > 0) {
        scale += 0.08 * smoothstep(vy);
      }
      pos.setXYZ(i, vx * scale, vy * scale, vz * scale);
    }
    geo.computeVertexNormals();
    return geo;
  }

  window.spnkWinterIsAvailable = function () {
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

  function createSnowflakeTexture() {
    var c = document.createElement('canvas');
    c.width = 64;
    c.height = 64;
    var ctx = c.getContext('2d');
    var g = ctx.createRadialGradient(32, 32, 1, 32, 32, 30);
    g.addColorStop(0.0, 'rgba(255,255,255,1.0)');
    g.addColorStop(0.38, 'rgba(235,247,255,0.78)');
    g.addColorStop(1.0, 'rgba(255,255,255,0.0)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, 64, 64);
    var tex = new THREE.CanvasTexture(c);
    tex.needsUpdate = true;
    return tex;
  }

  function createGlowTexture(innerCss, midCss) {
    var c = document.createElement('canvas');
    c.width = 128;
    c.height = 128;
    var ctx = c.getContext('2d');
    var g = ctx.createRadialGradient(64, 64, 3, 64, 64, 62);
    g.addColorStop(0.0, innerCss);
    g.addColorStop(0.34, midCss);
    g.addColorStop(1.0, 'rgba(0,0,0,0)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, 128, 128);
    var tex = new THREE.CanvasTexture(c);
    tex.needsUpdate = true;
    return tex;
  }

  function createCloudPuffTexture() {
    var c = document.createElement('canvas');
    c.width = 256;
    c.height = 160;
    var ctx = c.getContext('2d');
    var blobs = [
      [128, 86, 62, 0.72],
      [82, 92, 48, 0.56],
      [174, 94, 46, 0.56],
      [108, 66, 44, 0.62],
      [152, 68, 42, 0.60],
      [54, 104, 34, 0.42],
      [204, 104, 34, 0.42],
    ];
    for (var i = 0; i < blobs.length; i++) {
      var b = blobs[i];
      var g = ctx.createRadialGradient(b[0], b[1], 4, b[0], b[1], b[2]);
      g.addColorStop(0.0, 'rgba(255,255,255,' + b[3] + ')');
      g.addColorStop(0.55, 'rgba(240,248,255,' + (b[3] * 0.45) + ')');
      g.addColorStop(1.0, 'rgba(255,255,255,0)');
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(b[0], b[1], b[2], 0, Math.PI * 2);
      ctx.fill();
    }
    var tex = new THREE.CanvasTexture(c);
    tex.needsUpdate = true;
    return tex;
  }

  function createSnowGroundTextures() {
    var albedoCanvas = document.createElement('canvas');
    albedoCanvas.width = 512;
    albedoCanvas.height = 512;
    var ctx = albedoCanvas.getContext('2d');
    ctx.fillStyle = '#ebf3fc';
    ctx.fillRect(0, 0, 512, 512);

    var bumpCanvas = document.createElement('canvas');
    bumpCanvas.width = 512;
    bumpCanvas.height = 512;
    var bctx = bumpCanvas.getContext('2d');
    bctx.fillStyle = '#808080';
    bctx.fillRect(0, 0, 512, 512);

    // Subtle wind-swept snow ripples + crystalline specular flecks
    for (var w = 0; w < 24; w++) {
      var y = w * 22;
      var grad = bctx.createLinearGradient(0, y, 0, y + 22);
      grad.addColorStop(0.0, 'rgba(155,155,155,0.45)');
      grad.addColorStop(0.5, 'rgba(110,110,110,0.45)');
      grad.addColorStop(1.0, 'rgba(155,155,155,0.45)');
      bctx.fillStyle = grad;
      bctx.fillRect(0, y, 512, 22);
    }

    for (var i = 0; i < 3200; i++) {
      var x = (seededRand(i * 1.13) * 512) | 0;
      var y2 = (seededRand(i * 2.71) * 512) | 0;
      var r = 0.8 + seededRand(i * 3.9) * 2.1;
      ctx.fillStyle =
        i % 5 === 0 ? 'rgba(255,255,255,0.92)' : 'rgba(195,219,244,0.22)';
      ctx.beginPath();
      ctx.arc(x, y2, r, 0, Math.PI * 2);
      ctx.fill();

      var bVal = i % 2 === 0 ? 175 : 95;
      bctx.fillStyle = 'rgba(' + bVal + ',' + bVal + ',' + bVal + ',0.32)';
      bctx.fillRect(x, y2, 2, 2);
    }

    var map = new THREE.CanvasTexture(albedoCanvas);
    map.wrapS = THREE.RepeatWrapping;
    map.wrapT = THREE.RepeatWrapping;
    map.repeat.set(18, 24);

    var bump = new THREE.CanvasTexture(bumpCanvas);
    bump.wrapS = THREE.RepeatWrapping;
    bump.wrapT = THREE.RepeatWrapping;
    bump.repeat.set(18, 24);

    return { map: map, bump: bump };
  }

  function createFurTextures() {
    var c = document.createElement('canvas');
    c.width = 256;
    c.height = 256;
    var ctx = c.getContext('2d');
    var bg = ctx.createLinearGradient(0, 0, 0, 256);
    bg.addColorStop(0.0, '#6c4930');
    bg.addColorStop(0.45, '#865c3e');
    bg.addColorStop(0.82, '#9e7556');
    bg.addColorStop(1.0, '#cbb7a2');
    ctx.fillStyle = bg;
    ctx.fillRect(0, 0, 256, 256);

    var bc = document.createElement('canvas');
    bc.width = 256;
    bc.height = 256;
    var bctx = bc.getContext('2d');
    bctx.fillStyle = '#808080';
    bctx.fillRect(0, 0, 256, 256);

    // Fine directional hair strokes
    for (var i = 0; i < 3600; i++) {
      var x = seededRand(i * 1.7) * 256;
      var y = seededRand(i * 3.1) * 256;
      var len = 4 + seededRand(i * 5.3) * 7;
      var shade = seededRand(i * 7.7);
      ctx.strokeStyle =
        shade > 0.55
          ? 'rgba(186,144,110,0.32)'
          : 'rgba(68,42,24,0.34)';
      ctx.lineWidth = 1.0;
      ctx.beginPath();
      ctx.moveTo(x, y);
      ctx.lineTo(x + (shade - 0.5) * 2.0, y + len);
      ctx.stroke();

      var gv = (95 + shade * 80) | 0;
      bctx.strokeStyle = 'rgba(' + gv + ',' + gv + ',' + gv + ',0.55)';
      bctx.beginPath();
      bctx.moveTo(x, y);
      bctx.lineTo(x, y + len);
      bctx.stroke();
    }

    var map = new THREE.CanvasTexture(c);
    map.wrapS = THREE.RepeatWrapping;
    map.wrapT = THREE.RepeatWrapping;
    var bump = new THREE.CanvasTexture(bc);
    bump.wrapS = THREE.RepeatWrapping;
    bump.wrapT = THREE.RepeatWrapping;
    return { map: map, bump: bump };
  }

  function createBarkTexture() {
    var c = document.createElement('canvas');
    c.width = 128;
    c.height = 256;
    var ctx = c.getContext('2d');
    ctx.fillStyle = '#3c2618';
    ctx.fillRect(0, 0, 128, 256);
    for (var i = 0; i < 480; i++) {
      var x = seededRand(i * 2.1) * 128;
      var y = seededRand(i * 4.7) * 256;
      var h = 10 + seededRand(i * 6.3) * 24;
      ctx.fillStyle = i % 3 === 0 ? 'rgba(26,15,8,0.6)' : 'rgba(92,62,42,0.42)';
      ctx.fillRect(x, y, 2.5, h);
    }
    var tex = new THREE.CanvasTexture(c);
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    return tex;
  }

  function createIglooTextures() {
    var c = document.createElement('canvas');
    c.width = 512;
    c.height = 256;
    var ctx = c.getContext('2d');
    ctx.fillStyle = '#ebf3fc';
    ctx.fillRect(0, 0, 512, 256);

    var bc = document.createElement('canvas');
    bc.width = 512;
    bc.height = 256;
    var bctx = bc.getContext('2d');
    bctx.fillStyle = '#b4b4b4';
    bctx.fillRect(0, 0, 512, 256);

    // Spiral snow blocks with organic weathered mortar seams
    var rows = 9;
    var rowH = 256 / rows;
    for (var r = 0; r < rows; r++) {
      var y = r * rowH;
      ctx.strokeStyle = 'rgba(135,168,204,0.48)';
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.moveTo(0, y);
      for (var sx = 0; sx <= 512; sx += 16) {
        ctx.lineTo(sx, y + Math.sin(sx * 0.05 + r) * 1.4);
      }
      ctx.stroke();

      bctx.strokeStyle = '#3a3a3a';
      bctx.lineWidth = 5;
      bctx.beginPath();
      bctx.moveTo(0, y);
      bctx.lineTo(512, y);
      bctx.stroke();

      var cols = 8;
      var colW = 512 / cols;
      var offset = (r % 2) * (colW * 0.5);
      for (var k = 0; k < cols; k++) {
        var bx = (k * colW + offset) % 512;
        ctx.fillStyle =
          seededRand(r * 13 + k) > 0.5
            ? 'rgba(255,255,255,0.22)'
            : 'rgba(195,220,245,0.20)';
        ctx.fillRect(bx + 2, y + 2, colW - 4, rowH - 4);

        ctx.beginPath();
        ctx.moveTo(bx, y);
        ctx.lineTo(bx + Math.sin(r + k) * 1.5, y + rowH);
        ctx.stroke();

        bctx.beginPath();
        bctx.moveTo(bx, y);
        bctx.lineTo(bx, y + rowH);
        bctx.stroke();
      }
    }

    var map = new THREE.CanvasTexture(c);
    map.wrapS = THREE.RepeatWrapping;
    map.wrapT = THREE.RepeatWrapping;
    var bump = new THREE.CanvasTexture(bc);
    bump.wrapS = THREE.RepeatWrapping;
    bump.wrapT = THREE.RepeatWrapping;
    return { map: map, bump: bump };
  }

  function createTimberTextures() {
    var c = document.createElement('canvas');
    c.width = 256;
    c.height = 256;
    var ctx = c.getContext('2d');
    ctx.fillStyle = '#52321e';
    ctx.fillRect(0, 0, 256, 256);

    for (var i = 0; i < 600; i++) {
      var y = seededRand(i * 1.9) * 256;
      var x = seededRand(i * 3.3) * 256;
      var w = 18 + seededRand(i * 5.1) * 52;
      ctx.fillStyle =
        i % 4 === 0 ? 'rgba(30,16,8,0.45)' : 'rgba(116,74,44,0.34)';
      ctx.fillRect(x, y, w, 2);
    }
    var tex = new THREE.CanvasTexture(c);
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    return tex;
  }

  function terrainHeightAt(x, z) {
    var pathCenter = Math.sin(z * 0.055) * 4.5;
    var distFromPath = Math.abs(x - pathCenter);
    var pathFlatten = smoothstep((distFromPath - 2.6) / 7.5);
    var hills =
      Math.sin(x * 0.075) * Math.cos(z * 0.055) * 1.55 +
      Math.sin(x * 0.16 + z * 0.11) * 0.58 +
      Math.cos(x * 0.27 - z * 0.19) * 0.22;
    return hills * pathFlatten;
  }

  // Sculpted natural wind-bent spruce / pine tree built from multi-tiered organic boughs + snow cushions
  function buildRealisticPineTree(scale, decorated, warmLightsBucket, seed, barkTex) {
    var s = scale || 1.0;
    var sd = seed || 1.0;
    var group = new THREE.Group();

    // Organic tapered trunk with root flare
    var trunkPts = [
      new THREE.Vector2(0.0, 0.0),
      new THREE.Vector2(0.32 * s, 0.0),
      new THREE.Vector2(0.22 * s, 0.45 * s),
      new THREE.Vector2(0.17 * s, 1.5 * s),
      new THREE.Vector2(0.11 * s, 3.3 * s),
      new THREE.Vector2(0.03 * s, 5.1 * s),
    ];
    var trunk = new THREE.Mesh(
      new THREE.LatheGeometry(trunkPts, 10),
      new THREE.MeshStandardMaterial({
        map: barkTex,
        color: 0x5c3c28,
        roughness: 0.94,
      })
    );
    trunk.castShadow = true;
    trunk.receiveShadow = true;
    group.add(trunk);

    var foliageColors = [0x143c2b, 0x194733, 0x1e523a, 0x245d42];
    var snowBoughMat = new THREE.MeshStandardMaterial({
      color: 0xf2f7ff,
      roughness: 0.72,
      metalness: 0.02,
    });

    // 7 organic branch whorls built from radially staggered drooping needle clusters
    var whorls = 7;
    for (var w = 0; w < whorls; w++) {
      var wf = w / (whorls - 1);
      var yBase = lerp(1.15, 4.75, wf) * s;
      var maxReach = lerp(1.68, 0.36, Math.pow(wf, 0.85)) * s;
      var branchCount = Math.max(4, Math.round(lerp(8, 4, wf)));
      var whorlRot = w * 0.85 + seededRand(sd + w) * 1.4;
      var fMat = new THREE.MeshStandardMaterial({
        color: foliageColors[w % foliageColors.length],
        roughness: 0.88,
      });

      for (var b = 0; b < branchCount; b++) {
        var ang = whorlRot + (b / branchCount) * Math.PI * 2 + (seededRand(sd + w * 13 + b) - 0.5) * 0.25;
        var bLen = maxReach * (0.85 + seededRand(sd + w * 7 + b) * 0.28);

        // Build individual bough cluster stretching outward & sloping gently downward
        var bough = new THREE.Group();
        bough.position.set(0, yBase, 0);
        bough.rotation.y = ang;

        var subCount = bLen > 0.65 * s ? 3 : 2;
        for (var k = 0; k < subCount; k++) {
          var kf = (k + 0.5) / subCount;
          var rClump = lerp(0.46, 0.26, kf) * s * lerp(1.1, 0.58, wf);
          var tuftGeo = displaceGeometry(
            new THREE.IcosahedronGeometry(rClump, 1),
            0.24,
            3.2,
            sd + w * 23 + b * 7 + k
          );
          var tuft = new THREE.Mesh(tuftGeo, fMat);
          tuft.scale.set(1.25, 0.52, 0.92);
          tuft.position.set(kf * bLen * 0.85, -kf * 0.28 * s, 0);
          tuft.castShadow = true;
          tuft.receiveShadow = true;
          bough.add(tuft);

          // Soft organic snow pocket resting naturally on top of the needle cluster
          if (k === subCount - 1 || seededRand(sd + w * 19 + b + k) > 0.3) {
            var snowPadGeo = displaceGeometry(
              new THREE.IcosahedronGeometry(rClump * 0.82, 1),
              0.2,
              4.0,
              sd + w * 31 + k
            );
            var snowPad = new THREE.Mesh(snowPadGeo, snowBoughMat);
            snowPad.scale.set(1.12, 0.28, 0.82);
            snowPad.position.set(kf * bLen * 0.88, -kf * 0.28 * s + rClump * 0.34, 0);
            bough.add(snowPad);
          }
        }
        group.add(bough);
      }
    }

    // Crown needle tip + snow tuft
    var tip = new THREE.Mesh(
      displaceGeometry(new THREE.ConeGeometry(0.28 * s, 0.72 * s, 9), 0.16, 4.0, sd + 99),
      new THREE.MeshStandardMaterial({ color: 0x1e523a, roughness: 0.86 })
    );
    tip.position.y = 5.2 * s;
    tip.castShadow = true;
    group.add(tip);

    // Subtle organic asymmetry lean
    group.rotation.z = (seededRand(sd + 3.1) - 0.5) * 0.045;
    group.rotation.x = (seededRand(sd + 6.7) - 0.5) * 0.045;

    if (decorated) {
      // Spiral glowing filament wire garland + warm bulbs
      var garlandPts = [];
      for (var gi = 0; gi <= 36; gi++) {
        var gf = gi / 36;
        var ga = gf * Math.PI * 8.0;
        var gr = lerp(1.52, 0.26, gf) * s;
        var gy = lerp(1.05, 4.9, gf) * s;
        garlandPts.push(new THREE.Vector3(Math.cos(ga) * gr, gy, Math.sin(ga) * gr));
      }
      var wireCurve = new THREE.CatmullRomCurve3(garlandPts);
      var wireMesh = new THREE.Mesh(
        new THREE.TubeGeometry(wireCurve, 48, 0.018 * s, 5, false),
        new THREE.MeshStandardMaterial({ color: 0x1f2937, roughness: 0.8 })
      );
      group.add(wireMesh);

      var bulbPalette = [0xf5d076, 0xffe4b5, 0xe11d48, 0x38bdf8, 0x34d399];
      for (var bi = 0; bi < 18; bi++) {
        var pt = wireCurve.getPointAt((bi + 0.5) / 18);
        var col = bulbPalette[bi % bulbPalette.length];
        var bulbMat = new THREE.MeshStandardMaterial({
          color: col,
          emissive: col,
          emissiveIntensity: 1.05,
          roughness: 0.2,
          metalness: 0.25,
        });
        var bulb = new THREE.Mesh(new THREE.SphereGeometry(0.085 * s, 8, 8), bulbMat);
        bulb.position.copy(pt);
        group.add(bulb);
        warmLightsBucket.push({ mat: bulbMat, phase: bi * 0.75, base: 1.05 });
      }

      // Carved 5-point Bethlehem Star topper (ExtrudeGeometry)
      var starShape = new THREE.Shape();
      for (var sp = 0; sp < 10; sp++) {
        var rad = sp % 2 === 0 ? 0.34 * s : 0.14 * s;
        var sa = (sp * Math.PI) / 5 - Math.PI / 2;
        var sx = Math.cos(sa) * rad;
        var sy = Math.sin(sa) * rad;
        if (sp === 0) starShape.moveTo(sx, sy);
        else starShape.lineTo(sx, sy);
      }
      starShape.closePath();
      var starMat = new THREE.MeshStandardMaterial({
        color: 0xfde68a,
        emissive: 0xf59e0b,
        emissiveIntensity: 1.45,
        roughness: 0.2,
        metalness: 0.65,
      });
      var star = new THREE.Mesh(
        new THREE.ExtrudeGeometry(starShape, {
          depth: 0.08 * s,
          bevelEnabled: true,
          bevelThickness: 0.025 * s,
          bevelSize: 0.02 * s,
          bevelSegments: 2,
        }),
        starMat
      );
      star.position.set(0, 5.7 * s, -0.04 * s);
      group.add(star);
      warmLightsBucket.push({ mat: starMat, phase: 0.2, base: 1.45 });

      var treeLight = new THREE.PointLight(0xffd27a, 1.4, 15 * s, 1.8);
      treeLight.position.set(0, 3.2 * s, 0);
      group.add(treeLight);
      warmLightsBucket.push({ light: treeLight, nightIntensity: 1.6, dayIntensity: 0.25 });
    }

    return group;
  }

  // Realistic Packed-Snow Igloo with drifted base skirt, arched block tunnel & interior hearth glow
  function buildRealisticIgloo(iglooTex, warmLightsBucket, sectionId, seed) {
    var sd = seed || 1.0;
    var group = new THREE.Group();
    group.userData.sectionId = sectionId;

    var domeMat = new THREE.MeshStandardMaterial({
      map: iglooTex.map,
      bumpMap: iglooTex.bump,
      bumpScale: 0.08,
      color: 0xf0f6ff,
      roughness: 0.76,
      metalness: 0.03,
    });

    // Organic sculpted igloo dome (slightly squashed & hand-packed irregularity)
    var domeGeo = new THREE.SphereGeometry(2.35, 32, 20, 0, Math.PI * 2, 0, Math.PI * 0.55);
    var dPos = domeGeo.attributes.position;
    for (var i = 0; i < dPos.count; i++) {
      var x = dPos.getX(i);
      var y = dPos.getY(i);
      var z = dPos.getZ(i);
      var n = noise3(x * 1.4, y * 1.4, z * 1.4, sd);
      dPos.setXYZ(i, x * (1.0 + n * 0.035), y * 0.88 * (1.0 + n * 0.025), z * (1.0 + n * 0.035));
    }
    domeGeo.computeVertexNormals();
    var dome = new THREE.Mesh(domeGeo, domeMat);
    dome.castShadow = true;
    dome.receiveShadow = true;
    dome.userData.sectionId = sectionId;
    group.add(dome);

    // Wind-drifted snow mound skirt blending igloo into ground naturally
    var skirtGeo = new THREE.TorusGeometry(2.26, 0.42, 10, 28);
    skirtGeo.rotateX(Math.PI / 2);
    displaceGeometry(skirtGeo, 0.14, 1.5, sd + 2);
    var skirt = new THREE.Mesh(
      skirtGeo,
      new THREE.MeshStandardMaterial({ color: 0xf4f8ff, roughness: 0.82 })
    );
    skirt.scale.set(1.0, 0.48, 1.0);
    skirt.position.y = 0.08;
    skirt.receiveShadow = true;
    group.add(skirt);

    // Sculpted arched entrance vault built from stacked snow-arch ribs
    for (var rib = 0; rib < 4; rib++) {
      var archGeo = new THREE.TorusGeometry(0.86 - rib * 0.02, 0.24, 10, 18, Math.PI);
      var arch = new THREE.Mesh(archGeo, domeMat);
      arch.position.set(0, 0.02, 1.92 + rib * 0.32);
      arch.castShadow = true;
      arch.receiveShadow = true;
      arch.userData.sectionId = sectionId;
      group.add(arch);
    }

    // Shadowed recessed alcove & warm interior glow
    var innerBacking = new THREE.Mesh(
      new THREE.CircleGeometry(0.72, 18),
      new THREE.MeshStandardMaterial({
        color: 0xffb347,
        emissive: 0xff7b1c,
        emissiveIntensity: 1.05,
        roughness: 0.6,
      })
    );
    innerBacking.position.set(0, 0.42, 2.08);
    group.add(innerBacking);
    warmLightsBucket.push({ mat: innerBacking.material, phase: 1.1 + sd, base: 1.05 });

    // Wood lantern post beside igloo entrance
    var stick = new THREE.Mesh(
      new THREE.CylinderGeometry(0.04, 0.05, 1.35, 7),
      new THREE.MeshStandardMaterial({ color: 0x5c3c28, roughness: 0.9 })
    );
    stick.position.set(1.15, 0.68, 2.75);
    stick.castShadow = true;
    group.add(stick);

    var lanternGlassMat = new THREE.MeshStandardMaterial({
      color: 0xfde68a,
      emissive: 0xf59e0b,
      emissiveIntensity: 1.25,
      roughness: 0.25,
    });
    var lanternCage = new THREE.Mesh(
      new THREE.CylinderGeometry(0.11, 0.09, 0.24, 6),
      lanternGlassMat
    );
    lanternCage.position.set(1.15, 1.25, 2.75);
    group.add(lanternCage);
    warmLightsBucket.push({ mat: lanternGlassMat, phase: sd * 0.9, base: 1.25 });

    var warmLight = new THREE.PointLight(0xffa94d, 1.75, 12, 1.7);
    warmLight.position.set(0, 0.85, 2.55);
    group.add(warmLight);
    warmLightsBucket.push({ light: warmLight, nightIntensity: 1.95, dayIntensity: 0.25 });

    return group;
  }

  // Authentic Log Cabin with notched cylindrical logs, stone hearth chimney, rafters, snow eaves & icicles
  function buildRealisticWinterCabin(timberTex, barkTex, warmLightsBucket, sectionId, scale) {
    var s = scale || 1.0;
    var group = new THREE.Group();
    group.userData.sectionId = sectionId;

    var logMat = new THREE.MeshStandardMaterial({
      map: timberTex,
      color: 0x6b432a,
      roughness: 0.86,
    });
    var darkLogMat = new THREE.MeshStandardMaterial({
      map: barkTex,
      color: 0x452817,
      roughness: 0.92,
    });
    var snowMat = new THREE.MeshStandardMaterial({ color: 0xf3f8ff, roughness: 0.72 });

    // Stone cabin foundation plinth
    var plinth = new THREE.Mesh(
      new THREE.BoxGeometry(4.45 * s, 0.35 * s, 3.65 * s),
      new THREE.MeshStandardMaterial({ color: 0x475569, roughness: 0.95 })
    );
    plinth.position.y = 0.175 * s;
    plinth.receiveShadow = true;
    plinth.userData.sectionId = sectionId;
    group.add(plinth);

    // Stacked rounded horizontal logs with authentic overhanging notched corners
    var wallW = 4.2 * s;
    var wallD = 3.4 * s;
    var logR = 0.16 * s;
    var logCount = 7;
    var logGeoFront = new THREE.CylinderGeometry(logR, logR, wallW + 0.52 * s, 10);
    logGeoFront.rotateZ(Math.PI / 2);
    var logGeoSide = new THREE.CylinderGeometry(logR, logR, wallD + 0.52 * s, 10);
    logGeoSide.rotateX(Math.PI / 2);

    for (var li = 0; li < logCount; li++) {
      var ly = (0.44 + li * 0.31) * s;
      var frontLog = new THREE.Mesh(logGeoFront, logMat);
      frontLog.position.set(0, ly, wallD * 0.5);
      frontLog.castShadow = true;
      frontLog.userData.sectionId = sectionId;
      group.add(frontLog);

      var backLog = new THREE.Mesh(logGeoFront, logMat);
      backLog.position.set(0, ly, -wallD * 0.5);
      backLog.castShadow = true;
      group.add(backLog);

      var leftLog = new THREE.Mesh(logGeoSide, darkLogMat);
      leftLog.position.set(-wallW * 0.5, ly + 0.14 * s, 0);
      leftLog.castShadow = true;
      group.add(leftLog);

      var rightLog = new THREE.Mesh(logGeoSide, darkLogMat);
      rightLog.position.set(wallW * 0.5, ly + 0.14 * s, 0);
      rightLog.castShadow = true;
      group.add(rightLog);
    }

    // Inner cabin core backing so light doesn't leak between logs
    var coreBox = new THREE.Mesh(
      new THREE.BoxGeometry(wallW - 0.1 * s, 2.25 * s, wallD - 0.1 * s),
      darkLogMat
    );
    coreBox.position.y = 1.42 * s;
    coreBox.userData.sectionId = sectionId;
    group.add(coreBox);

    // Gable roof shape extruded for crisp timber gable + overhanging snow-blanketed roof slabs
    var gableShape = new THREE.Shape();
    gableShape.moveTo(-wallW * 0.5, 0);
    gableShape.lineTo(wallW * 0.5, 0);
    gableShape.lineTo(0, 1.65 * s);
    gableShape.closePath();
    var gable = new THREE.Mesh(
      new THREE.ExtrudeGeometry(gableShape, { depth: wallD - 0.06 * s, bevelEnabled: false }),
      logMat
    );
    gable.position.set(0, 2.52 * s, -(wallD - 0.06 * s) * 0.5);
    gable.castShadow = true;
    gable.userData.sectionId = sectionId;
    group.add(gable);

    // Pitched roof slopes with thick sculpted snow blanket overhang
    var slopeLen = 2.85 * s;
    var roofDepth = (wallD + 0.9 * s);
    var roofAngle = 0.66;
    for (var side = -1; side <= 1; side += 2) {
      var timberSlope = new THREE.Mesh(
        new THREE.BoxGeometry(slopeLen, 0.14 * s, roofDepth),
        darkLogMat
      );
      timberSlope.position.set(side * 1.12 * s, 3.22 * s, 0);
      timberSlope.rotation.z = -side * roofAngle;
      timberSlope.castShadow = true;
      group.add(timberSlope);

      var snowSlopeGeo = new THREE.BoxGeometry(slopeLen + 0.12 * s, 0.24 * s, roofDepth + 0.12 * s);
      var snowSlope = new THREE.Mesh(snowSlopeGeo, snowMat);
      snowSlope.position.set(side * 1.16 * s, 3.36 * s, 0);
      snowSlope.rotation.z = -side * roofAngle;
      snowSlope.castShadow = true;
      snowSlope.receiveShadow = true;
      group.add(snowSlope);
    }

    // Translucent ice-crystal icicles along front eaves
    var icicleMat = new THREE.MeshStandardMaterial({
      color: 0xdcf0ff,
      roughness: 0.15,
      metalness: 0.1,
      transparent: true,
      opacity: 0.85,
    });
    for (var ic = -3; ic <= 3; ic++) {
      if (ic === 0) continue;
      var iLen = (0.22 + seededRand(ic + 12) * 0.24) * s;
      var icicle = new THREE.Mesh(new THREE.ConeGeometry(0.032 * s, iLen, 5), icicleMat);
      icicle.rotation.x = Math.PI;
      icicle.position.set(
        ic * 0.58 * s,
        2.56 * s + (3 - Math.abs(ic)) * 0.36 * s - iLen * 0.5,
        roofDepth * 0.5 + 0.02 * s
      );
      group.add(icicle);
    }

    // Cobblestone hearth chimney built from irregular river stones
    var stoneMat = new THREE.MeshStandardMaterial({ color: 0x64748b, roughness: 0.94 });
    for (var st = 0; st < 16; st++) {
      var sr = (0.18 + seededRand(st * 2.1) * 0.14) * s;
      var stoneGeo = displaceGeometry(new THREE.IcosahedronGeometry(sr, 1), 0.22, 3.0, st + 5);
      var stone = new THREE.Mesh(stoneGeo, stoneMat);
      var row = (st / 4) | 0;
      var ang = (st % 4) * (Math.PI * 0.5) + row * 0.4;
      stone.position.set(
        1.25 * s + Math.cos(ang) * 0.22 * s,
        (3.15 + row * 0.34) * s,
        -0.55 * s + Math.sin(ang) * 0.22 * s
      );
      stone.castShadow = true;
      group.add(stone);
    }

    // Timber-framed Door + Mullioned glowing hearth windows
    var door = new THREE.Mesh(
      new THREE.BoxGeometry(0.84 * s, 1.52 * s, 0.14 * s),
      new THREE.MeshStandardMaterial({ color: 0x5b1822, roughness: 0.72 })
    );
    door.position.set(0, 1.05 * s, wallD * 0.5 + 0.12 * s);
    group.add(door);

    var winMat = new THREE.MeshStandardMaterial({
      color: 0xffd27a,
      emissive: 0xf59e0b,
      emissiveIntensity: 1.2,
      roughness: 0.25,
    });
    warmLightsBucket.push({ mat: winMat, phase: 0.4, base: 1.2 });

    var winXs = [-1.28, 1.28];
    for (var wx = 0; wx < winXs.length; wx++) {
      var xPos = winXs[wx] * s;
      var winFrame = new THREE.Mesh(
        new THREE.BoxGeometry(0.84 * s, 0.84 * s, 0.14 * s),
        darkLogMat
      );
      winFrame.position.set(xPos, 1.48 * s, wallD * 0.5 + 0.12 * s);
      group.add(winFrame);

      var glass = new THREE.Mesh(
        new THREE.BoxGeometry(0.68 * s, 0.68 * s, 0.16 * s),
        winMat
      );
      glass.position.set(xPos, 1.48 * s, wallD * 0.5 + 0.13 * s);
      group.add(glass);

      // Mullion crossbars
      var barH = new THREE.Mesh(new THREE.BoxGeometry(0.72 * s, 0.05 * s, 0.18 * s), darkLogMat);
      barH.position.set(xPos, 1.48 * s, wallD * 0.5 + 0.13 * s);
      group.add(barH);
      var barV = new THREE.Mesh(new THREE.BoxGeometry(0.05 * s, 0.72 * s, 0.18 * s), darkLogMat);
      barV.position.set(xPos, 1.48 * s, wallD * 0.5 + 0.13 * s);
      group.add(barV);
    }

    var porchLight = new THREE.PointLight(0xffb85c, 2.2, 15 * s, 1.75);
    porchLight.position.set(0, 2.0 * s, wallD * 0.5 + 1.05 * s);
    group.add(porchLight);
    warmLightsBucket.push({ light: porchLight, nightIntensity: 2.35, dayIntensity: 0.3 });

    return group;
  }

  function buildWoodenSignboard(timberTex, warmLightsBucket) {
    var group = new THREE.Group();
    var post = new THREE.Mesh(
      new THREE.CylinderGeometry(0.09, 0.12, 2.05, 8),
      new THREE.MeshStandardMaterial({ map: timberTex, roughness: 0.92 })
    );
    post.position.y = 1.02;
    post.castShadow = true;
    group.add(post);

    // Crossarm & iron bracket
    var arm = new THREE.Mesh(
      new THREE.CylinderGeometry(0.045, 0.055, 0.78, 6),
      new THREE.MeshStandardMaterial({ map: timberTex, roughness: 0.9 })
    );
    arm.rotation.z = Math.PI / 2;
    arm.position.set(0.32, 1.92, 0);
    arm.castShadow = true;
    group.add(arm);

    // Directional trail plank
    var board = new THREE.Mesh(
      new THREE.BoxGeometry(1.15, 0.38, 0.09),
      new THREE.MeshStandardMaterial({ map: timberTex, roughness: 0.85 })
    );
    board.position.set(-0.08, 1.56, 0.05);
    group.add(board);

    // Hanging glass lantern cage
    var lanternMat = new THREE.MeshStandardMaterial({
      color: 0xfde68a,
      emissive: 0xf59e0b,
      emissiveIntensity: 1.25,
    });
    var glass = new THREE.Mesh(new THREE.CylinderGeometry(0.11, 0.09, 0.24, 6), lanternMat);
    glass.position.set(0.62, 1.70, 0);
    group.add(glass);
    var cap = new THREE.Mesh(
      new THREE.ConeGeometry(0.15, 0.12, 6),
      new THREE.MeshStandardMaterial({ color: 0x1e293b, roughness: 0.6, metalness: 0.5 })
    );
    cap.position.set(0.62, 1.85, 0);
    group.add(cap);

    warmLightsBucket.push({ mat: lanternMat, phase: 2.1, base: 1.25 });
    return group;
  }

  // Anatomically Sculpted Realistic Deer (Lathe torso, curved neck, tapered snout, ears, cloven 3-segment legs, curved branching antlers)
  function buildRealisticDeer(scale, furTextures, seed) {
    var s = scale || 1.0;
    var root = new THREE.Group();

    var furMat = new THREE.MeshStandardMaterial({
      map: furTextures.map,
      bumpMap: furTextures.bump,
      bumpScale: 0.035,
      color: 0x997050,
      roughness: 0.84,
      metalness: 0.02,
    });
    var paleFurMat = new THREE.MeshStandardMaterial({
      color: 0xe6dacb,
      roughness: 0.86,
    });
    var hoofMat = new THREE.MeshStandardMaterial({
      color: 0x1c1816,
      roughness: 0.45,
      metalness: 0.1,
    });
    var antlerMat = new THREE.MeshStandardMaterial({
      color: 0xd9cbb8,
      roughness: 0.68,
    });

    // 1. Sculpted Lathe Torso (oriented along Z: rear -> waist -> broad chest -> brisket)
    var torsoProfile = [
      new THREE.Vector2(0.01, -0.74 * s),
      new THREE.Vector2(0.24 * s, -0.66 * s),
      new THREE.Vector2(0.32 * s, -0.42 * s),
      new THREE.Vector2(0.28 * s, -0.06 * s),
      new THREE.Vector2(0.31 * s, 0.28 * s),
      new THREE.Vector2(0.35 * s, 0.52 * s),
      new THREE.Vector2(0.24 * s, 0.68 * s),
      new THREE.Vector2(0.01, 0.74 * s),
    ];
    var torsoGeo = new THREE.LatheGeometry(torsoProfile, 18);
    torsoGeo.rotateX(Math.PI / 2);
    var torso = new THREE.Mesh(torsoGeo, furMat);
    torso.scale.set(0.82, 1.04, 1.0);
    torso.position.set(0, 1.06 * s, 0);
    torso.castShadow = true;
    torso.receiveShadow = true;
    root.add(torso);

    // Pale winter chest/belly undercoat + white rump patch
    var belly = new THREE.Mesh(
      new THREE.SphereGeometry(0.27 * s, 14, 12),
      paleFurMat
    );
    belly.scale.set(0.76, 0.82, 1.35);
    belly.position.set(0, 0.90 * s, 0.24 * s);
    root.add(belly);

    var rumpPatch = new THREE.Mesh(
      new THREE.SphereGeometry(0.18 * s, 12, 10),
      paleFurMat
    );
    rumpPatch.scale.set(0.95, 1.1, 0.55);
    rumpPatch.position.set(0, 1.08 * s, -0.68 * s);
    root.add(rumpPatch);

    // Graceful short deer tail
    var tailPivot = new THREE.Group();
    tailPivot.position.set(0, 1.18 * s, -0.68 * s);
    var tailMesh = new THREE.Mesh(
      new THREE.ConeGeometry(0.06 * s, 0.22 * s, 8),
      paleFurMat
    );
    tailMesh.rotation.x = -Math.PI * 0.72;
    tailMesh.position.set(0, -0.06 * s, -0.06 * s);
    tailPivot.add(tailMesh);
    root.add(tailPivot);

    // 2. Neck + Head Pivot at withers
    var neckPivot = new THREE.Group();
    neckPivot.position.set(0, 1.24 * s, 0.48 * s);
    root.add(neckPivot);

    // Smooth curved tapered neck (Lathe along upward-forward arc)
    var neckCurve = new THREE.CatmullRomCurve3([
      new THREE.Vector3(0, -0.05 * s, -0.04 * s),
      new THREE.Vector3(0, 0.22 * s, 0.10 * s),
      new THREE.Vector3(0, 0.52 * s, 0.18 * s),
    ]);
    var neckGeo = new THREE.TubeGeometry(neckCurve, 10, 0.145 * s, 12, false);
    // Taper neck toward skull
    var nPos = neckGeo.attributes.position;
    for (var ni = 0; ni < nPos.count; ni++) {
      var ny = nPos.getY(ni) / s;
      var taper = lerp(1.22, 0.76, clamp((ny + 0.05) / 0.57, 0, 1));
      nPos.setX(ni, nPos.getX(ni) * taper * 0.85);
    }
    neckGeo.computeVertexNormals();
    var neckMesh = new THREE.Mesh(neckGeo, furMat);
    neckMesh.castShadow = true;
    neckPivot.add(neckMesh);

    // Winter throat mane ruff
    var ruff = new THREE.Mesh(
      new THREE.SphereGeometry(0.14 * s, 10, 10),
      paleFurMat
    );
    ruff.scale.set(0.75, 1.65, 0.82);
    ruff.position.set(0, 0.16 * s, 0.16 * s);
    ruff.rotation.x = -0.35;
    neckPivot.add(ruff);

    // Sculpted Head Cranium + Tapered Muzzle
    var headGroup = new THREE.Group();
    headGroup.position.set(0, 0.54 * s, 0.20 * s);
    neckPivot.add(headGroup);

    var skull = new THREE.Mesh(
      new THREE.SphereGeometry(0.155 * s, 14, 12),
      furMat
    );
    skull.scale.set(0.84, 0.92, 1.18);
    skull.castShadow = true;
    headGroup.add(skull);

    // Tapered elongated muzzle
    var muzzlePts = [
      new THREE.Vector2(0.01, 0.0),
      new THREE.Vector2(0.052 * s, 0.04 * s),
      new THREE.Vector2(0.075 * s, 0.16 * s),
      new THREE.Vector2(0.115 * s, 0.30 * s),
    ];
    var muzzleGeo = new THREE.LatheGeometry(muzzlePts, 12);
    muzzleGeo.rotateX(-Math.PI / 2);
    var muzzle = new THREE.Mesh(muzzleGeo, furMat);
    muzzle.scale.set(0.86, 0.78, 1.0);
    muzzle.position.set(0, -0.04 * s, 0.34 * s);
    muzzle.castShadow = true;
    headGroup.add(muzzle);

    // Dark wet nose rhinarium + dark glassy eyes
    var nose = new THREE.Mesh(new THREE.SphereGeometry(0.042 * s, 10, 8), hoofMat);
    nose.scale.set(0.95, 0.75, 0.9);
    nose.position.set(0, -0.025 * s, 0.35 * s);
    headGroup.add(nose);

    var eyeMat = new THREE.MeshStandardMaterial({
      color: 0x0f0e0d,
      roughness: 0.12,
      metalness: 0.4,
    });
    for (var side = -1; side <= 1; side += 2) {
      var eye = new THREE.Mesh(new THREE.SphereGeometry(0.026 * s, 8, 8), eyeMat);
      eye.position.set(side * 0.105 * s, 0.03 * s, 0.11 * s);
      headGroup.add(eye);

      // Cupped Leaf Ears
      var ear = new THREE.Mesh(new THREE.SphereGeometry(0.11 * s, 10, 8), furMat);
      ear.scale.set(0.42, 1.35, 0.25);
      ear.position.set(side * 0.13 * s, 0.12 * s, -0.05 * s);
      ear.rotation.z = -side * 0.72;
      ear.rotation.y = side * 0.35;
      ear.rotation.x = -0.2;
      headGroup.add(ear);

      // Sweeping Multi-Point Organic Antlers via CatmullRomCurve3 Tubes (no straight sticks!)
      var mainBeamCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(side * 0.055 * s, 0.11 * s, -0.01 * s),
        new THREE.Vector3(side * 0.15 * s, 0.28 * s, -0.09 * s),
        new THREE.Vector3(side * 0.24 * s, 0.47 * s, 0.02 * s),
        new THREE.Vector3(side * 0.19 * s, 0.62 * s, 0.18 * s),
      ]);
      var beam = new THREE.Mesh(
        new THREE.TubeGeometry(mainBeamCurve, 14, 0.019 * s, 6, false),
        antlerMat
      );
      headGroup.add(beam);

      // Brow tine
      var browCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(side * 0.12 * s, 0.22 * s, -0.05 * s),
        new THREE.Vector3(side * 0.15 * s, 0.29 * s, 0.11 * s),
        new THREE.Vector3(side * 0.12 * s, 0.37 * s, 0.19 * s),
      ]);
      headGroup.add(
        new THREE.Mesh(new THREE.TubeGeometry(browCurve, 8, 0.013 * s, 5, false), antlerMat)
      );

      // Crown fork tine
      var forkCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(side * 0.22 * s, 0.42 * s, -0.02 * s),
        new THREE.Vector3(side * 0.29 * s, 0.56 * s, -0.06 * s),
      ]);
      headGroup.add(
        new THREE.Mesh(new THREE.TubeGeometry(forkCurve, 6, 0.012 * s, 5, false), antlerMat)
      );
    }

    // 3. 4 Multi-Jointed Legs (Upper Hip/Shoulder + Knee/Hock Joint + Cannon + Cloven Hoof)
    var legs = [];
    var legSpec = [
      { x: -0.18 * s, y: 0.92 * s, z: 0.45 * s, isHind: false },
      { x: 0.18 * s, y: 0.92 * s, z: 0.45 * s, isHind: false },
      { x: -0.19 * s, y: 0.95 * s, z: -0.45 * s, isHind: true },
      { x: 0.19 * s, y: 0.95 * s, z: -0.45 * s, isHind: true },
    ];

    for (var l = 0; l < 4; l++) {
      var sp = legSpec[l];
      var hip = new THREE.Group();
      hip.position.set(sp.x, sp.y, sp.z);

      // Muscular upper shoulder/thigh tapering cleanly to knee/hock
      var upperGeo = new THREE.CylinderGeometry(
        sp.isHind ? 0.12 * s : 0.095 * s,
        0.055 * s,
        0.46 * s,
        10
      );
      var upperMesh = new THREE.Mesh(upperGeo, furMat);
      upperMesh.position.set(0, -0.21 * s, sp.isHind ? -0.04 * s : 0.01 * s);
      upperMesh.rotation.x = sp.isHind ? -0.24 : 0.1;
      upperMesh.castShadow = true;
      hip.add(upperMesh);

      // Knee / Hock articulation pivot
      var knee = new THREE.Group();
      knee.position.set(0, -0.43 * s, sp.isHind ? -0.09 * s : 0.03 * s);
      hip.add(knee);

      // Slender cannon bone
      var lowerGeo = new THREE.CylinderGeometry(0.044 * s, 0.032 * s, 0.48 * s, 8);
      var lowerMesh = new THREE.Mesh(lowerGeo, furMat);
      lowerMesh.position.set(0, -0.23 * s, sp.isHind ? 0.05 * s : 0);
      lowerMesh.rotation.x = sp.isHind ? 0.18 : 0;
      lowerMesh.castShadow = true;
      knee.add(lowerMesh);

      // Dark keratin cloven hoof
      var hoof = new THREE.Mesh(
        new THREE.CylinderGeometry(0.036 * s, 0.046 * s, 0.08 * s, 8),
        hoofMat
      );
      hoof.position.set(0, -0.49 * s, sp.isHind ? 0.09 * s : 0.01 * s);
      knee.add(hoof);

      root.add(hip);
      legs.push({ hip: hip, knee: knee, isHind: sp.isHind });
    }

    return {
      root: root,
      neckPivot: neckPivot,
      tailPivot: tailPivot,
      legs: legs,
      seed: seed || 1.0,
    };
  }

  // Carved crimson & gold wooden Santa Sleigh pulled by 4 sculpted flying reindeer
  function buildRealisticSantaSleigh(furTextures) {
    var rig = new THREE.Group();

    // Carved sleigh scroll profile
    var bodyShape = new THREE.Shape();
    bodyShape.moveTo(-1.25, 0.25);
    bodyShape.quadraticCurveTo(-1.45, 1.05, -0.95, 1.25);
    bodyShape.lineTo(-0.35, 0.85);
    bodyShape.lineTo(0.75, 0.78);
    bodyShape.quadraticCurveTo(1.35, 1.02, 1.42, 0.55);
    bodyShape.quadraticCurveTo(1.15, 0.22, 0.72, 0.22);
    bodyShape.closePath();

    var crimsonWood = new THREE.MeshStandardMaterial({
      color: 0x8b1622,
      emissive: 0x3b070e,
      roughness: 0.36,
      metalness: 0.22,
    });
    var goldTrim = new THREE.MeshStandardMaterial({
      color: 0xfde68a,
      emissive: 0xf59e0b,
      emissiveIntensity: 0.72,
      metalness: 0.75,
      roughness: 0.22,
    });

    var sleighHull = new THREE.Mesh(
      new THREE.ExtrudeGeometry(bodyShape, {
        depth: 1.18,
        bevelEnabled: true,
        bevelThickness: 0.05,
        bevelSize: 0.04,
        bevelSegments: 2,
      }),
      crimsonWood
    );
    sleighHull.position.set(0, 0, -0.59);
    rig.add(sleighHull);

    // Graceful sweeping golden runners (CatmullRomCurve3)
    for (var rz = -1; rz <= 1; rz += 2) {
      var runnerCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-1.35, 0.06, rz * 0.52),
        new THREE.Vector3(0.0, 0.02, rz * 0.52),
        new THREE.Vector3(1.22, 0.08, rz * 0.52),
        new THREE.Vector3(1.62, 0.45, rz * 0.52),
        new THREE.Vector3(1.42, 0.65, rz * 0.52),
      ]);
      rig.add(
        new THREE.Mesh(new THREE.TubeGeometry(runnerCurve, 22, 0.042, 7, false), goldTrim)
      );
    }

    // Burlap gift sack + Santa figure with white trim & cap
    var sack = new THREE.Mesh(
      displaceGeometry(new THREE.IcosahedronGeometry(0.55, 1), 0.16, 2.5, 4),
      new THREE.MeshStandardMaterial({ color: 0x8d5b36, roughness: 0.9 })
    );
    sack.position.set(-0.62, 1.05, 0);
    rig.add(sack);

    var santaCoat = new THREE.Mesh(
      new THREE.ConeGeometry(0.38, 0.72, 12),
      new THREE.MeshStandardMaterial({ color: 0xb91c1c, roughness: 0.7 })
    );
    santaCoat.position.set(0.18, 1.15, 0);
    rig.add(santaCoat);

    var santaHead = new THREE.Mesh(
      new THREE.SphereGeometry(0.20, 12, 10),
      new THREE.MeshStandardMaterial({ color: 0xfad7bc, roughness: 0.6 })
    );
    santaHead.position.set(0.18, 1.62, 0);
    rig.add(santaHead);

    var santaCap = new THREE.Mesh(
      new THREE.ConeGeometry(0.21, 0.36, 10),
      new THREE.MeshStandardMaterial({ color: 0xb91c1c })
    );
    santaCap.position.set(0.12, 1.85, 0);
    santaCap.rotation.z = 0.25;
    rig.add(santaCap);

    // 4 Sculpted Reindeer flying in pair formation ahead (+X)
    var reindeer = [];
    for (var r = 0; r < 4; r++) {
      var d = buildRealisticDeer(0.72, furTextures, 10 + r);
      d.root.rotation.y = Math.PI / 2;
      var pairX = 3.2 + ((r / 2) | 0) * 2.35;
      var pairZ = (r % 2 === 0 ? 0.56 : -0.56);
      d.root.position.set(pairX, 0.22, pairZ);
      rig.add(d.root);
      reindeer.push(d);
    }

    // Fine glowing rein harness lines
    var reinMat = new THREE.LineBasicMaterial({
      color: 0xfde68a,
      transparent: true,
      opacity: 0.75,
    });
    var leftReinGeo = new THREE.BufferGeometry().setFromPoints([
      new THREE.Vector3(0.45, 1.15, -0.18),
      new THREE.Vector3(3.2, 1.15, -0.56),
      new THREE.Vector3(5.55, 1.15, -0.56),
    ]);
    var rightReinGeo = new THREE.BufferGeometry().setFromPoints([
      new THREE.Vector3(0.45, 1.15, 0.18),
      new THREE.Vector3(3.2, 1.15, 0.56),
      new THREE.Vector3(5.55, 1.15, 0.56),
    ]);
    rig.add(new THREE.Line(leftReinGeo, reinMat));
    rig.add(new THREE.Line(rightReinGeo, reinMat));

    var sleighGlow = new THREE.PointLight(0xfde68a, 2.2, 24, 1.5);
    sleighGlow.position.set(0, 1.4, 0);
    rig.add(sleighGlow);

    return { rig: rig, reindeer: reindeer };
  }

  // Sculpted alpine granite & snow-mantled mountain ridge (slope-driven vertex colors, zero geometric triangle caps)
  function buildRealisticMountains() {
    var group = new THREE.Group();
    var mtnMat = new THREE.MeshStandardMaterial({
      vertexColors: true,
      roughness: 0.9,
      metalness: 0.04,
      flatShading: false,
    });

    for (var m = 0; m < 18; m++) {
      var ma = -Math.PI * 0.92 + (m / 17) * Math.PI * 0.84 - Math.PI * 0.04;
      var dist = 90 + (m % 3) * 14;
      var mx = Math.cos(ma) * dist;
      var mz = Math.sin(ma) * dist - 20;
      var mh = 24 + (m % 5) * 6;
      var mr = 18 + (m % 3) * 5;

      var geo = new THREE.ConeGeometry(mr, mh, 18, 12, false);
      var pos = geo.attributes.position;
      for (var i = 0; i < pos.count; i++) {
        var vx = pos.getX(i);
        var vy = pos.getY(i);
        var vz = pos.getZ(i);
        var hFrac = clamp((vy + mh * 0.5) / mh, 0, 1);
        var ridge =
          Math.sin(vx * 0.25 + m) * 2.2 * (1 - hFrac * 0.35) +
          Math.cos(vz * 0.22 - m * 1.7) * 2.0 * (1 - hFrac * 0.35) +
          noise3(vx * 0.14, vy * 0.14, vz * 0.14, m + 3) * 3.4;
        pos.setXYZ(
          i,
          vx + Math.sin(m + vy * 0.1) * ridge * 0.45,
          vy + ridge * 0.25,
          vz + Math.cos(m + vx * 0.1) * ridge * 0.45
        );
      }
      geo.computeVertexNormals();

      var normals = geo.attributes.normal;
      var colors = new Float32Array(pos.count * 3);
      var rockCol = new THREE.Color(0x2d3f59);
      var snowCol = new THREE.Color(0xf2f7ff);
      var blendCol = new THREE.Color();

      for (var ci = 0; ci < pos.count; ci++) {
        var ny = normals.getY(ci);
        var py = pos.getY(ci);
        var alt = clamp((py + mh * 0.5) / mh, 0, 1);
        var snowMix = smoothstep((ny * 0.72 + alt * 0.55 - 0.58) / 0.26);
        blendCol.copy(rockCol).lerp(snowCol, snowMix);
        colors[ci * 3] = blendCol.r;
        colors[ci * 3 + 1] = blendCol.g;
        colors[ci * 3 + 2] = blendCol.b;
      }
      geo.setAttribute('color', new THREE.BufferAttribute(colors, 3));

      var mtnMesh = new THREE.Mesh(geo, mtnMat);
      mtnMesh.position.set(mx, mh * 0.40, mz);
      group.add(mtnMesh);
    }

    return group;
  }

  // Soft translucent painterly cloud banks in sky (Sprites with layered organic radial texture)
  function buildSoftCloudCluster(x, y, z, scale, cloudTex) {
    var g = new THREE.Group();
    var sprites = [];
    var puffs = [
      [0, 0, 0, 14, 7.5, 0.58],
      [-5.2, -0.6, 0.8, 10.5, 5.8, 0.45],
      [5.5, -0.5, -0.7, 11.0, 6.0, 0.46],
      [-2.2, 1.4, 0.5, 9.5, 5.5, 0.50],
      [2.6, 1.2, -0.4, 9.0, 5.2, 0.48],
    ];
    for (var i = 0; i < puffs.length; i++) {
      var pf = puffs[i];
      var mat = new THREE.SpriteMaterial({
        map: cloudTex,
        color: 0xffffff,
        transparent: true,
        opacity: pf[5],
        depthWrite: false,
      });
      var sp = new THREE.Sprite(mat);
      sp.position.set(pf[0] * scale, pf[1] * scale, pf[2] * scale);
      sp.scale.set(pf[3] * scale, pf[4] * scale, 1);
      g.add(sp);
      sprites.push({ mat: mat, baseAlpha: pf[5] });
    }
    g.position.set(x, y, z);
    return { group: g, sprites: sprites, baseY: y };
  }

  function createAuroraMesh() {
    var c = document.createElement('canvas');
    c.width = 512;
    c.height = 128;
    var ctx = c.getContext('2d');
    var g = ctx.createLinearGradient(0, 0, 512, 0);
    g.addColorStop(0.0, 'rgba(16,185,129,0.0)');
    g.addColorStop(0.24, 'rgba(52,211,153,0.52)');
    g.addColorStop(0.54, 'rgba(56,189,248,0.52)');
    g.addColorStop(0.82, 'rgba(168,85,247,0.42)');
    g.addColorStop(1.0, 'rgba(16,185,129,0.0)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, 512, 128);

    var vertFade = ctx.createLinearGradient(0, 0, 0, 128);
    vertFade.addColorStop(0.0, 'rgba(0,0,0,0)');
    vertFade.addColorStop(0.42, 'rgba(255,255,255,1)');
    vertFade.addColorStop(1.0, 'rgba(0,0,0,0)');
    ctx.globalCompositeOperation = 'destination-in';
    ctx.fillStyle = vertFade;
    ctx.fillRect(0, 0, 512, 128);

    var tex = new THREE.CanvasTexture(c);
    var mat = new THREE.MeshBasicMaterial({
      map: tex,
      transparent: true,
      opacity: 0.55,
      side: THREE.DoubleSide,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
    });
    var geo = new THREE.PlaneGeometry(156, 28, 32, 4);
    var mesh = new THREE.Mesh(geo, mat);
    mesh.position.set(0, 39, -84);
    return { mesh: mesh, mat: mat, geo: geo };
  }

  window.spnkWinterMount = function (container) {
    if (!window.spnkWinterIsAvailable() || !container) return 0;

    var w = Math.max(container.clientWidth || 800, 320);
    var h = Math.max(container.clientHeight || 540, 320);

    var renderer = new THREE.WebGLRenderer({
      antialias: true,
      alpha: false,
      powerPreference: 'high-performance',
    });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    renderer.setSize(w, h);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.05;
    renderer.domElement.style.width = '100%';
    renderer.domElement.style.height = '100%';
    renderer.domElement.style.display = 'block';
    container.innerHTML = '';
    container.appendChild(renderer.domElement);

    var scene = new THREE.Scene();
    scene.background = new THREE.Color(0x061024);
    scene.fog = new THREE.FogExp2(0x09162e, 0.0105);

    var camera = new THREE.PerspectiveCamera(50, w / h, 0.1, 300);
    camera.position.set(0, 6.2, 22);

    var hemiLight = new THREE.HemisphereLight(0x8bb8ff, 0x1e293b, 0.65);
    scene.add(hemiLight);

    var keyLight = new THREE.DirectionalLight(0xfff1d6, 1.35);
    keyLight.position.set(28, 36, 22);
    keyLight.castShadow = true;
    keyLight.shadow.mapSize.width = 1024;
    keyLight.shadow.mapSize.height = 1024;
    keyLight.shadow.camera.near = 5;
    keyLight.shadow.camera.far = 140;
    keyLight.shadow.camera.left = -45;
    keyLight.shadow.camera.right = 45;
    keyLight.shadow.camera.top = 45;
    keyLight.shadow.camera.bottom = -45;
    scene.add(keyLight);

    var warmLightsBucket = [];
    var interactiveTargets = [];

    var snowGroundTex = createSnowGroundTextures();
    var furTex = createFurTextures();
    var barkTex = createBarkTexture();
    var iglooTex = createIglooTextures();
    var timberTex = createTimberTextures();
    var cloudTex = createCloudPuffTexture();

    // Rolling Snow Ground Terrain
    var groundGeo = new THREE.PlaneGeometry(180, 220, 84, 96);
    groundGeo.rotateX(-Math.PI / 2);
    var posAttr = groundGeo.attributes.position;
    for (var vi = 0; vi < posAttr.count; vi++) {
      var gx = posAttr.getX(vi);
      var gz = posAttr.getZ(vi);
      posAttr.setY(vi, terrainHeightAt(gx, gz));
    }
    groundGeo.computeVertexNormals();

    var groundMat = new THREE.MeshStandardMaterial({
      map: snowGroundTex.map,
      bumpMap: snowGroundTex.bump,
      bumpScale: 0.04,
      color: 0xe6f0fa,
      roughness: 0.80,
      metalness: 0.02,
    });
    var groundMesh = new THREE.Mesh(groundGeo, groundMat);
    groundMesh.receiveShadow = true;
    scene.add(groundMesh);

    // Winding Wooden Trail Lantern Posts
    for (var pz = 14; pz >= -78; pz -= 11) {
      var px = Math.sin(pz * 0.055) * 4.5 + ((pz % 2 === 0) ? 2.9 : -2.9);
      var py = terrainHeightAt(px, pz);
      var sign = buildWoodenSignboard(timberTex, warmLightsBucket);
      sign.position.set(px, py, pz);
      sign.rotation.y = px > 0 ? -0.38 : 0.38;
      scene.add(sign);
    }

    // Alpine Sculpted Snow-Mantled Mountains
    scene.add(buildRealisticMountains());

    // Sun & Moon
    var sunMesh = new THREE.Mesh(
      new THREE.SphereGeometry(4.0, 20, 20),
      new THREE.MeshBasicMaterial({ color: 0xfff5c0 })
    );
    sunMesh.position.set(34, 42, -78);
    scene.add(sunMesh);

    var sunGlow = new THREE.Sprite(
      new THREE.SpriteMaterial({
        map: createGlowTexture('rgba(255,245,192,0.9)', 'rgba(253,224,71,0.22)'),
        transparent: true,
        blending: THREE.AdditiveBlending,
        depthWrite: false,
      })
    );
    sunGlow.scale.set(28, 28, 1);
    sunMesh.add(sunGlow);

    var moonMesh = new THREE.Mesh(
      new THREE.SphereGeometry(3.2, 20, 20),
      new THREE.MeshBasicMaterial({ color: 0xeef6ff })
    );
    moonMesh.position.set(-28, 38, -78);
    scene.add(moonMesh);

    var moonGlow = new THREE.Sprite(
      new THREE.SpriteMaterial({
        map: createGlowTexture('rgba(224,242,254,0.78)', 'rgba(147,197,253,0.2)'),
        transparent: true,
        blending: THREE.AdditiveBlending,
        depthWrite: false,
      })
    );
    moonGlow.scale.set(22, 22, 1);
    moonMesh.add(moonGlow);

    // Starfield
    var starCount = 950;
    var starPos = new Float32Array(starCount * 3);
    for (var si = 0; si < starCount; si++) {
      var st = si * 2.39996;
      var sr = 85 + (si % 40);
      var sy = 16 + ((si * 17) % 60);
      starPos[si * 3] = Math.cos(st) * sr;
      starPos[si * 3 + 1] = sy;
      starPos[si * 3 + 2] = Math.sin(st) * sr - 20;
    }
    var starGeo = new THREE.BufferGeometry();
    starGeo.setAttribute('position', new THREE.BufferAttribute(starPos, 3));
    var starMat = new THREE.PointsMaterial({
      color: 0xf8fafc,
      size: 0.72,
      transparent: true,
      opacity: 0.85,
    });
    scene.add(new THREE.Points(starGeo, starMat));

    var shootingStar = new THREE.Mesh(
      new THREE.SphereGeometry(0.22, 8, 8),
      new THREE.MeshBasicMaterial({ color: 0xfef9c3, transparent: true, opacity: 0 })
    );
    scene.add(shootingStar);

    // Aurora Borealis
    var aurora = createAuroraMesh();
    scene.add(aurora.mesh);

    // Soft Atmospheric Clouds
    var clouds = [];
    var cloudPositions = [
      [-24, 24, -44, 1.35],
      [18, 27, -52, 1.6],
      [-6, 22, -36, 1.15],
      [30, 21, -40, 1.25],
      [-32, 22, -55, 1.5],
    ];
    for (var ci = 0; ci < cloudPositions.length; ci++) {
      var cp = cloudPositions[ci];
      var cl = buildSoftCloudCluster(cp[0], cp[1], cp[2], cp[3], cloudTex);
      cl.speed = 0.55 + (ci % 3) * 0.25;
      cl.phase = ci * 1.3;
      scene.add(cl.group);
      clouds.push(cl);
    }

    // Packed-Snow Igloos
    var iglooPlacements = [
      { x: -10.5, z: 6.0, rot: 0.55, section: 'about' },
      { x: 11.5, z: -16.0, rot: -0.65, section: 'experience' },
      { x: -12.0, z: -38.0, rot: 0.45, section: 'projects' },
      { x: 10.5, z: -56.0, rot: -0.5, section: 'skills' },
    ];
    for (var ig = 0; ig < iglooPlacements.length; ig++) {
      var ip = iglooPlacements[ig];
      var igloo = buildRealisticIgloo(iglooTex, warmLightsBucket, ip.section, ig + 1);
      igloo.position.set(ip.x, terrainHeightAt(ip.x, ip.z) - 0.14, ip.z);
      igloo.rotation.y = ip.rot;
      scene.add(igloo);
      interactiveTargets.push(igloo);
    }

    // Authentic Log Cabins (About & Contact)
    var aboutCabin = buildRealisticWinterCabin(timberTex, barkTex, warmLightsBucket, 'about', 1.12);
    aboutCabin.position.set(11.0, terrainHeightAt(11.0, -5.0), -5.0);
    aboutCabin.rotation.y = -0.55;
    scene.add(aboutCabin);
    interactiveTargets.push(aboutCabin);

    var contactCabin = buildRealisticWinterCabin(timberTex, barkTex, warmLightsBucket, 'contact', 1.28);
    contactCabin.position.set(-7.5, terrainHeightAt(-7.5, -72.0), -72.0);
    contactCabin.rotation.y = 0.42;
    scene.add(contactCabin);
    interactiveTargets.push(contactCabin);

    // Chimney Smoke Puffs (soft sprites)
    var smokePuffs = [];
    for (var sp = 0; sp < 10; sp++) {
      var sMat = new THREE.SpriteMaterial({
        map: cloudTex,
        color: 0xe2e8f0,
        transparent: true,
        opacity: 0.28,
        depthWrite: false,
      });
      var puff = new THREE.Sprite(sMat);
      var useAbout = sp < 5;
      puff.userData.base = useAbout
        ? new THREE.Vector3(12.3, terrainHeightAt(11.0, -5.0) + 4.9, -5.6)
        : new THREE.Vector3(-6.1, terrainHeightAt(-7.5, -72.0) + 5.7, -72.6);
      puff.userData.phase = (sp % 5) / 5.0;
      scene.add(puff);
      smokePuffs.push(puff);
    }

    // Organic Multi-Whorl Hero Christmas Tree & Forest Pines
    var heroTree = buildRealisticPineTree(1.42, true, warmLightsBucket, 7.0, barkTex);
    heroTree.position.set(7.8, terrainHeightAt(7.8, 9.5), 9.5);
    heroTree.userData.sectionId = 'home';
    scene.add(heroTree);
    interactiveTargets.push(heroTree);

    var treeConfigs = [
      [-8.5, 11.5, 1.08, true, 12],
      [-14.5, -6.5, 1.22, false, 15],
      [15.5, -24.0, 1.28, true, 21],
      [-15.5, -28.0, 1.05, false, 29],
      [13.5, -43.0, 1.18, true, 35],
      [-14.0, -55.0, 1.14, false, 41],
      [14.5, -67.0, 1.32, true, 47],
      [-16.0, -76.0, 1.18, false, 53],
    ];
    for (var tc = 0; tc < treeConfigs.length; tc++) {
      var tcfg = treeConfigs[tc];
      var pine = buildRealisticPineTree(tcfg[2], tcfg[3], warmLightsBucket, tcfg[4], barkTex);
      pine.position.set(tcfg[0], terrainHeightAt(tcfg[0], tcfg[1]), tcfg[1]);
      scene.add(pine);
    }
    for (var bf = 0; bf < 26; bf++) {
      var bx = (bf % 2 === 0 ? 1 : -1) * (18.5 + (bf * 7) % 26);
      var bz = 18 - bf * 4.2;
      var bs = 0.85 + (bf % 4) * 0.22;
      var bgTree = buildRealisticPineTree(bs, false, warmLightsBucket, 100 + bf, barkTex);
      bgTree.position.set(bx, terrainHeightAt(bx, bz), bz);
      scene.add(bgTree);
    }

    // Sculpted Weather-Worn Alpine Boulders + Snow Caps
    var rockMat = new THREE.MeshStandardMaterial({ color: 0x475569, roughness: 0.94 });
    var rockSnowMat = new THREE.MeshStandardMaterial({ color: 0xf1f7ff, roughness: 0.72 });
    for (var rk = 0; rk < 18; rk++) {
      var rx = (rk % 2 === 0 ? 1 : -1) * (4.8 + (rk * 5) % 15);
      var rz = 12 - rk * 5.2;
      var rs = 0.48 + (rk % 3) * 0.24;
      var rockGroup = new THREE.Group();
      var rock = new THREE.Mesh(
        displaceGeometry(new THREE.IcosahedronGeometry(rs, 2), 0.26, 2.2, rk + 9),
        rockMat
      );
      rock.scale.set(1.28, 0.72, 1.08);
      rock.castShadow = true;
      rock.receiveShadow = true;
      rockGroup.add(rock);

      var rCap = new THREE.Mesh(
        displaceGeometry(new THREE.IcosahedronGeometry(rs * 0.88, 2), 0.18, 2.4, rk + 19),
        rockSnowMat
      );
      rCap.scale.set(1.18, 0.34, 1.0);
      rCap.position.y = rs * 0.32;
      rockGroup.add(rCap);

      rockGroup.position.set(rx, terrainHeightAt(rx, rz) + rs * 0.22, rz);
      rockGroup.rotation.y = rk * 0.8;
      scene.add(rockGroup);
    }

    // Sculpted Wild Deer Herd (natural gait, knee/hock bend, idle pause & alert head scanning)
    var deerActors = [];
    var deerConfigs = [
      { cx: -4.2, cz: 7.5, rx: 4.5, rz: 3.0, speed: 0.72, scale: 0.95, phase: 0.0 },
      { cx: 5.5, cz: -14.0, rx: 4.0, rz: 4.5, speed: 0.60, scale: 1.04, phase: 1.8 },
      { cx: -5.5, cz: -34.0, rx: 5.0, rz: 3.5, speed: 0.68, scale: 0.90, phase: 3.2 },
      { cx: 4.2, cz: -52.0, rx: 4.2, rz: 4.0, speed: 0.63, scale: 0.98, phase: 4.7 },
    ];
    for (var da = 0; da < deerConfigs.length; da++) {
      var dc = deerConfigs[da];
      var deer = buildRealisticDeer(dc.scale, furTex, da + 1);
      deer.root.userData.sectionId = 'experience';
      scene.add(deer.root);
      interactiveTargets.push(deer.root);
      deerActors.push({
        model: deer,
        cfg: dc,
        angle: dc.phase,
        isIdle: false,
        stateTimer: 3.5 + da * 1.3,
      });
    }

    // Santa Claus & Flying Reindeer Team
    var santa = buildRealisticSantaSleigh(furTex);
    santa.rig.visible = false;
    scene.add(santa.rig);
    var santaState = {
      active: false,
      timer: 18.0,
      progress: 0.0,
      direction: 1,
      yBase: 23,
      zBase: -42,
    };

    // 3D Snowfall Particle System
    var snowCount = 1350;
    var snowPositions = new Float32Array(snowCount * 3);
    var snowSpeeds = new Float32Array(snowCount);
    for (var sn = 0; sn < snowCount; sn++) {
      snowPositions[sn * 3] = ((sn * 73) % 100) - 50;
      snowPositions[sn * 3 + 1] = (sn * 37) % 40;
      snowPositions[sn * 3 + 2] = 24 - ((sn * 19) % 115);
      snowSpeeds[sn] = 1.6 + (sn % 7) * 0.45;
    }
    var snowGeo = new THREE.BufferGeometry();
    snowGeo.setAttribute('position', new THREE.BufferAttribute(snowPositions, 3));
    var snowMat = new THREE.PointsMaterial({
      map: createSnowflakeTexture(),
      size: 0.54,
      transparent: true,
      opacity: 0.85,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
    });
    var snowPoints = new THREE.Points(snowGeo, snowMat);
    scene.add(snowPoints);

    var cameraAnchor = new THREE.Vector3(0, 6.2, 22);
    var lookAnchor = new THREE.Vector3(0, 2.6, 2);

    var inst = {
      id: _nextId++,
      container: container,
      renderer: renderer,
      scene: scene,
      camera: camera,
      raycaster: new THREE.Raycaster(),
      interactiveTargets: interactiveTargets,
      targetDayFactor: 0.0,
      currentDayFactor: 0.0,
      targetScrollFraction: 0.0,
      currentScrollFraction: 0.0,
      pointerNormX: 0.0,
      pointerNormY: 0.0,
      snowEnabled: true,
      reducedMotion: false,
      disposed: false,
      rafId: 0,
      lastTime: performance.now(),
      elapsed: 0,
      onResize: null,
    };

    inst.onResize = function () {
      if (inst.disposed || !inst.container) return;
      var nw = Math.max(inst.container.clientWidth || 800, 320);
      var nh = Math.max(inst.container.clientHeight || 540, 320);
      camera.aspect = nw / nh;
      camera.updateProjectionMatrix();
      renderer.setSize(nw, nh);
    };
    window.addEventListener('resize', inst.onResize);

    function applyDayNightAtmosphere(dayF, timeSec) {
      var skyNight = new THREE.Color(0x061024);
      var skyDay = new THREE.Color(0x6eb6f5);
      scene.background.copy(skyNight).lerp(skyDay, dayF);

      var fogNight = new THREE.Color(0x0a172e);
      var fogDay = new THREE.Color(0xcde6fb);
      scene.fog.color.copy(fogNight).lerp(fogDay, dayF);
      scene.fog.density = lerp(0.0108, 0.0082, dayF);

      hemiLight.color.setHex(0x8bb8ff).lerp(new THREE.Color(0xe0f2fe), dayF);
      hemiLight.groundColor.setHex(0x132033).lerp(new THREE.Color(0x94a3b8), dayF);
      hemiLight.intensity = lerp(0.55, 1.05, dayF);

      keyLight.color.setHex(0x9ec5ff).lerp(new THREE.Color(0xfff4dc), dayF);
      keyLight.intensity = lerp(0.58, 1.55, dayF);
      keyLight.position.set(lerp(-24, 30, dayF), lerp(32, 40, dayF), lerp(-20, 22, dayF));

      sunMesh.visible = dayF > 0.04;
      sunMesh.position.y = lerp(12, 42, dayF);
      moonMesh.visible = dayF < 0.96;
      moonMesh.position.y = lerp(38, 10, dayF);

      starMat.opacity = clamp((1.0 - dayF * 1.35) * 0.9, 0, 0.95);
      aurora.mat.opacity = clamp((1.0 - dayF * 1.4) * (0.42 + 0.14 * Math.sin(timeSec * 0.7)), 0, 0.65);

      var cloudDayCol = new THREE.Color(0xffffff);
      var cloudNightCol = new THREE.Color(0x3a5275);
      var cloudTint = cloudNightCol.clone().lerp(cloudDayCol, dayF);
      for (var ci = 0; ci < clouds.length; ci++) {
        var spList = clouds[ci].sprites;
        for (var si = 0; si < spList.length; si++) {
          spList[si].mat.color.copy(cloudTint);
          spList[si].mat.opacity = spList[si].baseAlpha * lerp(0.45, 0.95, dayF);
        }
      }

      for (var wi = 0; wi < warmLightsBucket.length; wi++) {
        var item = warmLightsBucket[wi];
        if (item.light) {
          item.light.intensity = lerp(item.nightIntensity, item.dayIntensity, dayF);
        }
        if (item.mat) {
          var twinkle = inst.reducedMotion ? 1.0 : (0.76 + 0.24 * Math.sin(timeSec * 3.0 + item.phase));
          item.mat.emissiveIntensity = lerp(item.base * 1.15, item.base * 0.35, dayF) * twinkle;
        }
      }
    }

    function animate() {
      if (inst.disposed) return;
      inst.rafId = requestAnimationFrame(animate);

      var now = performance.now();
      var dt = clamp((now - inst.lastTime) / 1000.0, 0.001, 0.05);
      inst.lastTime = now;

      if (!inst.reducedMotion) {
        inst.elapsed += dt;
      }
      var t = inst.elapsed;

      inst.currentDayFactor = lerp(inst.currentDayFactor, inst.targetDayFactor, 1 - Math.exp(-2.8 * dt));
      inst.currentScrollFraction = lerp(inst.currentScrollFraction, inst.targetScrollFraction, 1 - Math.exp(-5.0 * dt));
      applyDayNightAtmosphere(inst.currentDayFactor, t);

      var s = inst.currentScrollFraction;
      var targetZ = lerp(21.0, -56.0, s);
      var targetX = Math.sin(targetZ * 0.055) * 4.0 + inst.pointerNormX * 1.8;
      var targetY = 6.2 - inst.pointerNormY * 0.7 + terrainHeightAt(targetX, targetZ) * 0.4;
      cameraAnchor.set(targetX, targetY, targetZ);
      lookAnchor.set(Math.sin((targetZ - 16) * 0.055) * 3.2, 2.2, targetZ - 18.0);
      camera.position.lerp(cameraAnchor, 1 - Math.exp(-6.0 * dt));
      camera.lookAt(lookAnchor);

      if (!inst.reducedMotion) {
        for (var ci = 0; ci < clouds.length; ci++) {
          var cl = clouds[ci];
          cl.group.position.x += cl.speed * dt;
          cl.group.position.y = cl.baseY + Math.sin(t * 0.45 + cl.phase) * 0.4;
          if (cl.group.position.x > 46) cl.group.position.x = -46;
        }

        var ap = aurora.geo.attributes.position;
        for (var ai = 0; ai < ap.count; ai++) {
          var ax = ap.getX(ai);
          ap.setZ(ai, Math.sin(ax * 0.08 + t * 0.9) * 5.0);
        }
        ap.needsUpdate = true;

        for (var si = 0; si < smokePuffs.length; si++) {
          var sf = smokePuffs[si];
          var age = (sf.userData.phase + t * 0.22) % 1.0;
          sf.position.set(
            sf.userData.base.x + Math.sin(age * 4 + si) * 0.35,
            sf.userData.base.y + age * 4.8,
            sf.userData.base.z - age * 0.65
          );
          var sc = 0.85 + age * 2.1;
          sf.scale.set(sc, sc, 1);
          sf.material.opacity = Math.sin(age * Math.PI) * 0.34;
        }

        // Articulated 2-joint Deer Walk + Natural Grazing / Scanning Pause
        for (var di = 0; di < deerActors.length; di++) {
          var da = deerActors[di];
          da.stateTimer -= dt;
          if (da.stateTimer <= 0) {
            da.isIdle = !da.isIdle;
            da.stateTimer = da.isIdle ? (2.4 + (di % 3) * 0.9) : (5.2 + (di % 4) * 1.4);
          }

          if (!da.isIdle) {
            da.angle += dt * da.cfg.speed * 0.45;
            var nx = da.cfg.cx + Math.cos(da.angle) * da.cfg.rx;
            var nz = da.cfg.cz + Math.sin(da.angle) * da.cfg.rz;
            var dx = -Math.sin(da.angle) * da.cfg.rx;
            var dz = Math.cos(da.angle) * da.cfg.rz;
            var groundY = terrainHeightAt(nx, nz);
            var stridePhase = t * 5.4 + di;
            da.model.root.position.set(nx, groundY + Math.abs(Math.sin(stridePhase)) * 0.025, nz);
            da.model.root.rotation.y = Math.atan2(dx, dz);

            for (var lg = 0; lg < 4; lg++) {
              var ph = stridePhase + (lg === 1 || lg === 2 ? Math.PI : 0);
              var swing = Math.sin(ph);
              var lift = Math.max(0, Math.cos(ph));
              var legObj = da.model.legs[lg];
              legObj.hip.rotation.x = swing * 0.38;
              legObj.knee.rotation.x = legObj.isHind
                ? -lift * 0.45
                : lift * 0.55;
            }
            da.model.neckPivot.rotation.y = Math.sin(t * 1.1 + di) * 0.1;
            da.model.neckPivot.rotation.x = 0.05 * Math.sin(stridePhase * 2.0);
            da.model.tailPivot.rotation.z = Math.sin(t * 3.0 + di) * 0.08;
          } else {
            for (var lg2 = 0; lg2 < 4; lg2++) {
              da.model.legs[lg2].hip.rotation.x *= 0.86;
              da.model.legs[lg2].knee.rotation.x *= 0.86;
            }
            da.model.neckPivot.rotation.y = Math.sin(t * 1.4 + di) * 0.48;
            da.model.neckPivot.rotation.x = 0.18 + Math.sin(t * 0.95) * 0.16;
            da.model.tailPivot.rotation.z = Math.sin(t * 5.0 + di) * 0.16;
          }
        }

        // Santa Sleigh + Flying Reindeer Team
        if (!santaState.active) {
          santaState.timer -= dt;
          if (santaState.timer <= 0) {
            santaState.active = true;
            santaState.progress = 0.0;
            santaState.direction = Math.random() > 0.5 ? 1 : -1;
            santaState.yBase = 21 + Math.random() * 8;
            santaState.zBase = camera.position.z - 52;
            santa.rig.visible = true;
            santa.rig.rotation.y = santaState.direction > 0 ? 0 : Math.PI;
          }
        } else {
          santaState.progress += dt * 0.09;
          var sx = lerp(-58 * santaState.direction, 58 * santaState.direction, santaState.progress);
          var sy = santaState.yBase + Math.sin(santaState.progress * Math.PI * 2) * 2.2;
          santa.rig.position.set(sx, sy, santaState.zBase);
          for (var sr = 0; sr < santa.reindeer.length; sr++) {
            var rd = santa.reindeer[sr];
            for (var rl = 0; rl < 4; rl++) {
              var gp = t * 9.0 + sr + (rl < 2 ? 0 : Math.PI);
              rd.legs[rl].hip.rotation.x = Math.sin(gp) * 0.55;
              rd.legs[rl].knee.rotation.x = (rd.legs[rl].isHind ? -0.45 : 0.65) * Math.max(0, Math.cos(gp));
            }
          }
          if (santaState.progress >= 1.0) {
            santaState.active = false;
            santaState.timer = 32 + Math.random() * 26;
            santa.rig.visible = false;
          }
        }

        if (inst.currentDayFactor < 0.35) {
          var shootCycle = t % 13.0;
          if (shootCycle < 1.1) {
            var sp2 = shootCycle / 1.1;
            shootingStar.material.opacity = Math.sin(sp2 * Math.PI) * 0.9;
            shootingStar.position.set(lerp(-35, 25, sp2), lerp(44, 24, sp2), -72);
          } else {
            shootingStar.material.opacity = 0;
          }
        } else {
          shootingStar.material.opacity = 0;
        }

        snowPoints.visible = inst.snowEnabled;
        if (inst.snowEnabled) {
          var spAttr = snowGeo.attributes.position;
          for (var i = 0; i < snowCount; i++) {
            var sy2 = spAttr.getY(i) - snowSpeeds[i] * dt;
            var sx2 = spAttr.getX(i) + Math.sin(t * 0.9 + i) * 0.35 * dt;
            if (sy2 < -1.0) {
              sy2 = 38.0;
              sx2 = ((i * 73) % 100) - 50;
            }
            spAttr.setXY(i, sx2, sy2);
          }
          spAttr.needsUpdate = true;
          snowPoints.position.z = camera.position.z - 38;
        }
      }

      renderer.render(scene, camera);
    }

    inst.rafId = requestAnimationFrame(animate);
    _instances[inst.id] = inst;
    return inst.id;
  };

  window.spnkWinterSyncState = function (id, jsonStr) {
    var inst = _instances[id];
    if (!inst || inst.disposed) return;
    try {
      var data = JSON.parse(jsonStr);
      if (typeof data.dayFactor === 'number') inst.targetDayFactor = clamp(data.dayFactor, 0, 1);
      if (typeof data.scrollFraction === 'number') inst.targetScrollFraction = clamp(data.scrollFraction, 0, 1);
      if (typeof data.pointerX === 'number') inst.pointerNormX = clamp(data.pointerX, -1, 1);
      if (typeof data.pointerY === 'number') inst.pointerNormY = clamp(data.pointerY, -1, 1);
      if (typeof data.snowEnabled === 'boolean') inst.snowEnabled = data.snowEnabled;
      if (typeof data.reducedMotion === 'boolean') inst.reducedMotion = data.reducedMotion;
    } catch (e) {}
  };

  window.spnkWinterRaycast = function (id, normX, normY) {
    var inst = _instances[id];
    if (!inst || inst.disposed) return '';
    try {
      inst.raycaster.setFromCamera(new THREE.Vector2(normX, normY), inst.camera);
      var hits = inst.raycaster.intersectObjects(inst.interactiveTargets, true);
      if (hits && hits.length > 0) {
        var obj = hits[0].object;
        while (obj && !obj.userData.sectionId && obj.parent) {
          obj = obj.parent;
        }
        return (obj && obj.userData && obj.userData.sectionId) ? obj.userData.sectionId : '';
      }
    } catch (e) {}
    return '';
  };

  window.spnkWinterDispose = function (id) {
    var inst = _instances[id];
    if (!inst) return;
    inst.disposed = true;
    cancelAnimationFrame(inst.rafId);
    if (inst.onResize) {
      window.removeEventListener('resize', inst.onResize);
    }
    try {
      inst.renderer.dispose();
    } catch (e) {}
    delete _instances[id];
  };
})();
