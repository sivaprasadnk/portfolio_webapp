import {
  DESTINATIONS,
  type DestinationConfig,
  type DestinationId,
} from '../data/portfolioData';
import {
  CITY_BUILDINGS,
  WORLD_BOUND,
  type BuildingFootprint,
} from './trackData';

export interface ControlInput {
  throttle: boolean;
  brake: boolean;
  steerLeft: boolean;
  steerRight: boolean;
  handbrake: boolean;
  nitro: boolean;
}

export type GearLabel = 'R' | 'N' | '1' | '2' | '3' | '4' | '5' | '6';

export interface CarPhysicsState {
  x: number;
  z: number;
  heading: number; // radians; 0 = facing -Z (North), + = CCW left turn, - = CW right turn
  vx: number; // world velocity m/s
  vz: number;
  forwardSpeed: number; // signed m/s along heading
  lateralSpeed: number; // m/s sideways
  speedKmh: number;
  steerAngle: number; // -0.52 .. +0.52 rad
  wheelSpin: number; // cumulative rad
  rpm: number; // 900 .. 8500
  gear: GearLabel;
  nitro: number; // 0 .. 100
  isBoosting: boolean;
  isDrifting: boolean;
  isBraking: boolean;
  isReversing: boolean;
  pitch: number; // body squat/dive rad
  roll: number; // body corner lean rad
  suspensionBounce: number;
  impactIntensity: number;
}

export interface CheckpointProximity {
  destination: DestinationConfig | null;
  distance: number;
  isInside: boolean;
}

export interface MissionTarget {
  destination: DestinationConfig;
  distance: number;
  bearingRad: number; // angle from car forward to destination
  allVisited: boolean;
}

export const CAR_RADIUS = 1.95;

export function createInitialCarState(
  spawnX = 0,
  spawnZ = 16,
  heading = 0
): CarPhysicsState {
  return {
    x: spawnX,
    z: spawnZ,
    heading,
    vx: 0,
    vz: 0,
    forwardSpeed: 0,
    lateralSpeed: 0,
    speedKmh: 0,
    steerAngle: 0,
    wheelSpin: 0,
    rpm: 950,
    gear: 'N',
    nitro: 100,
    isBoosting: false,
    isDrifting: false,
    isBraking: false,
    isReversing: false,
    pitch: 0,
    roll: 0,
    suspensionBounce: 0,
    impactIntensity: 0,
  };
}

function clamp(v: number, min: number, max: number): number {
  return v < min ? min : v > max ? max : v;
}

function computeGearAndRpm(
  forwardSpeedMs: number,
  isBoosting: boolean
): { gear: GearLabel; rpm: number } {
  const absKmh = Math.abs(forwardSpeedMs) * 3.6;
  if (forwardSpeedMs < -1.0) {
    return {
      gear: 'R',
      rpm: clamp(1400 + absKmh * 68, 1200, 7400),
    };
  }
  if (absKmh < 2.2) {
    return { gear: 'N', rpm: isBoosting ? 3600 : 950 };
  }
  const bands: Array<{ gear: GearLabel; min: number; max: number }> = [
    { gear: '1', min: 0, max: 42 },
    { gear: '2', min: 34, max: 82 },
    { gear: '3', min: 70, max: 132 },
    { gear: '4', min: 118, max: 186 },
    { gear: '5', min: 168, max: 245 },
    { gear: '6', min: 225, max: 340 },
  ];
  for (const b of bands) {
    if (absKmh <= b.max) {
      const ratio = clamp((absKmh - b.min) / Math.max(1, b.max - b.min), 0, 1);
      const rpm = 2300 + ratio * (isBoosting ? 6100 : 5600);
      return { gear: b.gear, rpm: clamp(rpm, 1100, 8600) };
    }
  }
  return { gear: '6', rpm: 8400 };
}

/**
 * Steps arcade-realistic vehicle dynamics + Circle-vs-AABB city collisions.
 */
