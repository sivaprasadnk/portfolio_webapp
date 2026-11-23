import { DESTINATIONS, type DestinationId } from '../data/portfolioData';
import {
  createInitialCarState,
  type CarPhysicsState,
  type CheckpointProximity,
  type MissionTarget,
} from '../world/physics';

export type GamePhase = 'title' | 'transition' | 'playing';
export type TimeOfDay = 'night' | 'dusk' | 'day';
export type CameraMode = 'chase' | 'hood' | 'cinematic';

const VISITED_STORAGE_KEY = 'spnk_v2_visited_destinations';

export interface LiveTelemetry {
  car: CarPhysicsState;
  proximity: CheckpointProximity;
  mission: MissionTarget;
  cameraOrbitYaw: number;
  cameraOrbitPitch: number;
  lastMouseOrbitAt: number;
  transitionProgress: number;
  teleportTarget: { x: number; z: number; heading: number } | null;
  finishBurstAt: number;
}

export const liveTelemetryRef: LiveTelemetry = {
  car: createInitialCarState(),
  proximity: {
    destination: DESTINATIONS[0],
    distance: 100,
    isInside: false,
  },
  mission: {
    destination: DESTINATIONS[0],
    distance: 100,
    bearingRad: 0,
    allVisited: false,
  },
  cameraOrbitYaw: 0,
  cameraOrbitPitch: 0.08,
  lastMouseOrbitAt: 0,
  transitionProgress: 0,
  teleportTarget: null,
  finishBurstAt: 0,
};

export function loadVisitedDestinations(): DestinationId[] {
  try {
    const raw = window.sessionStorage.getItem(VISITED_STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    const validIds = new Set(DESTINATIONS.map((d) => d.id));
    return parsed.filter((id): id is DestinationId => validIds.has(id));
  } catch {
    return [];
  }
}

export function saveVisitedDestinations(ids: DestinationId[]): void {
  try {
    window.sessionStorage.setItem(VISITED_STORAGE_KEY, JSON.stringify(ids));
  } catch {
    // Safe fallback if sessionStorage is restricted
  }
}
