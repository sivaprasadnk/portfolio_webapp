import { useCallback, useEffect, useRef, useState } from 'react';
import { soundEngine } from './audio/soundEngine';
import { MobileControls } from './components/hud/MobileControls';
import { RacingHud } from './components/hud/RacingHud';
import { AboutPanel } from './components/panels/AboutPanel';
import { ContactPanel } from './components/panels/ContactPanel';
import { ExperiencePanel } from './components/panels/ExperiencePanel';
import { HolographicPanelShell } from './components/panels/HolographicPanelShell';
import { ProjectsPanel } from './components/panels/ProjectsPanel';
import { SkillsPanel } from './components/panels/SkillsPanel';
import { StartScreen } from './components/StartScreen';
import {
  DESTINATIONS,
  type DestinationConfig,
  type DestinationId,
} from './data/portfolioData';
import { RacingScene } from './scene/RacingScene';
import {
  liveTelemetryRef,
  loadVisitedDestinations,
  saveVisitedDestinations,
  type CameraMode,
  type GamePhase,
  type TimeOfDay,
} from './state/gameStore';
import type { ControlInput } from './world/physics';

function checkIsMobileViewport(): boolean {
  if (typeof window === 'undefined') return false;
  return (
    window.innerWidth < 768 ||
    ('ontouchstart' in window && window.innerWidth < 1024)
  );
}

