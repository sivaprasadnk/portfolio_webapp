import { describe, expect, it } from 'vitest';
import {
  createInitialCarState,
  findNearestCheckpoint,
  getNextMissionDestination,
  stepCarPhysics,
  type ControlInput,
} from './physics';
import { CITY_BUILDINGS, isPointNearDriveway } from './trackData';
import { DESTINATIONS, SKILLS_DATA } from '../data/portfolioData';

const IDLE_INPUT: ControlInput = {
  throttle: false,
  brake: false,
  steerLeft: false,
  steerRight: false,
  handbrake: false,
  nitro: false,
};

describe('Racing Portfolio Physics & Track World', () => {
  it('accelerates smoothly, upshifts gears, and brakes into reverse', () => {
    let car = createInitialCarState(0, 16, 0);
    expect(car.gear).toBe('N');

    for (let i = 0; i < 120; i++) {
      car = stepCarPhysics(car, { ...IDLE_INPUT, throttle: true }, 0.016, []);
    }
    expect(car.speedKmh).toBeGreaterThan(100);
    expect(car.z).toBeLessThan(16);
    expect(['2', '3', '4', '5', '6']).toContain(car.gear);

    // Hold brake to stop and engage reverse gear
    for (let i = 0; i < 180; i++) {
      car = stepCarPhysics(car, { ...IDLE_INPUT, brake: true }, 0.016, []);
    }
    expect(car.gear).toBe('R');
    expect(car.isReversing).toBe(true);
    expect(car.forwardSpeed).toBeLessThan(0);
  });

  it('activates nitro boost for higher top speed and recharges while drifting', () => {
    let car = createInitialCarState(0, 16, 0);
    for (let i = 0; i < 80; i++) {
      car = stepCarPhysics(
        car,
        { ...IDLE_INPUT, throttle: true, nitro: true },
        0.016,
        []
      );
    }
    expect(car.isBoosting).toBe(true);
    expect(car.nitro).toBeLessThan(100);

    const nitroAfterBoost = car.nitro;
    // Steer + handbrake drift to recharge nitro faster
    for (let i = 0; i < 40; i++) {
      car = stepCarPhysics(
        car,
        { ...IDLE_INPUT, steerLeft: true, handbrake: true },
        0.016,
        []
      );
    }
    expect(car.nitro).toBeGreaterThan(nitroAfterBoost);
  });

  it('resolves collisions against city buildings without tunneling', () => {
    const collider = {
      x: 0,
      z: 0,
      halfW: 8,
      halfD: 8,
      height: 40,
      variant: 0 as const,
      accentHue: 'blue' as const,
      rooftopBeacon: true,
    };
    let car = createInitialCarState(0, 14, 0);
    for (let i = 0; i < 140; i++) {
      car = stepCarPhysics(
        car,
        { ...IDLE_INPUT, throttle: true },
        0.016,
        [collider]
      );
    }
    // Car radius + halfD keeps car outside building AABB
    expect(car.z).toBeGreaterThanOrEqual(8);
  });

  it('keeps all generated city skyscrapers off roads and destination plazas', () => {
    for (const d of DESTINATIONS) {
      const nearestBldg = CITY_BUILDINGS.reduce((min, b) => {
        const dist = Math.hypot(b.x - d.position[0], b.z - d.position[2]);
        return Math.min(min, dist);
      }, Infinity);
      expect(nearestBldg).toBeGreaterThan(20);
    }
    expect(isPointNearDriveway(0, -84, 1)).toBe(true);
  });

  it('detects all 5 checkpoints, 11 required skills, and mission progression', () => {
    expect(DESTINATIONS.map((d) => d.title)).toEqual([
      'ABOUT ME',
      'EXPERIENCE',
      'PROJECTS',
      'SKILLS',
      'CONTACT ME',
    ]);
    expect(SKILLS_DATA.map((s) => s.name)).toEqual([
      'Flutter',
      'Dart',
      'Firebase',
      'Supabase',
      'Node.js',
      'REST APIs',
      'Riverpod',
      'Bloc',
      'Clean Architecture',
      'GitHub Actions',
      'CI/CD',
    ]);

    const prox = findNearestCheckpoint(0, -80);
    expect(prox.destination?.id).toBe('about');
    expect(prox.isInside).toBe(true);

    const visited = new Set<'about' | 'experience' | 'projects' | 'skills' | 'contact'>(['about']);
    const next = getNextMissionDestination(visited, 0, -80, 0);
    expect(next.destination.id).toBe('experience');
    expect(next.allVisited).toBe(false);
  });
});
