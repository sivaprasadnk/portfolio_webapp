import { ArrowUpRight, Compass, Flame, Gauge, Play, Sparkles } from 'lucide-react';

interface StartScreenProps {
  onStartEngine: () => void;
  onSkipDriving: () => void;
}

export function StartScreen({
  onStartEngine,
  onSkipDriving,
}: StartScreenProps) {
  return (
    <div className="pointer-events-none absolute inset-0 z-30 flex flex-col justify-between p-4 sm:p-8">
      {/* Subtle Top & Bottom Vignette Readability Gradients (leave center clear for orbiting car) */}
      <div className="pointer-events-none absolute inset-x-0 top-0 h-44 bg-gradient-to-b from-[#040614]/85 via-[#040614]/40 to-transparent" />
      <div className="pointer-events-none absolute inset-x-0 bottom-0 h-72 bg-gradient-to-t from-[#040614]/95 via-[#040614]/70 to-transparent" />

      {/* Top Header Strip */}
      <div className="relative z-10 flex flex-wrap items-center justify-between gap-3">
        <div className="hud-glass pointer-events-auto inline-flex items-center gap-2.5 rounded-full px-4 py-2">
          <span className="h-2.5 w-2.5 animate-pulse rounded-full bg-sky-400 shadow-[0_0_12px_#38bdf8]" />
          <span className="font-display text-xs font-bold tracking-[0.2em] text-sky-300">
            SPNK // PORTFOLIO CIRCUIT v2
          </span>
        </div>

        <div className="pointer-events-auto flex items-center gap-2">
          <a
            href="/"
            className="hud-glass inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-semibold text-slate-200 transition hover:border-sky-400/70 hover:text-sky-300"
          >
            <span>Main Grid</span>
            <ArrowUpRight className="h-3.5 w-3.5 text-sky-400" />
          </a>
          <a
            href="/v3/"
            className="hud-glass inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-semibold text-slate-200 transition hover:border-purple-400/70 hover:text-purple-300"
          >
            <span>3D Solar /v3</span>
            <ArrowUpRight className="h-3.5 w-3.5 text-purple-400" />
          </a>
        </div>
      </div>

      {/* Bottom Hero Launch Console */}
      <div className="relative z-10 mx-auto w-full max-w-4xl">
        <div className="hud-glass-purple pointer-events-auto rounded-2xl p-5 sm:p-7">
          <div className="flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
            <div className="space-y-2">
              <div className="inline-flex items-center gap-2 rounded-full border border-purple-400/40 bg-purple-500/15 px-3 py-1 text-[11px] font-semibold tracking-widest text-purple-200">
                <Sparkles className="h-3.5 w-3.5 text-sky-400" />
                OPEN-WORLD 3D RACING PORTFOLIO
              </div>
              <h1 className="font-display text-2xl font-black tracking-wide text-white neon-text-blue sm:text-4xl">
                SIVA PRASAD N K
              </h1>
              <p className="font-tech text-base font-semibold tracking-wider text-sky-300 sm:text-lg">
                SENIOR FLUTTER DEVELOPER &nbsp;•&nbsp; 3.9+ YEARS &nbsp;•&nbsp; MOBILE & WEB ARCHITECTURE
              </p>
              <p className="max-w-xl text-xs leading-relaxed text-slate-300 sm:text-sm">
                Take the wheel across a neon futuristic city circuit. Reach 5 glowing checkpoints
                <span className="text-sky-300"> (About Me, Experience Pit-Stop, Projects Garage, Skills Tech Zone & Finish Line)</span>
                — or skip straight to any dossier.
              </p>
            </div>

            {/* Action Buttons */}
            <div className="flex shrink-0 flex-col gap-2.5 sm:flex-row lg:flex-col">
              <button
                type="button"
                onClick={onStartEngine}
                data-testid="start-engine-btn"
                className="animate-neon-pulse group flex cursor-pointer items-center justify-center gap-2.5 rounded-xl bg-gradient-to-r from-sky-500 via-blue-600 to-purple-600 px-6 py-3.5 font-display text-sm font-extrabold tracking-widest text-white shadow-lg transition hover:scale-[1.02] hover:brightness-110 active:scale-[0.98]"
              >
                <Play className="h-4 w-4 fill-current transition group-hover:translate-x-0.5" />
                START ENGINE
              </button>

              <button
                type="button"
                onClick={onSkipDriving}
                data-testid="skip-driving-btn"
                className="flex cursor-pointer items-center justify-center gap-2 rounded-xl border border-sky-400/35 bg-slate-900/70 px-5 py-2.5 font-tech text-xs font-bold tracking-[0.14em] text-sky-200 transition hover:border-sky-400/80 hover:bg-sky-500/15"
              >
                <Compass className="h-4 w-4 text-purple-400" />
                SKIP DRIVING // DIRECT ACCESS
              </button>
            </div>
          </div>

          {/* Controls Legend Strip */}
          <div className="mt-4 flex flex-wrap items-center gap-2 border-t border-slate-700/60 pt-3.5 text-[11px] text-slate-300">
            <span className="inline-flex items-center gap-1 rounded bg-slate-800/80 px-2 py-0.5 font-semibold text-sky-300">
              <Gauge className="h-3 w-3" /> W / ↑ Accel
            </span>
            <span className="rounded bg-slate-800/80 px-2 py-0.5 font-semibold text-slate-200">
              S / ↓ Brake / Rev
            </span>
            <span className="rounded bg-slate-800/80 px-2 py-0.5 font-semibold text-slate-200">
              A / D Steer
            </span>
            <span className="rounded bg-slate-800/80 px-2 py-0.5 font-semibold text-purple-300">
              SPACE Drift
            </span>
            <span className="inline-flex items-center gap-1 rounded bg-slate-800/80 px-2 py-0.5 font-semibold text-cyan-300">
              <Flame className="h-3 w-3" /> SHIFT Nitro
            </span>
            <span className="rounded bg-slate-800/80 px-2 py-0.5 font-semibold text-amber-300">
              E Explore Zone
            </span>
            <span className="rounded bg-slate-800/80 px-2 py-0.5 text-slate-400">
              Drag Mouse: Orbit Cam · Esc: Back
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
