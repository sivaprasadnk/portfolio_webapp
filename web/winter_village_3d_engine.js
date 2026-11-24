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
    var g = ctx.createRadialGradient(32, 32, 2, 32, 32, 30);
    g.addColorStop(0.0, 'rgba(255,255,255,1.0)');
    g.addColorStop(0.45, 'rgba(235,246,255,0.75)');
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
    var g = ctx.createRadialGradient(64, 64, 4, 64, 64, 62);
    g.addColorStop(0.0, innerCss);
    g.addColorStop(0.35, midCss);
    g.addColorStop(1.0, 'rgba(0,0,0,0)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, 128, 128);
    var tex = new THREE.CanvasTexture(c);
    tex.needsUpdate = true;
    return tex;
  }

  function createSnowGroundTexture() {
    var c = document.createElement('canvas');
    c.width = 512;
    c.height = 512;
    var ctx = c.getContext('2d');
    ctx.fillStyle = '#edf4fc';
    ctx.fillRect(0, 0, 512, 512);
    for (var i = 0; i < 1600; i++) {
      var x = (i * 97) % 512;
      var y = (i * 53) % 512;
      var r = 1 + (i % 3);
      ctx.fillStyle = i % 4 === 0
        ? 'rgba(255,255,255,0.85)'
        : 'rgba(186,214,242,0.28)';
      ctx.beginPath();
      ctx.arc(x, y, r, 0, Math.PI * 2);
      ctx.fill();
    }
    var tex = new THREE.CanvasTexture(c);
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    tex.repeat.set(16, 22);
    tex.needsUpdate = true;
    return tex;
  }

  function createIglooBlockTexture() {
    var c = document.createElement('canvas');
    c.width = 256;
    c.height = 128;
    var ctx = c.getContext('2d');
    ctx.fillStyle = '#e2eefb';
    ctx.fillRect(0, 0, 256, 128);
    ctx.strokeStyle = 'rgba(148, 179, 214, 0.55)';
    ctx.lineWidth = 2;
    for (var row = 0; row < 6; row++) {
      var y = row * 22;
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(256, y);
      ctx.stroke();
      var offset = (row % 2) * 20;
      for (var col = 0; col < 7; col++) {
        var x = (col * 40 + offset) % 256;
        ctx.beginPath();
        ctx.moveTo(x, y);
        ctx.lineTo(x, y + 22);
        ctx.stroke();
      }
    }
    var tex = new THREE.CanvasTexture(c);
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    tex.needsUpdate = true;
    return tex;
  }

  function createTimberTexture() {
    var c = document.createElement('canvas');
    c.width = 256;
    c.height = 256;
    var ctx = c.getContext('2d');
    ctx.fillStyle = '#4e2f1e';
    ctx.fillRect(0, 0, 256, 256);
    for (var y = 0; y < 256; y += 22) {
      ctx.fillStyle = (y / 22) % 2 === 0 ? '#5c3824' : '#432718';
      ctx.fillRect(0, y, 256, 20);
      ctx.fillStyle = 'rgba(20,10,5,0.45)';
      ctx.fillRect(0, y + 20, 256, 2);
    }
    var tex = new THREE.CanvasTexture(c);
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    tex.needsUpdate = true;
    return tex;
  }

  function terrainHeightAt(x, z) {
    // Keep central village path gently sloped and smooth
    var pathCenter = Math.sin(z * 0.055) * 4.5;
    var distFromPath = Math.abs(x - pathCenter);
    var pathFlatten = smoothstep((distFromPath - 2.4) / 7.0);
    var hills =
      Math.sin(x * 0.08) * Math.cos(z * 0.06) * 1.45 +
      Math.sin(x * 0.17 + z * 0.11) * 0.55;
    return hills * pathFlatten;
  }

  function buildPineTree(scale, decorated, warmLightsBucket) {
    var group = new THREE.Group();
    var trunk = new THREE.Mesh(
      new THREE.CylinderGeometry(0.18 * scale, 0.28 * scale, 1.3 * scale, 8),
      new THREE.MeshStandardMaterial({ color: 0x3f2414, roughness: 0.92 })
    );
    trunk.position.y = 0.65 * scale;
    trunk.castShadow = true;
    trunk.receiveShadow = true;
    group.add(trunk);

    var pineColors = [0x123f2c, 0x174d36, 0x1c5b40, 0x226849];
    var tierCount = 4;
    for (var i = 0; i < tierCount; i++) {
      var frac = i / (tierCount - 1);
      var radius = lerp(1.75, 0.68, frac) * scale;
      var height = lerp(2.0, 1.35, frac) * scale;
      var yPos = (1.6 + i * 1.08) * scale;

      var cone = new THREE.Mesh(
        new THREE.ConeGeometry(radius, height, 11),
        new THREE.MeshStandardMaterial({
          color: pineColors[i % pineColors.length],
          roughness: 0.85,
        })
      );
      cone.position.y = yPos;
      cone.castShadow = true;
      cone.receiveShadow = true;
      group.add(cone);

      // Snow cap rim on top of each branch tier
      var snowRim = new THREE.Mesh(
        new THREE.ConeGeometry(radius * 0.94, height * 0.42, 11),
        new THREE.MeshStandardMaterial({
          color: 0xf1f7ff,
          roughness: 0.65,
          metalness: 0.04,
        })
      );
      snowRim.position.y = yPos + height * 0.30;
      group.add(snowRim);
    }

    if (decorated) {
      var bulbPalette = [0xf5d076, 0xe11d48, 0x38bdf8, 0x34d399];
      for (var b = 0; b < 14; b++) {
        var bf = (b + 1) / 15;
        var ang = b * 2.15;
        var br = lerp(1.52, 0.42, bf) * scale;
        var by = lerp(1.35, 4.95, bf) * scale;
        var col = bulbPalette[b % bulbPalette.length];
        var bulbMat = new THREE.MeshStandardMaterial({
          color: col,
          emissive: col,
          emissiveIntensity: 0.95,
          roughness: 0.25,
          metalness: 0.35,
        });
        var bulb = new THREE.Mesh(
          new THREE.SphereGeometry(0.11 * scale, 8, 8),
          bulbMat
        );
        bulb.position.set(Math.cos(ang) * br, by, Math.sin(ang) * br);
        group.add(bulb);
        warmLightsBucket.push({
          mat: bulbMat,
          phase: b * 0.7,
          base: 0.95,
        });
      }

      // Golden star topper
      var starMat = new THREE.MeshStandardMaterial({
        color: 0xfde68a,
        emissive: 0xf59e0b,
        emissiveIntensity: 1.4,
        roughness: 0.2,
        metalness: 0.6,
      });
      var star = new THREE.Mesh(
        new THREE.OctahedronGeometry(0.28 * scale, 0),
        starMat
      );
      star.position.y = 5.65 * scale;
      group.add(star);
      warmLightsBucket.push({ mat: starMat, phase: 0.2, base: 1.4 });

      var treeLight = new THREE.PointLight(0xffd27a, 1.3, 14 * scale, 1.8);
      treeLight.position.set(0, 3.2 * scale, 0);
      group.add(treeLight);
      warmLightsBucket.push({ light: treeLight, nightIntensity: 1.45, dayIntensity: 0.25 });
    }

    return group;
  }

  function buildIgloo(iglooTex, warmLightsBucket, sectionId) {
    var group = new THREE.Group();
    group.userData.sectionId = sectionId;

    var domeMat = new THREE.MeshStandardMaterial({
      map: iglooTex,
      color: 0xf2f7ff,
      roughness: 0.72,
      metalness: 0.04,
    });
    var dome = new THREE.Mesh(
      new THREE.SphereGeometry(2.3, 20, 14, 0, Math.PI * 2, 0, Math.PI * 0.54),
      domeMat
    );
    dome.castShadow = true;
    dome.receiveShadow = true;
    dome.userData.sectionId = sectionId;
    group.add(dome);

    // Entrance tunnel arch
    var tunnel = new THREE.Mesh(
      new THREE.CylinderGeometry(0.95, 1.05, 1.65, 14, 1, false, 0, Math.PI),
      domeMat
    );
    tunnel.rotation.z = Math.PI / 2;
    tunnel.rotation.y = Math.PI / 2;
    tunnel.position.set(0, 0.05, 2.05);
    tunnel.castShadow = true;
    tunnel.receiveShadow = true;
    group.add(tunnel);

    // Warm glowing interior entrance backdrop
    var glowDoorMat = new THREE.MeshStandardMaterial({
      color: 0xffb347,
      emissive: 0xff8c1a,
      emissiveIntensity: 1.1,
      roughness: 0.5,
    });
    var glowDoor = new THREE.Mesh(
      new THREE.CircleGeometry(0.76, 16),
      glowDoorMat
    );
    glowDoor.position.set(0, 0.45, 2.15);
    group.add(glowDoor);
    warmLightsBucket.push({ mat: glowDoorMat, phase: 1.2, base: 1.1 });

    // Small festive bulbs over entrance
    var doorColors = [0xf5d076, 0xe11d48, 0x38bdf8];
    for (var k = -2; k <= 2; k++) {
      var col = doorColors[Math.abs(k) % doorColors.length];
      var bMat = new THREE.MeshStandardMaterial({
        color: col,
        emissive: col,
        emissiveIntensity: 1.0,
      });
      var bulb = new THREE.Mesh(new THREE.SphereGeometry(0.08, 8, 8), bMat);
      bulb.position.set(k * 0.34, 1.02 - Math.abs(k) * 0.10, 2.86);
      group.add(bulb);
      warmLightsBucket.push({ mat: bMat, phase: k * 0.8, base: 1.0 });
    }

    var warmLight = new THREE.PointLight(0xffa94d, 1.6, 11, 1.8);
    warmLight.position.set(0, 0.9, 2.8);
    group.add(warmLight);
    warmLightsBucket.push({ light: warmLight, nightIntensity: 1.8, dayIntensity: 0.25 });

    return group;
  }

  function buildWinterCabin(timberTex, warmLightsBucket, sectionId, scale) {
    var s = scale || 1.0;
    var group = new THREE.Group();
    group.userData.sectionId = sectionId;

    var wall = new THREE.Mesh(
      new THREE.BoxGeometry(4.2 * s, 2.5 * s, 3.4 * s),
      new THREE.MeshStandardMaterial({ map: timberTex, roughness: 0.85 })
    );
    wall.position.y = 1.25 * s;
    wall.castShadow = true;
    wall.receiveShadow = true;
    wall.userData.sectionId = sectionId;
    group.add(wall);

    // Pitched snowy roof
    var roof = new THREE.Mesh(
      new THREE.ConeGeometry(3.45 * s, 2.0 * s, 4),
      new THREE.MeshStandardMaterial({ color: 0xf4f8ff, roughness: 0.62 })
    );
    roof.rotation.y = Math.PI / 4;
    roof.position.y = 3.45 * s;
    roof.castShadow = true;
    roof.userData.sectionId = sectionId;
    group.add(roof);

    // Stone chimney
    var chimney = new THREE.Mesh(
      new THREE.BoxGeometry(0.65 * s, 1.4 * s, 0.65 * s),
      new THREE.MeshStandardMaterial({ color: 0x64748b, roughness: 0.9 })
    );
    chimney.position.set(1.1 * s, 3.6 * s, -0.5 * s);
    chimney.castShadow = true;
    group.add(chimney);

    // Glowing warm windows & door
    var winMat = new THREE.MeshStandardMaterial({
      color: 0xffd27a,
      emissive: 0xf59e0b,
      emissiveIntensity: 1.15,
      roughness: 0.3,
    });
    warmLightsBucket.push({ mat: winMat, phase: 0.4, base: 1.15 });

    var door = new THREE.Mesh(
      new THREE.BoxGeometry(0.82 * s, 1.45 * s, 0.12 * s),
      new THREE.MeshStandardMaterial({ color: 0x6e1423, roughness: 0.7 })
    );
    door.position.set(0, 0.72 * s, 1.72 * s);
    group.add(door);

    for (var wx in [-1.25, 1.25]) {
      var xPos = [-1.25, 1.25][wx];
      var win = new THREE.Mesh(
        new THREE.BoxGeometry(0.78 * s, 0.78 * s, 0.1 * s),
        winMat
      );
      win.position.set(xPos * s, 1.38 * s, 1.72 * s);
      group.add(win);
    }

    var porchLight = new THREE.PointLight(0xffb85c, 2.0, 14 * s, 1.8);
    porchLight.position.set(0, 1.8 * s, 2.7 * s);
    group.add(porchLight);
    warmLightsBucket.push({ light: porchLight, nightIntensity: 2.2, dayIntensity: 0.3 });

    return group;
  }

  function buildWoodenSignboard(timberTex, warmLightsBucket) {
    var group = new THREE.Group();
    var post = new THREE.Mesh(
      new THREE.CylinderGeometry(0.11, 0.13, 2.1, 8),
      new THREE.MeshStandardMaterial({ map: timberTex, roughness: 0.9 })
    );
    post.position.y = 1.05;
    post.castShadow = true;
    group.add(post);

    var board = new THREE.Mesh(
      new THREE.BoxGeometry(1.75, 0.95, 0.14),
      new THREE.MeshStandardMaterial({ map: timberTex, roughness: 0.8 })
    );
    board.position.y = 1.75;
    board.castShadow = true;
    group.add(board);

    var snowTop = new THREE.Mesh(
      new THREE.BoxGeometry(1.82, 0.12, 0.2),
      new THREE.MeshStandardMaterial({ color: 0xf8fafc, roughness: 0.65 })
    );
    snowTop.position.y = 2.25;
    group.add(snowTop);

    var lanternMat = new THREE.MeshStandardMaterial({
      color: 0xfde68a,
      emissive: 0xf59e0b,
      emissiveIntensity: 1.2,
    });
    var lantern = new THREE.Mesh(
      new THREE.SphereGeometry(0.12, 8, 8),
      lanternMat
    );
    lantern.position.set(0.78, 2.38, 0.1);
    group.add(lantern);
    warmLightsBucket.push({ mat: lanternMat, phase: 2.1, base: 1.2 });

    return group;
  }

  function buildArticulatedDeer(scale) {
    var s = scale || 1.0;
    var root = new THREE.Group();

    var furMat = new THREE.MeshStandardMaterial({
      color: 0x8b5a3c,
      roughness: 0.85,
    });
    var bellyMat = new THREE.MeshStandardMaterial({
      color: 0xd8c3b0,
      roughness: 0.88,
    });
    var antlerMat = new THREE.MeshStandardMaterial({
      color: 0xd6c7b2,
      roughness: 0.72,
    });

    // Body
    var body = new THREE.Mesh(
      new THREE.BoxGeometry(0.65 * s, 0.52 * s, 1.35 * s),
      furMat
    );
    body.position.set(0, 1.05 * s, 0);
    body.castShadow = true;
    root.add(body);

    var chest = new THREE.Mesh(
      new THREE.BoxGeometry(0.56 * s, 0.36 * s, 0.55 * s),
      bellyMat
    );
    chest.position.set(0, 0.88 * s, 0.2 * s);
    root.add(chest);

    // Neck + Head pivot
    var neckPivot = new THREE.Group();
    neckPivot.position.set(0, 1.25 * s, 0.55 * s);
    root.add(neckPivot);

    var neck = new THREE.Mesh(
      new THREE.BoxGeometry(0.28 * s, 0.62 * s, 0.3 * s),
      furMat
    );
    neck.position.set(0, 0.28 * s, 0.08 * s);
    neck.rotation.x = 0.25;
    neck.castShadow = true;
    neckPivot.add(neck);

    var head = new THREE.Mesh(
      new THREE.BoxGeometry(0.30 * s, 0.26 * s, 0.48 * s),
      furMat
    );
    head.position.set(0, 0.60 * s, 0.26 * s);
    head.castShadow = true;
    neckPivot.add(head);

    var nose = new THREE.Mesh(
      new THREE.SphereGeometry(0.065 * s, 8, 8),
      new THREE.MeshStandardMaterial({ color: 0x1e1b18, roughness: 0.4 })
    );
    nose.position.set(0, 0.58 * s, 0.51 * s);
    neckPivot.add(nose);

    // Branching Antlers
    for (var side in [-1, 1]) {
      var dir = [-1, 1][side];
      var mainBeam = new THREE.Mesh(
        new THREE.CylinderGeometry(0.025 * s, 0.035 * s, 0.52 * s, 6),
        antlerMat
      );
      mainBeam.position.set(dir * 0.14 * s, 0.90 * s, 0.14 * s);
      mainBeam.rotation.z = -dir * 0.32;
      mainBeam.rotation.x = -0.2;
      neckPivot.add(mainBeam);

      var tine = new THREE.Mesh(
        new THREE.CylinderGeometry(0.018 * s, 0.025 * s, 0.26 * s, 6),
        antlerMat
      );
      tine.position.set(dir * 0.20 * s, 0.98 * s, 0.24 * s);
      tine.rotation.x = 0.55;
      neckPivot.add(tine);
    }

    // 4 Articulated Legs
    var legs = [];
    var legOffsets = [
      [-0.20 * s, 0.82 * s, 0.48 * s],
      [0.20 * s, 0.82 * s, 0.48 * s],
      [-0.20 * s, 0.82 * s, -0.48 * s],
      [0.20 * s, 0.82 * s, -0.48 * s],
    ];
    for (var l = 0; l < 4; l++) {
      var lp = new THREE.Group();
      lp.position.set(legOffsets[l][0], legOffsets[l][1], legOffsets[l][2]);
      var legMesh = new THREE.Mesh(
        new THREE.BoxGeometry(0.12 * s, 0.82 * s, 0.14 * s),
        furMat
      );
      legMesh.position.y = -0.41 * s;
      legMesh.castShadow = true;
      lp.add(legMesh);
      root.add(lp);
      legs.push(lp);
    }

    return {
      root: root,
      neckPivot: neckPivot,
      legs: legs,
    };
  }

  function buildSantaSleighRig() {
    var rig = new THREE.Group();

    // Sleigh body
    var sleighBody = new THREE.Mesh(
      new THREE.BoxGeometry(2.2, 0.85, 1.25),
      new THREE.MeshStandardMaterial({
        color: 0x991b1b,
        emissive: 0x450a0a,
        roughness: 0.4,
        metalness: 0.25,
      })
    );
    sleighBody.position.set(0, 0.45, 0);
    rig.add(sleighBody);

    // Gold runners
    var goldMat = new THREE.MeshStandardMaterial({
      color: 0xfde68a,
      emissive: 0xf59e0b,
      emissiveIntensity: 0.7,
      metalness: 0.7,
      roughness: 0.25,
    });
    for (var rz in [-0.55, 0.55]) {
      var runner = new THREE.Mesh(
        new THREE.BoxGeometry(2.7, 0.10, 0.08),
        goldMat
      );
      runner.position.set(0.1, 0, [-0.55, 0.55][rz]);
      rig.add(runner);
    }

    // Santa silhouette
    var santaTorso = new THREE.Mesh(
      new THREE.CylinderGeometry(0.28, 0.36, 0.75, 10),
      new THREE.MeshStandardMaterial({ color: 0xdc2626 })
    );
    santaTorso.position.set(-0.2, 1.05, 0);
    rig.add(santaTorso);

    var santaHead = new THREE.Mesh(
      new THREE.SphereGeometry(0.22, 10, 10),
      new THREE.MeshStandardMaterial({ color: 0xfde2c8 })
    );
    santaHead.position.set(-0.2, 1.56, 0);
    rig.add(santaHead);

    // 3 flying reindeer ahead (+X direction)
    var reindeer = [];
    for (var r = 0; r < 3; r++) {
      var d = buildArticulatedDeer(0.68);
      d.root.rotation.y = Math.PI / 2;
      d.root.position.set(2.8 + r * 2.1, 0.15, (r % 2 === 0 ? 0.42 : -0.42));
      rig.add(d.root);
      reindeer.push(d);
    }

    var sleighGlow = new THREE.PointLight(0xfde68a, 2.2, 22, 1.5);
    sleighGlow.position.set(0, 1.2, 0);
    rig.add(sleighGlow);

    return { rig: rig, reindeer: reindeer };
  }

  function buildCloudCluster(x, y, z, scale) {
    var g = new THREE.Group();
    var mat = new THREE.MeshStandardMaterial({
      color: 0xffffff,
      roughness: 0.92,
      metalness: 0.0,
      transparent: true,
      opacity: 0.90,
    });
    var puffs = [
      [0, 0, 0, 1.4],
      [-1.1, -0.2, 0.2, 1.05],
      [1.15, -0.15, -0.15, 1.1],
      [-0.45, 0.55, 0.1, 1.0],
      [0.5, 0.45, -0.1, 0.95],
    ];
    for (var i = 0; i < puffs.length; i++) {
      var p = puffs[i];
      var m = new THREE.Mesh(
        new THREE.SphereGeometry(p[3] * scale, 14, 12),
        mat
      );
      m.position.set(p[0] * scale, p[1] * scale, p[2] * scale);
      g.add(m);
    }
    g.position.set(x, y, z);
    return { group: g, mat: mat, baseY: y };
  }

  function createAuroraMesh() {
    var c = document.createElement('canvas');
    c.width = 512;
    c.height = 128;
    var ctx = c.getContext('2d');
    var g = ctx.createLinearGradient(0, 0, 512, 0);
    g.addColorStop(0.0, 'rgba(16,185,129,0.0)');
    g.addColorStop(0.25, 'rgba(52,211,153,0.55)');
    g.addColorStop(0.55, 'rgba(56,189,248,0.55)');
    g.addColorStop(0.8, 'rgba(168,85,247,0.45)');
    g.addColorStop(1.0, 'rgba(16,185,129,0.0)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, 512, 128);

    var vertFade = ctx.createLinearGradient(0, 0, 0, 128);
    vertFade.addColorStop(0.0, 'rgba(0,0,0,0)');
    vertFade.addColorStop(0.4, 'rgba(255,255,255,1)');
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
    var geo = new THREE.PlaneGeometry(150, 26, 28, 4);
    var mesh = new THREE.Mesh(geo, mat);
    mesh.position.set(0, 38, -82);
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
    scene.fog = new THREE.FogExp2(0x09162e, 0.011);

    var camera = new THREE.PerspectiveCamera(50, w / h, 0.1, 300);
    camera.position.set(0, 6.5, 22);

    // Lighting rig (interpolated smoothly between Day and Night)
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

    // Ground terrain
    var groundGeo = new THREE.PlaneGeometry(180, 220, 72, 84);
    groundGeo.rotateX(-Math.PI / 2);
    var posAttr = groundGeo.attributes.position;
    for (var vi = 0; vi < posAttr.count; vi++) {
      var gx = posAttr.getX(vi);
      var gz = posAttr.getZ(vi);
      posAttr.setY(vi, terrainHeightAt(gx, gz));
    }
    groundGeo.computeVertexNormals();

    var groundMat = new THREE.MeshStandardMaterial({
      map: createSnowGroundTexture(),
      color: 0xe6f0fa,
      roughness: 0.78,
      metalness: 0.03,
    });
    var groundMesh = new THREE.Mesh(groundGeo, groundMat);
    groundMesh.receiveShadow = true;
    scene.add(groundMesh);

    // Winding village path markers (subtle golden lantern posts along path)
    var timberTex = createTimberTexture();
    var iglooTex = createIglooBlockTexture();

    for (var pz = 14; pz >= -78; pz -= 11) {
      var px = Math.sin(pz * 0.055) * 4.5 + ((pz % 2 === 0) ? 2.8 : -2.8);
      var py = terrainHeightAt(px, pz);
      var sign = buildWoodenSignboard(timberTex, warmLightsBucket);
      sign.position.set(px, py, pz);
      sign.rotation.y = (px > 0 ? -0.35 : 0.35);
      scene.add(sign);
    }

    // Distant Snow-Capped Mountains Ring
    var mountainMat = new THREE.MeshStandardMaterial({
      color: 0x334e6f,
      roughness: 0.92,
    });
    var snowCapMat = new THREE.MeshStandardMaterial({
      color: 0xf1f7ff,
      roughness: 0.65,
    });
    for (var m = 0; m < 16; m++) {
      var ma = -Math.PI * 0.88 + (m / 15) * Math.PI * 0.76 - Math.PI * 0.05;
      var dist = 92 + (m % 3) * 14;
      var mx = Math.cos(ma) * dist;
      var mz = Math.sin(ma) * dist - 20;
      var mh = 22 + (m % 4) * 7;
      var mr = 14 + (m % 3) * 4;

      var peak = new THREE.Mesh(
        new THREE.ConeGeometry(mr, mh, 7),
        mountainMat
      );
      peak.position.set(mx, mh * 0.42, mz);
      scene.add(peak);

      var cap = new THREE.Mesh(
        new THREE.ConeGeometry(mr * 0.45, mh * 0.42, 7),
        snowCapMat
      );
      cap.position.set(mx, mh * 0.71, mz);
      scene.add(cap);
    }

    // Celestial objects: Sun, Moon, Stars, Shooting Star, Aurora Borealis
    var sunMesh = new THREE.Mesh(
      new THREE.SphereGeometry(4.2, 20, 20),
      new THREE.MeshBasicMaterial({ color: 0xfff3b0 })
    );
    sunMesh.position.set(34, 42, -78);
    scene.add(sunMesh);

    var sunGlow = new THREE.Sprite(
      new THREE.SpriteMaterial({
        map: createGlowTexture('rgba(255,243,176,0.9)', 'rgba(253,224,71,0.25)'),
        transparent: true,
        blending: THREE.AdditiveBlending,
        depthWrite: false,
      })
    );
    sunGlow.scale.set(28, 28, 1);
    sunMesh.add(sunGlow);

    var moonMesh = new THREE.Mesh(
      new THREE.SphereGeometry(3.4, 20, 20),
      new THREE.MeshBasicMaterial({ color: 0xeef6ff })
    );
    moonMesh.position.set(-28, 38, -78);
    scene.add(moonMesh);

    var moonGlow = new THREE.Sprite(
      new THREE.SpriteMaterial({
        map: createGlowTexture('rgba(224,242,254,0.8)', 'rgba(147,197,253,0.22)'),
        transparent: true,
        blending: THREE.AdditiveBlending,
        depthWrite: false,
      })
    );
    moonGlow.scale.set(22, 22, 1);
    moonMesh.add(moonGlow);

    // Starfield
    var starCount = 900;
    var starPos = new Float32Array(starCount * 3);
    for (var si = 0; si < starCount; si++) {
      var st = (si * 2.39996);
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
    var starField = new THREE.Points(starGeo, starMat);
    scene.add(starField);

    // Shooting star
    var shootingStar = new THREE.Mesh(
      new THREE.SphereGeometry(0.24, 8, 8),
      new THREE.MeshBasicMaterial({ color: 0xfef9c3, transparent: true, opacity: 0 })
    );
    scene.add(shootingStar);

    // Aurora Borealis
    var aurora = createAuroraMesh();
    scene.add(aurora.mesh);

    // Sky 3D clouds
    var clouds = [];
    var cloudPositions = [
      [-24, 24, -44, 1.5],
      [18, 27, -52, 1.8],
      [-6, 22, -36, 1.2],
      [30, 20, -40, 1.4],
      [-32, 21, -55, 1.6],
    ];
    for (var ci = 0; ci < cloudPositions.length; ci++) {
      var cp = cloudPositions[ci];
      var cl = buildCloudCluster(cp[0], cp[1], cp[2], cp[3]);
      cl.speed = 0.55 + (ci % 3) * 0.25;
      cl.phase = ci * 1.3;
      scene.add(cl.group);
      clouds.push(cl);
    }

    // Village Architecture: Igloos, Cabins, Christmas Trees, Snow Rocks
    var iglooPlacements = [
      { x: -10.5, z: 6.0, rot: 0.55, section: 'about' },
      { x: 11.5, z: -16.0, rot: -0.65, section: 'experience' },
      { x: -12.0, z: -38.0, rot: 0.45, section: 'projects' },
      { x: 10.5, z: -56.0, rot: -0.5, section: 'skills' },
    ];
    for (var ig = 0; ig < iglooPlacements.length; ig++) {
      var ip = iglooPlacements[ig];
      var igloo = buildIgloo(iglooTex, warmLightsBucket, ip.section);
      igloo.position.set(ip.x, terrainHeightAt(ip.x, ip.z) - 0.1, ip.z);
      igloo.rotation.y = ip.rot;
      scene.add(igloo);
      interactiveTargets.push(igloo);
    }

    // Cozy Cabins (About Me cabin & Contact cabin)
    var aboutCabin = buildWinterCabin(timberTex, warmLightsBucket, 'about', 1.15);
    aboutCabin.position.set(11.0, terrainHeightAt(11.0, -5.0), -5.0);
    aboutCabin.rotation.y = -0.55;
    scene.add(aboutCabin);
    interactiveTargets.push(aboutCabin);

    var contactCabin = buildWinterCabin(timberTex, warmLightsBucket, 'contact', 1.35);
    contactCabin.position.set(-7.5, terrainHeightAt(-7.5, -72.0), -72.0);
    contactCabin.rotation.y = 0.42;
    scene.add(contactCabin);
    interactiveTargets.push(contactCabin);

    // Chimney smoke puffs
    var smokePuffs = [];
    var smokeGeo = new THREE.SphereGeometry(0.32, 8, 8);
    var smokeMat = new THREE.MeshBasicMaterial({
      color: 0xe2e8f0,
      transparent: true,
      opacity: 0.32,
    });
    for (var sp = 0; sp < 10; sp++) {
      var puff = new THREE.Mesh(smokeGeo, smokeMat);
      var useAbout = sp < 5;
      puff.userData.base = useAbout
        ? new THREE.Vector3(12.2, terrainHeightAt(11.0, -5.0) + 4.8, -5.5)
        : new THREE.Vector3(-6.2, terrainHeightAt(-7.5, -72.0) + 5.6, -72.5);
      puff.userData.phase = (sp % 5) / 5.0;
      scene.add(puff);
      smokePuffs.push(puff);
    }

    // Decorated Hero & Village Christmas Trees + Pine Forest
    var heroTree = buildPineTree(1.45, true, warmLightsBucket);
    heroTree.position.set(7.8, terrainHeightAt(7.8, 9.5), 9.5);
    heroTree.userData.sectionId = 'home';
    scene.add(heroTree);
    interactiveTargets.push(heroTree);

    var treeConfigs = [
      [-8.5, 11.5, 1.1, true],
      [-14.5, -6.5, 1.25, false],
      [15.5, -24.0, 1.3, true],
      [-15.5, -28.0, 1.05, false],
      [13.5, -43.0, 1.2, true],
      [-14.0, -55.0, 1.15, false],
      [14.5, -67.0, 1.35, true],
      [-16.0, -76.0, 1.2, false],
    ];
    for (var tc = 0; tc < treeConfigs.length; tc++) {
      var tcfg = treeConfigs[tc];
      var pine = buildPineTree(tcfg[2], tcfg[3], warmLightsBucket);
      pine.position.set(tcfg[0], terrainHeightAt(tcfg[0], tcfg[1]), tcfg[1]);
      scene.add(pine);
    }
    // Background forest ring
    for (var bf = 0; bf < 28; bf++) {
      var bx = ((bf % 2 === 0 ? 1 : -1) * (18 + (bf * 7) % 28));
      var bz = 18 - bf * 4.1;
      var bs = 0.85 + (bf % 4) * 0.25;
      var bgTree = buildPineTree(bs, false, warmLightsBucket);
      bgTree.position.set(bx, terrainHeightAt(bx, bz), bz);
      scene.add(bgTree);
    }

    // Snow-covered rocks
    var rockMat = new THREE.MeshStandardMaterial({ color: 0x475569, roughness: 0.95 });
    for (var rk = 0; rk < 18; rk++) {
      var rx = (rk % 2 === 0 ? 1 : -1) * (4.5 + (rk * 5) % 16);
      var rz = 12 - rk * 5.2;
      var rs = 0.45 + (rk % 3) * 0.22;
      var rock = new THREE.Mesh(new THREE.DodecahedronGeometry(rs, 0), rockMat);
      rock.scale.set(1.3, 0.75, 1.1);
      rock.position.set(rx, terrainHeightAt(rx, rz) + rs * 0.25, rz);
      rock.castShadow = true;
      rock.receiveShadow = true;
      scene.add(rock);
    }

    // Animated 3D Deer Herd (walk, stop, look around, resume)
    var deerActors = [];
    var deerConfigs = [
      { cx: -4.2, cz: 7.5, rx: 4.5, rz: 3.0, speed: 0.75, scale: 0.92, phase: 0.0 },
      { cx: 5.5, cz: -14.0, rx: 4.0, rz: 4.5, speed: 0.62, scale: 1.0, phase: 1.8 },
      { cx: -5.5, cz: -34.0, rx: 5.0, rz: 3.5, speed: 0.70, scale: 0.88, phase: 3.2 },
      { cx: 4.2, cz: -52.0, rx: 4.2, rz: 4.0, speed: 0.65, scale: 0.95, phase: 4.7 },
    ];
    for (var da = 0; da < deerConfigs.length; da++) {
      var dc = deerConfigs[da];
      var deer = buildArticulatedDeer(dc.scale);
      deer.root.userData.sectionId = 'experience';
      scene.add(deer.root);
      interactiveTargets.push(deer.root);
      deerActors.push({
        model: deer,
        cfg: dc,
        angle: dc.phase,
        isIdle: false,
        stateTimer: 3.0 + da * 1.4,
      });
    }

    // Santa Claus & Sleigh (appears every ~35-55 seconds across the sky)
    var santa = buildSantaSleighRig();
    santa.rig.visible = false;
    scene.add(santa.rig);
    var santaState = {
      active: false,
      timer: 18.0, // first cameo ~18s after load, then every 35-55s
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
      size: 0.55,
      transparent: true,
      opacity: 0.85,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
    });
    var snowPoints = new THREE.Points(snowGeo, snowMat);
    scene.add(snowPoints);

    // Camera targets per section / scroll
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
      scene.fog.density = lerp(0.011, 0.0082, dayF);

      hemiLight.color.setHex(0x8bb8ff).lerp(new THREE.Color(0xe0f2fe), dayF);
      hemiLight.groundColor.setHex(0x132033).lerp(new THREE.Color(0x94a3b8), dayF);
      hemiLight.intensity = lerp(0.55, 1.05, dayF);

      keyLight.color.setHex(0x9ec5ff).lerp(new THREE.Color(0xfff4dc), dayF);
      keyLight.intensity = lerp(0.55, 1.55, dayF);
      keyLight.position.set(lerp(-24, 30, dayF), lerp(32, 40, dayF), lerp(-20, 22, dayF));

      sunMesh.visible = dayF > 0.04;
      sunMesh.position.y = lerp(12, 42, dayF);
      moonMesh.visible = dayF < 0.96;
      moonMesh.position.y = lerp(38, 10, dayF);

      starMat.opacity = clamp((1.0 - dayF * 1.35) * 0.9, 0, 0.95);
      aurora.mat.opacity = clamp((1.0 - dayF * 1.4) * (0.42 + 0.14 * Math.sin(timeSec * 0.7)), 0, 0.65);

      for (var ci = 0; ci < clouds.length; ci++) {
        clouds[ci].mat.color.setHex(0x334c70).lerp(new THREE.Color(0xffffff), dayF);
        clouds[ci].mat.opacity = lerp(0.45, 0.92, dayF);
      }

      for (var wi = 0; wi < warmLightsBucket.length; wi++) {
        var item = warmLightsBucket[wi];
        if (item.light) {
          item.light.intensity = lerp(item.nightIntensity, item.dayIntensity, dayF);
        }
        if (item.mat) {
          var twinkle = inst.reducedMotion ? 1.0 : (0.75 + 0.25 * Math.sin(timeSec * 3.1 + item.phase));
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

      // Smooth Day / Night transition
      inst.currentDayFactor = lerp(inst.currentDayFactor, inst.targetDayFactor, 1 - Math.exp(-2.8 * dt));
      inst.currentScrollFraction = lerp(inst.currentScrollFraction, inst.targetScrollFraction, 1 - Math.exp(-5.0 * dt));
      applyDayNightAtmosphere(inst.currentDayFactor, t);

      // Camera flies gently along the snowy village road as user scrolls
      var s = inst.currentScrollFraction;
      var targetZ = lerp(21.0, -56.0, s);
      var targetX = Math.sin(targetZ * 0.055) * 4.0 + inst.pointerNormX * 1.8;
      var targetY = 6.2 - inst.pointerNormY * 0.7 + terrainHeightAt(targetX, targetZ) * 0.4;
      cameraAnchor.set(targetX, targetY, targetZ);
      lookAnchor.set(Math.sin((targetZ - 16) * 0.055) * 3.2, 2.2, targetZ - 18.0);
      camera.position.lerp(cameraAnchor, 1 - Math.exp(-6.0 * dt));
      camera.lookAt(lookAnchor);

      if (!inst.reducedMotion) {
        // Clouds drift
        for (var ci = 0; ci < clouds.length; ci++) {
          var cl = clouds[ci];
          cl.group.position.x += cl.speed * dt;
          cl.group.position.y = cl.baseY + Math.sin(t * 0.5 + cl.phase) * 0.45;
          if (cl.group.position.x > 46) cl.group.position.x = -46;
        }

        // Aurora gentle wave
        var ap = aurora.geo.attributes.position;
        for (var ai = 0; ai < ap.count; ai++) {
          var ax = ap.getX(ai);
          ap.setZ(ai, Math.sin(ax * 0.08 + t * 0.9) * 5.0);
        }
        ap.needsUpdate = true;

        // Chimney smoke rising
        for (var si = 0; si < smokePuffs.length; si++) {
          var sf = smokePuffs[si];
          var age = (sf.userData.phase + t * 0.22) % 1.0;
          sf.position.set(
            sf.userData.base.x + Math.sin(age * 4 + si) * 0.35,
            sf.userData.base.y + age * 4.5,
            sf.userData.base.z - age * 0.6
          );
          var sc = 0.5 + age * 1.4;
          sf.scale.set(sc, sc, sc);
        }

        // Deer walking + stopping + looking around
        for (var di = 0; di < deerActors.length; di++) {
          var da = deerActors[di];
          da.stateTimer -= dt;
          if (da.stateTimer <= 0) {
            da.isIdle = !da.isIdle;
            da.stateTimer = da.isIdle ? (2.2 + (di % 3)) : (5.0 + (di % 4) * 1.5);
          }

          if (!da.isIdle) {
            da.angle += dt * da.cfg.speed * 0.45;
            var nx = da.cfg.cx + Math.cos(da.angle) * da.cfg.rx;
            var nz = da.cfg.cz + Math.sin(da.angle) * da.cfg.rz;
            var dx = -Math.sin(da.angle) * da.cfg.rx;
            var dz = Math.cos(da.angle) * da.cfg.rz;
            da.model.root.position.set(nx, terrainHeightAt(nx, nz), nz);
            da.model.root.rotation.y = Math.atan2(dx, dz);

            var stride = Math.sin(t * 5.5 + di);
            da.model.legs[0].rotation.x = stride * 0.42;
            da.model.legs[1].rotation.x = -stride * 0.42;
            da.model.legs[2].rotation.x = -stride * 0.38;
            da.model.legs[3].rotation.x = stride * 0.38;
            da.model.neckPivot.rotation.y = Math.sin(t * 1.2 + di) * 0.12;
            da.model.neckPivot.rotation.x = 0.04 * Math.sin(t * 5.5 + di);
          } else {
            for (var lg = 0; lg < 4; lg++) {
              da.model.legs[lg].rotation.x *= 0.88;
            }
            // Look around naturally while paused
            da.model.neckPivot.rotation.y = Math.sin(t * 1.6 + di) * 0.48;
            da.model.neckPivot.rotation.x = 0.15 + Math.sin(t * 1.1) * 0.12;
          }
        }

        // Occasional Santa Sleigh every 30-60s
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
          var sx = lerp(-56 * santaState.direction, 56 * santaState.direction, santaState.progress);
          var sy = santaState.yBase + Math.sin(santaState.progress * Math.PI * 2) * 2.2;
          santa.rig.position.set(sx, sy, santaState.zBase);
          for (var sr = 0; sr < santa.reindeer.length; sr++) {
            var gallop = Math.sin(t * 9.0 + sr);
            santa.reindeer[sr].legs[0].rotation.x = gallop * 0.5;
            santa.reindeer[sr].legs[2].rotation.x = -gallop * 0.5;
          }
          if (santaState.progress >= 1.0) {
            santaState.active = false;
            santaState.timer = 32 + Math.random() * 26;
            santa.rig.visible = false;
          }
        }

        // Occasional Shooting Star at Night
        if (inst.currentDayFactor < 0.35) {
          var shootCycle = t % 13.0;
          if (shootCycle < 1.1) {
            var sp = shootCycle / 1.1;
            shootingStar.material.opacity = Math.sin(sp * Math.PI) * 0.9;
            shootingStar.position.set(lerp(-35, 25, sp), lerp(44, 24, sp), -72);
          } else {
            shootingStar.material.opacity = 0;
          }
        } else {
          shootingStar.material.opacity = 0;
        }

        // Snowfall
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
