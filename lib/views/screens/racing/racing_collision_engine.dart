import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:spnk/views/screens/racing/racing_models.dart';

enum CollisionKind {
  rearEnd,
  sideswipe,
  frontBump,
  barrier,
}

class SweptCollisionHit {
  final double timeOfImpact; // 0.0 .. 1.0 within frame
  final CollisionKind kind;
  final double pushDirection; // -1.0 (push left) or +1.0 (push right)
  final double penetrationX;
  final double impactLaneX;
  final double impactRelZ;

  const SweptCollisionHit({
    required this.timeOfImpact,
    required this.kind,
    required this.pushDirection,
    required this.penetrationX,
    required this.impactLaneX,
    required this.impactRelZ,
  });
}

class CircuitCollisionResolution {
  final double newPlayerSpeedKmh;
  final double newPlayerX;
  final double lateralBounceVelocity;
  final double newOppZ;
  final double newOppSpeedKmh;
  final double oppLateralRecoil;
  final double hullDamage;
  final double shakeIntensity;

  const CircuitCollisionResolution({
    required this.newPlayerSpeedKmh,
    required this.newPlayerX,
    required this.lateralBounceVelocity,
    required this.newOppZ,
    required this.newOppSpeedKmh,
    required this.oppLateralRecoil,
    required this.hullDamage,
    required this.shakeIntensity,
  });
}

class CircuitCollisionDetector {
  /// Longitudinal contact band in 3D Horizon mode matching RacingTrackPainter's
  /// projected car silhouette in front of camera (`relZ` ~ 35..185).
  static const double horizonPlayerZMin = 35.0;
  static const double horizonPlayerZMax = 185.0;

  /// Z units per vertical screen pixel in Vertical Highway mode (must match
  /// `RacingHighwayPainter._zPerPixel`).
  static const double highwayZPerPixel = 7.2;

  static double signedTrackDelta(double targetZ, double baseZ, double trackLen) {
    double d = targetZ - baseZ;
    while (d > trackLen * 0.5) {
      d -= trackLen;
    }
    while (d < -trackLen * 0.5) {
      d += trackLen;
    }
    return d;
  }

  /// Computes exact longitudinal overlap interval `[zMin, zMax]` for `relZ = oppZ - playerZ`.
  static (double zMin, double zMax) computeLongitudinalBand({
    required RacingGameMode mode,
    required VehicleType vehicle,
    required double oppZHalfLength,
    required double oppTopDownLength,
  }) {
    if (mode == RacingGameMode.verticalHighway) {
      final halfPx = (vehicle.topDownLength * 0.5) + (oppTopDownLength * 0.5);
      final halfZ = (halfPx * highwayZPerPixel) * 0.88;
      return (-halfZ, halfZ);
    }
    return (
      horizonPlayerZMin - oppZHalfLength,
      horizonPlayerZMax + oppZHalfLength,
    );
  }