export function App() {
  const [phase, setPhase] = useState<GamePhase>('title');
  const [cameraMode, setCameraMode] = useState<CameraMode>('chase');
  const [timeOfDay, setTimeOfDay] = useState<TimeOfDay>('night');
  const [isPaused, setIsPaused] = useState(false);
  const [isMuted, setIsMuted] = useState(false);
  const [activePanel, setActivePanel] = useState<DestinationId | null>(null);
  const [visitedIds, setVisitedIds] = useState<DestinationId[]>(() =>
    loadVisitedDestinations()
  );
  const [nearbyCheckpoint, setNearbyCheckpoint] =
    useState<DestinationConfig | null>(null);
  const [resetCounter, setResetCounter] = useState(0);
  const [isMobile, setIsMobile] = useState(checkIsMobileViewport);
  const [showTouchControls, setShowTouchControls] = useState(false);

  const inputRef = useRef<ControlInput>({
    throttle: false,
    brake: false,
    steerLeft: false,
    steerRight: false,
    handbrake: false,
    nitro: false,
  });

  useEffect(() => {
    const onResize = () => setIsMobile(checkIsMobileViewport());
    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, []);

  const markVisited = useCallback((id: DestinationId) => {
    setVisitedIds((prev) => {
      if (prev.includes(id)) return prev;
      const next = [...prev, id];
      saveVisitedDestinations(next);
      return next;
    });
  }, []);

  const clearInputs = useCallback(() => {
    inputRef.current = {
      throttle: false,
      brake: false,
      steerLeft: false,
      steerRight: false,
      handbrake: false,
      nitro: false,
    };
  }, []);

  const openPanel = useCallback(
    (id: DestinationId) => {
      clearInputs();
      markVisited(id);
      setIsPaused(false);
      setActivePanel(id);
      soundEngine.playPanelOpen();
    },
    [clearInputs, markVisited]
  );

  const closePanel = useCallback(() => {
    setActivePanel(null);
    soundEngine.playPanelClose();
  }, []);

  const handleStartEngine = useCallback(() => {
    soundEngine.playEngineStart();
    liveTelemetryRef.transitionProgress = 0;
    setPhase('transition');
  }, []);

  const handleSkipDriving = useCallback(() => {
    soundEngine.unlock();
    setPhase('playing');
    openPanel('about');
  }, [openPanel]);

  const handleTransitionComplete = useCallback(() => {
    setPhase('playing');
  }, []);

  const handleTeleportTo = useCallback(
    (id: DestinationId) => {
      const dest = DESTINATIONS.find((d) => d.id === id);
      if (!dest) return;
      clearInputs();
      setActivePanel(null);
      setIsPaused(false);
      liveTelemetryRef.teleportTarget = {
        x: dest.spawnPosition[0],
        z: dest.spawnPosition[1],
        heading: dest.spawnHeading,
      };
      if (phase !== 'playing') setPhase('playing');
      soundEngine.playCheckpointChime();
    },
    [clearInputs, phase]
  );

  const handleCheckpointChange = useCallback(
    (dest: DestinationConfig | null) => {
      setNearbyCheckpoint(dest);
      if (dest) {
        markVisited(dest.id);
      }
    },
    [markVisited]
  );

  const handleTogglePause = useCallback(() => {
    setIsPaused((prev) => {
      const next = !prev;
      soundEngine.setPaused(next);
      if (next) clearInputs();
      return next;
    });
  }, [clearInputs]);

  const handleResetGame = useCallback(() => {
    clearInputs();
    setActivePanel(null);
    setIsPaused(false);
    soundEngine.setPaused(false);
    setResetCounter((c) => c + 1);
  }, [clearInputs]);

  const handleToggleMute = useCallback(() => {
    setIsMuted((prev) => {
      const next = !prev;
      soundEngine.setMuted(next);
      return next;
    });
  }, []);

  const handleCycleCamera = useCallback(() => {
    setCameraMode((prev) =>
      prev === 'chase' ? 'hood' : prev === 'hood' ? 'cinematic' : 'chase'
    );
  }, []);

  const handleCycleTimeOfDay = useCallback(() => {
    setTimeOfDay((prev) =>
      prev === 'night' ? 'dusk' : prev === 'dusk' ? 'day' : 'night'
    );
  }, []);

  // Global keyboard bindings
  useEffect(() => {
    const isEditableTarget = (target: EventTarget | null) => {
      if (!(target instanceof HTMLElement)) return false;
      const tag = target.tagName;
      return (
        tag === 'INPUT' ||
        tag === 'TEXTAREA' ||
        tag === 'SELECT' ||
        target.isContentEditable
      );
    };

    const onKeyDown = (e: KeyboardEvent) => {
      if (e.code === 'Escape') {
        if (activePanel) {
          e.preventDefault();
          closePanel();
          return;
        }
        if (phase === 'playing') {
          e.preventDefault();
          handleTogglePause();
          return;
        }
      }

      if (isEditableTarget(e.target)) return;

      soundEngine.unlock();

      if (e.code === 'KeyE') {
        if (phase === 'playing' && !activePanel && nearbyCheckpoint) {
          e.preventDefault();
          openPanel(nearbyCheckpoint.id);
          return;
        }
      }

      if (e.code === 'KeyC' && phase === 'playing' && !activePanel) {
        e.preventDefault();
        handleCycleCamera();
        return;
      }

      if (e.code === 'KeyM' && !activePanel) {
        e.preventDefault();
        handleToggleMute();
        return;
      }

      if (e.code === 'KeyP' && phase === 'playing' && !activePanel) {
        e.preventDefault();
        handleTogglePause();
        return;
      }

      if (e.code === 'KeyR' && phase === 'playing' && !activePanel) {
        e.preventDefault();
        handleResetGame();
        return;
      }

      if (activePanel || isPaused || phase !== 'playing') return;

      switch (e.code) {
        case 'KeyW':
        case 'ArrowUp':
          inputRef.current.throttle = true;
          break;
        case 'KeyS':
        case 'ArrowDown':
          inputRef.current.brake = true;
          break;
        case 'KeyA':
        case 'ArrowLeft':
          inputRef.current.steerLeft = true;
          break;
        case 'KeyD':
        case 'ArrowRight':
          inputRef.current.steerRight = true;
          break;
        case 'Space':
          e.preventDefault();
          inputRef.current.handbrake = true;
          break;
        case 'ShiftLeft':
        case 'ShiftRight':
          inputRef.current.nitro = true;
          break;
      }
    };

    const onKeyUp = (e: KeyboardEvent) => {
      switch (e.code) {
        case 'KeyW':
        case 'ArrowUp':
          inputRef.current.throttle = false;
          break;
        case 'KeyS':
        case 'ArrowDown':
          inputRef.current.brake = false;
          break;
        case 'KeyA':
        case 'ArrowLeft':
          inputRef.current.steerLeft = false;
          break;
        case 'KeyD':
        case 'ArrowRight':
          inputRef.current.steerRight = false;
          break;
        case 'Space':
          inputRef.current.handbrake = false;
          break;
        case 'ShiftLeft':
        case 'ShiftRight':
          inputRef.current.nitro = false;
          break;
      }
    };

    window.addEventListener('keydown', onKeyDown);
    window.addEventListener('keyup', onKeyUp);
    window.addEventListener('blur', clearInputs);
    return () => {
      window.removeEventListener('keydown', onKeyDown);
      window.removeEventListener('keyup', onKeyUp);
      window.removeEventListener('blur', clearInputs);
    };
  }, [
    activePanel,
    clearInputs,
    closePanel,
    handleCycleCamera,
    handleResetGame,
    handleToggleMute,
    handleTogglePause,
    isPaused,
    nearbyCheckpoint,
    openPanel,
    phase,
  ]);

  const renderPanelContent = (id: DestinationId) => {
    switch (id) {
      case 'about':
        return <AboutPanel />;
      case 'experience':
        return <ExperiencePanel />;
      case 'projects':
        return <ProjectsPanel />;
      case 'skills':
        return <SkillsPanel />;
      case 'contact':
        return <ContactPanel />;
    }
  };

  return (
    <main className="relative h-full w-full overflow-hidden bg-[#050712]">
      {/* Live 3D Open-World Racing Canvas */}
      <RacingScene
        inputRef={inputRef}
        phase={phase}
        cameraMode={cameraMode}
        timeOfDay={timeOfDay}
        isPaused={isPaused}
        activePanel={activePanel}
        visitedIds={visitedIds}
        resetCounter={resetCounter}
        isMobile={isMobile}
        onTransitionComplete={handleTransitionComplete}
        onCheckpointChange={handleCheckpointChange}
        onSelectZone={openPanel}
        onTeleportHandled={() => {}}
      />

      {/* Cinematic Orbiting Start Screen */}
      {phase === 'title' && (
        <StartScreen
          onStartEngine={handleStartEngine}
          onSkipDriving={handleSkipDriving}
        />
      )}

      {/* Active Gameplay HUD */}
      {phase === 'playing' && (
        <RacingHud
          visitedIds={visitedIds}
          nearbyCheckpoint={nearbyCheckpoint}
          activePanel={activePanel}
          isPaused={isPaused}
          isMuted={isMuted}
          cameraMode={cameraMode}
          timeOfDay={timeOfDay}
          isMobile={isMobile}
          showTouchControls={showTouchControls}
          onExploreCheckpoint={openPanel}
          onTeleportTo={handleTeleportTo}
          onTogglePause={handleTogglePause}
          onResetGame={handleResetGame}
          onToggleMute={handleToggleMute}
          onCycleCamera={handleCycleCamera}
          onCycleTimeOfDay={handleCycleTimeOfDay}
          onToggleTouchControls={() => setShowTouchControls((v) => !v)}
        />
      )}

      {/* Responsive Mobile Touch Racing Controls */}
      {phase === 'playing' &&
        !isPaused &&
        !activePanel &&
        (isMobile || showTouchControls) && (
          <MobileControls
            inputRef={inputRef}
            nearbyCheckpoint={nearbyCheckpoint}
            onExploreCheckpoint={openPanel}
          />
        )}

      {/* Immersive Holographic Destination Panels */}
      {activePanel && (
        <HolographicPanelShell
          activeId={activePanel}
          visitedIds={visitedIds}
          onSelectPanel={openPanel}
          onTeleportHere={handleTeleportTo}
          onClose={closePanel}
        >
          {renderPanelContent(activePanel)}
        </HolographicPanelShell>
      )}
    </main>
  );
}

export default App;
