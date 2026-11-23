import { ArrowLeft, ArrowRight, ArrowUp, ArrowDown, Flame, Sparkles, Zap } from 'lucide-react';
import type { DestinationConfig, DestinationId } from '../../data/portfolioData';
import type { ControlInput } from '../../world/physics';

interface MobileControlsProps {
  inputRef: React.MutableRefObject<ControlInput>;
  nearbyCheckpoint: DestinationConfig | null;
  onExploreCheckpoint: (id: DestinationId) => void;
}

export function MobileControls({
  inputRef,
  nearbyCheckpoint,
  onExploreCheckpoint,
}: MobileControlsProps) {
  const setControl = (key: keyof ControlInput, value: boolean) => {
    inputRef.current[key] = value;
  };

  const bindPad = (key: keyof ControlInput) => ({
    onPointerDown: (e: React.PointerEvent) => {
      e.preventDefault();
      (e.currentTarget as HTMLElement).setPointerCapture?.(e.pointerId);
      setControl(key, true);
    },
    onPointerUp: (e: React.PointerEvent) => {
      e.preventDefault();
      setControl(key, false);
    },
    onPointerCancel: () => setControl(key, false),
    onLostPointerCapture: () => setControl(key, false),
  });

  return (
    <div
      data-testid="mobile-touch-controls"
      className="pointer-events-none absolute inset-x-0 bottom-0 z-25 flex items-end justify-between p-3 sm:p-5 touch-none select-none"
    >
      {/* Left: Steering Pads */}
      <div className="pointer-events-auto flex items-center gap-2.5">
        <button
          type="button"
          aria-label="Steer Left"
          {...bindPad('steerLeft')}
          className="hud-glass flex h-14 w-14 items-center justify-center rounded-2xl text-sky-300 active:scale-95 active:bg-sky-500/30 sm:h-16 sm:w-16"
        >
          <ArrowLeft className="h-7 w-7" />
        </button>
        <button
          type="button"
          aria-label="Steer Right"
          {...bindPad('steerRight')}
          className="hud-glass flex h-14 w-14 items-center justify-center rounded-2xl text-sky-300 active:scale-95 active:bg-sky-500/30 sm:h-16 sm:w-16"
        >
          <ArrowRight className="h-7 w-7" />
        </button>
      </div>

      {/* Center Action Explore Button if inside checkpoint */}
      {nearbyCheckpoint && (
        <button
          type="button"
          onClick={() => onExploreCheckpoint(nearbyCheckpoint.id)}
          className="animate-neon-pulse hud-glass-purple pointer-events-auto mb-1 flex items-center gap-1.5 rounded-xl px-3.5 py-2.5 font-display text-[11px] font-bold text-white"
        >
          <Sparkles className="h-4 w-4 text-sky-400" />
          OPEN {nearbyCheckpoint.shortLabel}
        </button>
      )}

      {/* Right: Drift / Nitro / Brake / Gas Pedals */}
      <div className="pointer-events-auto flex flex-col items-end gap-2">
        <div className="flex items-center gap-2">
          <button
            type="button"
            aria-label="Handbrake Drift"
            {...bindPad('handbrake')}
            className="hud-glass flex h-11 items-center gap-1 rounded-xl border-amber-400/40 px-3 font-display text-[10px] font-bold text-amber-300 active:scale-95 active:bg-amber-500/25"
          >
            <Zap className="h-3.5 w-3.5" /> DRIFT
          </button>
          <button
            type="button"
            aria-label="Nitro Boost"
            {...bindPad('nitro')}
            className="hud-glass flex h-11 items-center gap-1 rounded-xl border-purple-400/50 px-3 font-display text-[10px] font-bold text-purple-300 active:scale-95 active:bg-purple-500/30"
          >
            <Flame className="h-3.5 w-3.5" /> NITRO
          </button>
        </div>

        <div className="flex items-center gap-2.5">
          <button
            type="button"
            aria-label="Brake or Reverse"
            {...bindPad('brake')}
            className="hud-glass flex h-14 w-14 flex-col items-center justify-center rounded-2xl border-rose-400/40 text-rose-300 active:scale-95 active:bg-rose-500/25 sm:h-16 sm:w-16"
          >
            <ArrowDown className="h-6 w-6" />
            <span className="text-[9px] font-bold">BRK</span>
          </button>
          <button
            type="button"
            aria-label="Accelerate"
            {...bindPad('throttle')}
            className="hud-glass flex h-16 w-16 flex-col items-center justify-center rounded-2xl border-sky-400/60 bg-sky-500/15 text-sky-300 active:scale-95 active:bg-sky-500/35 sm:h-18 sm:w-18"
          >
            <ArrowUp className="h-7 w-7" />
            <span className="text-[9px] font-bold">GAS</span>
          </button>
        </div>
      </div>
    </div>
  );
}