  /// Performs continuous swept 1D-Z + 1D-X AABB collision detection across `[0, 1]`.
  /// Prevents high-speed Nitro tunneling by evaluating `prevRelZ` -> `currRelZ`.
  static SweptCollisionHit? detectSweptCircuitHit({
    required double prevNormZ,
    required double currNormZ,
    required double prevPlayerX,
    required double currPlayerX,
    required double prevOppZ,
    required double currOppZ,
    required double prevOppLane,
    required double currOppLane,
    required double trackLen,
    required double playerHalfWidth,
    required double oppHalfWidth,
    required double zBandMin,
    required double zBandMax,
    bool isStaticBarrier = false,
  }) {
    final prevRelZ = signedTrackDelta(prevOppZ, prevNormZ, trackLen);
    final currRelZ = signedTrackDelta(currOppZ, currNormZ, trackLen);

    // Guard against huge discontinuities from teleporting or track-wrap artifacts.
    if ((currRelZ - prevRelZ).abs() > trackLen * 0.25) {
      return null;
    }

    final dRelZ = currRelZ - prevRelZ;
    double tEnter = 0.0;
    double tExit = 1.0;

    if (dRelZ.abs() < 1e-6) {
      if (currRelZ < zBandMin || currRelZ > zBandMax) {
        return null;
      }
    } else {
      final t1 = (zBandMin - prevRelZ) / dRelZ;
      final t2 = (zBandMax - prevRelZ) / dRelZ;
      tEnter = math.max(0.0, math.min(t1, t2));
      tExit = math.min(1.0, math.max(t1, t2));
      if (tEnter > tExit) {
        return null;
      }
    }

    // Evaluate minimum lateral separation |playerX(t) - oppLane(t)| across t in [tEnter, tExit].
    final dX0 = prevPlayerX - prevOppLane;
    final dX1 = currPlayerX - currOppLane;
    final ddX = dX1 - dX0;

    double bestT = tEnter;
    double minAbsDX = (dX0 + ddX * tEnter).abs();

    final atExit = (dX0 + ddX * tExit).abs();
    if (atExit < minAbsDX) {
      minAbsDX = atExit;
      bestT = tExit;
    }

    if (ddX.abs() > 1e-6) {
      final tZero = -dX0 / ddX;
      if (tZero > tEnter && tZero < tExit) {
        final atZero = (dX0 + ddX * tZero).abs();
        if (atZero < minAbsDX) {
          minAbsDX = atZero;
          bestT = tZero;
        }
      }
    }

    final combinedHalfW = playerHalfWidth + oppHalfWidth;
    if (minAbsDX >= combinedHalfW) {
      return null;
    }

    final dxAtHit = dX0 + ddX * bestT;
    final oppLaneAtHit = prevOppLane + (currOppLane - prevOppLane) * bestT;
    final relZAtHit = prevRelZ + dRelZ * bestT;

    double pushDir;
    if (dxAtHit.abs() > 0.015) {
      pushDir = dxAtHit.sign;
    } else {
      // Dead-center impact: deflect toward whichever road side has more room.
      pushDir = oppLaneAtHit >= 0 ? -1.0 : 1.0;
    }

    final CollisionKind kind;
    if (isStaticBarrier) {
      kind = CollisionKind.barrier;
    } else if (prevRelZ > zBandMax) {
      kind = CollisionKind.rearEnd;
    } else if (prevRelZ < zBandMin) {
      kind = CollisionKind.frontBump;
    } else {
      kind = CollisionKind.sideswipe;
    }

    return SweptCollisionHit(
      timeOfImpact: bestT,
      kind: kind,
      pushDirection: pushDir,
      penetrationX: combinedHalfW - dxAtHit.abs(),
      impactLaneX: currPlayerX,
      impactRelZ: relZAtHit,
    );
  }

  /// Resolves velocity, lateral impulse, overlap separation, and damage on hit.
  static CircuitCollisionResolution resolveCircuitHit({
    required SweptCollisionHit hit,
    required VehicleType vehicle,
    required double playerSpeedKmh,
    required double playerX,
    required double currNormZ,
    required double oppZ,
    required double oppLane,
    required double oppSpeedKmh,
    required double oppMass,
    required double oppHalfWidth,
    required double zBandMin,
    required double zBandMax,
    required double trackLen,
    required double maxLateral,
    bool isStaticBarrier = false,
  }) {
    final combinedHalfW = vehicle.roadHalfWidth + oppHalfWidth;
    final armor = vehicle.armorFactor;
    final massRatio = (oppMass / (vehicle.mass + oppMass)).clamp(0.20, 0.85);

    double newPlayerSpeed = playerSpeedKmh;
    double newPlayerX = playerX;
    double bounceVel = 0.0;
    double newOppZ = oppZ;
    double newOppSpeed = oppSpeedKmh;
    double oppRecoil = 0.0;
    double hullDamage = 8.0;
    double shakeIntensity = 0.55;

    final relSpeed = math.max(0.0, playerSpeedKmh - oppSpeedKmh);

    switch (hit.kind) {
      case CollisionKind.barrier:
        final speedDrop = (0.50 - armor * 0.24).clamp(0.22, 0.55);
        newPlayerSpeed =
            math.max(48.0, playerSpeedKmh * (1.0 - speedDrop));
        newPlayerX = (oppLane + hit.pushDirection * (combinedHalfW + 0.06))
            .clamp(-maxLateral, maxLateral);
        bounceVel = hit.pushDirection * (0.95 + (1.0 - armor) * 0.45);
        hullDamage = (12.0 + relSpeed * 0.045) * (1.15 - armor * 0.65);
        shakeIntensity = (0.55 + (playerSpeedKmh / 420.0) * 0.45).clamp(0.4, 1.0);
        break;

      case CollisionKind.rearEnd:
        final penaltyScale = (1.0 - armor * 0.55) * massRatio;
        newPlayerSpeed = math.max(
          45.0,
          playerSpeedKmh - math.max(38.0, relSpeed * (0.55 + penaltyScale * 0.5)),
        );
        // Push opponent clearly ahead of contact zone so zero re-overlap occurs.
        newOppZ = (currNormZ + zBandMax + 42.0) % trackLen;
        newOppSpeed = math.min(
          oppSpeedKmh + relSpeed * (0.28 + (1.0 - massRatio) * 0.42),
          240.0,
        );
        bounceVel = hit.pushDirection * (0.80 + (1.0 - armor) * 0.45);
        oppRecoil = -hit.pushDirection * (0.14 + (1.0 - massRatio) * 0.14);
        hullDamage = (8.0 + relSpeed * 0.04) * (1.1 - armor * 0.62);
        shakeIntensity = (0.48 + (relSpeed / 260.0) * 0.52).clamp(0.4, 1.0);
        break;

      case CollisionKind.frontBump:
        newPlayerSpeed = math.min(vehicle.nitroMaxSpeed, playerSpeedKmh + 12.0);
        newOppZ = (currNormZ + zBandMin - 44.0 + trackLen) % trackLen;
        newOppSpeed = math.max(55.0, oppSpeedKmh * 0.80);
        bounceVel = hit.pushDirection * 0.65;
        oppRecoil = -hit.pushDirection * 0.14;
        hullDamage = 5.0 * (1.1 - armor * 0.5);
        shakeIntensity = 0.42;
        break;

      case CollisionKind.sideswipe:
        newPlayerSpeed = math.max(60.0, playerSpeedKmh * (0.90 + armor * 0.05));
        newPlayerX = (oppLane + hit.pushDirection * (combinedHalfW + 0.05))
            .clamp(-maxLateral, maxLateral);
        bounceVel = hit.pushDirection * (1.10 + (1.0 - armor) * 0.42);
        oppRecoil = -hit.pushDirection * (0.12 + (1.0 - massRatio) * 0.12);
        hullDamage = 7.5 * (1.1 - armor * 0.55);
        shakeIntensity = 0.50;
        break;
    }

    return CircuitCollisionResolution(
      newPlayerSpeedKmh: newPlayerSpeed,
      newPlayerX: newPlayerX,
      lateralBounceVelocity: bounceVel,
      newOppZ: newOppZ,
      newOppSpeedKmh: newOppSpeed,
      oppLateralRecoil: oppRecoil.clamp(-0.26, 0.26),
      hullDamage: hullDamage.clamp(3.0, 28.0),
      shakeIntensity: shakeIntensity,
    );
  }

