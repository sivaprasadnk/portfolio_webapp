import * as THREE from 'three';
import { DESTINATIONS } from '../data/portfolioData';

export const WORLD_BOUND = 205;
export const ROAD_WIDTH = 17.5;
export const ROAD_HALF_WIDTH = ROAD_WIDTH * 0.5;

export interface TrackSample {
  x: number;
  z: number;
  tx: number; // unit tangent x
  tz: number; // unit tangent z
  nx: number; // unit right normal x
  nz: number; // unit right normal z
}

export interface StraightRoad {
  x1: number;
  z1: number;
  x2: number;
  z2: number;
  width: number;
}

export interface BuildingFootprint {
  x: number;
  z: number;
  halfW: number;
  halfD: number;
  height: number;
  variant: 0 | 1 | 2;
  accentHue: 'blue' | 'purple' | 'cyan';
  rooftopBeacon: boolean;
}

export interface StreetLightPlacement {
  x: number;
  z: number;
  angle: number;
  side: 1 | -1;
}

export interface TreePlacement {
  x: number;
  z: number;
  scale: number;
}

/**
 * Closed-loop Grand Prix neon circuit passing cleanly near all 5 portfolio zones.
 */
export const TRACK_WAYPOINTS: [number, number][] = [
  [-62, -96],
  [0, -84], // North Citadel Plaza (ABOUT ME)
  [78, -98],
  [126, -56], // East Pit-Stop Complex (EXPERIENCE)
  [140, 28],
  [116, 108], // SE Showcase Garage (PROJECTS)
  [44, 134],
  [-40, 134],
  [-108, 112], // SW Quantum Tech Zone (SKILLS)
  [-136, 36],
  [-118, -48], // West Finish Line (CONTACT ME)
];

/**
 * Cross-town downtown avenues linking the start boulevard directly to ABOUT ME
 * and connecting opposite districts so visitors can freely explore or take shortcuts.
 */
export const CROSS_AVENUES: StraightRoad[] = [
  // North-South Central Skyline Avenue (Start Grid at z=16 straight North into ABOUT ME at z=-84)
  { x1: 0, z1: -86, x2: 0, z2: 128, width: 15 },
  // East-West Midtown Neon Avenue
  { x1: -136, z1: 14, x2: 140, z2: 14, width: 14 },
];

export function buildTrackCurve(): THREE.CatmullRomCurve3 {
  const pts = TRACK_WAYPOINTS.map(([x, z]) => new THREE.Vector3(x, 0, z));
  return new THREE.CatmullRomCurve3(pts, true, 'catmullrom', 0.45);
}

export function sampleClosedTrack(count = 260): TrackSample[] {
  const curve = buildTrackCurve();
  const samples: TrackSample[] = [];
  for (let i = 0; i < count; i++) {
    const t = i / count;
    const p = curve.getPointAt(t);
    const tangent = curve.getTangentAt(t).setY(0).normalize();
    const nx = tangent.z;
    const nz = -tangent.x;
    samples.push({
      x: p.x,
      z: p.z,
      tx: tangent.x,
      tz: tangent.z,
      nx,
      nz,
    });
  }
  return samples;
}

export const TRACK_SAMPLES: TrackSample[] = sampleClosedTrack(260);

function distToSegmentSq(
  px: number,
  pz: number,
  x1: number,
  z1: number,
  x2: number,
  z2: number
): number {
  const dx = x2 - x1;
  const dz = z2 - z1;
  const lenSq = dx * dx + dz * dz;
  if (lenSq < 1e-6) return (px - x1) * (px - x1) + (pz - z1) * (pz - z1);
  const t = Math.max(0, Math.min(1, ((px - x1) * dx + (pz - z1) * dz) / lenSq));
  const cx = x1 + t * dx;
  const cz = z1 + t * dz;
  return (px - cx) * (px - cx) + (pz - cz) * (pz - cz);
}

export function isPointNearDriveway(
  x: number,
  z: number,
  clearanceRadius: number
): boolean {
  // Keep clear of start plaza
  if (Math.hypot(x - 0, z - 16) < 22 + clearanceRadius) return true;

  // Keep clear of all 5 portfolio checkpoints
  for (const d of DESTINATIONS) {
    const dist = Math.hypot(x - d.position[0], z - d.position[2]);
    if (dist < 26 + clearanceRadius) return true;
  }

  // Keep clear of circuit ribbon
  const trackMin = ROAD_HALF_WIDTH + 5.5 + clearanceRadius;
  const trackMinSq = trackMin * trackMin;
  for (let i = 0; i < TRACK_SAMPLES.length; i += 2) {
    const s = TRACK_SAMPLES[i];
    const dSq = (x - s.x) * (x - s.x) + (z - s.z) * (z - s.z);
    if (dSq < trackMinSq) return true;
  }

  // Keep clear of cross-town avenues
  for (const ave of CROSS_AVENUES) {
    const aveClear = ave.width * 0.5 + 5.5 + clearanceRadius;
    if (
      distToSegmentSq(x, z, ave.x1, ave.z1, ave.x2, ave.z2) <
      aveClear * aveClear
    ) {
      return true;
    }
  }

  return false;
}

function seededRandom(seed: number): () => number {
  let s = seed >>> 0;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 4294967296;
  };
}