export function stepCarPhysics(
  state: CarPhysicsState,
  input: ControlInput,
  rawDt: number,
  colliders: BuildingFootprint[] = CITY_BUILDINGS
): CarPhysicsState {
  const dt = Math.min(Math.max(rawDt, 0.001), 0.05);

  // Forward unit vector in Three.js XZ coordinates (heading = 0 -> -Z)
  const fx = -Math.sin(state.heading);
  const fz = -Math.cos(state.heading);
  // Right unit vector (90 deg CW from forward)
  const rx = Math.cos(state.heading);
  const rz = -Math.sin(state.heading);

  let vForward = state.vx * fx + state.vz * fz;
  let vLateral = state.vx * rx + state.vz * rz;

  const canBoost = input.nitro && state.nitro > 1.5 && !input.brake;
  const isBoosting = canBoost && (input.throttle || vForward > 6);

  // Steering input (-1 right, +1 left)
  const rawSteer = (input.steerLeft ? 1 : 0) - (input.steerRight ? 1 : 0);
  const targetSteerAngle = rawSteer * 0.48;
  const steerLerp = clamp(dt * 9.5, 0, 1);
  const steerAngle =
    state.steerAngle + (targetSteerAngle - state.steerAngle) * steerLerp;

  // Longitudinal engine / braking forces
  const maxForwardSpeed = isBoosting ? 88.9 : 66.7; // ~320 km/h boosted vs ~240 km/h normal
  const maxReverseSpeed = 24.0; // ~86 km/h reverse
  const engineAccel = isBoosting ? 46.0 : 28.5;
  const reverseAccel = 19.0;
  const brakeDecel = 54.0;

  let isBraking = false;
  let isReversing = false;

  if (input.throttle) {
    if (vForward < -1.5) {
      // Braking out of reverse
      vForward = Math.min(0, vForward + brakeDecel * dt);
      isBraking = true;
    } else {
      // Progressive torque taper near top speed
      const speedRatio = clamp(vForward / maxForwardSpeed, 0, 1);
      const torqueScale = 1.0 - speedRatio * 0.58;
      vForward += engineAccel * torqueScale * dt;
    }
  } else if (input.brake) {
    if (vForward > 1.8) {
      vForward = Math.max(0, vForward - brakeDecel * dt);
      isBraking = true;
    } else {
      vForward = Math.max(-maxReverseSpeed, vForward - reverseAccel * dt);
      isReversing = true;
    }
  } else {
    // Rolling & aero coast drag
    const drag = Math.exp(-0.52 * dt);
    vForward *= drag;
    if (Math.abs(vForward) < 0.08) vForward = 0;
  }

  // Handbrake scrubs forward speed slightly while freeing rear lateral slip
  const absSpeed = Math.abs(vForward);
  const isDrifting =
    (input.handbrake && absSpeed > 8.0) ||
    (Math.abs(vLateral) > 5.5 && absSpeed > 10.0);

  if (input.handbrake && absSpeed > 1.5) {
    vForward *= Math.exp(-0.78 * dt);
    isBraking = true;
  }

  // Angular turning (speed-sensitive steering + drift oversteer)
  const steerSpeedFactor = clamp(absSpeed / 6.5, 0, 1) * (1.0 - clamp(absSpeed / 120, 0, 0.35));
  const reverseFlip = vForward >= -0.4 ? 1 : -1;
  const driftTurnBoost = input.handbrake ? 1.48 : 1.0;
  const yawRate =
    (steerAngle / 0.48) * 2.45 * steerSpeedFactor * reverseFlip * driftTurnBoost;
  const heading = state.heading + yawRate * dt;

  // Compute updated basis after heading change
  const nfx = -Math.sin(heading);
  const nfz = -Math.cos(heading);
  const nrx = Math.cos(heading);
  const nrz = -Math.sin(heading);

  // Preserve inertia in world space when yawing to create authentic drift slip angle!
  const worldVxBeforeGrip = fx * vForward + rx * vLateral;
  const worldVzBeforeGrip = fz * vForward + rz * vLateral;
  vForward = worldVxBeforeGrip * nfx + worldVzBeforeGrip * nfz;
  vLateral = worldVxBeforeGrip * nrx + worldVzBeforeGrip * nrz;

  // Lateral tire grip (tight carve normally, loose controlled slide during handbrake/drift)
  const lateralGrip = input.handbrake ? 2.2 : isDrifting ? 4.4 : 11.5;
  vLateral *= Math.exp(-lateralGrip * dt);
  if (Math.abs(vLateral) < 0.02) vLateral = 0;

  let vx = nfx * vForward + nrx * vLateral;
  let vz = nfz * vForward + nrz * vLateral;

  let x = state.x + vx * dt;
  let z = state.z + vz * dt;
  let impactIntensity = Math.max(0, state.impactIntensity - dt * 2.4);

  // Circle vs AABB Building Collision Resolution (slide cleanly along walls)
  for (let i = 0; i < colliders.length; i++) {
    const b = colliders[i];
    const minX = b.x - b.halfW;
    const maxX = b.x + b.halfW;
    const minZ = b.z - b.halfD;
    const maxZ = b.z + b.halfD;

    const closestX = clamp(x, minX, maxX);
    const closestZ = clamp(z, minZ, maxZ);
    const dx = x - closestX;
    const dz = z - closestZ;
    const distSq = dx * dx + dz * dz;

    if (distSq < CAR_RADIUS * CAR_RADIUS) {
      let nxCol = 0;
      let nzCol = 0;
      let overlap = 0;

      if (distSq > 1e-6) {
        const dist = Math.sqrt(distSq);
        nxCol = dx / dist;
        nzCol = dz / dist;
        overlap = CAR_RADIUS - dist;
      } else {
        // Inside AABB fallback: push out along nearest edge
        const penLeft = Math.abs(x - minX);
        const penRight = Math.abs(maxX - x);
        const penTop = Math.abs(z - minZ);
        const penBottom = Math.abs(maxZ - z);
        const m = Math.min(penLeft, penRight, penTop, penBottom);
        if (m === penLeft) {
          nxCol = -1;
          overlap = penLeft + CAR_RADIUS;
        } else if (m === penRight) {
          nxCol = 1;
          overlap = penRight + CAR_RADIUS;
        } else if (m === penTop) {
          nzCol = -1;
          overlap = penTop + CAR_RADIUS;
        } else {
          nzCol = 1;
          overlap = penBottom + CAR_RADIUS;
        }
      }

      x += nxCol * overlap;
      z += nzCol * overlap;

      const velAlongNormal = vx * nxCol + vz * nzCol;
      if (velAlongNormal < 0) {
        impactIntensity = Math.max(
          impactIntensity,
          clamp(Math.abs(velAlongNormal) / 35, 0.15, 1.0)
        );
        // Remove inward velocity & add subtle elastic bounce + wall friction
        vx -= (1.18 * velAlongNormal) * nxCol;
        vz -= (1.18 * velAlongNormal) * nzCol;
        vx *= 0.86;
        vz *= 0.86;
      }
    }
  }

  // World perimeter neon boundary clamp
  const bound = WORLD_BOUND - 4;
  if (x > bound) {
    x = bound;
    if (vx > 0) {
      impactIntensity = Math.max(impactIntensity, clamp(vx / 35, 0.15, 1));
      vx = -vx * 0.25;
    }
  } else if (x < -bound) {
    x = -bound;
    if (vx < 0) {
      impactIntensity = Math.max(impactIntensity, clamp(-vx / 35, 0.15, 1));
      vx = -vx * 0.25;
    }
  }
  if (z > bound) {
    z = bound;
    if (vz > 0) {
      impactIntensity = Math.max(impactIntensity, clamp(vz / 35, 0.15, 1));
      vz = -vz * 0.25;
    }
  } else if (z < -bound) {
    z = -bound;
    if (vz < 0) {
      impactIntensity = Math.max(impactIntensity, clamp(-vz / 35, 0.15, 1));
      vz = -vz * 0.25;
    }
  }

  // Recompute final speeds after collision adjustment
  const finalForward = vx * nfx + vz * nfz;
  const finalLateral = vx * nrx + vz * nrz;
  const speedKmh = Math.round(Math.hypot(vx, vz) * 3.6);

  // Nitro consumption & drift/cruise recharge
  let nitro = state.nitro;
  if (isBoosting) {
    nitro = Math.max(0, nitro - 22 * dt);
  } else {
    const rechargeRate = isDrifting ? 18.0 : 4.2;
    nitro = Math.min(100, nitro + rechargeRate * dt);
  }

  const wheelSpin = state.wheelSpin + (finalForward / 0.36) * dt;
  const { gear, rpm } = computeGearAndRpm(finalForward, isBoosting);

  // Suspension pitch (squat under throttle/boost, dive under brake) & roll (lean into corners)
  const targetPitch = isBraking
    ? 0.042
    : input.throttle
      ? isBoosting
        ? -0.045
        : -0.026
      : 0;
  const targetRoll = clamp(
    (-steerAngle * clamp(finalForward / 24, 0, 1.3)) * 0.16 +
      clamp(finalLateral / 24, -0.05, 0.05),
    -0.08,
    0.08
  );
  const suspLerp = clamp(dt * 8.0, 0, 1);
  const pitch = state.pitch + (targetPitch - state.pitch) * suspLerp;
  const roll = state.roll + (targetRoll - state.roll) * suspLerp;
  const suspensionBounce = Math.sin(wheelSpin * 0.18) * clamp(absSpeed / 120, 0, 0.018);

  return {
    x,
    z,
    heading,
    vx,
    vz,
    forwardSpeed: finalForward,
    lateralSpeed: finalLateral,
    speedKmh,
    steerAngle,
    wheelSpin,
    rpm,
    gear,
    nitro,
    isBoosting,
    isDrifting,
    isBraking,
    isReversing,
    pitch,
    roll,
    suspensionBounce,
    impactIntensity,
  };
}

