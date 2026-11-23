import { Award, CheckCircle2, Code2, Cpu, ExternalLink, FileText, MapPin, Sparkles } from 'lucide-react';
import { ABOUT_DATA } from '../../data/portfolioData';

export function AboutPanel() {
  return (
    <div className="space-y-6">
      {/* Driver Identity Hero Banner */}
      <div className="grid grid-cols-1 gap-5 rounded-2xl border border-sky-400/30 bg-slate-900/65 p-5 lg:grid-cols-[200px_1fr]">
        <div className="relative mx-auto flex h-44 w-44 items-center justify-center overflow-hidden rounded-2xl border-2 border-sky-400/50 bg-gradient-to-br from-sky-500/20 via-slate-900 to-purple-600/25 shadow-[0_0_28px_rgba(56,189,248,0.28)] sm:h-48 sm:w-48">
          <img
            src={ABOUT_DATA.photoUrl}
            alt={ABOUT_DATA.name}
            className="h-full w-full object-cover"
          />
          <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-slate-950/90 to-transparent px-3 py-1.5 text-center font-tech text-[11px] font-bold tracking-widest text-sky-300">
            PILOT ID // SPNK-01
          </div>
        </div>

        <div className="flex flex-col justify-between space-y-4">
          <div>
            <div className="inline-flex items-center gap-2 rounded-full border border-sky-400/40 bg-sky-500/15 px-3 py-1 font-tech text-xs font-bold tracking-widest text-sky-300">
              <Sparkles className="h-3.5 w-3.5" />
              SENIOR MOBILE ENGINEER
            </div>
            <h3 className="mt-2 font-display text-2xl font-black tracking-wide text-white sm:text-3xl">
              {ABOUT_DATA.name}
            </h3>
            <p className="font-tech text-base font-bold tracking-wider text-purple-300 sm:text-lg">
              {ABOUT_DATA.role} &nbsp;•&nbsp; {ABOUT_DATA.experience} Experience
            </p>
            <p className="mt-1 inline-flex items-center gap-1.5 text-xs text-slate-400">
              <MapPin className="h-3.5 w-3.5 text-sky-400" />
              {ABOUT_DATA.location}
            </p>
          </div>

          <div className="rounded-xl border border-purple-400/25 bg-slate-950/60 p-3.5">
            <div className="text-[11px] font-bold uppercase tracking-widest text-sky-400">
              Specialization
            </div>
            <div className="mt-1 font-tech text-base font-semibold text-white">
              {ABOUT_DATA.specialization}
            </div>
          </div>

          <div className="flex flex-wrap gap-2">
            <a
              href={ABOUT_DATA.resumeUrl}
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-sky-500 to-purple-600 px-4 py-2 font-tech text-xs font-bold tracking-wider text-white transition hover:brightness-110"
            >
              <FileText className="h-4 w-4" />
              VIEW RESUME PDF
              <ExternalLink className="h-3.5 w-3.5" />
            </a>
          </div>
        </div>
      </div>

      {/* Telemetry Metric Strip */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {ABOUT_DATA.stats.map((stat) => (
          <div
            key={stat.label}
            className="rounded-xl border border-slate-700/70 bg-slate-900/60 p-3.5 text-center"
          >
            <div className="font-display text-lg font-black text-sky-300 sm:text-xl">
              {stat.value}
            </div>
            <div className="mt-0.5 font-tech text-xs font-semibold uppercase tracking-wider text-slate-400">
              {stat.label}
            </div>
          </div>
        ))}
      </div>

      {/* Professional Introduction */}
      <div className="rounded-2xl border border-slate-700/70 bg-slate-900/55 p-5 space-y-3">
        <div className="flex items-center gap-2 font-display text-xs font-bold tracking-widest text-sky-300">
          <Code2 className="h-4 w-4 text-purple-400" />
          PROFESSIONAL PROFILE
        </div>
        <p className="text-sm leading-relaxed text-slate-200">{ABOUT_DATA.intro}</p>
        <p className="text-sm leading-relaxed text-slate-300">
          {ABOUT_DATA.extendedIntro}
        </p>
      </div>

      {/* Engineering Strengths & Technical Interests */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div className="rounded-2xl border border-slate-700/70 bg-slate-900/55 p-5">
          <div className="mb-3 flex items-center gap-2 font-display text-xs font-bold tracking-widest text-purple-300">
            <Award className="h-4 w-4 text-sky-400" />
            ENGINEERING STRENGTHS
          </div>
          <div className="space-y-3">
            {ABOUT_DATA.highlights.map((h) => (
              <div
                key={h.title}
                className="rounded-xl border border-slate-800 bg-slate-950/55 p-3"
              >
                <div className="flex items-center gap-2 text-sm font-bold text-white">
                  <CheckCircle2 className="h-4 w-4 shrink-0 text-sky-400" />
                  <span>{h.title}</span>
                </div>
                <p className="mt-1 pl-6 text-xs leading-relaxed text-slate-400">
                  {h.detail}
                </p>
              </div>
            ))}
          </div>
        </div>

        <div className="rounded-2xl border border-slate-700/70 bg-slate-900/55 p-5">
          <div className="mb-3 flex items-center gap-2 font-display text-xs font-bold tracking-widest text-sky-300">
            <Cpu className="h-4 w-4 text-purple-400" />
            TECHNICAL INTERESTS &amp; FOCUS
          </div>
          <div className="flex flex-wrap gap-2">
            {ABOUT_DATA.interests.map((item) => (
              <span
                key={item}
                className="rounded-xl border border-sky-400/30 bg-sky-500/10 px-3 py-2 font-tech text-xs font-bold tracking-wide text-sky-200"
              >
                {item}
              </span>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
