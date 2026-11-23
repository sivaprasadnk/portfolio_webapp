import { useEffect, useState } from 'react';
import {
  Camera,
  Check,
  Compass,
  Flag,
  Flame,
  Gamepad2,
  MapPin,
  Moon,
  Pause,
  Play,
  RotateCcw,
  Sparkles,
  Sun,
  Sunrise,
  Volume2,
  VolumeX,
} from 'lucide-react';
import {
  DESTINATIONS,
  type DestinationConfig,
  type DestinationId,
} from '../../data/portfolioData';
import {
  liveTelemetryRef,
  type CameraMode,
  type TimeOfDay,
} from '../../state/gameStore';
import {
  CROSS_AVENUES,
  TRACK_SAMPLES,
  WORLD_BOUND,
} from '../../world/trackData';

interface RacingHudProps {
  visitedIds: DestinationId[];
  nearbyCheckpoint: DestinationConfig | null;
  activePanel: DestinationId | null;
  isPaused: boolean;
  isMuted: boolean;
  cameraMode: CameraMode;
  timeOfDay: TimeOfDay;
  isMobile: boolean;
  showTouchControls: boolean;
  onExploreCheckpoint: (id: DestinationId) => void;
  onTeleportTo: (id: DestinationId) => void;
  onTogglePause: () => void;
  onResetGame: () => void;
  onToggleMute: () => void;
  onCycleCamera: () => void;
  onCycleTimeOfDay: () => void;
  onToggleTouchControls: () => void;
}

interface TelemetrySnapshot {
  speedKmh: number;
  gear: string;
  rpm: number;
  nitro: number;
  isBoosting: boolean;
  isDrifting: boolean;
  x: number;
  z: number;
  heading: number;
  missionDest: DestinationConfig;
  missionDist: number;
  allVisited: boolean;
}

function projectToMiniMap(x: number, z: number): [number, number] {
  const pad = 16;
  const mapSpan = 160 - pad * 2;
  const nx = (x + WORLD_BOUND) / (WORLD_BOUND * 2);
  const nz = (z + WORLD_BOUND) / (WORLD_BOUND * 2);
  return [pad + nx * mapSpan, pad + nz * mapSpan];
}

const MINI_TRACK_PATH = (() => {
  const pts = TRACK_SAMPLES.filter((_, idx) => idx % 4 === 0).map((s) => {
    const [mx, my] = projectToMiniMap(s.x, s.z);
    return `${mx.toFixed(1)},${my.toFixed(1)}`;
  });
  return `M ${pts.join(' L ')} Z`;
})();

