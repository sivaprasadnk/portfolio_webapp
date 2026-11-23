import { useState } from 'react';
import { Cpu, Layers } from 'lucide-react';
import { SKILLS_DATA, type SkillItem } from '../../data/portfolioData';

type CategoryFilter = 'All' | SkillItem['category'];

const CATEGORIES: CategoryFilter[] = [
  'All',
  'Core',
  'State & Arch',
  'Backend & Cloud',
  'DevOps & Delivery',
];

export function SkillsPanel() {
  const [filter, setFilter] = useState<CategoryFilter>('All');
  const [selectedSkillId, setSelectedSkillId] = useState(SKILLS_DATA[0].id);

  const visibleSkills =
    filter === 'All'
      ? SKILLS_DATA
      : SKILLS_DATA.filter((s) => s.category === filter);

  const activeSkill =
    SKILLS_DATA.find((s) => s.id === selectedSkillId) ?? visibleSkills[0];

  return (
    <div className="space-y-5">
      {/* Category Filter Strip */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex flex-wrap gap-1.5">
          {CATEGORIES.map((cat) => (
            <button
              key={cat}
              type="button"
              onClick={() => setFilter(cat)}
              className={`cursor-pointer rounded-lg px-3 py-1.5 font-tech text-xs font-bold tracking-wider transition ${
                filter === cat
                  ? 'border border-sky-400/70 bg-sky-500/20 text-white'
                  : 'border border-slate-700/70 bg-slate-900/60 text-slate-400 hover:text-white'
              }`}
            >
              {cat.toUpperCase()}
            </button>
          ))}
        </div>

        <div className="inline-flex items-center gap-1.5 font-tech text-xs font-bold text-purple-300">
          <Cpu className="h-4 w-4 text-sky-400" />
          <span>{SKILLS_DATA.length} QUANTUM TECH NODES</span>
        </div>
      </div>

      {/* Selected Skill Deep-Dive Card */}
      <div className="rounded-2xl border border-purple-400/35 bg-slate-900/70 p-4 sm:p-5">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <div className="font-tech text-xs font-bold tracking-widest text-sky-400">
              {activeSkill.category.toUpperCase()} · {activeSkill.years}
            </div>
            <h3 className="font-display text-xl font-black text-white">
              {activeSkill.name}
            </h3>
          </div>
          <div className="flex items-center gap-3">
            <span
              className="font-display text-2xl font-black"
              style={{ color: activeSkill.color }}
            >
              {activeSkill.level}%
            </span>
          </div>
        </div>
        <p className="mt-2 text-sm text-slate-300">{activeSkill.summary}</p>
        <div className="mt-3 h-2 w-full overflow-hidden rounded-full bg-slate-800">
          <div
            className="h-full rounded-full transition-all duration-500"
            style={{
              width: `${activeSkill.level}%`,
              background: `linear-gradient(90deg, ${activeSkill.color}, #a855f7)`,
            }}
          />
        </div>
      </div>

      {/* Interactive 11-Skill Holographic Matrix Grid */}
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {visibleSkills.map((skill) => {
          const isSelected = skill.id === activeSkill.id;
          return (
            <button
              key={skill.id}
              type="button"
              onClick={() => setSelectedSkillId(skill.id)}
              className={`cursor-pointer rounded-xl border p-4 text-left transition ${
                isSelected
                  ? 'border-sky-400/80 bg-sky-500/15 shadow-[0_0_22px_rgba(56,189,248,0.2)]'
                  : 'border-slate-700/70 bg-slate-900/55 hover:border-slate-500'
              }`}
            >
              <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-2">
                  <span
                    className="flex h-7 w-7 items-center justify-center rounded-lg border border-white/10"
                    style={{
                      backgroundColor: `${skill.color}22`,
                      color: skill.color,
                    }}
                  >
                    <Layers className="h-3.5 w-3.5" />
                  </span>
                  <span className="font-display text-sm font-bold text-white">
                    {skill.name}
                  </span>
                </div>
                <span
                  className="font-display text-xs font-black"
                  style={{ color: skill.color }}
                >
                  {skill.level}%
                </span>
              </div>

              <div className="mt-2.5 h-1.5 w-full overflow-hidden rounded-full bg-slate-800">
                <div
                  className="h-full rounded-full transition-all duration-500"
                  style={{
                    width: `${skill.level}%`,
                    backgroundColor: skill.color,
                  }}
                />
              </div>

              <p className="mt-2 line-clamp-2 text-[11px] leading-relaxed text-slate-400">
                {skill.summary}
              </p>
            </button>
          );
        })}
      </div>
    </div>
  );
}
