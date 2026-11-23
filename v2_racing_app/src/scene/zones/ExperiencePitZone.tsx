import { useMemo, useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';
import { DESTINATIONS, EXPERIENCE_DATA, type DestinationId } from '../../data/portfolioData';
import { createNeonSignTexture } from '../../utils/textures';

interface ZoneProps {
  onSelectZone: (id: DestinationId) => void;
  visitedIds: DestinationId[];
}

export default function ExperiencePitZone({ onSelectZone }: ZoneProps) {
  const dest = DESTINATIONS.find((d) => d.id === 'experience')!;
  const holoRefs = useRef<Array<THREE.Mesh | null>>([]);

  const mainSign = useMemo(
    () =>
      createNeonSignTexture(
        'EXPERIENCE',
        'RACING PIT-STOP // CAREER TELEMETRY BAYS',
        dest.primaryColor,
        dest.secondaryColor
      ),
    [dest.primaryColor, dest.secondaryColor]
  );

  const baySigns = useMemo(
    () =>
      EXPERIENCE_DATA.map((exp) =>
        createNeonSignTexture(
          exp.bayNumber,
          exp.company.toUpperCase(),
          exp.accent,
          '#38bdf8'
        )
      ),
    []
  );

  useFrame(({ clock }) => {
    const t = clock.getElapsedTime();
    holoRefs.current.forEach((m, i) => {
      if (!m) return;
      m.position.y = 3.2 + Math.sin(t * 2.1 + i * 1.1) * 0.22;
    });
  });

  return (
    <group
      position={dest.position}
      rotation={[0, -Math.PI * 0.45, 0]}
      onClick={(e) => {
        e.stopPropagation();
        onSelectZone('experience');
      }}
    >
      {/* Pit-Stop Canopy Roof Structure */}
      <mesh position={[0, 7.6, -15]} castShadow>
        <boxGeometry args={[28, 0.9, 9.5]} />
        <meshStandardMaterial color="#0b1022" metalness={0.85} roughness={0.25} />
      </mesh>
      <mesh position={[0, 8.8, -10.5]}>
        <boxGeometry args={[26, 3.6, 0.7]} />
        <meshStandardMaterial color="#070a18" metalness={0.8} roughness={0.3} />
      </mesh>
      <mesh position={[0, 8.8, -10.1]}>
        <planeGeometry args={[24.6, 3.1]} />
        <meshBasicMaterial map={mainSign} />
      </mesh>

      {/* 4 Pit-Garage Stanchions */}
      {[-12.5, -4.2, 4.2, 12.5].map((px, i) => (
        <mesh key={i} position={[px, 3.8, -15]} castShadow>
          <boxGeometry args={[0.85, 7.6, 1.2]} />
          <meshStandardMaterial
            color="#111827"
            emissive={dest.primaryColor}
            emissiveIntensity={0.4}
            metalness={0.85}
          />
        </mesh>
      ))}

      {/* 3 Illuminated Career Pit-Bays */}
      {EXPERIENCE_DATA.map((exp, idx) => {
        const bx = -8.3 + idx * 8.3;
        return (
          <group key={exp.id} position={[bx, 0, -15]}>
            {/* Glowing Pit Floor Pad */}
            <mesh position={[0, 0.08, 3.5]} rotation={[-Math.PI / 2, 0, 0]}>
              <planeGeometry args={[6.6, 7.2]} />
              <meshBasicMaterial
                color={exp.accent}
                transparent
                opacity={0.22}
              />
            </mesh>
            {/* Floating 3D Telemetry Screen */}
            <mesh
              ref={(el) => {
                holoRefs.current[idx] = el;
              }}
              position={[0, 3.2, 1.8]}
            >
              <planeGeometry args={[6.2, 2.2]} />
              <meshBasicMaterial map={baySigns[idx]} side={THREE.DoubleSide} />
            </mesh>
            {/* Racing Tire Stack Accent */}
            <mesh position={[2.6, 0.65, 2.8]}>
              <cylinderGeometry args={[0.52, 0.52, 1.2, 16]} />
              <meshStandardMaterial color="#090d16" roughness={0.85} />
            </mesh>
          </group>
        );
      })}

      <pointLight
        position={[0, 6.2, -9]}
        color={dest.primaryColor}
        intensity={18}
        distance={36}
      />
    </group>
  );
}
