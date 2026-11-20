(function () {
  'use strict';

  var _instances = {};
  var _nextId = 1;

  function parseHexColor(hexInt) {
    return new THREE.Color((hexInt || 0) & 0xffffff);
  }

  window.spnkSolarIsAvailable = function () {
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

  function createGlowTexture(innerCss, midCss) {
    var canvas = document.createElement('canvas');
    canvas.width = 256;
    canvas.height = 256;
    var ctx = canvas.getContext('2d');
    var grad = ctx.createRadialGradient(128, 128, 6, 128, 128, 128);
    grad.addColorStop(0.0, innerCss);
    grad.addColorStop(0.32, midCss);
    grad.addColorStop(1.0, 'rgba(0,0,0,0)');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, 256, 256);
    var tex = new THREE.CanvasTexture(canvas);
    tex.needsUpdate = true;
    return tex;
  }

  function createPlanetTexture(style, primaryHex, secondaryHex) {
    var canvas = document.createElement('canvas');
    canvas.width = 256;
    canvas.height = 128;
    var ctx = canvas.getContext('2d');
    var c1 = '#' + (primaryHex & 0xffffff).toString(16).padStart(6, '0');
    var c2 = '#' + (secondaryHex & 0xffffff).toString(16).padStart(6, '0');

    var grad = ctx.createLinearGradient(0, 0, 0, 128);
    grad.addColorStop(0.0, c1);
    grad.addColorStop(0.5, c2);
    grad.addColorStop(1.0, c1);
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, 256, 128);

    // Procedural atmospheric/surface detail per planet style
    ctx.globalAlpha = 0.28;
    if (style === 'ringed' || style === 'plasma') {
      for (var y = 0; y < 128; y += 8) {
        ctx.fillStyle = y % 16 === 0 ? '#ffffff' : '#090d16';
        ctx.fillRect(0, y, 256, 3 + (y % 5));
      }
    } else if (style === 'terran' || style === 'nebula') {
      for (var i = 0; i < 24; i++) {
        ctx.fillStyle = i % 2 === 0 ? '#ffffff' : c2;
        ctx.beginPath();
        ctx.ellipse(
          (i * 47) % 256,
          (i * 31) % 128,
          18 + (i % 14),
          7 + (i % 6),
          (i % 5) * 0.3,
          0,
          Math.PI * 2
        );
        ctx.fill();
      }
    } else {
      for (var k = 0; k < 18; k++) {
        ctx.fillStyle = k % 3 === 0 ? '#ffffff' : '#0f172a';
        ctx.beginPath();
        ctx.arc((k * 59) % 256, (k * 23) % 128, 4 + (k % 7), 0, Math.PI * 2);
        ctx.fill();
      }
    }
    ctx.globalAlpha = 1.0;

    var tex = new THREE.CanvasTexture(canvas);
    tex.wrapS = THREE.RepeatWrapping;
    tex.needsUpdate = true;
    return tex;
  }

  function createStarTexture() {
    var canvas = document.createElement('canvas');
    canvas.width = 256;
    canvas.height = 128;
    var ctx = canvas.getContext('2d');
    var grad = ctx.createLinearGradient(0, 0, 256, 128);
    grad.addColorStop(0.0, '#fff7ed');
    grad.addColorStop(0.35, '#fbbf24');
    grad.addColorStop(0.7, '#f97316');
    grad.addColorStop(1.0, '#fbbf24');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, 256, 128);
    for (var i = 0; i < 42; i++) {
      ctx.fillStyle = i % 2 === 0
        ? 'rgba(255,255,255,0.28)'
        : 'rgba(234,88,12,0.28)';
      ctx.beginPath();
      ctx.arc((i * 43) % 256, (i * 29) % 128, 6 + (i % 10), 0, Math.PI * 2);
      ctx.fill();
    }
    var tex = new THREE.CanvasTexture(canvas);
    tex.wrapS = THREE.RepeatWrapping;
    tex.needsUpdate = true;
    return tex;
  }

  function makeLabelSprite(title, subTitle, accentHex, scaleW, scaleH) {
    var canvas = document.createElement('canvas');
    canvas.width = 320;
    canvas.height = 96;
    var ctx = canvas.getContext('2d');
    var hexStr = '#' + (accentHex & 0xffffff).toString(16).padStart(6, '0');

    ctx.fillStyle = 'rgba(7, 11, 20, 0.82)';
    ctx.strokeStyle = hexStr;
    ctx.lineWidth = 3;
    var r = 18;
    ctx.beginPath();
    ctx.moveTo(r + 8, 8);
    ctx.lineTo(312 - r, 8);
    ctx.quadraticCurveTo(312, 8, 312, 8 + r);
    ctx.lineTo(312, 88 - r);
    ctx.quadraticCurveTo(312, 88, 312 - r, 88);
    ctx.lineTo(r + 8, 88);
    ctx.quadraticCurveTo(8, 88, 8, 88 - r);
    ctx.lineTo(8, 8 + r);
    ctx.quadraticCurveTo(8, 8, r + 8, 8);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    ctx.textAlign = 'center';
    ctx.fillStyle = '#f8fafc';
    ctx.font = 'bold 26px sans-serif';
    ctx.fillText(String(title || '').slice(0, 22), 160, subTitle ? 46 : 58);

    if (subTitle) {
      ctx.fillStyle = hexStr;
      ctx.font = 'bold 17px sans-serif';
      ctx.fillText(String(subTitle || '').slice(0, 28), 160, 74);
    }

    var tex = new THREE.CanvasTexture(canvas);
    tex.needsUpdate = true;
    var mat = new THREE.SpriteMaterial({
      map: tex,
      transparent: true,
      depthTest: false,
    });
    var sprite = new THREE.Sprite(mat);
    sprite.scale.set(scaleW, scaleH, 1);
    sprite.renderOrder = 12;
    return sprite;
  }

  function makeOrbitLine(radius, inclination, colorHex, opacity) {
    var segments = 128;
    var positions = new Float32Array(segments * 3);
    for (var i = 0; i < segments; i++) {
      var a = (i / segments) * Math.PI * 2;
      var cx = Math.cos(a) * radius;
      var cz = Math.sin(a) * radius;
      positions[i * 3] = cx;
      positions[i * 3 + 1] = cz * Math.sin(inclination || 0);
      positions[i * 3 + 2] = cz * Math.cos(inclination || 0);
    }
    var geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    var mat = new THREE.LineBasicMaterial({
      color: parseHexColor(colorHex),
      transparent: true,
      opacity: opacity,
    });
    return new THREE.LineLoop(geo, mat);
  }

  function disposeObjectTree(root, scene) {
    if (!root) return;
    root.traverse(function (obj) {
      if (obj.geometry) obj.geometry.dispose();
      if (obj.material) {
        var mats = Array.isArray(obj.material) ? obj.material : [obj.material];
        for (var i = 0; i < mats.length; i++) {
          if (mats[i].map) mats[i].map.dispose();
          mats[i].dispose();
        }
      }
    });
    if (scene && root.parent === scene) {
      scene.remove(root);
    }
  }

  window.spnkSolarMount = function (container) {
    if (!window.spnkSolarIsAvailable() || !container) return 0;

    var w = Math.max(container.clientWidth || 800, 320);
    var h = Math.max(container.clientHeight || 540, 320);

    var renderer = new THREE.WebGLRenderer({
      antialias: true,
      alpha: false,
      powerPreference: 'high-performance',
    });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    renderer.setSize(w, h);
    renderer.domElement.style.width = '100%';
    renderer.domElement.style.height = '100%';
    renderer.domElement.style.display = 'block';
    container.innerHTML = '';
    container.appendChild(renderer.domElement);

    var scene = new THREE.Scene();
    scene.background = new THREE.Color(0x040711);

    var camera = new THREE.PerspectiveCamera(48, w / h, 0.1, 650);
    camera.position.set(0, 30, 62);

    var ambientLight = new THREE.AmbientLight(0x8fa8ff, 0.48);
    scene.add(ambientLight);

    var sunLight = new THREE.PointLight(0xffcf70, 2.5, 260, 1.1);
    sunLight.position.set(0, 0, 0);
    scene.add(sunLight);

    var rimLight = new THREE.DirectionalLight(0x38bdf8, 0.42);
    rimLight.position.set(-40, 35, -35);
    scene.add(rimLight);

    // Deep-space multi-color starfield
    var starCount = 2400;
    var starPositions = new Float32Array(starCount * 3);
    var starColors = new Float32Array(starCount * 3);
    var palette = [
      new THREE.Color(0xf8fafc),
      new THREE.Color(0x7dd3fc),
      new THREE.Color(0xfde68a),
      new THREE.Color(0xc4b5fd),
    ];
    for (var i = 0; i < starCount; i++) {
      var r = 110 + ((i * 37) % 190);
      var theta = i * 2.39996;
      var phi = Math.acos(clampStarY(((i * 19) % 200) / 100 - 1));
      starPositions[i * 3] = r * Math.sin(phi) * Math.cos(theta);
      starPositions[i * 3 + 1] = r * Math.cos(phi);
      starPositions[i * 3 + 2] = r * Math.sin(phi) * Math.sin(theta);
      var col = palette[i % palette.length];
      starColors[i * 3] = col.r;
      starColors[i * 3 + 1] = col.g;
      starColors[i * 3 + 2] = col.b;
    }
    function clampStarY(v) {
      return v < -1 ? -1 : (v > 1 ? 1 : v);
    }
    var starGeo = new THREE.BufferGeometry();
    starGeo.setAttribute('position', new THREE.BufferAttribute(starPositions, 3));
    starGeo.setAttribute('color', new THREE.BufferAttribute(starColors, 3));
    var starMat = new THREE.PointsMaterial({
      size: 0.95,
      vertexColors: true,
      transparent: true,
      opacity: 0.92,
    });
    var starPoints = new THREE.Points(starGeo, starMat);
    scene.add(starPoints);

    // Subtle asteroid belt dust ring between Experience & Projects
    var beltCount = 420;
    var beltPos = new Float32Array(beltCount * 3);
    for (var b = 0; b < beltCount; b++) {
      var ang = (b / beltCount) * Math.PI * 2 + (b % 7) * 0.1;
      var br = 33.4 + ((b * 13) % 100) / 50.0;
      beltPos[b * 3] = Math.cos(ang) * br;
      beltPos[b * 3 + 1] = (((b * 7) % 20) - 10) * 0.08;
      beltPos[b * 3 + 2] = Math.sin(ang) * br;
    }
    var beltGeo = new THREE.BufferGeometry();
    beltGeo.setAttribute('position', new THREE.BufferAttribute(beltPos, 3));
    var beltPoints = new THREE.Points(
      beltGeo,
      new THREE.PointsMaterial({
        color: 0x94a3b8,
        size: 0.35,
        transparent: true,
        opacity: 0.45,
      })
    );
    scene.add(beltPoints);

    var systemRoot = new THREE.Group();
    scene.add(systemRoot);

    var inst = {
      id: _nextId++,
      container: container,
      renderer: renderer,
      scene: scene,
      camera: camera,
      ambientLight: ambientLight,
      sunLight: sunLight,
      starPoints: starPoints,
      beltPoints: beltPoints,
      systemRoot: systemRoot,
      starGroup: null,
      planets: {},
      moons: {},
      hitMeshes: [],
      raycaster: new THREE.Raycaster(),
      animId: 0,
      resizeObserver: null,
    };

    if (typeof ResizeObserver !== 'undefined') {
      inst.resizeObserver = new ResizeObserver(function () {
        var nw = Math.max(container.clientWidth || 1, 1);
        var nh = Math.max(container.clientHeight || 1, 1);
        camera.aspect = nw / nh;
        camera.updateProjectionMatrix();
        renderer.setSize(nw, nh);
      });
      inst.resizeObserver.observe(container);
    }

    var renderLoop = function () {
      inst.animId = window.requestAnimationFrame(renderLoop);
      starPoints.rotation.y += 0.00025;
      beltPoints.rotation.y += 0.0005;
      if (inst.starGroup) {
        inst.starGroup.rotation.y += 0.003;
      }
      renderer.render(scene, camera);
    };
    renderLoop();

    _instances[inst.id] = inst;
    return inst.id;
  };

  window.spnkSolarSetSystemData = function (id, jsonStr) {
    var inst = _instances[id];
    if (!inst) return;

    var data;
    try {
      data = JSON.parse(jsonStr);
    } catch (e) {
      return;
    }

    disposeObjectTree(inst.systemRoot, inst.scene);
    inst.systemRoot = new THREE.Group();
    inst.scene.add(inst.systemRoot);
    inst.planets = {};
    inst.moons = {};
    inst.hitMeshes = [];

    // 1. Central Star (SIVAPRASAD NK)
    var starGroup = new THREE.Group();
    var starGeo = new THREE.SphereGeometry(4.2, 42, 32);
    var starMat = new THREE.MeshBasicMaterial({ map: createStarTexture() });
    var starMesh = new THREE.Mesh(starGeo, starMat);
    starGroup.add(starMesh);

    var coronaSprite = new THREE.Sprite(
      new THREE.SpriteMaterial({
        map: createGlowTexture('rgba(255,245,214,0.92)', 'rgba(249,115,22,0.42)'),
        transparent: true,
        blending: THREE.AdditiveBlending,
        depthWrite: false,
      })
    );
    coronaSprite.scale.set(17.5, 17.5, 1);
    starGroup.add(coronaSprite);

    var starHit = new THREE.Mesh(
      new THREE.SphereGeometry(5.8, 16, 12),
      new THREE.MeshBasicMaterial({ transparent: true, opacity: 0.0, depthWrite: false })
    );
    starHit.userData = { kind: 'star' };
    starGroup.add(starHit);
    inst.hitMeshes.push(starHit);

    var starLabel = makeLabelSprite(
      (data.star && data.star.title) || 'SIVAPRASAD NK',
      (data.star && data.star.subtitle) || 'CENTRAL STAR',
      0xfbbf24,
      8.8,
      2.65
    );
    starLabel.position.set(0, 6.2, 0);
    starGroup.add(starLabel);

    inst.systemRoot.add(starGroup);
    inst.starGroup = starGroup;

    // 2. Orbiting Planets & their Moons
    var planetsList = data.planets || [];
    for (var i = 0; i < planetsList.length; i++) {
      var pData = planetsList[i];
      var orbitLine = makeOrbitLine(
        pData.orbitRadius,
        pData.inclination,
        pData.color,
        0.28
      );
      inst.systemRoot.add(orbitLine);

      var pGroup = new THREE.Group();
      var pGeo = new THREE.SphereGeometry(pData.radius, 32, 24);
      var pMat = new THREE.MeshStandardMaterial({
        map: createPlanetTexture(
          pData.textureStyle,
          pData.color,
          pData.secondaryColor
        ),
        roughness: 0.62,
        metalness: 0.14,
        emissive: parseHexColor(pData.color),
        emissiveIntensity: 0.18,
      });
      var pMesh = new THREE.Mesh(pGeo, pMat);
      pGroup.add(pMesh);

      // Atmosphere glow
      var atmoMesh = new THREE.Mesh(
        new THREE.SphereGeometry(pData.radius * 1.13, 24, 18),
        new THREE.MeshBasicMaterial({
          color: parseHexColor(pData.color),
          transparent: true,
          opacity: 0.16,
          side: THREE.BackSide,
          depthWrite: false,
        })
      );
      pGroup.add(atmoMesh);

      if (pData.hasRing) {
        var ringGeo = new THREE.RingGeometry(
          pData.radius * 1.38,
          pData.radius * 2.15,
          64
        );
        var ringMat = new THREE.MeshBasicMaterial({
          color: parseHexColor(pData.secondaryColor),
          side: THREE.DoubleSide,
          transparent: true,
          opacity: 0.55,
        });
        var ringMesh = new THREE.Mesh(ringGeo, ringMat);
        ringMesh.rotation.x = -Math.PI * 0.44;
        ringMesh.rotation.y = 0.25;
        pGroup.add(ringMesh);
      }

      // Generous raycast hit sphere for smooth clicking
      var pHit = new THREE.Mesh(
        new THREE.SphereGeometry(pData.radius * 1.75, 16, 12),
        new THREE.MeshBasicMaterial({ transparent: true, opacity: 0.0, depthWrite: false })
      );
      pHit.userData = { kind: 'planet', planetId: pData.id };
      pGroup.add(pHit);
      inst.hitMeshes.push(pHit);

      var pLabel = makeLabelSprite(
        pData.shortLabel,
        pData.moons ? pData.moons.length + ' MOONS' : '',
        pData.color,
        5.8,
        1.75
      );
      pLabel.position.set(0, pData.radius + 1.55, 0);
      pGroup.add(pLabel);

      // Moon local orbit group attached to planet group so moons track seamlessly
      var moonOrbitLines = [];
      var moonsArr = pData.moons || [];
      for (var mIdx = 0; mIdx < moonsArr.length; mIdx++) {
        var mData = moonsArr[mIdx];
        var mOrbit = makeOrbitLine(
          mData.orbitRadius,
          mData.inclination,
          mData.color,
          0.22
        );
        pGroup.add(mOrbit);
        moonOrbitLines.push(mOrbit);

        var mGroup = new THREE.Group();
        var mMesh = new THREE.Mesh(
          new THREE.SphereGeometry(mData.radius, 20, 16),
          new THREE.MeshStandardMaterial({
            color: parseHexColor(mData.color),
            roughness: 0.55,
            metalness: 0.2,
            emissive: parseHexColor(mData.color),
            emissiveIntensity: 0.28,
          })
        );
        mGroup.add(mMesh);

        var mHit = new THREE.Mesh(
          new THREE.SphereGeometry(Math.max(mData.radius * 2.1, 1.1), 12, 10),
          new THREE.MeshBasicMaterial({
            transparent: true,
            opacity: 0.0,
            depthWrite: false,
          })
        );
        mHit.userData = {
          kind: 'moon',
          planetId: pData.id,
          moonId: mData.id,
        };
        mGroup.add(mHit);
        inst.hitMeshes.push(mHit);

        var mLabel = makeLabelSprite(mData.title, mData.badge, mData.color, 3.8, 1.15);
        mLabel.position.set(0, mData.radius + 0.95, 0);
        mLabel.material.opacity = 0.72;
        mGroup.add(mLabel);

        inst.systemRoot.add(mGroup);
        inst.moons[mData.id] = {
          group: mGroup,
          mesh: mMesh,
          label: mLabel,
          parentId: pData.id,
        };
      }

      inst.systemRoot.add(pGroup);
      inst.planets[pData.id] = {
        group: pGroup,
        mesh: pMesh,
        orbitLine: orbitLine,
        moonOrbitLines: moonOrbitLines,
        label: pLabel,
      };
    }
  };

  window.spnkSolarSyncState = function (id, jsonStr) {
    var inst = _instances[id];
    if (!inst) return;

    var state;
    try {
      state = JSON.parse(jsonStr);
    } catch (e) {
      return;
    }

    inst.scene.background = new THREE.Color(state.isDark === false ? 0x0f172a : 0x040711);

    var focusedPlanetId = state.focusedPlanetId || null;
    var focusedMoonId = state.focusedMoonId || null;

    var pStates = state.planets || [];
    for (var i = 0; i < pStates.length; i++) {
      var ps = pStates[i];
      var pEntry = inst.planets[ps.id];
      if (!pEntry) continue;

      pEntry.group.position.set(ps.x, ps.y, ps.z);
      pEntry.mesh.rotation.y += 0.008;

      var isFocusedPlanet = focusedPlanetId === ps.id;
      pEntry.orbitLine.material.opacity =
        focusedPlanetId == null ? 0.34 : (isFocusedPlanet ? 0.78 : 0.14);

      var mLineScale = isFocusedPlanet ? 1.45 : 1.0;
      for (var ml = 0; ml < pEntry.moonOrbitLines.length; ml++) {
        pEntry.moonOrbitLines[ml].scale.set(mLineScale, mLineScale, mLineScale);
        pEntry.moonOrbitLines[ml].material.opacity = isFocusedPlanet ? 0.56 : 0.18;
      }

      var mStates = ps.moons || [];
      for (var j = 0; j < mStates.length; j++) {
        var ms = mStates[j];
        var mEntry = inst.moons[ms.id];
        if (!mEntry) continue;
        mEntry.group.position.set(ms.x, ms.y, ms.z);
        mEntry.mesh.rotation.y += 0.015;
        var isFocusedMoon = focusedMoonId === ms.id;
        mEntry.label.material.opacity = isFocusedMoon
          ? 1.0
          : (isFocusedPlanet ? 0.94 : 0.45);
      }
    }

    // Center camera look-at directly on focused body
    var lookAt = state.lookAt || { x: 0, y: 0, z: 0 };
    var dist = state.distance || 68.0;
    var yaw = state.yaw || 0.65;
    var pitch = state.pitch || 0.42;

    var cosP = Math.cos(pitch);
    var camX = lookAt.x + Math.sin(yaw) * cosP * dist;
    var camY = lookAt.y + Math.sin(pitch) * dist;
    var camZ = lookAt.z + Math.cos(yaw) * cosP * dist;

    inst.camera.position.set(camX, camY, camZ);
    inst.camera.lookAt(lookAt.x, lookAt.y, lookAt.z);
  };

  window.spnkSolarRaycast = function (id, normX, normY) {
    var inst = _instances[id];
    if (!inst || !inst.hitMeshes.length) return '';

    var ndc = new THREE.Vector2(normX * 2 - 1, -(normY * 2 - 1));
    inst.raycaster.setFromCamera(ndc, inst.camera);
    var hits = inst.raycaster.intersectObjects(inst.hitMeshes, false);
    if (!hits || !hits.length) return '';

    var ud = hits[0].object.userData || {};
    return JSON.stringify(ud);
  };

  window.spnkSolarDispose = function (id) {
    var inst = _instances[id];
    if (!inst) return;
    delete _instances[id];
    if (inst.animId) window.cancelAnimationFrame(inst.animId);
    if (inst.resizeObserver) inst.resizeObserver.disconnect();
    disposeObjectTree(inst.systemRoot, inst.scene);
    if (inst.starPoints) {
      inst.starPoints.geometry.dispose();
      inst.starPoints.material.dispose();
    }
    if (inst.beltPoints) {
      inst.beltPoints.geometry.dispose();
      inst.beltPoints.material.dispose();
    }
    inst.renderer.dispose();
  };
})();