  /// Detects a clean near-miss pass without contact for bonus XP & nitro.
  static bool isNearMiss({
    required double prevRelZ,
    required double currRelZ,
    required double trackLen,
    required double playerX,
    required double oppLane,
    required double playerHalfWidth,
    required double oppHalfWidth,
    required double playerSpeedKmh,
  }) {
    if ((currRelZ - prevRelZ).abs() > trackLen * 0.25) return false;
    if (playerSpeedKmh < 130.0) return false;
    if (!(prevRelZ > 0.0 && currRelZ <= 0.0)) return false;

    final lateralGap = (playerX - oppLane).abs();
    final combinedHalfW = playerHalfWidth + oppHalfWidth;
    return lateralGap >= combinedHalfW && lateralGap <= combinedHalfW + 0.22;
  }

  /// Picks the safest racing lane `[-0.66, 0.0, 0.66]` for Cruise Auto-Pilot,
  /// considering both moving TrafficCars and static TrackObstacles ahead.
  static double chooseBestAutopilotLane({
    required double normZ,
    required double currentPlayerX,
    required double trackLen,
    required VehicleType vehicle,
    required List<TrafficCar> trafficCars,
    required List<TrackObstacle> obstacles,
  }) {
    const candidateLanes = [-0.66, 0.0, 0.66];
    double bestLane = 0.0;
    double bestScore = double.negativeInfinity;

    for (final lane in candidateLanes) {
      double minClearZ = 3400.0;
      bool blocked = false;

      for (final car in trafficCars) {
        final dz = signedTrackDelta(car.z, normZ, trackLen);
        if (dz > -60.0 && dz < 3200.0) {
          final safeHalf = vehicle.roadHalfWidth + car.kind.roadHalfWidth + 0.09;
          if ((car.effectiveLane - lane).abs() < safeHalf) {
            blocked = true;
            if (dz < minClearZ) minClearZ = dz;
          }
        }
      }

      for (final obs in obstacles) {
        final dz = signedTrackDelta(obs.z, normZ, trackLen);
        if (dz > -40.0 && dz < 3200.0) {
          final safeHalf = vehicle.roadHalfWidth + obs.roadHalfWidth + 0.09;
          if ((obs.lane - lane).abs() < safeHalf) {
            blocked = true;
            if (dz < minClearZ) minClearZ = dz;
          }
        }
      }

      final stayBias = -(lane - currentPlayerX).abs() * 140.0;
      final centerBias = lane == 0.0 ? 25.0 : 0.0;
      final score = (blocked ? minClearZ : 3800.0) + stayBias + centerBias;

      if (score > bestScore) {
        bestScore = score;
        bestLane = lane;
      }
    }

    return bestLane;
  }
}

