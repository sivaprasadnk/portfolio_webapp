import { useEffect, useMemo, useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';
import { soundEngine } from '../audio/soundEngine';
import {
  DESTINATIONS,
  type DestinationConfig,
  type DestinationId,
} from '../data/portfolioData';
import {
  liveTelemetryRef,
  type GamePhase,
  type TimeOfDay,
} from '../state/gameStore';
import { createRadialGlowTexture, getCarbonTextures } from '../utils/textures';
import {
  createInitialCarState,
  findNearestCheckpoint,
  getNextMissionDestination,
  stepCarPhysics,
  type ControlInput,
} from '../world/physics';
import { CITY_BUILDINGS } from '../world/trackData';

interface PlayerCarProps {
  inputRef: React.MutableRefObject<ControlInput>;
  phase: GamePhase;
  isPaused: boolean;
  isModalOpen: boolean;
  visitedIds: DestinationId[];
  timeOfDay: TimeOfDay;
  resetCounter: number;
  onCheckpointChange: (dest: DestinationConfig | null, distance: number) => void;
  onTeleportHandled: () => void;
}

const MAX_SMOKE = 34;
const MAX_SPARKS = 24;

interface SmokeParticle {
  active: boolean;
  x: number;
  y: number;
  z: number;
  vx: number;
  vy: number;
  vz: number;
  age: number;
  maxAge: number;
  scale: number;
}

interface SparkParticle {
  active: boolean;
  x: number;
  y: number;
  z: number;
  vx: number;
  vy: number;
  vz: number;
  age: number;
  maxAge: number;
}

export function PlayerCar({
  inputRef,
  phase,
  isPaused,
  isModalOpen,
  visitedIds,
  timeOfDay,
  resetCounter,
  onCheckpointChange,
  onTeleportHandled,
}: PlayerCarProps) {
  const carRootRef = useRef<THREE.Group>(null);
  const chassisRef = useRef<THREE.Group>(null);
  const wheelFLSteerRef = useRef<THREE.Group>(null);
  const wheelFRSteerRef = useRef<THREE.Group>(null);
  const wheelSpinRefs = useRef<Array<THREE.Group | null>>([null, null, null, null]);
  const brakeBarMatRef = useRef<THREE.MeshStandardMaterial>(null);
  const reverseMatRef = useRef<THREE.MeshStandardMaterial>(null);
  const underglowMatRef = useRef<THREE.MeshBasicMaterial>(null);
  const underglowLightRef = useRef<THREE.PointLight>(null);
  const headSpotRef = useRef<THREE.SpotLight>(null);
  const headTargetRef = useRef<THREE.Object3D>(new THREE.Object3D());
  const flameLRef = useRef<THREE.Mesh>(null);
  const flameRRef = useRef<THREE.Mesh>(null);

  const smokeMeshRef = useRef<THREE.InstancedMesh>(null);
  const sparkMeshRef = useRef<THREE.InstancedMesh>(null);

  const lastCheckpointIdRef = useRef<DestinationId | null>(null);
  const visitedSetRef = useRef<Set<DestinationId>>(new Set(visitedIds));
  visitedSetRef.current = new Set(visitedIds);

  useEffect(() => {
    liveTelemetryRef.car = createInitialCarState(0, 16, 0);
  }, [resetCounter]);

  const smokePool = useMemo<SmokeParticle[]>(
    () =>
      Array.from({ length: MAX_SMOKE }, () => ({
        active: false,
        x: 0,
        y: -10,
        z: 0,
        vx: 0,
        vy: 0,
        vz: 0,
        age: 0,
        maxAge: 0.9,
        scale: 0.4,
      })),
    []
  );
  const sparkPool = useMemo<SparkParticle[]>(
    () =>
      Array.from({ length: MAX_SPARKS }, () => ({
        active: false,
        x: 0,
        y: -10,
        z: 0,
        vx: 0,
        vy: 0,
        vz: 0,
        age: 0,
        maxAge: 0.45,
      })),
    []
  );
  const smokeCursor = useRef(0);
  const sparkCursor = useRef(0);
  const smokeTimer = useRef(0);
  const sparkTimer = useRef(0);
  const dummy = useMemo(() => new THREE.Object3D(), []);

  // Sculpted Exotic Supercar Body ExtrudeGeometry
  const { bodyGeo, canopyGeo } = useMemo(() => {
    const profile = new THREE.Shape();
    profile.moveTo(-2.26, 0.24);
    profile.lineTo(-2.32, 0.41);
    profile.lineTo(-1.58, 0.68);
    profile.lineTo(-0.78, 0.77);
    profile.lineTo(-0.22, 1.15);
    profile.lineTo(0.66, 1.13);
    profile.lineTo(1.75, 0.86);
    profile.lineTo(2.22, 0.80);
    profile.lineTo(2.26, 0.34);
    profile.lineTo(1.88, 0.23);
    profile.closePath();

    const body = new THREE.ExtrudeGeometry(profile, {
      depth: 1.66,
      bevelEnabled: true,
      bevelThickness: 0.14,
      bevelSize: 0.08,
      bevelSegments: 3,
      curveSegments: 8,
    });
    body.translate(0, 0, -0.83);
    body.rotateY(-Math.PI * 0.5);
    body.computeVertexNormals();

    // Sleek teardrop cabin greenhouse glass
    const glassShape = new THREE.Shape();
    glassShape.moveTo(-0.74, 0.75);
    glassShape.lineTo(-0.20, 1.17);
    glassShape.lineTo(0.62, 1.15);
    glassShape.lineTo(1.18, 0.85);
    glassShape.lineTo(-0.74, 0.75);
    glassShape.closePath();

    const canopy = new THREE.ExtrudeGeometry(glassShape, {
      depth: 1.32,
      bevelEnabled: true,
      bevelThickness: 0.08,
      bevelSize: 0.04,
      bevelSegments: 2,
    });
    canopy.translate(0, 0, -0.66);
    canopy.rotateY(-Math.PI * 0.5);
    canopy.computeVertexNormals();

    return { bodyGeo: body, canopyGeo: canopy };
  }, []);

  const carbonTextures = useMemo(() => getCarbonTextures(), []);
  const glowTexture = useMemo(() => createRadialGlowTexture(), []);

  useFrame((_, rawDt) => {
    const dt = Math.min(rawDt, 0.05);

    // Handle instant fast-travel / teleport request
    if (liveTelemetryRef.teleportTarget) {
      const t = liveTelemetryRef.teleportTarget;
      liveTelemetryRef.car = createInitialCarState(t.x, t.z, t.heading);
      liveTelemetryRef.teleportTarget = null;
      onTeleportHandled();
    }

    // Step physics during active unlocked driving
    if (phase === 'playing' && !isPaused && !isModalOpen) {
      const prevImpact = liveTelemetryRef.car.impactIntensity;
      const next = stepCarPhysics(
        liveTelemetryRef.car,
        inputRef.current,
        dt,
        CITY_BUILDINGS
      );
      liveTelemetryRef.car = next;
      if (next.impactIntensity > prevImpact + 0.18) {
        soundEngine.playCollisionThud(next.impactIntensity);
      }
    } else if (phase === 'playing') {
      // Bleed off speed gently if modal/pause is open
      liveTelemetryRef.car = {
        ...liveTelemetryRef.car,
        speedKmh: 0,
        vx: 0,
        vz: 0,
        forwardSpeed: 0,
        rpm: 950,
        isBoosting: false,
      };
    }

    const car = liveTelemetryRef.car;

    // Proximity & Mission calculations
    const prox = findNearestCheckpoint(car.x, car.z);
    liveTelemetryRef.proximity = prox;
    liveTelemetryRef.mission = getNextMissionDestination(
      visitedSetRef.current,
      car.x,
      car.z,
      car.heading
    );

    const activeId = prox.isInside && prox.destination ? prox.destination.id : null;
    if (activeId !== lastCheckpointIdRef.current) {
      lastCheckpointIdRef.current = activeId;
      onCheckpointChange(activeId ? prox.destination : null, Math.round(prox.distance));
      if (activeId === 'contact') {
        liveTelemetryRef.finishBurstAt = performance.now() / 1000;
        soundEngine.playFinishFanfare();
      } else if (activeId) {
        soundEngine.playCheckpointChime();
      }
    }

    // Update audio engine
    soundEngine.updateTelemetry(
      car.rpm,
      car.speedKmh,
      car.isBoosting,
      car.isDrifting,
      phase === 'playing' && !isPaused && !isModalOpen
    );

    // Apply transform to 3D car root & suspension chassis
    if (carRootRef.current) {
      carRootRef.current.position.set(car.x, 0, car.z);
      carRootRef.current.rotation.y = car.heading;
    }

    if (chassisRef.current) {
      chassisRef.current.position.y = car.suspensionBounce;
      chassisRef.current.rotation.x = car.pitch;
      chassisRef.current.rotation.z = car.roll;
    }

    // Steering & spinning all 4 wheels
    if (wheelFLSteerRef.current) {
      wheelFLSteerRef.current.rotation.y = car.steerAngle;
    }
    if (wheelFRSteerRef.current) {
      wheelFRSteerRef.current.rotation.y = car.steerAngle;
    }
    for (let i = 0; i < 4; i++) {
      const wg = wheelSpinRefs.current[i];
      if (wg) wg.rotation.x = -car.wheelSpin;
    }

    // Headlight spotlight target in world ahead of car
    if (headSpotRef.current && carRootRef.current) {
      if (headTargetRef.current.parent !== carRootRef.current) {
        headTargetRef.current.position.set(0, 0.1, -22);
        carRootRef.current.add(headTargetRef.current);
        headSpotRef.current.target = headTargetRef.current;
      }
      headSpotRef.current.intensity = timeOfDay === 'day' ? 18 : 65;
    }

    // Dynamic brake, reverse & underglow lights
    if (brakeBarMatRef.current) {
      brakeBarMatRef.current.emissiveIntensity = car.isBraking ? 6.8 : 2.1;
    }
    if (reverseMatRef.current) {
      reverseMatRef.current.emissiveIntensity = car.isReversing ? 4.8 : 0.08;
    }
    if (underglowMatRef.current && underglowLightRef.current) {
      const glowColor = car.isBoosting ? '#c084fc' : '#38bdf8';
      underglowMatRef.current.color.set(glowColor);
      underglowLightRef.current.color.set(glowColor);
      underglowLightRef.current.intensity = car.isBoosting ? 7.5 : 3.2;
    }

    // Nitro flame cones
    const flameScale = car.isBoosting
      ? 0.9 + Math.sin(performance.now() * 0.045) * 0.28
      : 0.001;
    if (flameLRef.current && flameRRef.current) {
      flameLRef.current.scale.set(
        car.isBoosting ? 1 : 0.01,
        car.isBoosting ? 1 : 0.01,
        flameScale
      );
      flameRRef.current.scale.set(
        car.isBoosting ? 1 : 0.01,
        car.isBoosting ? 1 : 0.01,
        flameScale
      );
    }

    // Drift tire smoke & nitro/impact spark particle simulation
    const fx = -Math.sin(car.heading);
    const fz = -Math.cos(car.heading);
    const rx = Math.cos(car.heading);
    const rz = -Math.sin(car.heading);

    smokeTimer.current += dt;
    if (car.isDrifting && phase === 'playing' && smokeTimer.current > 0.032) {
      smokeTimer.current = 0;
      for (const side of [-0.94, 0.94]) {
        const p = smokePool[smokeCursor.current % MAX_SMOKE];
        smokeCursor.current++;
        p.active = true;
        p.age = 0;
        p.maxAge = 0.75 + Math.random() * 0.35;
        p.x = car.x - fx * 1.45 + rx * side + (Math.random() - 0.5) * 0.2;
        p.y = 0.28;
        p.z = car.z - fz * 1.45 + rz * side + (Math.random() - 0.5) * 0.2;
        p.vx = (Math.random() - 0.5) * 1.6;
        p.vy = 1.2 + Math.random() * 0.9;
        p.vz = (Math.random() - 0.5) * 1.6;
        p.scale = 0.55 + Math.random() * 0.35;
      }
    }

    if (smokeMeshRef.current) {
      for (let i = 0; i < MAX_SMOKE; i++) {
        const p = smokePool[i];
        if (!p.active) {
          dummy.position.set(0, -50, 0);
          dummy.scale.setScalar(0.001);
          dummy.updateMatrix();
          smokeMeshRef.current.setMatrixAt(i, dummy.matrix);
          continue;
        }
        p.age += dt;
        if (p.age >= p.maxAge) {
          p.active = false;
          dummy.position.set(0, -50, 0);
          dummy.scale.setScalar(0.001);
          dummy.updateMatrix();
          smokeMeshRef.current.setMatrixAt(i, dummy.matrix);
          continue;
        }
        const t = p.age / p.maxAge;
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.z += p.vz * dt;
        const s = p.scale * (1 + t * 2.4) * (1 - t * 0.35);
        dummy.position.set(p.x, p.y, p.z);
        dummy.scale.set(s, s, s);
        dummy.updateMatrix();
        smokeMeshRef.current.setMatrixAt(i, dummy.matrix);
      }
      smokeMeshRef.current.instanceMatrix.needsUpdate = true;
    }

    sparkTimer.current += dt;
    if (
      (car.isBoosting || car.impactIntensity > 0.3) &&
      phase === 'playing' &&
      sparkTimer.current > 0.025
    ) {
      sparkTimer.current = 0;
      const p = sparkPool[sparkCursor.current % MAX_SPARKS];
      sparkCursor.current++;
      p.active = true;
      p.age = 0;
      p.maxAge = 0.28 + Math.random() * 0.2;
      const side = Math.random() > 0.5 ? 0.45 : -0.45;
      p.x = car.x - fx * 2.15 + rx * side;
      p.y = 0.45 + Math.random() * 0.2;
      p.z = car.z - fz * 2.15 + rz * side;
      p.vx = -fx * (12 + Math.random() * 8) + (Math.random() - 0.5) * 4;
      p.vy = 1.5 + Math.random() * 3.0;
      p.vz = -fz * (12 + Math.random() * 8) + (Math.random() - 0.5) * 4;
    }

    if (sparkMeshRef.current) {
      for (let i = 0; i < MAX_SPARKS; i++) {
        const p = sparkPool[i];
        if (!p.active) {
          dummy.position.set(0, -50, 0);
          dummy.scale.setScalar(0.001);
          dummy.updateMatrix();
          sparkMeshRef.current.setMatrixAt(i, dummy.matrix);
          continue;
        }
        p.age += dt;
        if (p.age >= p.maxAge) {
          p.active = false;
          dummy.position.set(0, -50, 0);
          dummy.scale.setScalar(0.001);
          dummy.updateMatrix();
          sparkMeshRef.current.setMatrixAt(i, dummy.matrix);
          continue;
        }
        p.x += p.vx * dt;
        p.y = Math.max(0.08, p.y + p.vy * dt);
        p.vy -= 9.5 * dt;
        p.z += p.vz * dt;
        const shrink = 1 - p.age / p.maxAge;
        dummy.position.set(p.x, p.y, p.z);
        dummy.scale.setScalar(0.22 * shrink);
        dummy.updateMatrix();
        sparkMeshRef.current.setMatrixAt(i, dummy.matrix);
      }
      sparkMeshRef.current.instanceMatrix.needsUpdate = true;
    }
  });

  const renderWheelAssembly = (spinIndex: number, isFront: boolean) => (
    <group
      ref={(el) => {
        wheelSpinRefs.current[spinIndex] = el;
      }}
    >
      {/* Tire Tread */}
      <mesh rotation={[0, 0, Math.PI / 2]} castShadow>
        <cylinderGeometry args={[0.36, 0.36, isFront ? 0.28 : 0.33, 24]} />
        <meshStandardMaterial color="#0b0e16" roughness={0.85} metalness={0.08} />
      </mesh>
      {/* Sidewall / Alloy Outer Lip */}
      <mesh rotation={[0, 0, Math.PI / 2]}>
        <cylinderGeometry args={[0.25, 0.25, isFront ? 0.29 : 0.34, 20]} />
        <meshStandardMaterial color="#94a3b8" roughness={0.18} metalness={0.94} />
      </mesh>
      {/* 5-Spoke Performance Wheel Star */}
      {[0, 1, 2, 3, 4].map((sp) => (
        <mesh
          key={sp}
          rotation={[(sp * Math.PI) / 2.5, 0, 0]}
          position={[0, 0, 0]}
        >
          <boxGeometry args={[isFront ? 0.3 : 0.35, 0.44, 0.045]} />
          <meshStandardMaterial color="#1e293b" roughness={0.22} metalness={0.92} />
        </mesh>
      ))}
      {/* Glowing Neon Caliper Accent */}
      <mesh position={[0, 0.08, 0.11]}>
        <boxGeometry args={[0.14, 0.14, 0.08]} />
        <meshStandardMaterial
          color="#38bdf8"
          emissive="#38bdf8"
          emissiveIntensity={2.0}
          roughness={0.3}
        />
      </mesh>
    </group>
  );

  return (
    <>
      <group ref={carRootRef} position={[0, 0, 16]}>
        {/* Sculpted Suspension Chassis Group */}
        <group ref={chassisRef}>
          {/* Main Clearcoat Metallic Supercar Body */}
          <mesh geometry={bodyGeo} castShadow receiveShadow>
            <meshPhysicalMaterial
              color="#0b1530"
              metalness={0.88}
              roughness={0.14}
              clearcoat={1}
              clearcoatRoughness={0.05}
              envMapIntensity={1.6}
            />
          </mesh>

          {/* Tinted Teardrop Canopy Glass */}
          <mesh geometry={canopyGeo} castShadow>
            <meshPhysicalMaterial
              color="#020617"
              metalness={0.15}
              roughness={0.05}
              clearcoat={1}
              clearcoatRoughness={0.04}
              envMapIntensity={1.9}
              transparent
              opacity={0.92}
            />
          </mesh>

          {/* Widebody Wheel Arch Fenders (FL, FR, RL, RR) */}
          {[
            [-0.9, 0.38, -1.42],
            [0.9, 0.38, -1.42],
            [-0.92, 0.4, 1.4],
            [0.92, 0.4, 1.4],
          ].map(([fx, fy, fz], idx) => (
            <mesh
              key={idx}
              position={[fx, fy, fz]}
              rotation={[0, 0, Math.PI / 2]}
              castShadow
            >
              <cylinderGeometry args={[0.43, 0.43, 0.24, 16, 1, false, 0, Math.PI]} />
              <meshPhysicalMaterial
                color="#0f1b3d"
                metalness={0.88}
                roughness={0.16}
                clearcoat={1}
                clearcoatRoughness={0.05}
              />
            </mesh>
          ))}

          {/* Carbon Front Splitter & Aero Lip */}
          <mesh position={[0, 0.19, -2.28]} castShadow>
            <boxGeometry args={[1.98, 0.06, 0.42]} />
            <meshStandardMaterial
              map={carbonTextures.map}
              roughnessMap={carbonTextures.roughnessMap}
              metalness={0.5}
              roughness={0.38}
            />
          </mesh>

          {/* Carbon Side Skirts with Neon Pinstripes */}
          {[-0.96, 0.96].map((sx, idx) => (
            <group key={idx} position={[sx, 0.21, 0]}>
              <mesh castShadow>
                <boxGeometry args={[0.14, 0.07, 2.25]} />
                <meshStandardMaterial
                  map={carbonTextures.map}
                  roughnessMap={carbonTextures.roughnessMap}
                  metalness={0.5}
                />
              </mesh>
              <mesh position={[sx > 0 ? 0.075 : -0.075, 0, 0]}>
                <boxGeometry args={[0.02, 0.03, 2.15]} />
                <meshStandardMaterial
                  color="#38bdf8"
                  emissive="#38bdf8"
                  emissiveIntensity={2.8}
                />
              </mesh>
            </group>
          ))}

          {/* Center Racing Neon Stripe */}
          <mesh position={[0, 0.72, -1.45]} rotation={[-0.14, 0, 0]}>
            <boxGeometry args={[0.24, 0.015, 1.32]} />
            <meshStandardMaterial
              color="#a855f7"
              emissive="#a855f7"
              emissiveIntensity={1.9}
            />
          </mesh>

          {/* Aerodynamic Side Mirrors */}
          {[-1.04, 1.04].map((mx, idx) => (
            <mesh key={idx} position={[mx, 0.85, -0.52]} castShadow>
              <boxGeometry args={[0.22, 0.07, 0.14]} />
              <meshPhysicalMaterial
                color="#0f1b3d"
                metalness={0.9}
                roughness={0.15}
                clearcoat={1}
              />
            </mesh>
          ))}

          {/* Swan-Neck Carbon GT Rear Spoiler */}
          <group position={[0, 1.05, 2.08]}>
            <mesh castShadow>
              <boxGeometry args={[1.92, 0.045, 0.34]} />
              <meshStandardMaterial
                map={carbonTextures.map}
                roughnessMap={carbonTextures.roughnessMap}
                metalness={0.65}
                roughness={0.28}
              />
            </mesh>
            {/* Wing uprights & neon endplates */}
            {[-0.55, 0.55].map((ux, idx) => (
              <mesh key={idx} position={[ux, -0.18, 0.04]}>
                <boxGeometry args={[0.05, 0.32, 0.18]} />
                <meshStandardMaterial color="#1e293b" metalness={0.9} roughness={0.25} />
              </mesh>
            ))}
            {[-0.97, 0.97].map((ex, idx) => (
              <mesh key={idx} position={[ex, 0, 0]}>
                <boxGeometry args={[0.03, 0.18, 0.42]} />
                <meshStandardMaterial
                  color="#a855f7"
                  emissive="#a855f7"
                  emissiveIntensity={1.6}
                />
              </mesh>
            ))}
          </group>

          {/* Rear Engine Bay Glowing Accent */}
          <mesh position={[0, 0.92, 1.48]}>
            <boxGeometry args={[0.72, 0.04, 0.65]} />
            <meshStandardMaterial
              color="#0ea5e9"
              emissive="#38bdf8"
              emissiveIntensity={1.5}
              metalness={0.8}
              roughness={0.2}
            />
          </mesh>

          {/* Dual Matrix Headlights + Volumetric Cones */}
          {[-0.66, 0.66].map((hx, idx) => (
            <group key={idx} position={[hx, 0.48, -2.26]}>
              <mesh>
                <boxGeometry args={[0.32, 0.08, 0.07]} />
                <meshStandardMaterial
                  color="#e0f2fe"
                  emissive="#7dd3fc"
                  emissiveIntensity={5.0}
                />
              </mesh>
              <mesh
                position={[0, -0.1, -3.2]}
                rotation={[Math.PI * 0.52, 0, 0]}
              >
                <coneGeometry args={[1.1, 6.2, 16, 1, true]} />
                <meshBasicMaterial
                  color="#bae6fd"
                  transparent
                  opacity={timeOfDay === 'day' ? 0.03 : 0.13}
                  blending={THREE.AdditiveBlending}
                  depthWrite={false}
                  side={THREE.DoubleSide}
                />
              </mesh>
            </group>
          ))}

          {/* Full-Width LED Taillight Bar + Reverse Lamps */}
          <mesh position={[0, 0.62, 2.27]}>
            <boxGeometry args={[1.72, 0.075, 0.06]} />
            <meshStandardMaterial
              ref={brakeBarMatRef}
              color="#fb7185"
              emissive="#f43f5e"
              emissiveIntensity={2.1}
            />
          </mesh>
          {[-0.62, 0.62].map((rxPos, idx) => (
            <mesh key={idx} position={[rxPos, 0.51, 2.27]}>
              <boxGeometry args={[0.24, 0.05, 0.05]} />
              <meshStandardMaterial
                ref={idx === 0 ? reverseMatRef : undefined}
                color="#ffffff"
                emissive="#e0f2fe"
                emissiveIntensity={0.08}
              />
            </mesh>
          ))}

          {/* Rear Diffuser & Quad Titanium Exhausts + Nitro Flame Cones */}
          <mesh position={[0, 0.24, 2.24]}>
            <boxGeometry args={[1.45, 0.16, 0.22]} />
            <meshStandardMaterial color="#090c14" metalness={0.75} roughness={0.4} />
          </mesh>
          {[-0.45, 0.45].map((ex, idx) => (
            <group key={idx} position={[ex, 0.26, 2.3]}>
              <mesh rotation={[Math.PI / 2, 0, 0]}>
                <cylinderGeometry args={[0.075, 0.075, 0.16, 12]} />
                <meshStandardMaterial color="#94a3b8" metalness={0.95} roughness={0.18} />
              </mesh>
              <mesh
                ref={idx === 0 ? flameLRef : flameRRef}
                position={[0, 0, 0.58]}
                rotation={[Math.PI / 2, 0, 0]}
              >
                <coneGeometry args={[0.14, 1.15, 12]} />
                <meshBasicMaterial
                  color="#38bdf8"
                  transparent
                  opacity={0.88}
                  blending={THREE.AdditiveBlending}
                  depthWrite={false}
                />
              </mesh>
            </group>
          ))}

          {/* Chassis Neon Underglow Strip */}
          <mesh position={[0, 0.06, 0]} rotation={[-Math.PI / 2, 0, 0]}>
            <planeGeometry args={[1.95, 4.15]} />
            <meshBasicMaterial
              ref={underglowMatRef}
              map={glowTexture}
              color="#38bdf8"
              transparent
              opacity={0.55}
              blending={THREE.AdditiveBlending}
              depthWrite={false}
            />
          </mesh>
        </group>

        {/* Live Dynamic Underglow & Forward Headlight */}
        <pointLight
          ref={underglowLightRef}
          position={[0, 0.28, 0]}
          color="#38bdf8"
          intensity={3.2}
          distance={9}
        />
        <spotLight
          ref={headSpotRef}
          position={[0, 0.72, -2.05]}
          color="#bae6fd"
          intensity={65}
          distance={58}
          angle={0.58}
          penumbra={0.65}
          decay={1.4}
        />

        {/* 4 Independent Detailed Wheels */}
        <group position={[-0.93, 0.36, -1.42]} ref={wheelFLSteerRef}>
          {renderWheelAssembly(0, true)}
        </group>
        <group position={[0.93, 0.36, -1.42]} ref={wheelFRSteerRef}>
          {renderWheelAssembly(1, true)}
        </group>
        <group position={[-0.95, 0.36, 1.4]}>
          {renderWheelAssembly(2, false)}
        </group>
        <group position={[0.95, 0.36, 1.4]}>
          {renderWheelAssembly(3, false)}
        </group>
      </group>

      {/* Instanced Drift Smoke Pool */}
      <instancedMesh
        ref={smokeMeshRef}
        args={[undefined, undefined, MAX_SMOKE]}
        frustumCulled={false}
      >
        <sphereGeometry args={[0.5, 8, 8]} />
        <meshBasicMaterial
          color="#94a3b8"
          transparent
          opacity={0.32}
          depthWrite={false}
        />
      </instancedMesh>

      {/* Instanced Nitro & Impact Sparks Pool */}
      <instancedMesh
        ref={sparkMeshRef}
        args={[undefined, undefined, MAX_SPARKS]}
        frustumCulled={false}
      >
        <octahedronGeometry args={[0.25, 0]} />
        <meshBasicMaterial
          color="#7dd3fc"
          transparent
          opacity={0.95}
          blending={THREE.AdditiveBlending}
          depthWrite={false}
        />
      </instancedMesh>
    </>
  );
}
