import { useMemo, useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';
import { DESTINATIONS, PROJECTS_DATA, type DestinationId } from '../../data/portfolioData';
import { createNeonSignTexture } from '../../utils/textures';

interface ZoneProps {
  onSelectZone: (id: DestinationId) => void;
  visitedIds: DestinationId[];
}

export default function ProjectsGarageZone({ onSelectZone }: ZoneProps) {
  const dest = DESTINATIONS.find((d) => d.id === 'projects')!;
  const screenRefs = useRef<Array<THREE.Mesh | null>>([]);

  const garageSign = useMemo(
    () =>
      createNeonSignTexture(
        'PROJECTS',
        'CYBER SHOWCASE GARAGE // CLICK OR PRESS E',
        dest.primaryColor,
        dest.secondaryColor
      ),
    [dest.primaryColor, dest.secondaryColor]
  );

  const projectHoloTex = useMemo(
    () =>
      PROJECTS_DATA.slice(0, 4).map((proj) =>
        createNeonSignTexture(
          proj.name.toUpperCase(),
          proj.technologies.slice(0, 3).join(' · '),
          proj.accentColor,
          '#a855f7'
        )
      ),
    []
  );

  useFrame(({ clock }) => {
    const t = clock.getElapsedTime();
    screenRefs.current.forEach((m, idx) => {
      if (!m) return;
      m.position.y = 3.5 + Math.sin(t * 2 + idx * 0.9) * 0.18;
    });
  });

  return (
    <group
      position={dest.position}
      rotation={[0, Math.PI * 0.78, 0]}
      onClick={(e) => {
        e.stopPropagation();
        onSelectZone('projects');
      }}
    >
      {/* Futuristic Cyber Garage Neon Light Frame */}
      {[-12, -4, 4, 12].map((rx, i) => (
        <mesh key={i} position={[rx, 4.5, -14]}>
          <torusGeometry args={[7.2, 0.14, 10, 24, Math.PI]} />
          <meshStandardMaterial
            color={i % 2 === 0 ? dest.primaryColor : dest.secondaryColor}
            emissive={i % 2 === 0 ? dest.primaryColor : dest.secondaryColor}
            emissiveIntensity={2.4}
          />
        </mesh>
      ))}

      {/* Garage Header Signboard */}
      <mesh position={[0, 11.2, -13.5]}>
        <boxGeometry args={[24, 3.8, 0.8]} />
        <meshStandardMaterial color="#060a16" metalness={0.85} roughness={0.25} />
      </mesh>
      <mesh position={[0, 11.2, -13.05]}>
        <planeGeometry args={[22.8, 3.3]} />
        <meshBasicMaterial map={garageSign} />
      </mesh>

      {/* 4 Angled Holographic Showcase Screens */}
      {projectHoloTex.map((tex, idx) => {
        const angle = (-1.5 + idx) * 0.24;
        const sx = (-1.5 + idx) * 6.8;
        const sz = -13 + Math.abs(-1.5 + idx) * 1.4;
        return (
          <mesh
            key={idx}
            ref={(el) => {
              screenRefs.current[idx] = el;
            }}
            position={[sx, 3.5, sz]}
            rotation={[0, angle, 0]}
          >
            <planeGeometry args={[6.1, 2.3]} />
            <meshBasicMaterial map={tex} side={THREE.DoubleSide} />
          </mesh>
        );
      })}

      <pointLight
        position={[0, 6.0, -9]}
        color={dest.primaryColor}
        intensity={18}
        distance={36}
      />
    </group>
  );
}
