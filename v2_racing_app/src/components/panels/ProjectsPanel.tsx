import { useState } from 'react';
import { CheckCircle2, Code2, ExternalLink, Github, Monitor, Smartphone } from 'lucide-react';
import { PROJECTS_DATA } from '../../data/portfolioData';

export function ProjectsPanel() {
  const [selectedId, setSelectedId] = useState(PROJECTS_DATA[0].id);
  const active =
    PROJECTS_DATA.find((p) => p.id === selectedId) ?? PROJECTS_DATA[0];

  return (
    <div className="grid grid-cols-1 gap-5 lg:grid-cols-[290px_1fr]">
      {/* Left Garage Bay List */}
      <div className="space-y-2.5">
        <div className="font-display text-xs font-bold tracking-widest text-sky-300">
          GARAGE SHOWCASE ({PROJECTS_DATA.length} BUILDS)
        </div>
        <div className="space-y-2">
          {PROJECTS_DATA.map((proj) => {
            const isSelected = proj.id === active.id;
            return (
              <button
                key={proj.id}
                type="button"
                onClick={() => setSelectedId(proj.id)}
                className={`w-full cursor-pointer rounded-xl border p-3.5 text-left transition ${
                  isSelected
                    ? 'border-sky-400/80 bg-sky-500/15 shadow-[0_0_20px_rgba(56,189,248,0.2)]'
                    : 'border-slate-700/70 bg-slate-900/60 hover:border-slate-500'
                }`}
              >
                <div className="flex items-center justify-between gap-2">
                  <span className="font-display text-xs font-bold text-white">
                    {proj.name}
                  </span>
                  <span
                    className="h-2.5 w-2.5 shrink-0 rounded-full"
                    style={{ backgroundColor: proj.accentColor }}
                  />
                </div>
                <div className="mt-1 text-[11px] text-slate-400">
                  {proj.category}
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Right Holographic Project Spotlight */}
      <div className="rounded-2xl border border-sky-400/30 bg-slate-900/65 p-5 space-y-4">
        {/* Visual Preview Banner */}
        <div
          className={`relative flex h-52 w-full items-center justify-center overflow-hidden rounded-xl border border-slate-700/70 bg-gradient-to-br ${active.previewGradient}`}
        >
          {active.previewImage ? (
            <img
              src={active.previewImage}
              alt={active.name}
              className="h-full w-full object-cover object-top opacity-90"
            />
          ) : (
            <div className="flex flex-col items-center gap-2 px-6 text-center">
              <Monitor className="h-11 w-11 text-sky-300" />
              <div className="font-display text-lg font-black tracking-wide text-white">
                {active.name}
              </div>
              <div className="font-tech text-xs font-semibold tracking-widest text-sky-200">
                {active.technologies.join(' • ')}
              </div>
            </div>
          )}
          <div className="absolute left-3 top-3 rounded-full border border-white/15 bg-slate-950/80 px-3 py-1 font-tech text-[11px] font-bold tracking-wider text-sky-300 backdrop-blur">
            {active.category.toUpperCase()}
          </div>
        </div>

        {/* Title & Description */}
        <div>
          <h3 className="font-display text-xl font-black text-white sm:text-2xl">
            {active.name}
          </h3>
          <p className="mt-0.5 font-tech text-sm font-bold text-purple-300">
            {active.tagline}
          </p>
          <p className="mt-2.5 text-sm leading-relaxed text-slate-300">
            {active.description}
          </p>
        </div>

        {/* Feature Highlights */}
        <div className="space-y-2">
          {active.features.map((feat) => (
            <div
              key={feat}
              className="flex items-start gap-2 rounded-lg border border-slate-800 bg-slate-950/55 px-3 py-2 text-xs text-slate-200"
            >
              <CheckCircle2 className="mt-0.5 h-3.5 w-3.5 shrink-0 text-sky-400" />
              <span>{feat}</span>
            </div>
          ))}
        </div>

        {/* Tech Badges */}
        <div className="flex flex-wrap items-center gap-2">
          <Code2 className="h-4 w-4 text-purple-400" />
          {active.technologies.map((tech) => (
            <span
              key={tech}
              className="rounded-lg border border-purple-400/30 bg-purple-500/10 px-2.5 py-1 font-tech text-xs font-bold text-purple-200"
            >
              {tech}
            </span>
          ))}
        </div>

        {/* Action Links */}
        <div className="flex flex-wrap gap-2.5 border-t border-slate-700/70 pt-3">
          <a
            href={active.githubUrl}
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center gap-2 rounded-xl border border-slate-600 bg-slate-800/80 px-4 py-2 font-tech text-xs font-bold tracking-wider text-white transition hover:border-sky-400"
          >
            <Github className="h-4 w-4" />
            GITHUB PROFILE
            <ExternalLink className="h-3.5 w-3.5" />
          </a>

          {active.liveUrl && (
            <a
              href={active.liveUrl}
              target={active.liveUrl.startsWith('http') ? '_blank' : undefined}
              rel={active.liveUrl.startsWith('http') ? 'noreferrer' : undefined}
              className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-sky-500 to-blue-600 px-4 py-2 font-tech text-xs font-bold tracking-wider text-white transition hover:brightness-110"
            >
              <Monitor className="h-4 w-4" />
              LAUNCH LIVE DEMO
              <ExternalLink className="h-3.5 w-3.5" />
            </a>
          )}

          {active.playStoreUrl && (
            <a
              href={active.playStoreUrl}
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-2 rounded-xl border border-emerald-400/45 bg-emerald-500/15 px-4 py-2 font-tech text-xs font-bold tracking-wider text-emerald-200 transition hover:bg-emerald-500/30"
            >
              <Smartphone className="h-4 w-4" />
              GOOGLE PLAY
              <ExternalLink className="h-3.5 w-3.5" />
            </a>
          )}
        </div>
      </div>
    </div>
  );
}
