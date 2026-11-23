import { useMemo, useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';
import { DESTINATIONS, type DestinationId } from '../../data/portfolioData';
import { liveTelemetryRef } from '../../state/gameStore';
import {
  createCheckeredFinishTexture,
  createNeonSignTexture,
} from '../../utils/textures';

interface ZoneProps {
  onSelectZone: (id: DestinationId) => void;
  visitedIds: DestinationId[];
}

const BURST_COUNT = 36;

export default function ContactFinishZone({ onSelectZone }: ZoneProps) {
  const dest = DESTINATIONS.find((d) => d.id === 'contact')!;
  const beamLRef = useRef<THREE.Mesh>(null);
  const beamRRef = useRef<THREE.Mesh>(null);
  const burstRef = useRef<THREE.InstancedMesh>(null);

  const signTex = useMemo(
    () =>
      createNeonSignTexture(
        'CONTACT ME',
        "FINISH LINE // LET'S BUILD SOMETHING AMAZING TOGETHER!",
        dest.primaryColor,
        dest.secondaryColor
      ),
    [dest.primaryColor, dest.secondaryColor]
  );

  const checkeredTex = useMemo(() => createCheckeredFinishTexture(), []);

  const burstData = useMemo(
    () =>
      Array.from({ length: BURST_COUNT }, (_, i) => {
        const a = (i / BURST_COUNT) * Math.PI * 2;
        const speed = 7 + (i % 5) * 2.5;
        return {
          vx: Math.cos(a) * speed,
          vy: 10 + (i % 4) * 3.5,
          vz: Math.sin(a) * speed,
        };
      }),
    []
  );
  const dummy = useMemo(() => new THREE.Object3D(), []);

  useFrame(({ clock }) => {
    const t = clock.getElapsedTime();
    if (beamLRef.current) {
      beamLRef.current.rotation.z = Math.sin(t * 1.4) * 0.25;
    }
    if (beamRRef.current) {
      beamRRef.current.rotation.z = -Math.sin(t * 1.4) * 0.25;
    }

    if (burstRef.current) {
      const elapsedSinceBurst = performance.now() / 1000 - liveTelemetryRef.finishBurstAt;
      const showBurst =
        liveTelemetryRef.finishBurstAt > 0 && elapsedSinceBurst < 3.6;

      for (let i = 0; i < BURST_COUNT; i++) {
        if (!showBurst) {
          dummy.position.set(0, -60, 0);
          dummy.scale.setScalar(0.001);
        } else {
          const b = burstData[i];
          const age = elapsedSinceBurst;
          dummy.position.set(
            b.vx * age,
            1.5 + b.vy * age - 4.8 * age * age,
            -8 + b.vz * age
          );
          const s = Math.max(0.01, (1 - age / 3.6) * 0.42);
          dummy.rotation.set(age * 4, age * 3, 0);
          dummy.scale.setScalar(s);
        }
        dummy.updateMatrix();
        burstRef.current.setMatrixAt(i, dummy.matrix);
      }
      burstRef.current.instanceMatrix.needsUpdate = true;
    }
  });

  return (
    <group
      position={dest.position}
      onClick={(e) => {
        e.stopPropagation();
        onSelectZone('contact');
      }}
    >
      {/* Checkered Asphalt Finish Stripe */}
      <mesh position={[0, 0.06, -4]} rotation={[-Math.PI / 2, 0, 0]}>
        <planeGeometry args={[18, 4.2]} />
        <meshBasicMaterial map={checkeredTex} />
      </mesh>

      {/* Grand Neon Finish Arch Pillars */}
      {[-11.5, 11.5].map((px, i) => (
        <group key={i} position={[px, 0, -8]}>
          <mesh position={[0, 6.2, 0]} castShadow>
            <boxGeometry args={[1.6, 12.4, 1.6]} />
            <meshStandardMaterial
              color="#0b1024"
              emissive={dest.primaryColor}
              emissiveIntensity={0.65}
              metalness={0.88}
            />
          </mesh>
          {/* Sweeping Sky Laser Beams */}
          <mesh
            ref={i === 0 ? beamLRef : beamRRef}
            position={[0, 20, 0]}
          >
            <cylinderGeometry args={[0.16, 1.25, 32, 12, 1, true]} />
            <meshBasicMaterial
              color={i === 0 ? '#38bdf8' : '#c084fc'}
              transparent
              opacity={0.2}
              blending={THREE.AdditiveBlending}
              depthWrite={false}
              side={THREE.DoubleSide}
            />
          </mesh>
        </group>
      ))}

      {/* Overhead Checkered & Neon Finish Span */}
      <mesh position={[0, 11.2, -8]}>
        <boxGeometry args={[25, 4.4, 1.1]} />
        <meshStandardMaterial color="#070b1c" metalness={0.85} roughness={0.22} />
      </mesh>
      <mesh position={[0, 11.2, -7.42]}>
        <planeGeometry args={[23.8, 3.8]} />
        <meshBasicMaterial map={signTex} />
      </mesh>
      <mesh position={[0, 11.2, -8.58]} rotation={[0, Math.PI, 0]}>
        <planeGeometry args={[23.8, 3.8]} />
        <meshBasicMaterial map={signTex} />
      </mesh>

      {/* Finish Line Confetti/Spark Celebration Pool */}
      <instancedMesh
        ref={burstRef}
        args={[undefined, undefined, BURST_COUNT]}
        frustumCulled={false}
      >
        <octahedronGeometry args={[0.55, 0]} />
        <meshStandardMaterial
          color="#c084fc"
          emissive="#38bdf8"
          emissiveIntensity={2.8}
        />
      </instancedMesh>

      <pointLight
        position={[0, 7.5, -5]}
        color={dest.primaryColor}
        intensity={22}
        distance={42}
      />
    </group>
  );
}