export function findNearestCheckpoint(x: number, z: number): CheckpointProximity {
  let nearest: DestinationConfig | null = null;
  let minDist = Infinity;
  for (const dest of DESTINATIONS) {
    const d = Math.hypot(x - dest.position[0], z - dest.position[2]);
    if (d < minDist) {
      minDist = d;
      nearest = dest;
    }
  }
  return {
    destination: nearest,
    distance: minDist,
    isInside: nearest ? minDist <= nearest.triggerRadius : false,
  };
}

export function getNextMissionDestination(
  visited: Set<DestinationId>,
  x: number,
  z: number,
  heading = 0
): MissionTarget {
  const unvisited = DESTINATIONS.filter((d) => !visited.has(d.id));
  const target =
    unvisited.length > 0
      ? unvisited[0]
      : findNearestCheckpoint(x, z).destination ?? DESTINATIONS[0];

  const dx = target.position[0] - x;
  const dz = target.position[2] - z;
  const distance = Math.round(Math.hypot(dx, dz));
  // Bearing relative to car forward vector (-sin(h), -cos(h))
  const worldAngle = Math.atan2(-dx, -dz);
  const bearingRad = worldAngle - heading;

  return {
    destination: target,
    distance,
    bearingRad,
    allVisited: unvisited.length === 0,
  };
}
