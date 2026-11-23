import { useMemo, useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import { Environment, Lightformer, Stars } from '@react-three/drei';
import * as THREE from 'three';
import { liveTelemetryRef, type TimeOfDay } from '../state/gameStore';

interface EnvironmentSkyProps {
  timeOfDay: TimeOfDay;
  isMobile: boolean;
}

interface PalettePreset {
  bg: string;
  fog: string;
  fogDensity: number;
  skyTop: string;
  skyMid: string;
  skyHorizon: string;
  ambientColor: string;
  ambientIntensity: number;
  hemiSky: string;
  hemiGround: string;
  hemiIntensity: number;
  dirColor: string;
  dirIntensity: number;
  dirPos: [number, number, number];
  starOpacity: number;
  cloudColor: string;
  cloudOpacity: number;
}

const PALETTES: Record<TimeOfDay, PalettePreset> = {
  night: {
    bg: '#040614',
    fog: '#070a1c',
    fogDensity: 0.0046,
    skyTop: '#030412',
    skyMid: '#0d1033',
    skyHorizon: '#2a1659',
    ambientColor: '#1e3a8a',
    ambientIntensity: 0.55,
    hemiSky: '#3b82f6',
    hemiGround: '#1e1038',
    hemiIntensity: 0.72,
    dirColor: '#93c5fd',
    dirIntensity: 1.55,
    dirPos: [65, 95, -55],
    starOpacity: 1,
    cloudColor: '#1e1b4b',
    cloudOpacity: 0.35,
  },
  dusk: {
    bg: '#0c0820',
    fog: '#1c1038',
    fogDensity: 0.0042,
    skyTop: '#090b28',
    skyMid: '#3b155e',
    skyHorizon: '#9333ea',
    ambientColor: '#7c3aed',
    ambientIntensity: 0.65,
    hemiSky: '#c084fc',
    hemiGround: '#1e1b4b',
    hemiIntensity: 0.85,
    dirColor: '#fbcfe8',
    dirIntensity: 1.85,
    dirPos: [-90, 52, -70],
    starOpacity: 0.65,
    cloudColor: '#581c87',
    cloudOpacity: 0.42,
  },
  day: {
    bg: '#0e1b38',
    fog: '#17294f',
    fogDensity: 0.0034,
    skyTop: '#0f172a',
    skyMid: '#1d4ed8',
    skyHorizon: '#38bdf8',
    ambientColor: '#bae6fd',
    ambientIntensity: 0.9,
    hemiSky: '#7dd3fc',
    hemiGround: '#1e293b',
    hemiIntensity: 1.1,
    dirColor: '#e0f2fe',
    dirIntensity: 2.35,
    dirPos: [80, 120, 60],
    starOpacity: 0.15,
    cloudColor: '#cbd5e1',
    cloudOpacity: 0.3,
  },
};

export function EnvironmentSky({ timeOfDay, isMobile }: EnvironmentSkyProps) {
  const palette = PALETTES[timeOfDay];
  const dirLightRef = useRef<THREE.DirectionalLight>(null);
  const targetRef = useRef<THREE.Object3D>(new THREE.Object3D());
  const cloudsRef = useRef<THREE.Group>(null);

  const skyUniforms = useMemo(
    () => ({
      uTop: { value: new THREE.Color(palette.skyTop) },
      uMid: { value: new THREE.Color(palette.skyMid) },
      uHorizon: { value: new THREE.Color(palette.skyHorizon) },
    }),
    []
  );

  const cloudPositions = useMemo(() => {
    const arr: Array<{ x: number; y: number; z: number; sx: number; sz: number }> = [];
    for (let i = 0; i < 18; i++) {
      const a = (i / 18) * Math.PI * 2;
      const r = 160 + (i % 3) * 48;
      arr.push({
        x: Math.cos(a) * r,
        y: 92 + (i % 4) * 14,
        z: Math.sin(a) * r,
        sx: 38 + (i % 5) * 14,
        sz: 18 + (i % 3) * 9,
      });
    }
    return arr;
  }, []);

  useFrame(({ scene }, dt) => {
    skyUniforms.uTop.value.lerp(new THREE.Color(palette.skyTop), Math.min(1, dt * 3));
    skyUniforms.uMid.value.lerp(new THREE.Color(palette.skyMid), Math.min(1, dt * 3));
    skyUniforms.uHorizon.value.lerp(new THREE.Color(palette.skyHorizon), Math.min(1, dt * 3));

    const car = liveTelemetryRef.car;
    if (dirLightRef.current) {
      dirLightRef.current.position.set(
        car.x + palette.dirPos[0],
        palette.dirPos[1],
        car.z + palette.dirPos[2]
      );
      targetRef.current.position.set(car.x, 0, car.z);
      targetRef.current.updateMatrixWorld();
      if (dirLightRef.current.target !== targetRef.current) {
        dirLightRef.current.target = targetRef.current;
        if (!targetRef.current.parent) {
          scene.add(targetRef.current);
        }
      }
    }

    if (cloudsRef.current) {
      cloudsRef.current.rotation.y += dt * 0.008;
    }
  });

  const shadowSize = isMobile ? 1024 : 2048;

  return (
    <>
      <color attach="background" args={[palette.bg]} />
      <fogExp2 attach="fog" args={[palette.fog, palette.fogDensity]} />

      {/* Gradient Neon Atmospheric Sky Dome */}
      <mesh scale={[480, 480, 480]} frustumCulled={false}>
        <sphereGeometry args={[1, 32, 24]} />
        <shaderMaterial
          side={THREE.BackSide}
          depthWrite={false}
          uniforms={skyUniforms}
          vertexShader={`
            varying vec3 vWorldPos;
            void main() {
              vec4 worldPosition = modelMatrix * vec4(position, 1.0);
              vWorldPos = normalize(worldPosition.xyz);
              gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }
          `}
          fragmentShader={`
            uniform vec3 uTop;
            uniform vec3 uMid;
            uniform vec3 uHorizon;
            varying vec3 vWorldPos;
            void main() {
              float h = clamp(vWorldPos.y, 0.0, 1.0);
              vec3 col = mix(uHorizon, uMid, smoothstep(0.0, 0.28, h));
              col = mix(col, uTop, smoothstep(0.24, 0.78, h));
              gl_FragColor = vec4(col, 1.0);
            }
          `}
        />
      </mesh>

      {/* Atmospheric Stars & Drifting Clouds */}
      <Stars
        radius={260}
        depth={70}
        count={isMobile ? 900 : 2200}
        factor={3.8}
        saturation={0.45}
        fade
        speed={0.45}
      />

      <group ref={cloudsRef}>
        {cloudPositions.map((c, idx) => (
          <mesh
            key={idx}
            position={[c.x, c.y, c.z]}
            scale={[c.sx, 4.2, c.sz]}
          >
            <sphereGeometry args={[1, 10, 8]} />
            <meshBasicMaterial
              color={palette.cloudColor}
              transparent
              opacity={palette.cloudOpacity}
              depthWrite={false}
            />
          </mesh>
        ))}
      </group>

      {/* Stylized Sun / Moon Horizon Disc */}
      <mesh position={[0, 72, -320]}>
        <circleGeometry args={[28, 32]} />
        <meshBasicMaterial
          color={timeOfDay === 'night' ? '#a855f7' : timeOfDay === 'dusk' ? '#f472b6' : '#7dd3fc'}
          transparent
          opacity={timeOfDay === 'day' ? 0.55 : 0.72}
          fog={false}
        />
      </mesh>

      {/* Physically-inspired IBL Reflection Map for Car Paint Clearcoat & Wet Asphalt */}
      <Environment resolution={256} frames={1}>
        <color attach="background" args={['#06091a']} />
        <Lightformer
          form="rect"
          intensity={3.5}
          color="#38bdf8"
          scale={[45, 4, 1]}
          position={[0, 12, -28]}
          target={[0, 0, 0]}
        />
        <Lightformer
          form="rect"
          intensity={3.0}
          color="#a855f7"
          scale={[45, 4, 1]}
          position={[26, 10, 12]}
          target={[0, 0, 0]}
        />
        <Lightformer
          form="rect"
          intensity={2.6}
          color="#60a5fa"
          scale={[40, 3, 1]}
          position={[-26, 11, 14]}
          target={[0, 0, 0]}
        />
        <Lightformer
          form="ring"
          intensity={2.2}
          color="#e0f2fe"
          scale={18}
          position={[0, 26, 0]}
          rotation-x={Math.PI / 2}
        />
      </Environment>

      {/* Key Lighting Rig */}
      <ambientLight color={palette.ambientColor} intensity={palette.ambientIntensity} />
      <hemisphereLight
        args={[palette.hemiSky, palette.hemiGround, palette.hemiIntensity]}
      />
      <directionalLight
        ref={dirLightRef}
        castShadow
        color={palette.dirColor}
        intensity={palette.dirIntensity}
        position={palette.dirPos}
        shadow-mapSize={[shadowSize, shadowSize]}
        shadow-camera-near={10}
        shadow-camera-far={260}
        shadow-camera-left={-75}
        shadow-camera-right={75}
        shadow-camera-top={75}
        shadow-camera-bottom={-75}
        shadow-bias={-0.0004}
      />
    </>
  );
}
