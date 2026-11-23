class RacingSoundEngine {
  private ctx: AudioContext | null = null;
  private masterGain: GainNode | null = null;
  private engineGain: GainNode | null = null;
  private oscPrimary: OscillatorNode | null = null;
  private oscHarmonic: OscillatorNode | null = null;
  private engineFilter: BiquadFilterNode | null = null;

  private turboGain: GainNode | null = null;
  private screechGain: GainNode | null = null;

  private muted = false;
  private paused = false;
  private continuousStarted = false;

  private ensureContext(): AudioContext | null {
    if (typeof window === 'undefined') return null;
    if (!this.ctx) {
      const AudioCtx =
        window.AudioContext ||
        (window as unknown as { webkitAudioContext?: typeof AudioContext })
          .webkitAudioContext;
      if (!AudioCtx) return null;
      try {
        this.ctx = new AudioCtx();
        this.masterGain = this.ctx.createGain();
        this.masterGain.gain.value = this.muted ? 0 : 0.42;
        this.masterGain.connect(this.ctx.destination);
      } catch {
        return null;
      }
    }
    if (this.ctx.state === 'suspended') {
      void this.ctx.resume().catch(() => {});
    }
    return this.ctx;
  }

  public unlock(): void {
    this.ensureContext();
  }

  public startContinuous(): void {
    const ctx = this.ensureContext();
    if (!ctx || !this.masterGain || this.continuousStarted) return;

    this.continuousStarted = true;

    // Dual-oscillator supercar V8/V10 exhaust synth
    this.engineFilter = ctx.createBiquadFilter();
    this.engineFilter.type = 'lowpass';
    this.engineFilter.frequency.value = 260;
    this.engineFilter.Q.value = 2.4;

    this.engineGain = ctx.createGain();
    this.engineGain.gain.value = 0.08;

    this.oscPrimary = ctx.createOscillator();
    this.oscPrimary.type = 'sawtooth';
    this.oscPrimary.frequency.value = 52;

    this.oscHarmonic = ctx.createOscillator();
    this.oscHarmonic.type = 'triangle';
    this.oscHarmonic.frequency.value = 104;

    this.oscPrimary.connect(this.engineFilter);
    this.oscHarmonic.connect(this.engineFilter);
    this.engineFilter.connect(this.engineGain);
    this.engineGain.connect(this.masterGain);

    this.oscPrimary.start();
    this.oscHarmonic.start();

    // Shared white-noise buffer for nitro turbine + drift tire screech
    const bufferSize = ctx.sampleRate * 2;
    const noiseBuffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
    const data = noiseBuffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      data[i] = Math.random() * 2 - 1;
    }

    const turboSrc = ctx.createBufferSource();
    turboSrc.buffer = noiseBuffer;
    turboSrc.loop = true;
    const turboFilter = ctx.createBiquadFilter();
    turboFilter.type = 'bandpass';
    turboFilter.frequency.value = 950;
    turboFilter.Q.value = 1.6;
    this.turboGain = ctx.createGain();
    this.turboGain.gain.value = 0;
    turboSrc.connect(turboFilter);
    turboFilter.connect(this.turboGain);
    this.turboGain.connect(this.masterGain);
    turboSrc.start();

    const screechSrc = ctx.createBufferSource();
    screechSrc.buffer = noiseBuffer;
    screechSrc.loop = true;
    const screechFilter = ctx.createBiquadFilter();
    screechFilter.type = 'bandpass';
    screechFilter.frequency.value = 1850;
    screechFilter.Q.value = 7.5;
    this.screechGain = ctx.createGain();
    this.screechGain.gain.value = 0;
    screechSrc.connect(screechFilter);
    screechFilter.connect(this.screechGain);
    this.screechGain.connect(this.masterGain);
    screechSrc.start();
  }

  public updateTelemetry(
    rpm: number,
    speedKmh: number,
    isBoosting: boolean,
    isDrifting: boolean,
    activePlaying: boolean
  ): void {
    if (!this.ctx || !this.continuousStarted) return;
    const now = this.ctx.currentTime;
    const active = activePlaying && !this.paused && !this.muted;

    if (!active) {
      this.engineGain?.gain.setTargetAtTime(0, now, 0.08);
      this.turboGain?.gain.setTargetAtTime(0, now, 0.08);
      this.screechGain?.gain.setTargetAtTime(0, now, 0.08);
      return;
    }

    const normRpm = Math.max(0, Math.min(1, (rpm - 900) / 7600));
    const baseFreq = 46 + normRpm * 135 + (isBoosting ? 24 : 0);

    this.oscPrimary?.frequency.setTargetAtTime(baseFreq, now, 0.04);
    this.oscHarmonic?.frequency.setTargetAtTime(baseFreq * 2.02, now, 0.04);
    this.engineFilter?.frequency.setTargetAtTime(
      220 + normRpm * 1100 + (isBoosting ? 450 : 0),
      now,
      0.05
    );
    this.engineGain?.gain.setTargetAtTime(
      0.075 + normRpm * 0.11 + (speedKmh > 10 ? 0.03 : 0),
      now,
      0.06
    );

    this.turboGain?.gain.setTargetAtTime(isBoosting ? 0.12 : 0.0, now, 0.07);
    this.screechGain?.gain.setTargetAtTime(
      isDrifting && speedKmh > 25 ? 0.085 : 0.0,
      now,
      0.05
    );
  }

  public setMuted(m: boolean): void {
    this.muted = m;
    if (this.ctx && this.masterGain) {
      this.masterGain.gain.setTargetAtTime(
        m || this.paused ? 0 : 0.42,
        this.ctx.currentTime,
        0.05
      );
    }
  }

  public setPaused(p: boolean): void {
    this.paused = p;
    if (this.ctx && this.masterGain) {
      this.masterGain.gain.setTargetAtTime(
        p || this.muted ? 0 : 0.42,
        this.ctx.currentTime,
        0.05
      );
    }
  }

  public playEngineStart(): void {
    const ctx = this.ensureContext();
    if (!ctx || !this.masterGain || this.muted) return;
    this.startContinuous();
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(38, now);
    osc.frequency.exponentialRampToValueAtTime(165, now + 0.35);
    osc.frequency.exponentialRampToValueAtTime(62, now + 0.85);
    gain.gain.setValueAtTime(0.01, now);
    gain.gain.linearRampToValueAtTime(0.26, now + 0.18);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.9);
    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.92);
  }

  public playCheckpointChime(): void {
    const ctx = this.ensureContext();
    if (!ctx || !this.masterGain || this.muted) return;
    const now = ctx.currentTime;
    const freqs = [523.25, 659.25, 783.99, 1046.5];
    freqs.forEach((f, idx) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(f, now + idx * 0.055);
      gain.gain.setValueAtTime(0.001, now + idx * 0.055);
      gain.gain.linearRampToValueAtTime(0.11, now + idx * 0.055 + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.055 + 0.35);
      osc.connect(gain);
      gain.connect(this.masterGain!);
      osc.start(now + idx * 0.055);
      osc.stop(now + idx * 0.055 + 0.38);
    });
  }

  public playFinishFanfare(): void {
    const ctx = this.ensureContext();
    if (!ctx || !this.masterGain || this.muted) return;
    const now = ctx.currentTime;
    const notes = [523.25, 659.25, 783.99, 1046.5, 1318.5];
    notes.forEach((f, idx) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(f, now + idx * 0.08);
      gain.gain.setValueAtTime(0.001, now + idx * 0.08);
      gain.gain.linearRampToValueAtTime(0.16, now + idx * 0.08 + 0.03);
      gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.08 + 0.55);
      osc.connect(gain);
      gain.connect(this.masterGain!);
      osc.start(now + idx * 0.08);
      osc.stop(now + idx * 0.08 + 0.6);
    });
  }

  public playPanelOpen(): void {
    const ctx = this.ensureContext();
    if (!ctx || !this.masterGain || this.muted) return;
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(340, now);
    osc.frequency.exponentialRampToValueAtTime(880, now + 0.18);
    gain.gain.setValueAtTime(0.12, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.22);
    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.24);
  }

  public playPanelClose(): void {
    const ctx = this.ensureContext();
    if (!ctx || !this.masterGain || this.muted) return;
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(660, now);
    osc.frequency.exponentialRampToValueAtTime(260, now + 0.15);
    gain.gain.setValueAtTime(0.1, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.17);
    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.19);
  }

  public playCollisionThud(intensity: number): void {
    const ctx = this.ensureContext();
    if (!ctx || !this.masterGain || this.muted) return;
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(115, now);
    osc.frequency.exponentialRampToValueAtTime(32, now + 0.18);
    gain.gain.setValueAtTime(Math.min(0.28, 0.1 + intensity * 0.2), now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.22);
  }
}

export const soundEngine = new RacingSoundEngine();
