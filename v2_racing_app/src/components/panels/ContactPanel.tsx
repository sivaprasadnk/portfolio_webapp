import { useState } from 'react';
import {
  Check,
  Copy,
  ExternalLink,
  Flag,
  Github,
  Linkedin,
  Mail,
  MapPin,
  Send,
  Sparkles,
} from 'lucide-react';
import { CONTACT_DATA } from '../../data/portfolioData';

export function ContactPanel() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState('');
  const [copiedEmail, setCopiedEmail] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [formError, setFormError] = useState('');

  const handleCopyEmail = async () => {
    try {
      await navigator.clipboard.writeText(CONTACT_DATA.email);
      setCopiedEmail(true);
      window.setTimeout(() => setCopiedEmail(false), 2000);
    } catch {
      // Clipboard fallback ignored cleanly
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !email.trim() || !message.trim()) {
      setFormError('Please fill in your name, email, and message.');
      return;
    }
    setFormError('');
    setSubmitted(true);

    const subject = encodeURIComponent(
      `Portfolio Racing Inquiry from ${name.trim()}`
    );
    const body = encodeURIComponent(
      `Name: ${name.trim()}\nEmail: ${email.trim()}\n\n${message.trim()}`
    );
    window.open(
      `mailto:${CONTACT_DATA.email}?subject=${subject}&body=${body}`,
      '_blank',
      'noopener'
    );
  };

  return (
    <div className="space-y-6">
      {/* Finish-Line Celebration Banner */}
      <div className="relative overflow-hidden rounded-2xl border border-purple-400/50 bg-gradient-to-r from-sky-500/20 via-purple-600/25 to-blue-600/20 p-5 text-center sm:p-6">
        <div className="inline-flex items-center gap-2 rounded-full border border-sky-400/45 bg-slate-950/75 px-3.5 py-1 font-tech text-xs font-bold tracking-[0.2em] text-sky-300">
          <Flag className="h-3.5 w-3.5 text-purple-400" />
          FINISH LINE CROSSED
          <Sparkles className="h-3.5 w-3.5 text-sky-400" />
        </div>
        <h3 className="mt-2 font-display text-xl font-black tracking-wide text-white neon-text-purple sm:text-3xl">
          {CONTACT_DATA.finishMessage}
        </h3>
        <p className="mx-auto mt-1.5 max-w-xl text-xs text-slate-300 sm:text-sm">
          Available for Senior Flutter Developer roles, cross-platform mobile architecture,
          and interactive Web / 3D frontend collaborations.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">
        {/* Left: Direct Channels & Portfolio Links */}
        <div className="space-y-4">
          <div className="rounded-2xl border border-slate-700/70 bg-slate-900/60 p-5 space-y-3">
            <div className="font-display text-xs font-bold tracking-widest text-sky-300">
              DIRECT TELEMETRY CHANNELS
            </div>

            <div className="flex items-center justify-between gap-2 rounded-xl border border-slate-800 bg-slate-950/65 p-3">
              <a
                href={`mailto:${CONTACT_DATA.email}`}
                className="flex min-w-0 items-center gap-2.5 text-sm font-medium text-white hover:text-sky-300"
              >
                <Mail className="h-4 w-4 shrink-0 text-sky-400" />
                <span className="truncate">{CONTACT_DATA.email}</span>
              </a>
              <button
                type="button"
                onClick={handleCopyEmail}
                className="flex shrink-0 cursor-pointer items-center gap-1 rounded-lg border border-sky-400/40 bg-sky-500/15 px-2.5 py-1 font-tech text-xs font-bold text-sky-200 hover:bg-sky-500/30"
              >
                {copiedEmail ? (
                  <>
                    <Check className="h-3.5 w-3.5 text-emerald-400" />
                    COPIED
                  </>
                ) : (
                  <>
                    <Copy className="h-3.5 w-3.5" />
                    COPY
                  </>
                )}
              </button>
            </div>

            <div className="grid grid-cols-1 gap-2.5 sm:grid-cols-2">
              <a
                href={CONTACT_DATA.linkedin}
                target="_blank"
                rel="noreferrer"
                className="flex items-center justify-between rounded-xl border border-blue-400/35 bg-blue-500/10 p-3 text-xs font-bold text-blue-200 transition hover:bg-blue-500/20"
              >
                <span className="inline-flex items-center gap-2">
                  <Linkedin className="h-4 w-4 text-blue-400" />
                  LinkedIn Profile
                </span>
                <ExternalLink className="h-3.5 w-3.5" />
              </a>

              <a
                href={CONTACT_DATA.github}
                target="_blank"
                rel="noreferrer"
                className="flex items-center justify-between rounded-xl border border-slate-600 bg-slate-800/75 p-3 text-xs font-bold text-slate-100 transition hover:border-sky-400"
              >
                <span className="inline-flex items-center gap-2">
                  <Github className="h-4 w-4 text-sky-300" />
                  GitHub (@sivaprasadnk)
                </span>
                <ExternalLink className="h-3.5 w-3.5" />
              </a>
            </div>

            <div className="flex items-center gap-2 px-1 text-xs text-slate-400">
              <MapPin className="h-3.5 w-3.5 text-purple-400" />
              <span>{CONTACT_DATA.location}</span>
            </div>
          </div>

          <div className="rounded-2xl border border-slate-700/70 bg-slate-900/60 p-5 space-y-2.5">
            <div className="font-display text-xs font-bold tracking-widest text-purple-300">
              PORTFOLIO &amp; PUBLISHER LINKS
            </div>
            <div className="space-y-2">
              {CONTACT_DATA.portfolioLinks.map((item) => (
                <a
                  key={item.label}
                  href={item.url}
                  target={item.external ? '_blank' : undefined}
                  rel={item.external ? 'noreferrer' : undefined}
                  className="flex items-center justify-between rounded-xl border border-slate-800 bg-slate-950/60 px-3.5 py-2.5 text-xs font-semibold text-slate-200 transition hover:border-sky-400/60 hover:text-sky-300"
                >
                  <span>{item.label}</span>
                  <ExternalLink className="h-3.5 w-3.5 text-sky-400" />
                </a>
              ))}
            </div>
          </div>
        </div>

        {/* Right: Interactive Contact Form */}
        <form
          onSubmit={handleSubmit}
          className="rounded-2xl border border-sky-400/30 bg-slate-900/65 p-5 space-y-4"
        >
          <div className="font-display text-xs font-bold tracking-widest text-sky-300">
            SEND A PIT-RADIO MESSAGE
          </div>

          <div>
            <label
              htmlFor="contact-name"
              className="mb-1 block font-tech text-xs font-bold tracking-wider text-slate-300"
            >
              YOUR NAME
            </label>
            <input
              id="contact-name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Alex Mercer / Hiring Lead"
              className="w-full rounded-xl border border-slate-700 bg-slate-950/80 px-3.5 py-2.5 text-sm text-white outline-none focus:border-sky-400"
            />
          </div>

          <div>
            <label
              htmlFor="contact-email"
              className="mb-1 block font-tech text-xs font-bold tracking-wider text-slate-300"
            >
              EMAIL ADDRESS
            </label>
            <input
              id="contact-email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@company.com"
              className="w-full rounded-xl border border-slate-700 bg-slate-950/80 px-3.5 py-2.5 text-sm text-white outline-none focus:border-sky-400"
            />
          </div>

          <div>
            <label
              htmlFor="contact-message"
              className="mb-1 block font-tech text-xs font-bold tracking-wider text-slate-300"
            >
              MESSAGE / PROJECT DETAILS
            </label>
            <textarea
              id="contact-message"
              rows={4}
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Tell me about your team, Flutter roadmap, or project..."
              className="w-full resize-none rounded-xl border border-slate-700 bg-slate-950/80 px-3.5 py-2.5 text-sm text-white outline-none focus:border-sky-400"
            />
          </div>

          {formError && (
            <div className="rounded-lg border border-rose-400/40 bg-rose-500/15 px-3 py-2 text-xs text-rose-200">
              {formError}
            </div>
          )}

          {submitted && (
            <div className="rounded-lg border border-emerald-400/40 bg-emerald-500/15 px-3 py-2 text-xs text-emerald-200">
              Opening your mail client to send directly to {CONTACT_DATA.email}.
            </div>
          )}

          <button
            type="submit"
            className="flex w-full cursor-pointer items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-sky-500 via-blue-600 to-purple-600 px-5 py-3 font-display text-xs font-bold tracking-widest text-white transition hover:brightness-110"
          >
            <Send className="h-4 w-4" />
            DISPATCH MESSAGE
          </button>
        </form>
      </div>
    </div>
  );
}
