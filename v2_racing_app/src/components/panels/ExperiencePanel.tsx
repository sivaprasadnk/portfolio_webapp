import { useState } from 'react';
import { Briefcase, Calendar, CheckCircle2, Flag, Layers, Trophy } from 'lucide-react';
import { EXPERIENCE_DATA } from '../../data/portfolioData';

export function ExperiencePanel() {
  const [selectedId, setSelectedId] = useState(EXPERIENCE_DATA[0].id);
  const active =
    EXPERIENCE_DATA.find((e) => e.id === selectedId) ?? EXPERIENCE_DATA[0];

  return (
    <div className="space-y-5">
      {/* Pit-Stop Bay Selector Strip */}
      <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
        {EXPERIENCE_DATA.map((exp) => {
          const isSelected = exp.id === active.id;
          return (
            <button
              key={exp.id}
              type="button"
              onClick={() => setSelectedId(exp.id)}
              className={`cursor-pointer rounded-xl border p-4 text-left transition ${
                isSelected
                  ? 'border-sky-400/80 bg-sky-500/15 shadow-[0_0_24px_rgba(56,189,248,0.2)]'
                  : 'border-slate-700/70 bg-slate-900/60 hover:border-slate-500'
              }`}
            >
              <div className="flex items-center justify-between gap-2">
                <span
                  className="rounded px-2 py-0.5 font-display text-[10px] font-black"
                  style={{
                    backgroundColor: `${exp.accent}25`,
                    color: exp.accent,
                  }}
                >
                  {exp.bayNumber}
                </span>
                <span className="font-tech text-xs font-semibold text-slate-400">
                  {exp.period}
                </span>
              </div>
              <div className="mt-2 font-display text-sm font-bold text-white">
                {exp.company}
              </div>
              <div className="mt-0.5 text-xs font-medium text-sky-300">
                {exp.role}
              </div>
            </button>
          );
        })}
      </div>

      {/* Active Pit-Bay Telemetry Dossier */}
      <div className="rounded-2xl border border-purple-400/35 bg-slate-900/65 p-5 sm:p-6">
        <div className="flex flex-wrap items-start justify-between gap-3 border-b border-slate-700/70 pb-4">
          <div>
            <div className="inline-flex items-center gap-2 font-tech text-xs font-bold tracking-[0.18em] text-purple-300">
              <Flag className="h-3.5 w-3.5 text-sky-400" />
              {active.durationTag}
            </div>
            <h3 className="mt-1 font-display text-xl font-black text-white sm:text-2xl">
              {active.role}
            </h3>
            <div className="mt-1 flex flex-wrap items-center gap-3 text-sm text-sky-300">
              <span className="inline-flex items-center gap-1.5 font-semibold">
                <Briefcase className="h-4 w-4" />
                {active.company}
              </span>
              <span className="inline-flex items-center gap-1.5 text-xs text-slate-400">
                <Calendar className="h-3.5 w-3.5" />
                {active.period}
              </span>
            </div>
          </div>

          <span
            className="rounded-xl border px-3 py-1.5 font-display text-xs font-black"
            style={{
              borderColor: `${active.accent}66`,
              backgroundColor: `${active.accent}18`,
              color: active.accent,
            }}
          >
            {active.bayNumber} TELEMETRY
          </span>
        </div>

        <div className="mt-5 grid grid-cols-1 gap-5 lg:grid-cols-[1.4fr_1fr]">
          {/* Key Responsibilities */}
          <div className="space-y-3">
            <div className="font-display text-xs font-bold tracking-widest text-sky-300">
              KEY RESPONSIBILITIES &amp; EXECUTION
            </div>
            <div className="space-y-2.5">
              {active.responsibilities.map((item) => (
                <div
                  key={item}
                  className="flex items-start gap-2.5 rounded-xl border border-slate-800 bg-slate-950/60 p-3 text-sm text-slate-200"
                >
                  <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-sky-400" />
                  <span>{item}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Tech Stack & Key Achievement */}
          <div className="space-y-4">
            <div className="rounded-xl border border-slate-800 bg-slate-950/60 p-4">
              <div className="mb-2.5 flex items-center gap-2 font-display text-xs font-bold tracking-widest text-purple-300">
                <Layers className="h-4 w-4 text-sky-400" />
                TECHNOLOGIES DEPLOYED
              </div>
              <div className="flex flex-wrap gap-2">
                {active.technologies.map((tech) => (
                  <span
                    key={tech}
                    className="rounded-lg border border-sky-400/30 bg-sky-500/10 px-2.5 py-1 font-tech text-xs font-bold text-sky-200"
                  >
                    {tech}
                  </span>
                ))}
              </div>
            </div>

            <div className="rounded-xl border border-emerald-400/30 bg-emerald-500/10 p-4">
              <div className="mb-1.5 flex items-center gap-2 font-display text-xs font-bold tracking-widest text-emerald-300">
                <Trophy className="h-4 w-4" />
                PIT-STOP MILESTONE
              </div>
              <p className="text-xs leading-relaxed text-emerald-100 sm:text-sm">
                {active.achievement}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