/// 2D Oriented Bounding Box using Paddock heading convention (`0 = UP (0, -1)`).
class Obb2D {
  final Offset center;
  final double headingRad;
  final double halfWidth;
  final double halfLength;

  const Obb2D({
    required this.center,
    required this.headingRad,
    required this.halfWidth,
    required this.halfLength,
  });

  Offset get forwardAxis =>
      Offset(math.sin(headingRad), -math.cos(headingRad));

  Offset get rightAxis =>
      Offset(math.cos(headingRad), math.sin(headingRad));

  List<Offset> get corners {
    final f = forwardAxis * halfLength;
    final r = rightAxis * halfWidth;
    return [
      center + f - r,
      center + f + r,
      center - f + r,
      center - f - r,
    ];
  }
}

class ObbCollisionResult {
  /// Minimum Translation Vector to push box `a` completely clear of `b`.
  final Offset mtv;
  final Offset normal;
  final double overlap;
  final Offset contactPoint;

  const ObbCollisionResult({
    required this.mtv,
    required this.normal,
    required this.overlap,
    required this.contactPoint,
  });
}

class ObbCollisionDetector {
  /// Exact 4-axis Separating Axis Theorem (SAT) collision test for two 2D OBBs.
  static ObbCollisionResult? testObbVsObb(Obb2D a, Obb2D b) {
    final axes = <Offset>[
      a.rightAxis,
      a.forwardAxis,
      b.rightAxis,
      b.forwardAxis,
    ];

    final cornersA = a.corners;
    final cornersB = b.corners;

    double minOverlap = double.infinity;
    Offset bestAxis = Offset.zero;

    for (final axis in axes) {
      final (minA, maxA) = _projectCorners(cornersA, axis);
      final (minB, maxB) = _projectCorners(cornersB, axis);

      final overlap = math.min(maxA, maxB) - math.max(minA, minB);
      if (overlap <= 0) {
        return null; // Separating axis found!
      }
      if (overlap < minOverlap) {
        minOverlap = overlap;
        bestAxis = axis;
      }
    }

    // Ensure normal points from B toward A so MTV pushes A out of B.
    final bToA = a.center - b.center;
    if (bToA.dx * bestAxis.dx + bToA.dy * bestAxis.dy < 0) {
      bestAxis = Offset(-bestAxis.dx, -bestAxis.dy);
    }

    return ObbCollisionResult(
      mtv: bestAxis * minOverlap,
      normal: bestAxis,
      overlap: minOverlap,
      contactPoint: Offset(
        (a.center.dx + b.center.dx) * 0.5,
        (a.center.dy + b.center.dy) * 0.5,
      ),
    );
  }

  /// Exact OBB vs Circle collision test (used for Central Driver Monument).
  static ObbCollisionResult? testObbVsCircle(
    Obb2D box,
    Offset circleCenter,
    double radius,
  ) {
    final d = circleCenter - box.center;
    final right = box.rightAxis;
    final forward = box.forwardAxis;

    final localX = d.dx * right.dx + d.dy * right.dy;
    final localY = d.dx * forward.dx + d.dy * forward.dy;

    final clampedX = localX.clamp(-box.halfWidth, box.halfWidth);
    final clampedY = localY.clamp(-box.halfLength, box.halfLength);

    final closestWorld = box.center + right * clampedX + forward * clampedY;
    final diff = closestWorld - circleCenter;
    final dist = diff.distance;

    if (dist >= radius) {
      return null;
    }

    if (dist < 1e-4) {
      // Circle center is inside OBB; push out along shortest axis.
      final penX = box.halfWidth - localX.abs();
      final penY = box.halfLength - localY.abs();
      final Offset normal;
      final double overlap;
      if (penX < penY) {
        final s = localX >= 0 ? -1.0 : 1.0;
        normal = right * s;
        overlap = radius + penX;
      } else {
        final s = localY >= 0 ? -1.0 : 1.0;
        normal = forward * s;
        overlap = radius + penY;
      }
      return ObbCollisionResult(
        mtv: normal * overlap,
        normal: normal,
        overlap: overlap,
        contactPoint: closestWorld,
      );
    }

    final normal = diff / dist; // Points outward from circle toward box.
    final overlap = radius - dist;
    return ObbCollisionResult(
      mtv: normal * overlap,
      normal: normal,
      overlap: overlap,
      contactPoint: closestWorld,
    );
  }

  static (double min, double max) _projectCorners(
    List<Offset> corners,
    Offset axis,
  ) {
    double minP = double.infinity;
    double maxP = double.negativeInfinity;
    for (final c in corners) {
      final p = c.dx * axis.dx + c.dy * axis.dy;
      if (p < minP) minP = p;
      if (p > maxP) maxP = p;
    }
    return (minP, maxP);
  }
}
