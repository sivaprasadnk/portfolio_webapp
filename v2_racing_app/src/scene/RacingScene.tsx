import React, { Component, Suspense, useRef } from 'react';
import { Canvas } from '@react-three/fiber';
import { Bloom, EffectComposer, Vignette } from '@react-three/postprocessing';
import * as THREE from 'three';
import type { DestinationConfig, DestinationId } from '../data/portfolioData';
import {
  liveTelemetryRef,
  type CameraMode,
  type GamePhase,
  type TimeOfDay,
} from '../state/gameStore';
import type { ControlInput } from '../world/physics';
import { CameraRig } from './CameraRig';
import { CityWorld } from './CityWorld';
import { EnvironmentSky } from './EnvironmentSky';
import { PlayerCar } from './PlayerCar';

// Lazy-loaded 3D zone architectural landmarks
const AboutCheckpointZone = React.lazy(() => import('./zones/AboutCheckpointZone'));
const ExperiencePitZone = React.lazy(() => import('./zones/ExperiencePitZone'));
const ProjectsGarageZone = React.lazy(() => import('./zones/ProjectsGarageZone'));
const SkillsTechZone = React.lazy(() => import('./zones/SkillsTechZone'));
const ContactFinishZone = React.lazy(() => import('./zones/ContactFinishZone'));

interface RacingSceneProps {
  inputRef: React.MutableRefObject<ControlInput>;
  phase: GamePhase;
  cameraMode: CameraMode;
  timeOfDay: TimeOfDay;
  isPaused: boolean;
  activePanel: DestinationId | null;
  visitedIds: DestinationId[];
  resetCounter: number;
  isMobile: boolean;
  onTransitionComplete: () => void;
  onCheckpointChange: (dest: DestinationConfig | null, distance: number) => void;
  onSelectZone: (id: DestinationId) => void;
  onTeleportHandled: () => void;
}

class SceneErrorBoundary extends Component<
  { children: React.ReactNode },
  { hasError: boolean }
> {
  public state = { hasError: false };

  public static getDerivedStateFromError(): { hasError: boolean } {
    return { hasError: true };
  }

  public render(): React.ReactNode {
    if (this.state.hasError) {
      return (
        <div className="absolute inset-0 flex flex-col items-center justify-center bg-[#050712] px-6 text-center">
          <div className="hud-glass max-w-md rounded-2xl p-6">
            <h2 className="font-display text-lg font-bold text-sky-400">
              3D WebGL Renderer Unavailable
            </h2>
            <p className="mt-2 text-sm text-slate-300">
              Hardware WebGL could not initialize in this browser context. You
              can still explore every portfolio section directly using the HUD
              navigation buttons.
            </p>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}

export function RacingScene({
  inputRef,
  phase,
  cameraMode,
  timeOfDay,
  isPaused,
  activePanel,
  visitedIds,
  resetCounter,
  isMobile,
  onTransitionComplete,
  onCheckpointChange,
  onSelectZone,
  onTeleportHandled,
}: RacingSceneProps) {
  const dragActiveRef = useRef(false);
  const lastPointerRef = useRef({ x: 0, y: 0 });

  const handlePointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    if (phase !== 'playing' || activePanel) return;
    dragActiveRef.current = true;
    lastPointerRef.current = { x: e.clientX, y: e.clientY };
  };

  const handlePointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!dragActiveRef.current || phase !== 'playing' || activePanel) return;
    const dx = e.clientX - lastPointerRef.current.x;
    const dy = e.clientY - lastPointerRef.current.y;
    lastPointerRef.current = { x: e.clientX, y: e.clientY };
    liveTelemetryRef.cameraOrbitYaw = THREE.MathUtils.clamp(
      liveTelemetryRef.cameraOrbitYaw - dx * 0.0045,
      -1.35,
      1.35
    );
    liveTelemetryRef.cameraOrbitPitch = THREE.MathUtils.clamp(
      liveTelemetryRef.cameraOrbitPitch + dy * 0.0025,
      -0.06,
      0.42
    );
    liveTelemetryRef.lastMouseOrbitAt = performance.now() / 1000;
  };

  const handlePointerUp = () => {
    dragActiveRef.current = false;
  };

  return (
    <SceneErrorBoundary>
      <div
        className="absolute inset-0 cursor-grab active:cursor-grabbing"
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerUp}
        onPointerLeave={handlePointerUp}
      >
        <Canvas
          shadows
          dpr={isMobile ? [1, 1.35] : [1, 1.75]}
          camera={{ fov: 56, near: 0.25, far: 720, position: [6, 3.2, 23] }}
          gl={{
            antialias: true,
            powerPreference: 'high-performance',
            toneMapping: THREE.ACESFilmicToneMapping,
            toneMappingExposure: 1.12,
          }}
        >
          <EnvironmentSky timeOfDay={timeOfDay} isMobile={isMobile} />

          <CityWorld isMobile={isMobile} />

          <PlayerCar
            inputRef={inputRef}
            phase={phase}
            isPaused={isPaused}
            isModalOpen={activePanel !== null}
            visitedIds={visitedIds}
            timeOfDay={timeOfDay}
            resetCounter={resetCounter}
            onCheckpointChange={onCheckpointChange}
            onTeleportHandled={onTeleportHandled}
          />

          <CameraRig
            phase={phase}
            cameraMode={cameraMode}
            activePanel={activePanel}
            onTransitionComplete={onTransitionComplete}
          />

          <Suspense fallback={null}>
            <AboutCheckpointZone
              onSelectZone={onSelectZone}
              visitedIds={visitedIds}
            />
            <ExperiencePitZone
              onSelectZone={onSelectZone}
              visitedIds={visitedIds}
            />
            <ProjectsGarageZone
              onSelectZone={onSelectZone}
              visitedIds={visitedIds}
            />
            <SkillsTechZone
              onSelectZone={onSelectZone}
              visitedIds={visitedIds}
            />
            <ContactFinishZone
              onSelectZone={onSelectZone}
              visitedIds={visitedIds}
            />
          </Suspense>

          <EffectComposer multisampling={0}>
            <Bloom
              mipmapBlur
              luminanceThreshold={0.9}
              luminanceSmoothing={0.28}
              intensity={isMobile ? 0.55 : 0.85}
            />
            <Vignette eskil={false} offset={0.22} darkness={0.46} />
          </EffectComposer>
        </Canvas>
      </div>
    </SceneErrorBoundary>
  );
}