export function RacingHud({
  visitedIds,
  nearbyCheckpoint,
  activePanel,
  isPaused,
  isMuted,
  cameraMode,
  timeOfDay,
  isMobile,
  showTouchControls,
  onExploreCheckpoint,
  onTeleportTo,
  onTogglePause,
  onResetGame,
  onToggleMute,
  onCycleCamera,
  onCycleTimeOfDay,
  onToggleTouchControls,
}: RacingHudProps) {
  const [showDestMenu, setShowDestMenu] = useState(false);
  const [telemetry, setTelemetry] = useState<TelemetrySnapshot>(() => ({
    speedKmh: 0,
    gear: 'N',
    rpm: 950,
    nitro: 100,
    isBoosting: false,
    isDrifting: false,
    x: 0,
    z: 16,
    heading: 0,
    missionDest: DESTINATIONS[0],
    missionDist: 100,
    allVisited: false,
  }));

  useEffect(() => {
    const id = window.setInterval(() => {
      const car = liveTelemetryRef.car;
      const mission = liveTelemetryRef.mission;
      setTelemetry({
        speedKmh: car.speedKmh,
        gear: car.gear,
        rpm: car.rpm,
        nitro: car.nitro,
        isBoosting: car.isBoosting,
        isDrifting: car.isDrifting,
        x: car.x,
        z: car.z,
        heading: car.heading,
        missionDest: mission.destination,
        missionDist: mission.distance,
        allVisited: mission.allVisited,
      });
    }, 65);
    return () => window.clearInterval(id);
  }, []);

  const visitedSet = new Set(visitedIds);
  const [playerMapX, playerMapY] = projectToMiniMap(telemetry.x, telemetry.z);
  const rpmRatio = Math.min(1, Math.max(0, (telemetry.rpm - 900) / 7600));
  const arcLen = 195;
  const rpmDash = arcLen * (1 - rpmRatio);

  const TimeIcon = timeOfDay === 'night' ? Moon : timeOfDay === 'dusk' ? Sunrise : Sun;

  return (
    <div className="pointer-events-none absolute inset-0 z-20 flex flex-col justify-between p-3 sm:p-5">
      {/* TOP BAR: Mission Tracker (Left) + Action Controls (Right) */}
      <div className="flex flex-wrap items-start justify-between gap-2.5">
        {/* Top-Left Mission Panel */}
        <div
          data-testid="mission-panel"
          className="hud-glass pointer-events-auto max-w-[330px] rounded-xl p-3 sm:p-3.5"
        >
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-1.5 text-[10px] font-bold tracking-[0.18em] text-sky-300">
              <Compass className="h-3.5 w-3.5 text-purple-400" />
              <span>MISSION</span>
            </div>
            <span className="rounded-full bg-sky-500/15 px-2 py-0.5 font-display text-[10px] font-bold text-sky-300">
              {visitedIds.length} / {DESTINATIONS.length} VISITED
            </span>
          </div>

          <h2 className="mt-1 font-display text-xs font-extrabold tracking-wide text-white sm:text-sm">
            Explore Siva&apos;s Developer Journey
          </h2>

          {/* Active Next Destination & Distance */}
          <div className="mt-2 flex items-center justify-between gap-2 rounded-lg border border-slate-700/70 bg-slate-900/65 px-2.5 py-1.5">
            <div className="min-w-0">
              <div className="text-[10px] uppercase tracking-wider text-slate-400">
                {telemetry.allVisited ? 'Nearest Zone' : 'Next Destination'}
              </div>
              <div className="truncate font-display text-xs font-bold text-sky-300">
                {telemetry.missionDest.title}
              </div>
            </div>
            <div className="flex shrink-0 items-center gap-1.5">
              <span className="font-tech text-sm font-bold text-purple-300">
                {telemetry.missionDist}m
              </span>
              <button
                type="button"
                onClick={() => onTeleportTo(telemetry.missionDest.id)}
                title="Fast Travel to Destination"
                className="cursor-pointer rounded bg-sky-500/20 px-1.5 py-0.5 text-[10px] font-bold text-sky-300 transition hover:bg-sky-500/35"
              >
                WARP
              </button>
            </div>
          </div>

          {/* 5-Checkpoint Progress Bar Pills */}
          <div className="mt-2 flex flex-wrap gap-1">
            {DESTINATIONS.map((dest) => {
              const done = visitedSet.has(dest.id);
              const isNext = telemetry.missionDest.id === dest.id;
              return (
                <button
                  key={dest.id}
                  type="button"
                  onClick={() => onExploreCheckpoint(dest.id)}
                  title={`Open ${dest.title} (${dest.zoneName})`}
                  className={`flex cursor-pointer items-center gap-1 rounded px-1.5 py-0.5 text-[10px] font-semibold transition ${
                    done
                      ? 'border border-emerald-400/40 bg-emerald-500/15 text-emerald-300'
                      : isNext
                        ? 'border border-sky-400/60 bg-sky-500/20 text-sky-200'
                        : 'border border-slate-700/60 bg-slate-800/60 text-slate-400 hover:text-white'
                  }`}
                >
                  {done && <Check className="h-2.5 w-2.5" />}
                  <span>{dest.shortLabel}</span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Top-Right Utility Controls */}
        <div className="pointer-events-auto relative flex flex-wrap items-center justify-end gap-1.5 sm:gap-2">
          <button
            type="button"
            onClick={() => setShowDestMenu((v) => !v)}
            data-testid="destinations-drawer-btn"
            className="hud-glass flex cursor-pointer items-center gap-1.5 rounded-lg px-2.5 py-2 font-tech text-xs font-bold tracking-wider text-sky-200 transition hover:border-sky-400/80"
          >
            <MapPin className="h-3.5 w-3.5 text-purple-400" />
            <span className="hidden sm:inline">SKIP DRIVING / ZONES</span>
            <span className="sm:hidden">ZONES</span>
          </button>

          <button
            type="button"
            onClick={onCycleTimeOfDay}
            title={`Lighting: ${timeOfDay.toUpperCase()}`}
            className="hud-glass flex cursor-pointer items-center gap-1 rounded-lg px-2.5 py-2 text-xs font-semibold text-slate-200 transition hover:border-sky-400/70"
          >
            <TimeIcon className="h-3.5 w-3.5 text-sky-400" />
            <span className="hidden md:inline uppercase">{timeOfDay}</span>
          </button>

          <button
            type="button"
            onClick={onCycleCamera}
            title="Switch Camera (C)"
            className="hud-glass flex cursor-pointer items-center gap-1 rounded-lg px-2.5 py-2 text-xs font-semibold text-slate-200 transition hover:border-sky-400/70"
          >
            <Camera className="h-3.5 w-3.5 text-purple-400" />
            <span className="hidden md:inline uppercase">{cameraMode}</span>
          </button>

          <button
            type="button"
            onClick={onToggleMute}
            title="Mute / Unmute Audio (M)"
            className="hud-glass cursor-pointer rounded-lg p-2 text-slate-200 transition hover:border-sky-400/70"
          >
            {isMuted ? (
              <VolumeX className="h-4 w-4 text-rose-400" />
            ) : (
              <Volume2 className="h-4 w-4 text-sky-400" />
            )}
          </button>

          <button
            type="button"
            onClick={onResetGame}
            title="Reset Game (R)"
            data-testid="reset-game-btn"
            className="hud-glass cursor-pointer rounded-lg p-2 text-slate-200 transition hover:border-sky-400/70"
          >
            <RotateCcw className="h-4 w-4 text-slate-200" />
          </button>

          <button
            type="button"
            onClick={onTogglePause}
            title="Pause / Resume (P)"
            data-testid="pause-game-btn"
            className="hud-glass cursor-pointer rounded-lg p-2 text-slate-200 transition hover:border-purple-400/80"
          >
            {isPaused ? (
              <Play className="h-4 w-4 text-emerald-400" />
            ) : (
              <Pause className="h-4 w-4 text-purple-300" />
            )}
          </button>

          {/* Direct Destinations Dropdown Menu */}
          {showDestMenu && (
            <div className="hud-glass-purple absolute right-0 top-12 z-40 w-72 rounded-xl p-3 shadow-2xl">
              <div className="mb-2 flex items-center justify-between border-b border-slate-700/70 pb-1.5">
                <span className="font-display text-[11px] font-bold tracking-widest text-sky-300">
                  PORTFOLIO CHECKPOINTS
                </span>
                <button
                  type="button"
                  onClick={() => setShowDestMenu(false)}
                  className="cursor-pointer text-xs text-slate-400 hover:text-white"
                >
                  ✕
                </button>
              </div>
              <div className="space-y-1.5">
                {DESTINATIONS.map((d) => (
                  <div
                    key={d.id}
                    className="flex items-center justify-between gap-2 rounded-lg border border-slate-700/60 bg-slate-900/75 p-2"
                  >
                    <button
                      type="button"
                      onClick={() => {
                        setShowDestMenu(false);
                        onExploreCheckpoint(d.id);
                      }}
                      className="flex flex-1 cursor-pointer items-center gap-2 text-left"
                    >
                      <span
                        className="h-2.5 w-2.5 rounded-full"
                        style={{ backgroundColor: d.primaryColor }}
                      />
                      <div>
                        <div className="font-display text-[11px] font-bold text-white">
                          {d.title}
                        </div>
                        <div className="text-[10px] text-slate-400">
                          {d.zoneName}
                        </div>
                      </div>
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        setShowDestMenu(false);
                        onTeleportTo(d.id);
                      }}
                      className="cursor-pointer rounded border border-sky-400/40 bg-sky-500/15 px-2 py-1 text-[10px] font-bold text-sky-300 hover:bg-sky-500/30"
                    >
                      DRIVE
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* CENTER-BOTTOM INTERACTIVE CHECKPOINT PROMPT */}
      {nearbyCheckpoint && !activePanel && !isPaused && (
        <div className="pointer-events-none mx-auto flex justify-center">
          <button
            type="button"
            onClick={() => onExploreCheckpoint(nearbyCheckpoint.id)}
            data-testid="press-e-prompt"
            className="animate-neon-pulse hud-glass-purple pointer-events-auto flex cursor-pointer items-center gap-3 rounded-2xl px-5 py-3 transition hover:scale-105"
          >
            <Sparkles className="h-5 w-5 text-sky-400" />
            <div className="text-left">
              <div className="font-display text-xs font-black tracking-wider text-white sm:text-sm">
                PRESS <span className="rounded bg-sky-500/30 px-2 py-0.5 text-sky-300">E</span> TO EXPLORE
              </div>
              <div className="font-tech text-xs font-semibold tracking-wider text-purple-300">
                {nearbyCheckpoint.title} — {nearbyCheckpoint.zoneName}
              </div>
            </div>
          </button>
        </div>
      )}

      {/* BOTTOM BAR: Live Mini-Map (Left) + AAA Speedometer/Gear/Nitro (Right) */}
      <div
        className={`flex items-end justify-between gap-3 ${
          showTouchControls || isMobile ? 'mb-36 sm:mb-40' : ''
        }`}
      >
        {/* Live SVG Circuit Mini-Map */}
        <div className="hud-glass pointer-events-auto rounded-2xl p-2 sm:p-2.5">
          <svg
            viewBox="0 0 160 160"
            className="h-24 w-24 sm:h-36 sm:w-36"
            aria-label="Circuit Mini-Map"
          >
            <rect
              x="2"
              y="2"
              width="156"
              height="156"
              rx="14"
              fill="rgba(4,7,20,0.85)"
              stroke="rgba(56,189,248,0.22)"
            />
            {/* Cross-town avenues */}
            {CROSS_AVENUES.map((ave, idx) => {
              const [x1, y1] = projectToMiniMap(ave.x1, ave.z1);
              const [x2, y2] = projectToMiniMap(ave.x2, ave.z2);
              return (
                <line
                  key={idx}
                  x1={x1}
                  y1={y1}
                  x2={x2}
                  y2={y2}
                  stroke="rgba(148,163,184,0.25)"
                  strokeWidth="3.5"
                />
              );
            })}
            {/* Main Circuit Loop */}
            <path
              d={MINI_TRACK_PATH}
              fill="none"
              stroke="rgba(56,189,248,0.55)"
              strokeWidth="4.5"
              strokeLinejoin="round"
            />
            {/* Destination Checkpoints */}
            {DESTINATIONS.map((dest) => {
              const [dx, dy] = projectToMiniMap(dest.position[0], dest.position[2]);
              const visited = visitedSet.has(dest.id);
              const isNext = telemetry.missionDest.id === dest.id;
              return (
                <g
                  key={dest.id}
                  onClick={() => onTeleportTo(dest.id)}
                  style={{ cursor: 'pointer' }}
                >
                  {isNext && (
                    <circle
                      cx={dx}
                      cy={dy}
                      r="8"
                      fill="none"
                      stroke={dest.primaryColor}
                      strokeWidth="1.5"
                      opacity="0.8"
                    />
                  )}
                  <circle
                    cx={dx}
                    cy={dy}
                    r="4.6"
                    fill={visited ? '#34d399' : dest.primaryColor}
                    stroke="#020617"
                    strokeWidth="1.2"
                  />
                </g>
              );
            })}
            {/* Player Vehicle Arrow */}
            <g
              transform={`translate(${playerMapX.toFixed(1)}, ${playerMapY.toFixed(
                1
              )}) rotate(${((-telemetry.heading * 180) / Math.PI).toFixed(1)})`}
            >
              <polygon
                points="0,-6.5 4.8,5.2 0,2.8 -4.8,5.2"
                fill="#ffffff"
                stroke="#38bdf8"
                strokeWidth="1.2"
              />
            </g>
          </svg>
        </div>

        {/* Bottom-Right AAA Speedometer / Gear / Nitro Telemetry Cluster */}
        <div
          data-testid="telemetry-cluster"
          className="hud-glass-purple pointer-events-auto flex items-center gap-3 rounded-2xl px-3.5 py-2.5 sm:px-5 sm:py-3.5"
        >
          {/* Tachometer Arc + Speed Readout */}
          <div className="relative flex h-20 w-24 items-center justify-center sm:h-24 sm:w-28">
            <svg viewBox="0 0 120 100" className="h-full w-full">
              <path
                d="M 18 82 A 46 46 0 1 1 102 82"
                fill="none"
                stroke="rgba(51,65,85,0.55)"
                strokeWidth="7"
                strokeLinecap="round"
              />
              <path
                d="M 18 82 A 46 46 0 1 1 102 82"
                fill="none"
                stroke={telemetry.isBoosting ? '#c084fc' : '#38bdf8'}
                strokeWidth="7"
                strokeLinecap="round"
                strokeDasharray={arcLen}
                strokeDashoffset={rpmDash}
              />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center pt-2">
              <span
                data-testid="speedometer-value"
                className="font-display text-2xl font-black leading-none text-white sm:text-3xl"
              >
                {telemetry.speedKmh}
              </span>
              <span className="font-tech text-[10px] font-bold tracking-[0.2em] text-sky-300">
                KM/H
              </span>
            </div>
          </div>

          {/* Gear & Nitro Column */}
          <div className="flex flex-col gap-2">
            <div className="flex items-center gap-2">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl border border-sky-400/50 bg-sky-500/15 font-display text-lg font-black text-sky-300">
                {telemetry.gear}
              </div>
              <div className="space-y-0.5 text-[10px]">
                <div className="font-bold tracking-widest text-slate-400">
                  GEAR
                </div>
                <div className="flex items-center gap-1">
                  {telemetry.isBoosting && (
                    <span className="rounded bg-purple-500/30 px-1.5 py-0.5 font-bold text-purple-200">
                      NITRO
                    </span>
                  )}
                  {telemetry.isDrifting && (
                    <span className="rounded bg-amber-500/25 px-1.5 py-0.5 font-bold text-amber-300">
                      DRIFT
                    </span>
                  )}
                  {!telemetry.isBoosting && !telemetry.isDrifting && (
                    <span className="font-tech text-slate-300">
                      {Math.round(telemetry.rpm)} RPM
                    </span>
                  )}
                </div>
              </div>
            </div>

            {/* Nitro Gauge */}
            <div className="w-28 sm:w-32">
              <div className="mb-1 flex items-center justify-between text-[10px] font-bold">
                <span className="inline-flex items-center gap-1 text-cyan-300">
                  <Flame className="h-3 w-3" /> NITRO
                </span>
                <span className="text-slate-300">{Math.round(telemetry.nitro)}%</span>
              </div>
              <div className="h-2 w-full overflow-hidden rounded-full bg-slate-800">
                <div
                  className="h-full rounded-full bg-gradient-to-r from-sky-400 via-blue-500 to-purple-500 transition-all duration-75"
                  style={{ width: `${telemetry.nitro}%` }}
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* PAUSE OVERLAY MODAL */}
      {isPaused && !activePanel && (
        <div className="pointer-events-auto absolute inset-0 z-40 flex items-center justify-center bg-[#040614]/80 p-4 backdrop-blur-md">
          <div className="hud-glass-purple w-full max-w-lg rounded-2xl p-6">
            <div className="flex items-center justify-between border-b border-slate-700/70 pb-3">
              <div>
                <div className="font-tech text-xs font-bold tracking-[0.2em] text-sky-400">
                  SYSTEM PAUSED
                </div>
                <h2 className="font-display text-xl font-black text-white">
                  RACE CONTROL &amp; QUICK ACCESS
                </h2>
              </div>
              <Flag className="h-6 w-6 text-purple-400" />
            </div>

            <div className="mt-4 grid grid-cols-1 gap-2.5 sm:grid-cols-2">
              <button
                type="button"
                onClick={onTogglePause}
                className="flex cursor-pointer items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-sky-500 to-blue-600 px-4 py-3 font-display text-xs font-bold tracking-wider text-white"
              >
                <Play className="h-4 w-4 fill-current" /> RESUME DRIVING
              </button>
              <button
                type="button"
                onClick={onResetGame}
                className="flex cursor-pointer items-center justify-center gap-2 rounded-xl border border-slate-600 bg-slate-800/80 px-4 py-3 font-display text-xs font-bold tracking-wider text-slate-200 hover:border-sky-400/60"
              >
                <RotateCcw className="h-4 w-4" /> RESET CAR / GAME
              </button>
              <button
                type="button"
                onClick={onToggleTouchControls}
                className="flex cursor-pointer items-center justify-center gap-2 rounded-xl border border-slate-700 bg-slate-900/80 px-4 py-2.5 text-xs font-semibold text-slate-200 hover:border-purple-400/60"
              >
                <Gamepad2 className="h-4 w-4 text-purple-400" />
                Touch Pedals: {showTouchControls ? 'ON' : 'AUTO'}
              </button>
              <button
                type="button"
                onClick={onCycleTimeOfDay}
                className="flex cursor-pointer items-center justify-center gap-2 rounded-xl border border-slate-700 bg-slate-900/80 px-4 py-2.5 text-xs font-semibold text-slate-200 hover:border-sky-400/60"
              >
                <TimeIcon className="h-4 w-4 text-sky-400" />
                Sky Mode: {timeOfDay.toUpperCase()}
              </button>
            </div>

            <div className="mt-5">
              <div className="mb-2 font-tech text-xs font-bold tracking-[0.18em] text-purple-300">
                SKIP DRIVING — OPEN ANY SECTION DIRECTLY
              </div>
              <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
                {DESTINATIONS.map((d) => (
                  <button
                    key={d.id}
                    type="button"
                    onClick={() => onExploreCheckpoint(d.id)}
                    className="flex cursor-pointer items-center gap-2 rounded-lg border border-slate-700/70 bg-slate-900/70 px-3 py-2 text-left text-xs font-semibold text-slate-200 hover:border-sky-400/70 hover:text-sky-300"
                  >
                    <span
                      className="h-2 w-2 shrink-0 rounded-full"
                      style={{ backgroundColor: d.primaryColor }}
                    />
                    <span className="truncate">{d.title}</span>
                  </button>
                ))}
              </div>
            </div>

            <div className="mt-5 flex items-center justify-between border-t border-slate-700/70 pt-3 text-xs text-slate-400">
              <a href="/" className="hover:text-sky-300">
                ← Main Portfolio (/)
              </a>
              <a href="/v3/" className="hover:text-purple-300">
                3D Solar System (/v3) →
              </a>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
