import { useMemo, useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';
import { DESTINATIONS, type DestinationId } from '../../data/portfolioData';
import { createNeonSignTexture } from '../../utils/textures';

interface ZoneProps {
  onSelectZone: (id: DestinationId) => void;
  visitedIds: DestinationId[];
}

export default function AboutCheckpointZone({ onSelectZone, visitedIds }: ZoneProps) {
  const dest = DESTINATIONS.find((d) => d.id === 'about')!;
  const isVisited = visitedIds.includes('about');
  const ring1Ref = useRef<THREE.Mesh>(null);
  const ring2Ref = useRef<THREE.Mesh>(null);
  const coreRef = useRef<THREE.Mesh>(null);

  const signTex = useMemo(
    () =>
      createNeonSignTexture(
        'ABOUT ME',
        'SIVA PRASAD N K // SENIOR FLUTTER DEVELOPER',
        dest.primaryColor,
        dest.secondaryColor
      ),
    [dest.primaryColor, dest.secondaryColor]
  );

  useFrame(({ clock }) => {
    const t = clock.getElapsedTime();
    if (ring1Ref.current) {
      ring1Ref.current.rotation.z = t * 0.7;
      ring1Ref.current.rotation.y = Math.sin(t * 0.4) * 0.35;
    }
    if (ring2Ref.current) {
      ring2Ref.current.rotation.x = t * 0.85;
      ring2Ref.current.rotation.z = -t * 0.5;
    }
    if (coreRef.current) {
      coreRef.current.position.y = 4.6 + Math.sin(t * 2.2) * 0.4;
      coreRef.current.rotation.y = t * 0.9;
    }
  });

  return (
    <group
      position={dest.position}
      onClick={(e) => {
        e.stopPropagation();
        onSelectZone('about');
      }}
    >
      {/* Illuminated Futuristic Gate Pillars */}
      {[-12, 12].map((px, idx) => (
        <mesh key={idx} position={[px, 5.5, -14]} castShadow>
          <boxGeometry args={[1.4, 11, 1.4]} />
          <meshStandardMaterial
            color="#0b132b"
            emissive={dest.secondaryColor}
            emissiveIntensity={0.45}
            metalness={0.85}
            roughness={0.22}
          />
        </mesh>
      ))}

      {/* Overhead Neon Signboard */}
      <mesh position={[0, 10.6, -14]}>
        <boxGeometry args={[25, 4.2, 0.9]} />
        <meshStandardMaterial color="#070b1a" metalness={0.8} roughness={0.25} />
      </mesh>
      <mesh position={[0, 10.6, -13.52]}>
        <planeGeometry args={[23.8, 3.6]} />
        <meshBasicMaterial map={signTex} />
      </mesh>
      <mesh position={[0, 10.6, -14.48]} rotation={[0, Math.PI, 0]}>
        <planeGeometry args={[23.8, 3.6]} />
        <meshBasicMaterial map={signTex} />
      </mesh>

      {/* Central Spinning Holographic Monument Rings */}
      <mesh ref={ring1Ref} position={[0, 5.0, -14]}>
        <torusGeometry args={[6.2, 0.14, 14, 48]} />
        <meshStandardMaterial
          color={dest.primaryColor}
          emissive={dest.primaryColor}
          emissiveIntensity={isVisited ? 1.8 : 2.8}
        />
      </mesh>
      <mesh ref={ring2Ref} position={[0, 5.0, -14]}>
        <torusGeometry args={[4.6, 0.11, 12, 40]} />
        <meshStandardMaterial
          color={dest.secondaryColor}
          emissive={dest.secondaryColor}
          emissiveIntensity={2.4}
        />
      </mesh>

      {/* Levitating Cyber Crystal */}
      <mesh ref={coreRef} position={[0, 4.6, -14]}>
        <octahedronGeometry args={[1.4, 0]} />
        <meshStandardMaterial
          color="#7dd3fc"
          emissive="#38bdf8"
          emissiveIntensity={2.5}
          metalness={0.85}
          roughness={0.12}
          wireframe={false}
        />
      </mesh>

      <pointLight
        position={[0, 6.5, -8]}
        color={dest.primaryColor}
        intensity={18}
        distance={36}
      />
    </group>
  );
}
