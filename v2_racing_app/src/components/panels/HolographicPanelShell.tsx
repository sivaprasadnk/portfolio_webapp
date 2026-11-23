import type React from 'react';
import { Check, MapPin, Navigation, X } from 'lucide-react';
import {
  DESTINATIONS,
  type DestinationId,
} from '../../data/portfolioData';

interface HolographicPanelShellProps {
  activeId: DestinationId;
  visitedIds: DestinationId[];
  onSelectPanel: (id: DestinationId) => void;
  onTeleportHere: (id: DestinationId) => void;
  onClose: () => void;
  children: React.ReactNode;
}

export function HolographicPanelShell({
  activeId,
  visitedIds,
  onSelectPanel,
  onTeleportHere,
  onClose,
  children,
}: HolographicPanelShellProps) {
  const dest = DESTINATIONS.find((d) => d.id === activeId)!;
  const visitedSet = new Set(visitedIds);

  return (
    <div
      data-testid={`panel-${activeId}`}
      className="fixed inset-0 z-40 flex items-center justify-center bg-[#040614]/72 p-3 backdrop-blur-md sm:p-6"
      onClick={onClose}
    >
      <div
        className="holo-scanlines hud-glass-purple relative flex max-h-[90vh] w-full max-w-5xl flex-col overflow-hidden rounded-2xl border border-sky-400/40"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Top Glowing Neon Accent Line */}
        <div
          className="h-1 w-full"
          style={{
            background: `linear-gradient(90deg, ${dest.primaryColor}, ${dest.secondaryColor}, ${dest.primaryColor})`,
          }}
        />

        {/* Header Bar */}
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-700/70 bg-slate-950/60 px-4 py-3.5 sm:px-6">
          <div className="flex items-center gap-3">
            <span
              className="flex h-9 w-9 items-center justify-center rounded-xl border border-white/15"
              style={{
                background: `${dest.primaryColor}22`,
                boxShadow: `0 0 18px ${dest.primaryColor}45`,
              }}
            >
              <MapPin className="h-4.5 w-4.5" style={{ color: dest.primaryColor }} />
            </span>
            <div>
              <div className="flex items-center gap-2 font-tech text-[11px] font-bold tracking-[0.2em] text-sky-300">
                <span>CHECKPOINT 0{dest.order}</span>
                <span className="text-slate-500">//</span>
                <span className="text-purple-300">{dest.zoneName.toUpperCase()}</span>
              </div>
              <h2 className="font-display text-lg font-black tracking-wide text-white sm:text-xl">
                {dest.title}
              </h2>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => onTeleportHere(activeId)}
              className="hidden cursor-pointer items-center gap-1.5 rounded-lg border border-sky-400/40 bg-sky-500/15 px-3 py-1.5 font-tech text-xs font-bold tracking-wider text-sky-200 transition hover:bg-sky-500/30 sm:inline-flex"
            >
              <Navigation className="h-3.5 w-3.5" />
              PARK CAR HERE
            </button>

            <button
              type="button"
              onClick={onClose}
              data-testid="close-panel-btn"
              className="flex cursor-pointer items-center gap-1.5 rounded-lg border border-purple-400/50 bg-purple-500/20 px-3.5 py-1.5 font-tech text-xs font-bold tracking-wider text-white transition hover:bg-purple-500/35"
            >
              <span>ESC // DRIVE</span>
              <X className="h-4 w-4" />
            </button>
          </div>
        </div>

        {/* Section Quick-Jump Bar */}
        <div className="flex items-center gap-1.5 overflow-x-auto border-b border-slate-800/80 bg-slate-950/45 px-4 py-2 sm:px-6">
          {DESTINATIONS.map((item) => {
            const isCurrent = item.id === activeId;
            const visited = visitedSet.has(item.id);
            return (
              <button
                key={item.id}
                type="button"
                onClick={() => onSelectPanel(item.id)}
                className={`flex shrink-0 cursor-pointer items-center gap-1.5 rounded-lg px-3 py-1.5 font-tech text-xs font-bold tracking-wider transition ${
                  isCurrent
                    ? 'border border-sky-400/70 bg-sky-500/25 text-white'
                    : 'border border-slate-700/60 bg-slate-900/70 text-slate-400 hover:border-slate-500 hover:text-slate-100'
                }`}
              >
                {visited && <Check className="h-3 w-3 text-emerald-400" />}
                <span>{item.title}</span>
              </button>
            );
          })}
        </div>

        {/* Scrollable Content Slot */}
        <div className="holo-scroll flex-1 overflow-y-auto p-4 sm:p-6">
          {children}
        </div>
      </div>
    </div>
  );
}