export function generateCityBuildings(): BuildingFootprint[] {
  const rand = seededRandom(20261123);
  const buildings: BuildingFootprint[] = [];
  const candidates: Array<{ x: number; z: number; inner: boolean }> = [];

  // Inner skyline blocks (quadrants around downtown cross-roads)
  for (let gx = -165; gx <= 165; gx += 26) {
    for (let gz = -165; gz <= 165; gz += 26) {
      const jitterX = (rand() - 0.5) * 9;
      const jitterZ = (rand() - 0.5) * 9;
      const x = gx + jitterX;
      const z = gz + jitterZ;
      const inner = Math.abs(x) < 120 && Math.abs(z) < 120;
      candidates.push({ x, z, inner });
    }
  }

  // Outer perimeter towering skyline outside circuit
  for (let a = 0; a < 48; a++) {
    const angle = (a / 48) * Math.PI * 2;
    const radius = 166 + rand() * 34;
    candidates.push({
      x: Math.cos(angle) * radius,
      z: Math.sin(angle) * radius,
      inner: false,
    });
  }

  for (let i = 0; i < candidates.length; i++) {
    const c = candidates[i];
    if (Math.abs(c.x) > WORLD_BOUND - 14 || Math.abs(c.z) > WORLD_BOUND - 14) {
      continue;
    }

    const halfW = (c.inner ? 5.2 : 6.8) + rand() * 4.5;
    const halfD = (c.inner ? 5.2 : 6.8) + rand() * 4.5;
    const boundRadius = Math.hypot(halfW, halfD);

    if (isPointNearDriveway(c.x, c.z, boundRadius)) {
      continue;
    }

    // Prevent building-to-building overlap
    let overlaps = false;
    for (const existing of buildings) {
      const minSep = boundRadius + Math.hypot(existing.halfW, existing.halfD) + 2.5;
      if (Math.hypot(c.x - existing.x, c.z - existing.z) < minSep) {
        overlaps = true;
        break;
      }
    }
    if (overlaps) continue;

    const variant = (i % 3) as 0 | 1 | 2;
    const accentHue: BuildingFootprint['accentHue'] =
      i % 5 === 0 ? 'purple' : i % 2 === 0 ? 'blue' : 'cyan';
    const height = (c.inner ? 26 : 36) + rand() * (c.inner ? 48 : 66);

    buildings.push({
      x: c.x,
      z: c.z,
      halfW,
      halfD,
      height,
      variant,
      accentHue,
      rooftopBeacon: rand() > 0.35,
    });
  }

  return buildings;
}

export const CITY_BUILDINGS: BuildingFootprint[] = generateCityBuildings();

export function generateStreetLights(): StreetLightPlacement[] {
  const lights: StreetLightPlacement[] = [];
  const step = 10;
  for (let i = 0; i < TRACK_SAMPLES.length; i += step) {
    const s = TRACK_SAMPLES[i];
    const side: 1 | -1 = (i / step) % 2 === 0 ? 1 : -1;
    const offset = (ROAD_HALF_WIDTH + 1.55) * side;
    const lx = s.x + s.nx * offset;
    const lz = s.z + s.nz * offset;

    // Skip lights inside checkpoint plazas so landmarks stay unobstructed
    let nearZone = false;
    for (const d of DESTINATIONS) {
      if (Math.hypot(lx - d.position[0], lz - d.position[2]) < 21) {
        nearZone = true;
        break;
      }
    }
    if (nearZone) continue;

    // Orient light arm toward road centerline
    const angle = Math.atan2(s.x - lx, s.z - lz);
    lights.push({ x: lx, z: lz, angle, side });
  }
  return lights;
}

export const STREET_LIGHTS: StreetLightPlacement[] = generateStreetLights();

export function generateTrees(): TreePlacement[] {
  const rand = seededRandom(88421);
  const trees: TreePlacement[] = [];
  for (let i = 0; i < TRACK_SAMPLES.length; i += 7) {
    const s = TRACK_SAMPLES[i];
    const side = i % 14 === 0 ? 1 : -1;
    const dist = ROAD_HALF_WIDTH + 3.8 + rand() * 2.5;
    const tx = s.x + s.nx * dist * side;
    const tz = s.z + s.nz * dist * side;

    if (isPointNearDriveway(tx, tz, 1.4)) {
      // Only place along roadside shoulder, not inside checkpoints/cross-roads
      let insideCheckpoint = false;
      for (const d of DESTINATIONS) {
        if (Math.hypot(tx - d.position[0], tz - d.position[2]) < 24) {
          insideCheckpoint = true;
          break;
        }
      }
      if (insideCheckpoint) continue;

      let onBuilding = false;
      for (const b of CITY_BUILDINGS) {
        if (
          Math.abs(tx - b.x) < b.halfW + 2 &&
          Math.abs(tz - b.z) < b.halfD + 2
        ) {
          onBuilding = true;
          break;
        }
      }
      if (onBuilding) continue;

      // Ensure not inside cross avenues
      let onAve = false;
      for (const ave of CROSS_AVENUES) {
        if (
          distToSegmentSq(tx, tz, ave.x1, ave.z1, ave.x2, ave.z2) <
          (ave.width * 0.5 + 2.2) ** 2
        ) {
          onAve = true;
          break;
        }
      }
      if (onAve) continue;

      trees.push({ x: tx, z: tz, scale: 0.85 + rand() * 0.45 });
    }
  }
  return trees;
}

export const CITY_TREES: TreePlacement[] = generateTrees();
