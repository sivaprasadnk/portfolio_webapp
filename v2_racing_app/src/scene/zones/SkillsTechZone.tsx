import { useMemo, useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';
import {
  DESTINATIONS,
  SKILLS_DATA,
  type DestinationId,
} from '../../data/portfolioData';
import { createNeonSignTexture } from '../../utils/textures';

interface ZoneProps {
  onSelectZone: (id: DestinationId) => void;
  visitedIds: DestinationId[];
}

export default function SkillsTechZone({ onSelectZone }: ZoneProps) {
  const dest = DESTINATIONS.find((d) => d.id === 'skills')!;
  const orbitGroupRef = useRef<THREE.Group>(null);
  const spireRingRef = useRef<THREE.Mesh>(null);
  const nodeRefs = useRef<Array<THREE.Group | null>>([]);

  const zoneSign = useMemo(
    () =>
      createNeonSignTexture(
        'SKILLS',
        'QUANTUM TECH ZONE // 11 CORE TECHNOLOGIES',
        dest.primaryColor,
        dest.secondaryColor
      ),
    [dest.primaryColor, dest.secondaryColor]
  );

  const skillTextures = useMemo(
    () =>
      SKILLS_DATA.map((skill) =>
        createNeonSignTexture(
          skill.name.toUpperCase(),
          `${skill.category.toUpperCase()} · ${skill.level}%`,
          skill.color,
          '#38bdf8'
        )
      ),
    []
  );

  useFrame(({ clock }) => {
    const t = clock.getElapsedTime();
    if (orbitGroupRef.current) {
      orbitGroupRef.current.rotation.y = t * 0.24;
    }
    if (spireRingRef.current) {
      spireRingRef.current.rotation.z = t * 0.9;
    }
    nodeRefs.current.forEach((grp, idx) => {
      if (!grp) return;
      grp.position.y = 3.1 + Math.sin(t * 2.2 + idx * 0.65) * 0.32;
      grp.lookAt(0, grp.position.y, 18);
    });
  });

  return (
    <group
      position={dest.position}
      rotation={[0, -Math.PI * 0.72, 0]}
      onClick={(e) => {
        e.stopPropagation();
        onSelectZone('skills');
      }}
    >
      {/* Tech Zone Header Sign */}
      <mesh position={[0, 10.2, -14]}>
        <boxGeometry args={[24, 3.8, 0.8]} />
        <meshStandardMaterial color="#070b1a" metalness={0.85} roughness={0.25} />
      </mesh>
      <mesh position={[0, 10.2, -13.55]}>
        <planeGeometry args={[22.8, 3.3]} />
        <meshBasicMaterial map={zoneSign} />
      </mesh>

      {/* Central Quantum Energy Spire */}
      <mesh position={[0, 4.5, -14]}>
        <cylinderGeometry args={[0.45, 0.9, 9, 8]} />
        <meshStandardMaterial
          color="#1e1b4b"
          emissive={dest.primaryColor}
          emissiveIntensity={1.6}
          metalness={0.9}
        />
      </mesh>
      <mesh ref={spireRingRef} position={[0, 5.2, -14]}>
        <torusGeometry args={[3.4, 0.12, 12, 36]} />
        <meshStandardMaterial
          color={dest.secondaryColor}
          emissive={dest.secondaryColor}
          emissiveIntensity={2.6}
        />
      </mesh>

      {/* 11 Orbiting Holographic Skill Nodes */}
      <group ref={orbitGroupRef} position={[0, 0, -14]}>
        {SKILLS_DATA.map((skill, idx) => {
          const angle = (idx / SKILLS_DATA.length) * Math.PI * 2;
          const radius = idx % 2 === 0 ? 7.6 : 10.4;
          const nx = Math.cos(angle) * radius;
          const nz = Math.sin(angle) * radius;
          return (
            <group
              key={skill.id}
              ref={(el) => {
                nodeRefs.current[idx] = el;
              }}
              position={[nx, 3.1, nz]}
            >
              <mesh>
                <planeGeometry args={[3.4, 1.15]} />
                <meshBasicMaterial
                  map={skillTextures[idx]}
                  side={THREE.DoubleSide}
                />
              </mesh>
              <mesh position={[0, -0.95, 0]}>
                <octahedronGeometry args={[0.35, 0]} />
                <meshStandardMaterial
                  color={skill.color}
                  emissive={skill.color}
                  emissiveIntensity={2.5}
                />
              </mesh>
            </group>
          );
        })}
      </group>

      <pointLight
        position={[0, 6.0, -8]}
        color={dest.secondaryColor}
        intensity={18}
        distance={36}
      />
    </group>
  );
}
