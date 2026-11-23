import { useEffect, useMemo, useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import { MeshReflectorMaterial } from '@react-three/drei';
import * as THREE from 'three';
import { DESTINATIONS } from '../data/portfolioData';
import { liveTelemetryRef } from '../state/gameStore';
import {
  createNeonSignTexture,
  getAsphaltTextures,
  getSkyscraperTextures,
} from '../utils/textures';
import {
  CITY_BUILDINGS,
  CITY_TREES,
  CROSS_AVENUES,
  ROAD_HALF_WIDTH,
  STREET_LIGHTS,
  TRACK_SAMPLES,
  WORLD_BOUND,
} from '../world/trackData';

interface CityWorldProps {
  isMobile: boolean;
}

function buildClosedTrackRibbonGeometry(): THREE.BufferGeometry {
  const n = TRACK_SAMPLES.length;
  const positions: number[] = [];
  const normals: number[] = [];
  const uvs: number[] = [];
  const indices: number[] = [];

  let accumDist = 0;

  for (let i = 0; i <= n; i++) {
    const s = TRACK_SAMPLES[i % n];
    const prev = TRACK_SAMPLES[(i - 1 + n) % n];
    if (i > 0) {
      accumDist += Math.hypot(s.x - prev.x, s.z - prev.z);
    }

    const lx = s.x - s.nx * ROAD_HALF_WIDTH;
    const lz = s.z - s.nz * ROAD_HALF_WIDTH;
    const rx = s.x + s.nx * ROAD_HALF_WIDTH;
    const rz = s.z + s.nz * ROAD_HALF_WIDTH;

    positions.push(lx, 0.03, lz, rx, 0.03, rz);
    normals.push(0, 1, 0, 0, 1, 0);
    const vCoord = accumDist * 0.055;
    uvs.push(0, vCoord, 1, vCoord);

    if (i < n) {
      const base = i * 2;
      indices.push(base, base + 1, base + 2, base + 1, base + 3, base + 2);
    }
  }

  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
  geo.setAttribute('normal', new THREE.Float32BufferAttribute(normals, 3));
  geo.setAttribute('uv', new THREE.Float32BufferAttribute(uvs, 2));
  geo.setIndex(indices);
  return geo;
}

export function CityWorld({ isMobile }: CityWorldProps) {
  const asphalt = useMemo(() => getAsphaltTextures(), []);
  const trackGeo = useMemo(() => buildClosedTrackRibbonGeometry(), []);

  const towerV0 = useMemo(() => getSkyscraperTextures(0), []);
  const towerV1 = useMemo(() => getSkyscraperTextures(1), []);
  const towerV2 = useMemo(() => getSkyscraperTextures(2), []);

  const startBannerTex = useMemo(
    () =>
      createNeonSignTexture(
        'SIVA PRASAD N K',
        'PORTFOLIO CIRCUIT // EXPLORE 5 CHECKPOINTS',
        '#38bdf8',
        '#a855f7'
      ),
    []
  );

  const groupedBuildings = useMemo(() => {
    const g0 = CITY_BUILDINGS.filter((b) => b.variant === 0);
    const g1 = CITY_BUILDINGS.filter((b) => b.variant === 1);
    const g2 = CITY_BUILDINGS.filter((b) => b.variant === 2);
    return [g0, g1, g2] as const;
  }, []);

  const bldgRefs = [
    useRef<THREE.InstancedMesh>(null),
    useRef<THREE.InstancedMesh>(null),
    useRef<THREE.InstancedMesh>(null),
  ];
  const beaconRef = useRef<THREE.InstancedMesh>(null);
  const poleRef = useRef<THREE.InstancedMesh>(null);
  const lampHeadRef = useRef<THREE.InstancedMesh>(null);
  const treeTrunkRef = useRef<THREE.InstancedMesh>(null);
  const treeCanopyRef = useRef<THREE.InstancedMesh>(null);
  const guideArrowRefs = useRef<Array<THREE.Group | null>>([]);
  const beaconBeamRef = useRef<THREE.Mesh>(null);

  useEffect(() => {
    const dummy = new THREE.Object3D();

    // Populate 3 skyscraper InstancedMeshes
    groupedBuildings.forEach((group, gIdx) => {
      const mesh = bldgRefs[gIdx].current;
      if (!mesh) return;
      group.forEach((b, idx) => {
        dummy.position.set(b.x, b.height * 0.5, b.z);
        dummy.rotation.set(0, 0, 0);
        dummy.scale.set(b.halfW * 2, b.height, b.halfD * 2);
        dummy.updateMatrix();
        mesh.setMatrixAt(idx, dummy.matrix);
      });
      mesh.instanceMatrix.needsUpdate = true;
    });

    // Rooftop neon beacons
    if (beaconRef.current) {
      let idx = 0;
      CITY_BUILDINGS.forEach((b) => {
        if (!b.rooftopBeacon) return;
        dummy.position.set(b.x, b.height + 1.1, b.z);
        dummy.rotation.set(0, 0, 0);
        dummy.scale.set(b.halfW * 1.4, 1.4, b.halfD * 1.4);
        dummy.updateMatrix();
        beaconRef.current!.setMatrixAt(idx++, dummy.matrix);
      });
      beaconRef.current.count = idx;
      beaconRef.current.instanceMatrix.needsUpdate = true;
    }

    // Streetlights
    if (poleRef.current && lampHeadRef.current) {
      STREET_LIGHTS.forEach((sl, idx) => {
        dummy.position.set(sl.x, 4.4, sl.z);
        dummy.rotation.set(0, sl.angle, 0);
        dummy.scale.set(1, 1, 1);
        dummy.updateMatrix();
        poleRef.current!.setMatrixAt(idx, dummy.matrix);

        dummy.position.set(
          sl.x + Math.sin(sl.angle) * 1.4,
          8.65,
          sl.z + Math.cos(sl.angle) * 1.4
        );
        dummy.rotation.set(0, sl.angle, 0);
        dummy.scale.set(1, 1, 1);
        dummy.updateMatrix();
        lampHeadRef.current!.setMatrixAt(idx, dummy.matrix);
      });
      poleRef.current.instanceMatrix.needsUpdate = true;
      lampHeadRef.current.instanceMatrix.needsUpdate = true;
    }

    // Urban stylized trees
    if (treeTrunkRef.current && treeCanopyRef.current) {
      CITY_TREES.forEach((tr, idx) => {
        dummy.position.set(tr.x, 1.8 * tr.scale, tr.z);
        dummy.rotation.set(0, 0, 0);
        dummy.scale.setScalar(tr.scale);
        dummy.updateMatrix();
        treeTrunkRef.current!.setMatrixAt(idx, dummy.matrix);

        dummy.position.set(tr.x, 4.5 * tr.scale, tr.z);
        dummy.scale.set(tr.scale, tr.scale * 1.25, tr.scale);
        dummy.updateMatrix();
        treeCanopyRef.current!.setMatrixAt(idx, dummy.matrix);
      });
      treeTrunkRef.current.instanceMatrix.needsUpdate = true;
      treeCanopyRef.current.instanceMatrix.needsUpdate = true;
    }
  }, [groupedBuildings]);

  // Distant Mountain Peaks silhouette around the outer valley
  const mountains = useMemo(() => {
    const items: Array<{ x: number; z: number; r: number; h: number; rot: number }> = [];
    for (let i = 0; i < 28; i++) {
      const a = (i / 28) * Math.PI * 2;
      const dist = 255 + (i % 3) * 28;
      items.push({
        x: Math.cos(a) * dist,
        z: Math.sin(a) * dist,
        r: 44 + (i % 4) * 14,
        h: 58 + (i % 5) * 18,
        rot: i * 0.7,
      });
    }
    return items;
  }, []);

  // Dynamically animate floating guidance chevrons & mission sky beam toward next checkpoint
  useFrame(({ clock }) => {
    const t = clock.getElapsedTime();
    const car = liveTelemetryRef.car;
    const mission = liveTelemetryRef.mission;
    const target = mission.destination;

    const dx = target.position[0] - car.x;
    const dz = target.position[2] - car.z;
    const totalDist = Math.hypot(dx, dz);
    const angle = Math.atan2(dx, dz);

    guideArrowRefs.current.forEach((grp, idx) => {
      if (!grp) return;
      const stepDist = 11 + idx * 10;
      if (totalDist < 20 || stepDist > totalDist - 8) {
        grp.visible = false;
        return;
      }
      grp.visible = true;
      const ratio = stepDist / totalDist;
      const pulse = Math.sin(t * 5 - idx * 0.85) * 0.5 + 0.5;
      grp.position.set(car.x + dx * ratio, 0.36 + pulse * 0.28, car.z + dz * ratio);
      grp.rotation.set(0, angle, 0);
      grp.scale.setScalar(0.85 + pulse * 0.25);
    });

    if (beaconBeamRef.current) {
      beaconBeamRef.current.position.set(
        target.position[0],
        45,
        target.position[2]
      );
      const beamMat = beaconBeamRef.current.material as THREE.MeshBasicMaterial;
      beamMat.color.set(target.primaryColor);
      beamMat.opacity = 0.14 + Math.sin(t * 3.5) * 0.05;
    }
  });

  const maxBeacons = useMemo(
    () => CITY_BUILDINGS.filter((b) => b.rooftopBeacon).length,
    []
  );

  return (
    <group>
      {/* Infinite Urban Floor Plane */}
      <mesh
        rotation={[-Math.PI / 2, 0, 0]}
        position={[0, 0, 0]}
        receiveShadow
      >
        <planeGeometry args={[900, 900]} />
        <meshStandardMaterial
          color="#060914"
          roughness={0.58}
          metalness={0.25}
        />
      </mesh>

      {/* Wet Mirror-Reflective Neon Plaza at Downtown Start & About Boulevard */}
      <mesh
        rotation={[-Math.PI / 2, 0, 0]}
        position={[0, 0.014, -22]}
        receiveShadow
      >
        <planeGeometry args={[62, 118]} />
        {isMobile ? (
          <meshPhysicalMaterial
            color="#091024"
            roughness={0.14}
            metalness={0.65}
            clearcoat={0.9}
            clearcoatRoughness={0.12}
          />
        ) : (
          <MeshReflectorMaterial
            blur={[260, 80]}
            resolution={512}
            mixBlur={1}
            mixStrength={22}
            roughness={0.28}
            depthScale={0.9}
            minDepthThreshold={0.4}
            maxDepthThreshold={1.3}
            color="#070b18"
            metalness={0.65}
            mirror={0.45}
          />
        )}
      </mesh>

      {/* Closed Grand Prix Asphalt Circuit Ribbon */}
      <mesh geometry={trackGeo} receiveShadow>
        <meshStandardMaterial
          map={asphalt.map}
          roughnessMap={asphalt.roughnessMap}
          bumpMap={asphalt.bumpMap}
          bumpScale={0.04}
          metalness={0.28}
          roughness={0.48}
          envMapIntensity={1.25}
        />
      </mesh>

      {/* Downtown Cross-Town Boulevards */}
      {CROSS_AVENUES.map((ave, idx) => {
        const dx = ave.x2 - ave.x1;
        const dz = ave.z2 - ave.z1;
        const len = Math.hypot(dx, dz);
        const cx = (ave.x1 + ave.x2) * 0.5;
        const cz = (ave.z1 + ave.z2) * 0.5;
        const rotY = Math.atan2(dx, dz);
        return (
          <mesh
            key={idx}
            position={[cx, 0.024, cz]}
            rotation={[-Math.PI / 2, 0, rotY]}
            receiveShadow
          >
            <planeGeometry args={[ave.width, len]} />
            <meshStandardMaterial
              map={asphalt.map}
              roughnessMap={asphalt.roughnessMap}
              bumpMap={asphalt.bumpMap}
              bumpScale={0.035}
              metalness={0.32}
              roughness={0.42}
              envMapIntensity={1.35}
            />
          </mesh>
        );
      })}

      {/* Start Boulevard Neon Gantry Arch */}
      <group position={[0, 0, -4]}>
        {[-9.5, 9.5].map((px, i) => (
          <mesh key={i} position={[px, 4.5, 0]} castShadow>
            <boxGeometry args={[0.9, 9, 0.9]} />
            <meshStandardMaterial color="#0f172a" metalness={0.85} roughness={0.25} />
          </mesh>
        ))}
        <mesh position={[0, 8.6, 0]}>
          <boxGeometry args={[20.2, 3.2, 0.75]} />
          <meshStandardMaterial color="#090d1f" metalness={0.85} roughness={0.25} />
        </mesh>
        <mesh position={[0, 8.6, 0.4]}>
          <planeGeometry args={[18.8, 2.7]} />
          <meshBasicMaterial map={startBannerTex} />
        </mesh>
        <mesh position={[0, 8.6, -0.4]} rotation={[0, Math.PI, 0]}>
          <planeGeometry args={[18.8, 2.7]} />
          <meshBasicMaterial map={startBannerTex} />
        </mesh>
      </group>

      {/* Instanced City Skyscrapers (3 Material Variants) */}
      {[towerV0, towerV1, towerV2].map((texSet, idx) => (
        <instancedMesh
          key={idx}
          ref={bldgRefs[idx]}
          args={[undefined, undefined, Math.max(1, groupedBuildings[idx].length)]}
          castShadow
          receiveShadow
        >
          <boxGeometry args={[1, 1, 1]} />
          <meshStandardMaterial
            map={texSet.map}
            emissiveMap={texSet.emissiveMap}
            emissive="#ffffff"
            emissiveIntensity={1.25}
            roughness={0.35}
            metalness={0.55}
          />
        </instancedMesh>
      ))}

      {/* Rooftop Glowing Neon Crowns */}
      <instancedMesh
        ref={beaconRef}
        args={[undefined, undefined, Math.max(1, maxBeacons)]}
      >
        <boxGeometry args={[1, 1, 1]} />
        <meshStandardMaterial
          color="#a855f7"
          emissive="#38bdf8"
          emissiveIntensity={2.0}
        />
      </instancedMesh>

      {/* Instanced Streetlights */}
      <instancedMesh
        ref={poleRef}
        args={[undefined, undefined, Math.max(1, STREET_LIGHTS.length)]}
        castShadow
      >
        <cylinderGeometry args={[0.1, 0.14, 8.8, 6]} />
        <meshStandardMaterial color="#1e293b" metalness={0.85} roughness={0.35} />
      </instancedMesh>
      <instancedMesh
        ref={lampHeadRef}
        args={[undefined, undefined, Math.max(1, STREET_LIGHTS.length)]}
      >
        <boxGeometry args={[0.45, 0.2, 2.1]} />
        <meshStandardMaterial
          color="#e0f2fe"
          emissive="#38bdf8"
          emissiveIntensity={3.4}
        />
      </instancedMesh>

      {/* Instanced Urban Trees */}
      <instancedMesh
        ref={treeTrunkRef}
        args={[undefined, undefined, Math.max(1, CITY_TREES.length)]}
        castShadow
      >
        <cylinderGeometry args={[0.18, 0.28, 3.6, 6]} />
        <meshStandardMaterial color="#1f172a" roughness={0.9} />
      </instancedMesh>
      <instancedMesh
        ref={treeCanopyRef}
        args={[undefined, undefined, Math.max(1, CITY_TREES.length)]}
        castShadow
      >
        <dodecahedronGeometry args={[1.65, 1]} />
        <meshStandardMaterial
          color="#0b2e3b"
          emissive="#0c4a6e"
          emissiveIntensity={0.22}
          roughness={0.75}
        />
      </instancedMesh>

      {/* Distant Mountain Horizon Ring */}
      <group>
        {mountains.map((m, i) => (
          <mesh
            key={i}
            position={[m.x, m.h * 0.45, m.z]}
            rotation={[0, m.rot, 0]}
          >
            <coneGeometry args={[m.r, m.h, 5]} />
            <meshStandardMaterial
              color="#070a1c"
              roughness={0.95}
              metalness={0.1}
            />
          </mesh>
        ))}
      </group>

      {/* Glowing Perimeter Energy Barrier Walls */}
      {[
        { pos: [0, 0.9, -WORLD_BOUND] as [number, number, number], size: [WORLD_BOUND * 2, 1.8, 0.5] as [number, number, number], col: '#38bdf8' },
        { pos: [0, 0.9, WORLD_BOUND] as [number, number, number], size: [WORLD_BOUND * 2, 1.8, 0.5] as [number, number, number], col: '#a855f7' },
        { pos: [-WORLD_BOUND, 0.9, 0] as [number, number, number], size: [0.5, 1.8, WORLD_BOUND * 2] as [number, number, number], col: '#38bdf8' },
        { pos: [WORLD_BOUND, 0.9, 0] as [number, number, number], size: [0.5, 1.8, WORLD_BOUND * 2] as [number, number, number], col: '#a855f7' },
      ].map((wall, idx) => (
        <mesh key={idx} position={wall.pos}>
          <boxGeometry args={wall.size} />
          <meshStandardMaterial
            color={wall.col}
            emissive={wall.col}
            emissiveIntensity={1.6}
            transparent
            opacity={0.75}
          />
        </mesh>
      ))}

      {/* Subtle Destination Pad Rings (Visual Anchor for All 5 Checkpoints) */}
      {DESTINATIONS.map((dest) => (
        <group key={dest.id} position={dest.position}>
          <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.05, 0]}>
            <ringGeometry args={[17.2, 18.4, 48]} />
            <meshBasicMaterial
              color={dest.primaryColor}
              transparent
              opacity={0.85}
            />
          </mesh>
          <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.04, 0]}>
            <circleGeometry args={[17.2, 48]} />
            <meshStandardMaterial
              color="#070d1f"
              roughness={0.18}
              metalness={0.7}
            />
          </mesh>
        </group>
      ))}

      {/* Animated Glowing Guide Chevrons Pointing Toward Active Mission */}
      {[0, 1, 2, 3, 4, 5].map((idx) => (
        <group
          key={idx}
          ref={(el) => {
            guideArrowRefs.current[idx] = el;
          }}
        >
          <mesh rotation={[Math.PI * 0.5, 0, 0]}>
            <coneGeometry args={[0.95, 1.8, 3]} />
            <meshStandardMaterial
              color="#38bdf8"
              emissive="#38bdf8"
              emissiveIntensity={2.6}
              transparent
              opacity={0.85}
            />
          </mesh>
        </group>
      ))}

      {/* Tall Sky Beacon on Next Unvisited Mission Target */}
      <mesh ref={beaconBeamRef} position={[0, 45, -84]}>
        <cylinderGeometry args={[0.7, 2.2, 90, 16, 1, true]} />
        <meshBasicMaterial
          color="#38bdf8"
          transparent
          opacity={0.16}
          blending={THREE.AdditiveBlending}
          depthWrite={false}
          side={THREE.DoubleSide}
        />
      </mesh>
    </group>
  );
}
