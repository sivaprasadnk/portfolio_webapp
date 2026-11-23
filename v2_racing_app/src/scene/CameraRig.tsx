import { useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';
import { liveTelemetryRef, type CameraMode, type GamePhase } from '../state/gameStore';

interface CameraRigProps {
  phase: GamePhase;
  cameraMode: CameraMode;
  activePanel: string | null;
  onTransitionComplete: () => void;
}

const _desiredPos = new THREE.Vector3();
const _desiredLook = new THREE.Vector3();
const _smoothedPos = new THREE.Vector3(6, 3.2, 23);
const _smoothedLook = new THREE.Vector3(0, 1.0, 16);

export function CameraRig({
  phase,
  cameraMode,
  activePanel,
  onTransitionComplete,
}: CameraRigProps) {
  const orbitAngleRef = useRef(0.35);
  const transitionDoneRef = useRef(false);

  useFrame(({ camera }, rawDt) => {
    const dt = Math.min(rawDt, 0.05);
    const car = liveTelemetryRef.car;
    const persp = camera as THREE.PerspectiveCamera;

    const fx = -Math.sin(car.heading);
    const fz = -Math.cos(car.heading);
    const rx = Math.cos(car.heading);
    const rz = -Math.sin(car.heading);

    if (phase === 'title') {
      transitionDoneRef.current = false;
      orbitAngleRef.current += dt * 0.28;
      const a = orbitAngleRef.current;
      const radius = 6.9;
      _desiredPos.set(
        car.x + Math.sin(a) * radius,
        2.35 + Math.sin(a * 0.5) * 0.45,
        car.z + Math.cos(a) * radius
      );
      _desiredLook.set(car.x + fx * 0.7, 0.92, car.z + fz * 0.7);
      _smoothedPos.lerp(_desiredPos, 1 - Math.exp(-5 * dt));
      _smoothedLook.lerp(_desiredLook, 1 - Math.exp(-6 * dt));
      if (Math.abs(persp.fov - 52) > 0.1) {
        persp.fov = THREE.MathUtils.lerp(persp.fov, 52, dt * 4);
        persp.updateProjectionMatrix();
      }
      camera.position.copy(_smoothedPos);
      camera.lookAt(_smoothedLook);
      return;
    }

    if (phase === 'transition') {
      liveTelemetryRef.transitionProgress += dt / 1.25;
      const p = Math.min(1, liveTelemetryRef.transitionProgress);
      const ease = 1 - Math.pow(1 - p, 3);

      const chaseX = car.x - fx * 7.8;
      const chaseZ = car.z - fz * 7.8;
      _desiredPos.set(chaseX, 3.25, chaseZ);
      _desiredLook.set(car.x + fx * 6.5, 1.15, car.z + fz * 6.5);

      _smoothedPos.lerp(_desiredPos, 0.08 + ease * 0.22);
      _smoothedLook.lerp(_desiredLook, 0.08 + ease * 0.24);
      persp.fov = THREE.MathUtils.lerp(persp.fov, 58, dt * 4);
      persp.updateProjectionMatrix();

      camera.position.copy(_smoothedPos);
      camera.lookAt(_smoothedLook);

      if (p >= 1 && !transitionDoneRef.current) {
        transitionDoneRef.current = true;
        onTransitionComplete();
      }
      return;
    }

    // Active gameplay / open panel camera
    if (activePanel) {
      // Frame the car and surrounding landmark dramatically behind the HUD panel
      _desiredPos.set(
        car.x - fx * 8.4 + rx * 4.6,
        3.6,
        car.z - fz * 8.4 + rz * 4.6
      );
      _desiredLook.set(car.x + fx * 4.5, 1.4, car.z + fz * 4.5);
      persp.fov = THREE.MathUtils.lerp(persp.fov, 54, dt * 4);
      persp.updateProjectionMatrix();
      _smoothedPos.lerp(_desiredPos, 1 - Math.exp(-4.5 * dt));
      _smoothedLook.lerp(_desiredLook, 1 - Math.exp(-5 * dt));
      camera.position.copy(_smoothedPos);
      camera.lookAt(_smoothedLook);
      return;
    }

    // Decay manual mouse-orbit offset when player hasn't dragged recently while driving
    const nowSec = performance.now() / 1000;
    if (nowSec - liveTelemetryRef.lastMouseOrbitAt > 2.2 && car.speedKmh > 12) {
      liveTelemetryRef.cameraOrbitYaw *= Math.exp(-2.8 * dt);
      liveTelemetryRef.cameraOrbitPitch = THREE.MathUtils.lerp(
        liveTelemetryRef.cameraOrbitPitch,
        0.08,
        1 - Math.exp(-2.8 * dt)
      );
    }

    const speedRatio = Math.min(1, car.speedKmh / 280);
    const orbitYaw = liveTelemetryRef.cameraOrbitYaw;
    const orbitPitch = liveTelemetryRef.cameraOrbitPitch;

    if (cameraMode === 'hood') {
      _desiredPos.set(car.x + fx * 0.55, 1.24 + car.suspensionBounce, car.z + fz * 0.55);
      _desiredLook.set(car.x + fx * 24, 1.15 - car.pitch * 3, car.z + fz * 24);
      _smoothedPos.lerp(_desiredPos, 1 - Math.exp(-22 * dt));
      _smoothedLook.lerp(_desiredLook, 1 - Math.exp(-22 * dt));
    } else if (cameraMode === 'cinematic') {
      const camYaw = car.heading + 0.42 + orbitYaw;
      const cfx = -Math.sin(camYaw);
      const cfz = -Math.cos(camYaw);
      _desiredPos.set(car.x - cfx * 8.8, 2.55 + orbitPitch * 4, car.z - cfz * 8.8);
      _desiredLook.set(car.x + fx * 5.2, 1.1, car.z + fz * 5.2);
      _smoothedPos.lerp(_desiredPos, 1 - Math.exp(-6.5 * dt));
      _smoothedLook.lerp(_desiredLook, 1 - Math.exp(-8 * dt));
    } else {
      // Dynamic AAA Forza/NFS chase cam
      const camHeading = car.heading + orbitYaw;
      const cfx = -Math.sin(camHeading);
      const cfz = -Math.cos(camHeading);
      const followDist = 7.4 + speedRatio * 1.6 + (car.isBoosting ? 0.7 : 0);
      const followHeight = 2.85 + orbitPitch * 5.2 - speedRatio * 0.22;
      const driftLead = THREE.MathUtils.clamp(car.lateralSpeed * 0.09, -1.6, 1.6);

      _desiredPos.set(
        car.x - cfx * followDist + rx * driftLead * 0.35,
        followHeight,
        car.z - cfz * followDist + rz * driftLead * 0.35
      );
      _desiredLook.set(
        car.x + fx * (8.5 + speedRatio * 4),
        1.18,
        car.z + fz * (8.5 + speedRatio * 4)
      );

      _smoothedPos.lerp(_desiredPos, 1 - Math.exp(-7.8 * dt));
      _smoothedLook.lerp(_desiredLook, 1 - Math.exp(-10.5 * dt));
    }

    // Subtle nitro / collision micro-shake
    const shakeMag = (car.isBoosting ? 0.032 : 0) + car.impactIntensity * 0.16;
    if (shakeMag > 0.002) {
      camera.position.set(
        _smoothedPos.x + (Math.random() - 0.5) * shakeMag,
        _smoothedPos.y + (Math.random() - 0.5) * shakeMag,
        _smoothedPos.z + (Math.random() - 0.5) * shakeMag
      );
    } else {
      camera.position.copy(_smoothedPos);
    }

    const targetFov =
      cameraMode === 'hood'
        ? 64 + speedRatio * 12
        : 56 + speedRatio * 14 + (car.isBoosting ? 6 : 0);
    if (Math.abs(persp.fov - targetFov) > 0.08) {
      persp.fov = THREE.MathUtils.lerp(persp.fov, targetFov, 1 - Math.exp(-6 * dt));
      persp.updateProjectionMatrix();
    }

    camera.lookAt(_smoothedLook);
  });

  return null;
}
