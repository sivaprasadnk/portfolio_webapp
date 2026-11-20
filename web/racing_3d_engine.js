(function () {
  'use strict';

  var ROAD_HALF_W = 9.0;
  var KERB_W = 1.15;
  var SEG_LEN_DART = 200.0;
  var SLICE_BACK = 3;
  var SLICE_AHEAD = 88;
  var TOTAL_SLICES = SLICE_BACK + SLICE_AHEAD + 1; // 92 slices
  var PADDOCK_SCALE = 0.085; // 1 Dart px = 0.085 3D meters

  var _instances = {};
  var _nextId = 1;

  function clamp(v, min, max) {
    return v < min ? min : (v > max ? max : v);
  }

  function lerp(a, b, t) {
    return a + (b - a) * t;
  }

  function parseHexColor(hexInt) {
    return new THREE.Color(hexInt & 0xffffff);
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

  function createBuildingFacadeTexture(accentHex, secondaryHex, isDark) {
    var canvas = document.createElement('canvas');
    canvas.width = 128;
    canvas.height = 256;
    var ctx = canvas.getContext('2d');
    ctx.fillStyle = isDark ? '#080e1f' : '#1e293b';
    ctx.fillRect(0, 0, 128, 256);

    var aCol = '#' + (accentHex & 0xffffff).toString(16).padStart(6, '0');
    var sCol = '#' + (secondaryHex & 0xffffff).toString(16).padStart(6, '0');

    for (var y = 10; y < 246; y += 14) {
      for (var x = 8; x < 120; x += 16) {
        var seed = ((x * 37 + y * 13) % 11);
        if (seed < 4) {
          ctx.fillStyle = seed === 0 ? aCol : (seed === 1 ? sCol : 'rgba(224,242,254,0.65)');
          ctx.fillRect(x, y, 10, 8);
        } else {
          ctx.fillStyle = 'rgba(255,255,255,0.05)';
          ctx.fillRect(x, y, 10, 8);
        }
      }
    }
    var tex = new THREE.CanvasTexture(canvas);
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    return tex;
  }

  // =========================================================================
  // 5 SCULPTED 3D USER VEHICLES
  // =========================================================================
  function buildPlayerVehicleGroup(typeIndex, accentColor, secondaryColor, bodyColor) {
    var root = new THREE.Group();
    var bodyMat = new THREE.MeshStandardMaterial({
      color: bodyColor,
      metalness: 0.72,
      roughness: 0.25,
    });
    var trimMat = new THREE.MeshStandardMaterial({
      color: accentColor,
      emissive: accentColor,
      emissiveIntensity: 0.65,
      metalness: 0.4,
      roughness: 0.3,
    });
    var secMat = new THREE.MeshStandardMaterial({
      color: secondaryColor,
      emissive: secondaryColor,
      emissiveIntensity: 0.55,
      metalness: 0.4,
      roughness: 0.3,
    });
    var glassMat = new THREE.MeshStandardMaterial({
      color: 0x050a16,
      metalness: 0.9,
      roughness: 0.12,
    });
    var tireMat = new THREE.MeshStandardMaterial({
      color: 0x0b0f18,
      roughness: 0.85,
      metalness: 0.15,
    });
    var tailMat = new THREE.MeshBasicMaterial({ color: 0xff1e42 });
    var flameMat = new THREE.MeshBasicMaterial({
      color: 0xff8a1f,
      transparent: true,
      opacity: 0.88,
    });

    var wheels = [];
    var flames = [];
    var wingMesh = null;
    var shieldRing = null;

    function addWheel(x, y, z, r, w, isGlowing) {
      var wg = new THREE.Group();
      wg.position.set(x, y, z);
      var tire = new THREE.Mesh(
        new THREE.CylinderGeometry(r, r, w, 18),
        tireMat
      );
      tire.rotation.z = Math.PI * 0.5;
      tire.castShadow = true;
      wg.add(tire);

      var rim = new THREE.Mesh(
        new THREE.CylinderGeometry(r * 0.58, r * 0.58, w + 0.04, 12),
        isGlowing ? trimMat : secMat
      );
      rim.rotation.z = Math.PI * 0.5;
      wg.add(rim);

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

    // Underglow shadow plane
    var glowDisc = new THREE.Mesh(
      new THREE.PlaneGeometry(3.8, 6.4),
      new THREE.MeshBasicMaterial({
        color: accentColor,
        transparent: true,
        opacity: 0.22,
        depthWrite: false,
      })
    );
    glowDisc.rotation.x = -Math.PI * 0.5;
    glowDisc.position.y = 0.04;
    root.add(glowDisc);

    if (typeIndex === 1) {
      // 1: FORMULA-X (Open-Wheel F1 Racer)
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
        // Suspension wishbones
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
      // 2: CYBER-BIKE (Tron Lightcycle)
      var bikeFrame = new THREE.Mesh(new THREE.BoxGeometry(0.74, 0.65, 3.3), bodyMat);
      bikeFrame.position.set(0, 0.65, 0);
      bikeFrame.castShadow = true;
      root.add(bikeFrame);

      var cowl = new THREE.Mesh(new THREE.BoxGeometry(0.86, 0.48, 1.65), trimMat);
      cowl.position.set(0, 0.95, -0.55);
      cowl.rotation.x = 0.25;
      root.add(cowl);

      var handle = new THREE.Mesh(new THREE.BoxGeometry(1.45, 0.09, 0.12), secMat);
      handle.position.set(0, 1.15, -0.95);
      root.add(handle);

      // Rider torso + helmet
      var rider = new THREE.Mesh(new THREE.BoxGeometry(0.62, 0.60, 0.95), bodyMat);
      rider.position.set(0, 1.28, 0.05);
      rider.rotation.x = 0.48;
      root.add(rider);

      var visorHelmet = new THREE.Mesh(new THREE.SphereGeometry(0.28, 12, 12), secMat);
      visorHelmet.position.set(0, 1.56, -0.35);
      root.add(visorHelmet);

      // Hubless glowing tires (front & rear)
      addWheel(0, 0.52, -1.55, 0.52, 0.34, true);
      addWheel(0, 0.56, 1.55, 0.56, 0.44, true);

      var tailStrip = new THREE.Mesh(new THREE.BoxGeometry(0.62, 0.14, 0.12), tailMat);
      tailStrip.position.set(0, 0.85, 1.72);
      root.add(tailStrip);

      addFlame(0, 0.52, 1.95, 0.20, 1.3);
    } else if (typeIndex === 3) {
      // 3: TITAN-6X (Armored Cyber-SUV / Truck)
      var chassis = new THREE.Mesh(new THREE.BoxGeometry(3.5, 1.05, 6.2), bodyMat);
      chassis.position.set(0, 0.92, 0);
      chassis.castShadow = true;
      root.add(chassis);

      var cab = new THREE.Mesh(new THREE.BoxGeometry(3.05, 0.82, 3.2), bodyMat);
      cab.position.set(0, 1.82, -0.35);
      cab.castShadow = true;
      root.add(cab);

      var roofBar = new THREE.Mesh(new THREE.BoxGeometry(2.4, 0.16, 0.24), secMat);
      roofBar.position.set(0, 2.30, -1.2);
      root.add(roofBar);

      var bumper = new THREE.Mesh(new THREE.BoxGeometry(3.75, 0.32, 0.35), trimMat);
      bumper.position.set(0, 0.52, 3.12);
      root.add(bumper);

      var windshield = new THREE.Mesh(new THREE.BoxGeometry(2.85, 0.62, 0.14), glassMat);
      windshield.position.set(0, 1.78, -1.96);
      windshield.rotation.x = -0.35;
      root.add(windshield);

      for (var ts = -1; ts <= 1; ts += 2) {
        var tLight = new THREE.Mesh(new THREE.BoxGeometry(0.28, 0.58, 0.12), tailMat);
        tLight.position.set(ts * 1.48, 1.02, 3.12);
        root.add(tLight);
      }

      addWheel(-1.82, 0.62, -2.05, 0.62, 0.52, false);
      addWheel(1.82, 0.62, -2.05, 0.62, 0.52, false);
      addWheel(-1.82, 0.62, 2.05, 0.62, 0.52, false);
      addWheel(1.82, 0.62, 2.05, 0.62, 0.52, false);

      addFlame(-1.05, 0.55, 3.15, 0.16, 0.95);
      addFlame(1.05, 0.55, 3.15, 0.16, 0.95);
    } else if (typeIndex === 4) {
      // 4: AERO-HOVER (Delta-Wing Anti-Grav Speeder)
      var hull = new THREE.Mesh(new THREE.BoxGeometry(1.75, 0.52, 5.2), bodyMat);
      hull.position.set(0, 0.95, 0);
      hull.castShadow = true;
      root.add(hull);

      // Swept delta wings
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

        // Hover repulsor ring underneath
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

      addFlame(-0.55, 0.92, 2.65, 0.26, 1.55);
      addFlame(0.55, 0.92, 2.65, 0.26, 1.55);
    } else {
      // 0: APEX GT-01 (Carbon Supercar)
      var lowerBody = new THREE.Mesh(new THREE.BoxGeometry(3.15, 0.58, 5.4), bodyMat);
      lowerBody.position.set(0, 0.54, 0);
      lowerBody.castShadow = true;
      root.add(lowerBody);

      var sideTrim = new THREE.Mesh(new THREE.BoxGeometry(3.24, 0.14, 5.2), trimMat);
      sideTrim.position.set(0, 0.32, 0);
      root.add(sideTrim);

      var cabin = new THREE.Mesh(new THREE.BoxGeometry(2.1, 0.54, 2.55), glassMat);
      cabin.position.set(0, 1.02, 0.15);
      cabin.castShadow = true;
      root.add(cabin);

      var stripe = new THREE.Mesh(new THREE.BoxGeometry(0.45, 0.05, 5.38), secMat);
      stripe.position.set(0, 0.85, 0);
      root.add(stripe);

      wingMesh = new THREE.Mesh(new THREE.BoxGeometry(2.85, 0.10, 0.55), trimMat);
      wingMesh.position.set(0, 1.22, 2.38);
      root.add(wingMesh);

      for (var ws = -1; ws <= 1; ws += 2) {
        var strut = new THREE.Mesh(new THREE.BoxGeometry(0.10, 0.42, 0.28), bodyMat);
        strut.position.set(ws * 0.88, 0.98, 2.38);
        root.add(strut);
      }

      var tailBar = new THREE.Mesh(new THREE.BoxGeometry(2.72, 0.14, 0.12), tailMat);
      tailBar.position.set(0, 0.66, 2.72);
      root.add(tailBar);

      addWheel(-1.58, 0.44, -1.68, 0.44, 0.36, true);
      addWheel(1.58, 0.44, -1.68, 0.44, 0.36, true);
      addWheel(-1.58, 0.46, 1.68, 0.46, 0.42, true);
      addWheel(1.58, 0.46, 1.68, 0.46, 0.42, true);

      addFlame(-0.78, 0.44, 2.76, 0.20, 1.25);
      addFlame(0.78, 0.44, 2.76, 0.20, 1.25);
    }

    // Impact shield flash wireframe bubble
    shieldRing = new THREE.Mesh(
      new THREE.TorusGeometry(2.45, 0.08, 8, 28),
      new THREE.MeshBasicMaterial({
        color: 0xff3b5c,
        transparent: true,
        opacity: 0.0,
      })
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
    };
  }

  // =========================================================================
  // OPPONENT 3D VEHICLE BUILDER (coupe / truck / interceptor)
  // =========================================================================
  function buildOpponentGroup(kind, trimHex) {
    var g = new THREE.Group();
    var bodyMat = new THREE.MeshStandardMaterial({
      color: 0x161f33,
      metalness: 0.6,
      roughness: 0.35,
    });
    var trimMat = new THREE.MeshStandardMaterial({
      color: trimHex,
      emissive: trimHex,
      emissiveIntensity: 0.55,
    });
    var glassMat = new THREE.MeshStandardMaterial({
      color: 0x050914,
      metalness: 0.85,
      roughness: 0.2,
    });
    var tireMat = new THREE.MeshStandardMaterial({ color: 0x090d16 });

    if (kind === 1) {
      // Truck
      var box = new THREE.Mesh(new THREE.BoxGeometry(3.4, 2.15, 6.8), bodyMat);
      box.position.set(0, 1.38, 0);
      box.castShadow = true;
      g.add(box);
      var roofFrame = new THREE.Mesh(new THREE.BoxGeometry(3.45, 0.14, 6.85), trimMat);
      roofFrame.position.set(0, 2.45, 0);
      g.add(roofFrame);
      var tail = new THREE.Mesh(
        new THREE.BoxGeometry(2.9, 0.22, 0.12),
        new THREE.MeshBasicMaterial({ color: 0xff2a5f })
      );
      tail.position.set(0, 0.82, 3.44);
      g.add(tail);
    } else {
      // Coupe or Interceptor
      var w = kind === 2 ? 2.75 : 2.95;
      var l = kind === 2 ? 4.9 : 5.2;
      var chassis = new THREE.Mesh(new THREE.BoxGeometry(w, 0.65, l), bodyMat);
      chassis.position.set(0, 0.56, 0);
      chassis.castShadow = true;
      g.add(chassis);

      var cab = new THREE.Mesh(new THREE.BoxGeometry(w * 0.68, 0.52, l * 0.48), glassMat);
      cab.position.set(0, 1.06, 0.15);
      g.add(cab);

      var trimLine = new THREE.Mesh(new THREE.BoxGeometry(w + 0.08, 0.14, l + 0.04), trimMat);
      trimLine.position.set(0, 0.34, 0);
      g.add(trimLine);

      if (kind === 2) {
        var wing = new THREE.Mesh(new THREE.BoxGeometry(w * 0.95, 0.10, 0.45), trimMat);
        wing.position.set(0, 1.15, l * 0.44);
        g.add(wing);
      }

      var tailBar = new THREE.Mesh(
        new THREE.BoxGeometry(w * 0.85, 0.14, 0.10),
        new THREE.MeshBasicMaterial({ color: 0xff2a5f })
      );
      tailBar.position.set(0, 0.64, l * 0.5 + 0.04);
      g.add(tailBar);
    }

    for (var wx = -1; wx <= 1; wx += 2) {
      for (var wz = -1; wz <= 1; wz += 2) {
        var tire = new THREE.Mesh(new THREE.CylinderGeometry(0.42, 0.42, 0.34, 10), tireMat);
        tire.rotation.z = Math.PI * 0.5;
        tire.position.set(wx * (kind === 1 ? 1.65 : 1.42), 0.42, wz * 1.7);
        g.add(tire);
      }
    }

    g.userData = { bodyMat: bodyMat, trimMat: trimMat, trimHex: trimHex };
    return g;
  }

  // =========================================================================
  // MAIN MOUNTED SCENE INSTANCE
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
    renderer.toneMappingExposure = 1.12;
    renderer.domElement.style.pointerEvents = 'none';
    renderer.domElement.style.display = 'block';
    renderer.domElement.style.width = '100%';
    renderer.domElement.style.height = '100%';

    container.innerHTML = '';
    container.appendChild(renderer.domElement);

    var scene = new THREE.Scene();
    scene.background = new THREE.Color(0x040611);
    scene.fog = new THREE.FogExp2(0x091026, 0.0022);

    var camera = new THREE.PerspectiveCamera(62, width / height, 0.5, 1600);
    camera.position.set(0, 6.2, 13.5);

    // Lighting
    var hemiLight = new THREE.HemisphereLight(0x38bdf8, 0x050814, 0.85);
    scene.add(hemiLight);

    var dirLight = new THREE.DirectionalLight(0xffffff, 1.15);
    dirLight.position.set(35, 75, 40);
    dirLight.castShadow = true;
    dirLight.shadow.mapSize.width = 1024;
    dirLight.shadow.mapSize.height = 1024;
    dirLight.shadow.camera.near = 5;
    dirLight.shadow.camera.far = 220;
    dirLight.shadow.camera.left = -45;
    dirLight.shadow.camera.right = 45;
    dirLight.shadow.camera.top = 45;
    dirLight.shadow.camera.bottom = -95;
    scene.add(dirLight);

    var underGlowLight = new THREE.PointLight(0x00f0ff, 2.2, 24);
    underGlowLight.position.set(0, 1.2, 0);
    scene.add(underGlowLight);

    // Driver portrait texture (loaded asynchronously with safe fallback)
    var driverTexture = null;
    try {
      var loader = new THREE.TextureLoader();
      loader.load(
        'assets/assets/images/propic3.png',
        function (tex) {
          driverTexture = tex;
        },
        undefined,
        function () {}
      );
    } catch (e) {}

    var texCache = {};

    // Sky elements: Starfield, Horizon Sun, Mountains
    var starGeo = new THREE.BufferGeometry();
    var starCount = 260;
    var starPos = new Float32Array(starCount * 3);
    for (var si = 0; si < starCount; si++) {
      var sa = (si * 2.39996) % (Math.PI * 2);
      var sr = 480 + ((si * 53) % 240);
      starPos[si * 3] = Math.cos(sa) * sr;
      starPos[si * 3 + 1] = 45 + ((si * 29) % 210);
      starPos[si * 3 + 2] = Math.sin(sa) * sr;
    }
    starGeo.setAttribute('position', new THREE.BufferAttribute(starPos, 3));
    var starMat = new THREE.PointsMaterial({ color: 0xffffff, size: 2.2, transparent: true, opacity: 0.75 });
    var starField = new THREE.Points(starGeo, starMat);
    scene.add(starField);

    var sunMat = new THREE.MeshBasicMaterial({ color: 0x00f0ff, transparent: true, opacity: 0.85, fog: false });
    var horizonSun = new THREE.Mesh(new THREE.CircleGeometry(68, 40), sunMat);
    horizonSun.position.set(0, 48, -620);
    scene.add(horizonSun);

    // Distant Mountain Ring
    var mtnGroup = new THREE.Group();
    var mtnMat = new THREE.MeshStandardMaterial({
      color: 0x070b19,
      roughness: 0.9,
      metalness: 0.15,
    });
    for (var mi = 0; mi < 32; mi++) {
      var ma = (mi / 32) * Math.PI * 2;
      var mh = 34 + ((mi * 37) % 48);
      var cone = new THREE.Mesh(new THREE.ConeGeometry(46, mh, 4), mtnMat);
      cone.position.set(Math.cos(ma) * 560, mh * 0.42 - 6, Math.sin(ma) * 560);
      cone.rotation.y = ma;
      mtnGroup.add(cone);
    }
    scene.add(mtnGroup);

    // Ground Plane + Grid Helper (for circuit modes)
    var circuitGroup = new THREE.Group();
    scene.add(circuitGroup);

    var groundMat = new THREE.MeshStandardMaterial({ color: 0x050814, roughness: 0.95 });
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

    // Pre-allocated dynamic ribbon meshes for Road, Left/Right Kerbs
    function createRibbonMesh(material, yBias) {
      var geo = new THREE.BufferGeometry();
      var verts = new Float32Array(TOTAL_SLICES * 2 * 3);
      var colors = new Float32Array(TOTAL_SLICES * 2 * 3);
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
      geo.setIndex(indices);
      var mesh = new THREE.Mesh(geo, material);
      mesh.receiveShadow = true;
      mesh.frustumCulled = false;
      mesh.position.y = yBias || 0;
      return { mesh: mesh, verts: verts, colors: colors, geo: geo };
    }

    var roadRibbon = createRibbonMesh(
      new THREE.MeshStandardMaterial({
        vertexColors: true,
        roughness: 0.72,
        metalness: 0.12,
      }),
      0.0
    );
    circuitGroup.add(roadRibbon.mesh);

    var leftKerbRibbon = createRibbonMesh(
      new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.6 }),
      0.03
    );
    var rightKerbRibbon = createRibbonMesh(
      new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.6 }),
      0.03
    );
    circuitGroup.add(leftKerbRibbon.mesh);
    circuitGroup.add(rightKerbRibbon.mesh);

    // Pooled lane dashes & boost pads
    var dashPool = [];
    var dashMat = new THREE.MeshBasicMaterial({ color: 0xe2e8f0, transparent: true, opacity: 0.72 });
    var dashGeo = new THREE.PlaneGeometry(0.32, 3.8);
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

    // Tunnel Arches pool
    var archPool = [];
    var archMat = new THREE.MeshBasicMaterial({ color: 0x00f0ff, transparent: true, opacity: 0.55 });
    var archGeo = new THREE.TorusGeometry(ROAD_HALF_W + 1.8, 0.24, 6, 20, Math.PI);
    for (var ai = 0; ai < 18; ai++) {
      var am = new THREE.Mesh(archGeo, archMat);
      am.visible = false;
      circuitGroup.add(am);
      archPool.push(am);
    }

    // Roadside Prop Pool (Light Pylons, Buildings / Palmtrees)
    var propPool = [];
    var poleGeo = new THREE.CylinderGeometry(0.12, 0.16, 6.2, 6);
    var lampGeo = new THREE.SphereGeometry(0.38, 8, 8);
    var bldgGeo = new THREE.BoxGeometry(10, 32, 10);
    var facadeTex = createBuildingFacadeTexture(0x38bdf8, 0xa855f7, true);
    var bldgMat = new THREE.MeshStandardMaterial({ map: facadeTex, roughness: 0.5 });
    var trunkGeo = new THREE.CylinderGeometry(0.22, 0.34, 7.5, 6);
    var crownGeo = new THREE.ConeGeometry(2.8, 2.2, 7);
    var trunkMat = new THREE.MeshStandardMaterial({ color: 0x1e0b36 });
    var crownMat = new THREE.MeshStandardMaterial({ color: 0x00f5d4, emissive: 0x00f5d4, emissiveIntensity: 0.25 });

    for (var pi = 0; pi < 28; pi++) {
      var pg = new THREE.Group();
      var poleMat = new THREE.MeshStandardMaterial({ color: 0x334155 });
      var lampMat = new THREE.MeshBasicMaterial({ color: 0x38bdf8 });
      var pole = new THREE.Mesh(poleGeo, poleMat);
      pole.position.y = 3.1;
      var lamp = new THREE.Mesh(lampGeo, lampMat);
      lamp.position.y = 6.2;
      var bldg = new THREE.Mesh(bldgGeo, bldgMat);
      bldg.position.set(14, 16, 0);
      var palm = new THREE.Group();
      var tr = new THREE.Mesh(trunkGeo, trunkMat);
      tr.position.y = 3.75;
      var cr = new THREE.Mesh(crownGeo, crownMat);
      cr.position.y = 7.8;
      palm.add(tr, cr);
      palm.visible = false;

      pg.add(pole, lamp, bldg, palm);
      pg.visible = false;
      circuitGroup.add(pg);
      propPool.push({
        group: pg,
        pole: pole,
        lamp: lamp,
        lampMat: lampMat,
        bldg: bldg,
        palm: palm,
      });
    }

    // Billboard Pool (3D truss + CanvasTexture sign)
    var billboardPool = [];
    for (var bbi = 0; bbi < 10; bbi++) {
      var bg = new THREE.Group();
      var bMat = new THREE.MeshBasicMaterial({ color: 0xffffff });
      var frameMat = new THREE.MeshBasicMaterial({ color: 0x00f0ff });
      var bSign = new THREE.Mesh(new THREE.PlaneGeometry(10.5, 5.2), bMat);
      bSign.position.set(0, 6.2, 0.12);
      var bBack = new THREE.Mesh(new THREE.BoxGeometry(10.8, 5.5, 0.22), new THREE.MeshStandardMaterial({ color: 0x091022 }));
      bBack.position.set(0, 6.2, 0);
      var bBorder = new THREE.Mesh(new THREE.BoxGeometry(11.1, 5.8, 0.10), frameMat);
      bBorder.position.set(0, 6.2, -0.08);
      var legL = new THREE.Mesh(new THREE.CylinderGeometry(0.2, 0.2, 3.8, 6), frameMat);
      legL.position.set(-3.2, 1.9, 0);
      var legR = new THREE.Mesh(new THREE.CylinderGeometry(0.2, 0.2, 3.8, 6), frameMat);
      legR.position.set(3.2, 1.9, 0);
      bg.add(bBorder, bBack, bSign, legL, legR);
      bg.visible = false;
      circuitGroup.add(bg);
      billboardPool.push({ group: bg, sign: bSign, bMat: bMat, frameMat: frameMat });
    }

    // Gantry Holographic Gate Pool
    var gantryPool = [];
    for (var gi = 0; gi < 4; gi++) {
      var gg = new THREE.Group();
      var gMat = new THREE.MeshStandardMaterial({ color: 0x0a1326, metalness: 0.7, roughness: 0.3 });
      var gCyanMat = new THREE.MeshBasicMaterial({ color: 0x00f0ff, transparent: true, opacity: 0.75 });
      var beamMat = new THREE.MeshBasicMaterial({ color: 0x00f0ff, transparent: true, opacity: 0.22, side: THREE.DoubleSide });
      var signMat = new THREE.MeshBasicMaterial({ color: 0xffffff });

      var pL = new THREE.Mesh(new THREE.BoxGeometry(1.1, 9.5, 1.1), gMat);
      pL.position.set(-ROAD_HALF_W - 1.2, 4.75, 0);
      var pR = new THREE.Mesh(new THREE.BoxGeometry(1.1, 9.5, 1.1), gMat);
      pR.position.set(ROAD_HALF_W + 1.2, 4.75, 0);
      var beamL = new THREE.Mesh(new THREE.PlaneGeometry(1.4, 24), beamMat);
      beamL.position.set(-ROAD_HALF_W - 1.2, 12, 0);
      var beamR = new THREE.Mesh(new THREE.PlaneGeometry(1.4, 24), beamMat);
      beamR.position.set(ROAD_HALF_W + 1.2, 12, 0);

      var banner = new THREE.Mesh(new THREE.BoxGeometry(ROAD_HALF_W * 2 + 3.2, 3.2, 0.55), gMat);
      banner.position.set(0, 9.6, 0);
      var signFace = new THREE.Mesh(new THREE.PlaneGeometry(ROAD_HALF_W * 2 + 2.6, 2.8), signMat);
      signFace.position.set(0, 9.6, 0.30);

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
      holoDiamond.position.set(0, 13.6, 0);

      gg.add(pL, pR, beamL, beamR, banner, signFace, holoPad, holoDiamond);
      gg.visible = false;
      circuitGroup.add(gg);
      gantryPool.push({
        group: gg,
        signFace: signFace,
        signMat: signMat,
        holoDiamond: holoDiamond,
        gCyanMat: gCyanMat,
      });
    }

    // 3D Checkered Strip on Road
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

    // Opponent Traffic Pool (supports coupe=0, truck=1, interceptor=2)
    var rivalColors = [0x38bdf8, 0xf43f5e, 0xa855f7, 0x10b981];
    var opponentPool = [];
    for (var oi = 0; oi < 12; oi++) {
      var kinds = [0, 1, 2];
      var variants = {};
      for (var vk = 0; vk < 3; vk++) {
        var mesh = buildOpponentGroup(vk, rivalColors[oi % rivalColors.length]);
        mesh.visible = false;
        scene.add(mesh);
        variants[vk] = mesh;
      }
      opponentPool.push(variants);
    }

    // Static Roadblock Obstacle Pool
    var obstaclePool = [];
    var obsBodyGeo = new THREE.BoxGeometry(2.85, 1.05, 0.95);
    var obsBeaconGeo = new THREE.SphereGeometry(0.22, 8, 8);
    for (var obi = 0; obi < 14; obi++) {
      var og = new THREE.Group();
      var obsBodyMat = new THREE.MeshStandardMaterial({ color: 0x1f1224, roughness: 0.4 });
      var obsStripeMat = new THREE.MeshBasicMaterial({ color: 0xf59e0b });
      var obsBeaconMat = new THREE.MeshBasicMaterial({ color: 0xff3b5c });

      var obBody = new THREE.Mesh(obsBodyGeo, obsBodyMat);
      obBody.position.y = 0.55;
      obBody.castShadow = true;
      var stripeBar = new THREE.Mesh(new THREE.BoxGeometry(2.90, 0.25, 0.98), obsStripeMat);
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

    // Data Crystal Orb Pool
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

    // 5 Player Vehicle Models (pre-built, instant switching!)
    var playerVehicles = {};
    for (var vt = 0; vt < 5; vt++) {
      var pv = buildPlayerVehicleGroup(vt, 0x38bdf8, 0x00f0ff, 0x141e36);
      pv.root.visible = vt === 0;
      scene.add(pv.root);
      playerVehicles[vt] = pv;
    }

    // Expanding Hologram Arrival Wave Ring around Player
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

    // 3D Spark Particle Pool
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

    // =========================================================================
    // OPEN-WORLD 3D PADDOCK STADIUM GROUP (MODE 1: openPaddock)
    // =========================================================================
    var paddockGroup = new THREE.Group();
    paddockGroup.visible = false;
    scene.add(paddockGroup);

    var paddockFloor = new THREE.Mesh(
      new THREE.PlaneGeometry(340, 240),
      new THREE.MeshStandardMaterial({ color: 0x060a18, roughness: 0.92 })
    );
    paddockFloor.rotation.x = -Math.PI * 0.5;
    paddockFloor.receiveShadow = true;
    paddockGroup.add(paddockFloor);

    var paddockGrid = new THREE.GridHelper(320, 40, 0x38bdf8, 0x172554);
    paddockGrid.position.y = 0.02;
    paddockGrid.material.transparent = true;
    paddockGrid.material.opacity = 0.28;
    paddockGroup.add(paddockGrid);

    // Oval Asphalt Track in 3D Paddock (scaled by PADDOCK_SCALE = 0.085)
    var ovalPts = [];
    for (var ovi = 0; ovi <= 72; ovi++) {
      var oa = (ovi / 72) * Math.PI * 2;
      ovalPts.push(new THREE.Vector3(Math.cos(oa) * 900 * PADDOCK_SCALE, 0.06, Math.sin(oa) * 535 * PADDOCK_SCALE));
    }
    var ovalCurve = new THREE.CatmullRomCurve3(ovalPts, true);
    var ovalTube = new THREE.Mesh(
      new THREE.TubeGeometry(ovalCurve, 96, 5.6, 4, true),
      new THREE.MeshStandardMaterial({ color: 0x11192e, roughness: 0.85 })
    );
    ovalTube.scale.y = 0.025;
    ovalTube.position.y = 0.05;
    paddockGroup.add(ovalTube);

    // Arena Fence Perimeter
    var arenaBorder = new THREE.Mesh(
      new THREE.BoxGeometry(3300 * PADDOCK_SCALE, 2.2, 2300 * PADDOCK_SCALE),
      new THREE.MeshBasicMaterial({ color: 0x38bdf8, wireframe: true, transparent: true, opacity: 0.16 })
    );
    arenaBorder.position.y = 1.1;
    paddockGroup.add(arenaBorder);

    // Central Driver Monument Pedestal (Radius = 168 * 0.085 = 14.28m matching OBB vs Circle!)
    var monGroup = new THREE.Group();
    var monRadius = 168.0 * PADDOCK_SCALE;
    var monPedestal = new THREE.Mesh(
      new THREE.CylinderGeometry(monRadius, monRadius * 1.04, 1.6, 36),
      new THREE.MeshStandardMaterial({ color: 0x0b1224, metalness: 0.7, roughness: 0.3 })
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
    var paddockBoostMeshes = [];

    // GPS target beacon in 3D Paddock
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
      starField: starField,
      starMat: starMat,
      horizonSun: horizonSun,
      sunMat: sunMat,
      mtnGroup: mtnGroup,
      mtnMat: mtnMat,
      circuitGroup: circuitGroup,
      paddockGroup: paddockGroup,
      groundMat: groundMat,
      gridHelper: gridHelper,
      roadRibbon: roadRibbon,
      leftKerbRibbon: leftKerbRibbon,
      rightKerbRibbon: rightKerbRibbon,
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
      monPortraitDisc: monPortraitDisc,
      monPortraitMat: monPortraitMat,
      paddockSectorMeshes: paddockSectorMeshes,
      paddockPortalMeshes: paddockPortalMeshes,
      paddockBoostMeshes: paddockBoostMeshes,
      gpsBeacon: gpsBeacon,
      texCache: texCache,
      segments: [],
      trackLen: 720 * SEG_LEN_DART,
      lastThemeKey: '',
      lastCollisionSeq: 0,
      lastArrivalSeq: 0,
      arrivalWaveTimer: 0,
      lastTimeSec: 0,
      camPos: new THREE.Vector3(0, 6.2, 13.5),
      camLook: new THREE.Vector3(0, 1.5, -24),
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

    // Build 3D Paddock Sector Pavilions
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
        new THREE.MeshStandardMaterial({ color: 0x0b152a, roughness: 0.6 })
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
          ctx.fillStyle = '#061126';
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

    // Build 7 Link Portals around Center Monument
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
          ctx.fillStyle = 'rgba(6, 12, 28, 0.9)';
          ctx.fillRect(0, 0, w, h);
          ctx.fillStyle = '#ffffff';
          ctx.font = 'bold 52px Rajdhani, sans-serif';
          ctx.textAlign = 'center';
          ctx.fillText(pt.shortCode, w / 2, 68);
          ctx.fillStyle = '#00f0ff';
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
        sp.vx = (pushDir * (5 + Math.random() * 10)) + (Math.random() - 0.5) * 9;
        sp.vy = 4 + Math.random() * 8;
        sp.vz = (Math.random() - 0.5) * 10;
        sp.mesh.visible = true;
        spawned++;
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

    var mode = d.gameMode || 0; // 0: horizon3d, 1: openPaddock, 2: verticalHighway
    var themeIdx = d.visualTheme || 0; // 0: neonCyber, 1: f1PitWall, 2: retroSynthwave
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

    var accentCol = parseHexColor(d.accentHex || 0x38bdf8);
    var secCol = parseHexColor(d.secondaryHex || 0x00f0ff);
    var skyTopCol = parseHexColor(d.skyTopHex || 0x040611);
    var groundCol = parseHexColor(d.groundNearHex || 0x050814);
    var aspACol = parseHexColor(d.asphaltAHex || 0x0f1629);
    var aspBCol = parseHexColor(d.asphaltBHex || 0x131c33);
    var kerbACol = parseHexColor(d.kerbAHex || 0x38bdf8);
    var kerbBCol = parseHexColor(d.kerbBHex || 0xf8fafc);
    var carBodyCol = parseHexColor(d.carBodyHex || 0x141e36);

    // Update theme colors when changed
    var themeKey = themeIdx + '_' + isDark + '_' + d.accentHex + '_' + d.secondaryHex;
    if (st.lastThemeKey !== themeKey) {
      st.lastThemeKey = themeKey;
      st.scene.background.copy(skyTopCol);
      st.scene.fog.color.copy(skyTopCol);
      st.scene.fog.density = mode === 1 ? 0.0014 : 0.0021;
      st.groundMat.color.copy(groundCol);
      st.sunMat.color.copy(themeIdx === 2 ? new THREE.Color(0xfde047) : accentCol);
      st.horizonSun.visible = themeIdx !== 1;
      st.starField.visible = isDark;
      st.hemiLight.color.copy(secCol);
      st.hemiLight.groundColor.copy(groundCol);
      st.mtnMat.color.setHex(isDark ? 0x070b19 : 0x64748b);
      st.bldgMat.map = createBuildingFacadeTexture(d.accentHex, d.secondaryHex, isDark);
      st.bldgMat.needsUpdate = true;

      for (var vk = 0; vk < 5; vk++) {
        var pv = st.playerVehicles[vk];
        pv.bodyMat.color.copy(carBodyCol);
        pv.trimMat.color.copy(accentCol);
        pv.trimMat.emissive.copy(accentCol);
      }
    }

    // Update spark particles
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

    // Animate player vehicle parts (wheels, DRS wing, flames, impact flash)
    var wheelSpin = (speedKmh * 0.12) * dt;
    for (var wi = 0; wi < activePV.wheels.length; wi++) {
      activePV.wheels[wi].rotation.x -= wheelSpin;
    }
    activePV.tailMat.color.setHex(isBraking ? 0xff1e42 : 0x991b1b);
    activePV.flameMat.color.setHex(nitroActive ? 0x00f0ff : 0xff8a1f);
    var showFlame = speedKmh > 20 || nitroActive;
    for (var fli = 0; fli < activePV.flames.length; fli++) {
      var fl = activePV.flames[fli];
      fl.visible = showFlame;
      if (showFlame) {
        var fScale = (nitroActive ? 1.55 : 0.85) + 0.3 * Math.sin(timeSec * 62 + fli);
        fl.scale.set(1, 1, fScale);
      }
    }
    if (activePV.wingMesh) {
      activePV.wingMesh.rotation.x = (speedKmh > 220 || nitroActive) ? -0.25 : 0.0;
    }
    var flashHit = !!d.collisionFlash;
    activePV.shieldRing.material.opacity = flashHit ? 0.75 : 0.0;
    activePV.shieldRing.scale.setScalar(flashHit ? 1.08 : 1.0);
    st.underGlowLight.color.setHex(flashHit ? 0xff3b5c : (nitroActive ? 0x00f0ff : d.accentHex));

    // =========================================================================
    // RENDER MODE 1: OPEN-WORLD 3D PADDOCK STADIUM
    // =========================================================================
    if (mode === 1) {
      st.circuitGroup.visible = false;
      st.paddockGroup.visible = true;
      st.horizonSun.visible = false;
      st.mtnGroup.visible = false;

      var px = (d.paddockX || 0) * PADDOCK_SCALE;
      var pz = (d.paddockY || 0) * PADDOCK_SCALE;
      var heading = d.paddockHeading || 0; // 0 = UP (-Z), +pi/2 = RIGHT (+X)
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

      // Update sector billboard orientation to face camera
      for (var si = 0; si < st.paddockSectorMeshes.length; si++) {
        var sm = st.paddockSectorMeshes[si];
        var signChild = sm.children[3];
        if (signChild) signChild.lookAt(st.camera.position.x, signChild.getWorldPosition(new THREE.Vector3()).y, st.camera.position.z);
      }
      for (var pi = 0; pi < st.paddockPortalMeshes.length; pi++) {
        var pm = st.paddockPortalMeshes[pi];
        if (pm.children[1]) pm.children[1].lookAt(st.camera.position);
      }

      // GPS Beacon
      if (d.gpsX != null && d.gpsY != null) {
        st.gpsBeacon.visible = true;
        st.gpsBeacon.position.set(d.gpsX * PADDOCK_SCALE, 13, d.gpsY * PADDOCK_SCALE);
      } else {
        st.gpsBeacon.visible = false;
      }

      // Roaming Rivals in Paddock
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
        }
      }

      // Hide circuit-only crystals in paddock
      for (var ci = 0; ci < st.orbPool.length; ci++) {
        st.orbPool[ci].visible = false;
      }

      // Spawn sparks on new collision
      if ((d.collisionEventSeq || 0) !== st.lastCollisionSeq) {
        st.lastCollisionSeq = d.collisionEventSeq || 0;
        var sx = (d.impactWorldX != null ? d.impactWorldX * PADDOCK_SCALE : px);
        var sz = (d.impactWorldY != null ? d.impactWorldY * PADDOCK_SCALE : pz);
        spawnSparks(st, sx, 0.9, sz, 1.0);
      }

      // Camera for Open-World 3D Paddock (or Garage 360 Orbit)
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

      st.dirLight.position.set(px + 30, 65, pz + 35);
      st.dirLight.target.position.set(px, 0, pz);
      st.dirLight.target.updateMatrixWorld();

      st.renderer.render(st.scene, st.camera);
      return;
    }

    // =========================================================================
    // RENDER MODE 0 (3D HORIZON) & MODE 2 (VERTICAL HIGHWAY)
    // =========================================================================
    st.circuitGroup.visible = true;
    st.paddockGroup.visible = false;
    st.horizonSun.visible = mode === 0 && themeIdx !== 1;
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
    var zStepMeters = isHighway ? 2.716 : 8.0; // matches highwayZPerPixel=7.2 vs horizon 0.04m/Z
    var carRefZOffset = isHighway ? 0.0 : 110.0;

    var playerElevY = (baseSeg.y + (nextSeg.y - baseSeg.y) * basePct) * hillScale;

    // C1-continuous forward & backward road curve integration
    var sliceX = new Float32Array(TOTAL_SLICES);
    var sliceY = new Float32Array(TOTAL_SLICES);
    var sliceZ = new Float32Array(TOTAL_SLICES);
    var sliceHeading = new Float32Array(TOTAL_SLICES);
    var sliceSegIdx = new Int32Array(TOTAL_SLICES);

    // Anchor relSeg = 0 at world origin (0, 0, zCarOffset)
    var fwdX = 0.0;
    var fwdSlope = 0.0;
    var backX = 0.0;
    var backSlope = 0.0;

    // n = 0 (at baseIdx, behind relSeg=0)
    var seg0Curve = baseSeg.curve * curveScale;
    backSlope -= seg0Curve * basePct * 0.5;
    backX -= backSlope * basePct;
    backSlope -= seg0Curve * basePct * 0.5;

    sliceX[SLICE_BACK] = backX;
    sliceY[SLICE_BACK] = baseSeg.y * hillScale - playerElevY;
    sliceZ[SLICE_BACK] = -((-basePct * SEG_LEN_DART - carRefZOffset) * (zStepMeters / SEG_LEN_DART));
    sliceSegIdx[SLICE_BACK] = baseIdx;

    // Backward slices: -1, -2, -3
    for (var bi2 = 1; bi2 <= SLICE_BACK; bi2++) {
      var bSegIdx = (baseIdx - bi2 + totalSegs) % totalSegs;
      var bSeg = segs[bSegIdx];
      var bc = bSeg.curve * curveScale;
      backSlope -= bc * 0.5;
      backX -= backSlope;
      backSlope -= bc * 0.5;
      var arrI = SLICE_BACK - bi2;
      sliceX[arrI] = backX;
      sliceY[arrI] = bSeg.y * hillScale - playerElevY;
      sliceZ[arrI] = -(((-bi2 - basePct) * SEG_LEN_DART - carRefZOffset) * (zStepMeters / SEG_LEN_DART));
      sliceSegIdx[arrI] = bSegIdx;
    }

    // Forward slice n = 1
    var fFrac = 1.0 - basePct;
    fwdSlope += seg0Curve * fFrac * 0.5;
    fwdX += fwdSlope * fFrac;
    fwdSlope += seg0Curve * fFrac * 0.5;
    var idx1 = (baseIdx + 1) % totalSegs;
    sliceX[SLICE_BACK + 1] = fwdX;
    sliceY[SLICE_BACK + 1] = nextSeg.y * hillScale - playerElevY;
    sliceZ[SLICE_BACK + 1] = -(((1.0 - basePct) * SEG_LEN_DART - carRefZOffset) * (zStepMeters / SEG_LEN_DART));
    sliceSegIdx[SLICE_BACK + 1] = idx1;

    // Forward slices n = 2 .. SLICE_AHEAD
    for (var fi2 = 2; fi2 <= SLICE_AHEAD; fi2++) {
      var prevFIdx = (baseIdx + fi2 - 1) % totalSegs;
      var fIdx = (baseIdx + fi2) % totalSegs;
      var prevFSeg = segs[prevFIdx];
      var fSeg = segs[fIdx];
      var fc = prevFSeg.curve * curveScale;
      fwdSlope += fc * 0.5;
      fwdX += fwdSlope;
      fwdSlope += fc * 0.5;
      var sIdx = SLICE_BACK + fi2;
      sliceX[sIdx] = fwdX;
      sliceY[sIdx] = fSeg.y * hillScale - playerElevY;
      sliceZ[sIdx] = -(((fi2 - basePct) * SEG_LEN_DART - carRefZOffset) * (zStepMeters / SEG_LEN_DART));
      sliceSegIdx[sIdx] = fIdx;
    }

    // Compute per-slice tangent angle
    for (var ti = 0; ti < TOTAL_SLICES; ti++) {
      var tiA = Math.max(0, ti - 1);
      var tiB = Math.min(TOTAL_SLICES - 1, ti + 1);
      var dxT = sliceX[tiB] - sliceX[tiA];
      var dzT = sliceZ[tiB] - sliceZ[tiA];
      sliceHeading[ti] = Math.atan2(-dxT, -dzT);
    }

    function sampleRoad(relZ) {
      var relSegPos = (relZ / SEG_LEN_DART) + basePct + SLICE_BACK;
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

    // Update Road & Kerb Ribbon Vertex Buffers
    var rVerts = st.roadRibbon.verts;
    var rCols = st.roadRibbon.colors;
    var lkVerts = st.leftKerbRibbon.verts;
    var lkCols = st.leftKerbRibbon.colors;
    var rkVerts = st.rightKerbRibbon.verts;
    var rkCols = st.rightKerbRibbon.colors;

    for (var si2 = 0; si2 < TOTAL_SLICES; si2++) {
      var sx = sliceX[si2];
      var sy = sliceY[si2];
      var sz = sliceZ[si2];
      var segI = sliceSegIdx[si2];
      var band = (Math.floor(segI / 3) % 2) === 0;
      var rc = band ? aspACol : aspBCol;
      var kBand = (Math.floor(segI / 2) % 2) === 0;
      var kc = kBand ? kerbACol : kerbBCol;

      var vOff = si2 * 6;
      rVerts[vOff] = sx - ROAD_HALF_W;
      rVerts[vOff + 1] = sy;
      rVerts[vOff + 2] = sz;
      rVerts[vOff + 3] = sx + ROAD_HALF_W;
      rVerts[vOff + 4] = sy;
      rVerts[vOff + 5] = sz;

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

      for (var cOff = 0; cOff < 6; cOff += 3) {
        lkCols[vOff + cOff] = kc.r;
        lkCols[vOff + cOff + 1] = kc.g;
        lkCols[vOff + cOff + 2] = kc.b;
        rkCols[vOff + cOff] = kc.r;
        rkCols[vOff + cOff + 1] = kc.g;
        rkCols[vOff + cOff + 2] = kc.b;
      }
    }

    st.roadRibbon.geo.attributes.position.needsUpdate = true;
    st.roadRibbon.geo.attributes.color.needsUpdate = true;
    st.leftKerbRibbon.geo.attributes.position.needsUpdate = true;
    st.leftKerbRibbon.geo.attributes.color.needsUpdate = true;
    st.rightKerbRibbon.geo.attributes.position.needsUpdate = true;
    st.rightKerbRibbon.geo.attributes.color.needsUpdate = true;

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
        var am = st.archPool[archIdx++];
        am.visible = true;
        am.position.set(xC, yC, zC);
        am.rotation.y = yawC;
      }

      if (segObj.hasLightPylon && !isHighway && propIdx + 1 < st.propPool.length) {
        for (var side = -1; side <= 1; side += 2) {
          var pr = st.propPool[propIdx++];
          pr.group.visible = true;
          pr.group.position.set(xC + side * (ROAD_HALF_W + 2.6), yC, zC);
          pr.group.rotation.y = yawC;
          var isSynth = themeIdx === 2;
          var isNeon = themeIdx === 0;
          pr.palm.visible = isSynth;
          pr.pole.visible = !isSynth;
          pr.lamp.visible = !isSynth;
          pr.lampMat.color.copy(segObj.index % 16 === 0 ? accentCol : secCol);
          pr.bldg.visible = isNeon && (segObj.index % 16 === 0);
          pr.bldg.position.x = side * 12.5;
        }
      }

      // Billboards
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
            'bb_' + item.spec.title + '_' + item.spec.tag + '_' + (hasPhoto ? 'p1' : 'p0'),
            512,
            256,
            function (ctx, w, h) {
              ctx.fillStyle = '#070c1c';
              ctx.fillRect(0, 0, w, h);
              ctx.fillStyle = 'rgba(0, 240, 255, 0.20)';
              ctx.fillRect(0, 0, w, 58);
              ctx.fillStyle = '#00f0ff';
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
                ctx.strokeStyle = '#00f0ff';
                ctx.lineWidth = 4;
                ctx.beginPath();
                ctx.arc(82, 154, 54, 0, Math.PI * 2);
                ctx.stroke();
                tx = 154;
              }
              ctx.fillStyle = '#ffffff';
              ctx.font = 'bold 42px Rajdhani, sans-serif';
              ctx.fillText(item.spec.title, tx, 134);
              ctx.fillStyle = '#94a3b8';
              ctx.font = 'bold 24px Rajdhani, sans-serif';
              ctx.fillText(item.spec.sub, tx, 192);
            }
          );
          bPool.bMat.needsUpdate = true;
        }
      }

      // Destination Hologram Gantries
      if (segObj.gantryTitle && ganIdx < st.gantryPool.length) {
        var gObj = st.gantryPool[ganIdx++];
        gObj.group.visible = true;
        gObj.group.position.set(xC, yC, zC);
        gObj.group.rotation.y = yawC;
        gObj.holoDiamond.rotation.y = timeSec * 1.8;
        gObj.holoDiamond.position.y = 13.6 + Math.sin(timeSec * 3.5) * 0.65;
        var gDest = segObj.gantryDest || segObj.gantryCode || 'SECTOR';
        gObj.signMat.map = makeTextTexture(
          st.texCache,
          'gan_' + gDest + '_' + segObj.gantryTitle,
          768,
          160,
          function (ctx, w, h) {
            ctx.fillStyle = '#071022';
            ctx.fillRect(0, 0, w, h);
            ctx.strokeStyle = '#00f0ff';
            ctx.lineWidth = 6;
            ctx.strokeRect(4, 4, w - 8, h - 8);
            ctx.fillStyle = '#00f0ff';
            ctx.font = 'bold 34px Rajdhani, sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText('HOLO-GATE // ' + gDest, w / 2, 54);
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
    while (archIdx < st.archPool.length) st.archPool[archIdx++].visible = false;
    while (propIdx < st.propPool.length) st.propPool[propIdx++].group.visible = false;
    while (bbIdx < st.billboardPool.length) st.billboardPool[bbIdx++].group.visible = false;
    while (ganIdx < st.gantryPool.length) st.gantryPool[ganIdx++].group.visible = false;

    // Position Player 3D Vehicle at Exact Physics Lane & Ground Pose
    var playerWorldX = playerX * ROAD_HALF_W;
    var hoverOffset = vehicleType === 4 ? 0.35 + Math.sin(timeSec * 6.0) * 0.14 : 0.0;
    activePV.root.position.set(playerWorldX, hoverOffset, 0);
    var rollAngle = vehicleType === 2 ? -steer * 0.48 : -steer * 0.07;
    activePV.root.rotation.set(0, -steer * 0.16, rollAngle);
    st.underGlowLight.position.set(playerWorldX, 1.2, 0);
    st.arrivalWave.position.set(playerWorldX, 0.14, 0);

    // Position 3D Opponent Vehicles
    var cars = d.trafficCars || [];
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
        }
      }
    }

    // Position 3D Static Roadblock Obstacles
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
          var blinkEven = (Math.floor(timeSec * 8) % 2) === 0;
          obItem.beaconMat.color.setHex(ob.hit ? 0xffffff : (blinkEven ? 0xff3b5c : 0xf59e0b));
          obItem.bodyMat.emissive.setHex(ob.hit ? 0xff3b5c : 0x000000);
          obItem.bodyMat.emissiveIntensity = ob.hit ? 0.8 : 0.0;
        }
      }
    }

    // Position 3D Data Crystal Orbs
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

    // Trigger 3D Sparks on Collision
    if ((d.collisionEventSeq || 0) !== st.lastCollisionSeq) {
      st.lastCollisionSeq = d.collisionEventSeq || 0;
      var ix = (d.impactLaneX != null ? d.impactLaneX : playerX) * ROAD_HALF_W;
      spawnSparks(st, ix, 0.9, -1.6, d.impactPushDir || 1.0);
    }

    // 3D Camera Controller (Horizon Chase / Hood / Orbit / Highway / Garage 360)
    var shakeX = d.shakeX || 0;
    var shakeY = d.shakeY || 0;
    var targetCamPos = new THREE.Vector3();
    var targetLook = new THREE.Vector3();
    var targetFov = nitroActive ? 74 : 62;

    if (isGarageOpen) {
      var gAng = timeSec * 0.85;
      targetCamPos.set(playerWorldX + Math.cos(gAng) * 8.6, 3.1, Math.sin(gAng) * 8.6);
      targetLook.set(playerWorldX, 0.9, 0);
      targetFov = 54;
    } else if (isHighway) {
      targetCamPos.set(0, 29.0, 9.5);
      targetLook.set(0, 0, -4.5);
      targetFov = 58;
    } else if (cameraPreset === 1) {
      // Hood / Cockpit Low Racing Cam
      var hoodPose = sampleRoad(1400);
      targetCamPos.set(playerWorldX, 1.85 + hoverOffset, -0.45);
      targetLook.set(lerp(playerWorldX, hoodPose.x, 0.35), 1.45 + hoodPose.y * 0.2, -32);
      targetFov = nitroActive ? 80 : 68;
    } else if (cameraPreset === 2) {
      // Dynamic Low Hero Orbit Cam
      var cAngle = steer * 0.45;
      targetCamPos.set(playerWorldX + Math.sin(cAngle) * 7.5, 3.3, Math.cos(cAngle) * 8.4);
      targetLook.set(playerWorldX * 0.6, 1.15, -24);
      targetFov = nitroActive ? 72 : 60;
    } else {
      // Classic Dynamic 3D Chase Cam
      var aheadPose = sampleRoad(1800);
      targetCamPos.set(playerWorldX * 0.78 - steer * 0.8, 4.45, 9.8);
      targetLook.set(lerp(playerWorldX * 0.5, aheadPose.x * 0.25, 0.5), 1.35 + aheadPose.y * 0.12, -34);
    }

    st.camPos.lerp(targetCamPos, isGarageOpen ? 0.14 : 0.24);
    st.camLook.lerp(targetLook, isGarageOpen ? 0.14 : 0.28);

    st.camera.position.set(
      st.camPos.x + shakeX * 0.05,
      st.camPos.y + shakeY * 0.05,
      st.camPos.z
    );
    st.camera.lookAt(st.camLook);
    st.camera.fov = lerp(st.camera.fov, targetFov, 0.12);
    st.camera.updateProjectionMatrix();

    // Keep Horizon Sun & Sky aligned ahead
    st.horizonSun.position.set(sliceX[SLICE_AHEAD - 4] * 0.12, 42, -560);
    st.mtnGroup.rotation.y = (d.skyParallax || 0) * 0.03;

    st.dirLight.position.set(playerWorldX + 25, 65, 30);
    st.dirLight.target.position.set(playerWorldX, 0, -15);
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
      try { st.resizeObserver.disconnect(); } catch (e) {}
    }
    try {
      st.renderer.dispose();
    } catch (e) {}
    delete _instances[id];
  };
})();
