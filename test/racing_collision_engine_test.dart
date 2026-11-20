import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:spnk/views/screens/racing/racing_collision_engine.dart';
import 'package:spnk/views/screens/racing/racing_models.dart';

void main() {
  group('CircuitCollisionDetector (Swept CCD)', () {
    const trackLen = CircuitBuilder.trackLength;

    test('catches high-speed Nitro rear-end hit without tunneling', () {
      // At 420 km/h with dt=0.05s, car moves ~515 Z-units in a single frame.
      // Player starts behind opponent (prevRelZ = +300 > zMax 255) and ends ahead (currRelZ = -175 < zMin -35).
      const prevNormZ = 5000.0;
      const currNormZ = 5515.0;
      const prevOppZ = 5300.0;
      const currOppZ = 5340.0;

      final (zMin, zMax) = CircuitCollisionDetector.computeLongitudinalBand(
        mode: RacingGameMode.horizon3d,
        vehicle: VehicleType.apexGt,
        oppZHalfLength: OpponentVehicleKind.coupe.zHalfLength,
        oppTopDownLength: OpponentVehicleKind.coupe.topDownLength,
      );

      final hit = CircuitCollisionDetector.detectSweptCircuitHit(
        prevNormZ: prevNormZ,
        currNormZ: currNormZ,
        prevPlayerX: 0.0,
        currPlayerX: 0.0,
        prevOppZ: prevOppZ,
        currOppZ: currOppZ,
        prevOppLane: 0.0,
        currOppLane: 0.0,
        trackLen: trackLen,
        playerHalfWidth: VehicleType.apexGt.roadHalfWidth,
        oppHalfWidth: OpponentVehicleKind.coupe.roadHalfWidth,
        zBandMin: zMin,
        zBandMax: zMax,
      );

      expect(hit, isNotNull);
      expect(hit!.kind, CollisionKind.rearEnd);
      expect(hit.timeOfImpact, inInclusiveRange(0.0, 1.0));
    });

    test('respects vehicle hitbox differences (CyberBike passes where TitanTruck hits)', () {
      // Player at lane 0.30, opponent coupe (halfWidth 0.17) at lane 0.0:
      // gap = 0.30. CyberBike halfWidth=0.10 (sum=0.27 -> clear!), TitanTruck=0.23 (sum=0.40 -> hit!).
      final (zMin, zMax) = CircuitCollisionDetector.computeLongitudinalBand(
        mode: RacingGameMode.horizon3d,
        vehicle: VehicleType.cyberBike,
        oppZHalfLength: OpponentVehicleKind.coupe.zHalfLength,
        oppTopDownLength: OpponentVehicleKind.coupe.topDownLength,
      );

      final bikeHit = CircuitCollisionDetector.detectSweptCircuitHit(
        prevNormZ: 1000.0,
        currNormZ: 1200.0,
        prevPlayerX: 0.30,
        currPlayerX: 0.30,
        prevOppZ: 1180.0,
        currOppZ: 1200.0,
        prevOppLane: 0.0,
        currOppLane: 0.0,
        trackLen: trackLen,
        playerHalfWidth: VehicleType.cyberBike.roadHalfWidth,
        oppHalfWidth: OpponentVehicleKind.coupe.roadHalfWidth,
        zBandMin: zMin,
        zBandMax: zMax,
      );
      expect(bikeHit, isNull);

      final truckHit = CircuitCollisionDetector.detectSweptCircuitHit(
        prevNormZ: 1000.0,
        currNormZ: 1200.0,
        prevPlayerX: 0.30,
        currPlayerX: 0.30,
        prevOppZ: 1180.0,
        currOppZ: 1200.0,
        prevOppLane: 0.0,
        currOppLane: 0.0,
        trackLen: trackLen,
        playerHalfWidth: VehicleType.titanTruck.roadHalfWidth,
        oppHalfWidth: OpponentVehicleKind.coupe.roadHalfWidth,
        zBandMin: zMin,
        zBandMax: zMax,
      );
      expect(truckHit, isNotNull);
    });

    test('sideswipe detection resolves with zero lateral overlap', () {
      final (zMin, zMax) = CircuitCollisionDetector.computeLongitudinalBand(
        mode: RacingGameMode.verticalHighway,
        vehicle: VehicleType.apexGt,
        oppZHalfLength: OpponentVehicleKind.coupe.zHalfLength,
        oppTopDownLength: OpponentVehicleKind.coupe.topDownLength,
      );

      // Already longitudinally overlapping at prevNormZ == oppZ == 4000, steering left into lane 0.0
      final hit = CircuitCollisionDetector.detectSweptCircuitHit(
        prevNormZ: 4000.0,
        currNormZ: 4050.0,
        prevPlayerX: 0.42,
        currPlayerX: 0.20,
        prevOppZ: 4000.0,
        currOppZ: 4050.0,
        prevOppLane: 0.0,
        currOppLane: 0.0,
        trackLen: trackLen,
        playerHalfWidth: VehicleType.apexGt.roadHalfWidth,
        oppHalfWidth: OpponentVehicleKind.coupe.roadHalfWidth,
        zBandMin: zMin,
        zBandMax: zMax,
      );

      expect(hit, isNotNull);
      expect(hit!.kind, CollisionKind.sideswipe);
      expect(hit.pushDirection, 1.0);

      final res = CircuitCollisionDetector.resolveCircuitHit(
        hit: hit,
        vehicle: VehicleType.apexGt,
        playerSpeedKmh: 220.0,
        playerX: 0.20,
        currNormZ: 4050.0,
        oppZ: 4050.0,
        oppLane: 0.0,
        oppSpeedKmh: 120.0,
        oppMass: OpponentVehicleKind.coupe.mass,
        oppHalfWidth: OpponentVehicleKind.coupe.roadHalfWidth,
        zBandMin: zMin,
        zBandMax: zMax,
        trackLen: trackLen,
        maxLateral: 1.42,
      );

      final minRequired =
          VehicleType.apexGt.roadHalfWidth + OpponentVehicleKind.coupe.roadHalfWidth;
      expect(res.newPlayerX.abs(), greaterThan(minRequired));
      expect(res.newPlayerSpeedKmh, lessThan(220.0));
    });

    test('adjacent lanes produce zero false-positive collisions', () {
      final (zMin, zMax) = CircuitCollisionDetector.computeLongitudinalBand(
        mode: RacingGameMode.horizon3d,
        vehicle: VehicleType.titanTruck,
        oppZHalfLength: OpponentVehicleKind.truck.zHalfLength,
        oppTopDownLength: OpponentVehicleKind.truck.topDownLength,
      );

      // Player in center (0.0), opponent truck in right lane (0.66):
      // combined halfWidth = 0.23 + 0.22 = 0.45 < 0.66
      final hit = CircuitCollisionDetector.detectSweptCircuitHit(
        prevNormZ: 2000.0,
        currNormZ: 2400.0,
        prevPlayerX: 0.0,
        currPlayerX: 0.0,
        prevOppZ: 2150.0,
        currOppZ: 2220.0,
        prevOppLane: 0.66,
        currOppLane: 0.66,
        trackLen: trackLen,
        playerHalfWidth: VehicleType.titanTruck.roadHalfWidth,
        oppHalfWidth: OpponentVehicleKind.truck.roadHalfWidth,
        zBandMin: zMin,
        zBandMax: zMax,
      );

      expect(hit, isNull);
    });

    test('armor & mass weighting gives TitanTruck greater crash resilience than FormulaX', () {
      final (zMin, zMax) = CircuitCollisionDetector.computeLongitudinalBand(
        mode: RacingGameMode.horizon3d,
        vehicle: VehicleType.formulaX,
        oppZHalfLength: OpponentVehicleKind.coupe.zHalfLength,
        oppTopDownLength: OpponentVehicleKind.coupe.topDownLength,
      );
      const hit = SweptCollisionHit(
        timeOfImpact: 0.5,
        kind: CollisionKind.rearEnd,
        pushDirection: 1.0,
        penetrationX: 0.2,
        impactLaneX: 0.0,
        impactRelZ: 120.0,
      );

      final formulaRes = CircuitCollisionDetector.resolveCircuitHit(
        hit: hit,
        vehicle: VehicleType.formulaX,
        playerSpeedKmh: 300.0,
        playerX: 0.0,
        currNormZ: 3000.0,
        oppZ: 3050.0,
        oppLane: 0.0,
        oppSpeedKmh: 100.0,
        oppMass: 1.0,
        oppHalfWidth: 0.17,
        zBandMin: zMin,
        zBandMax: zMax,
        trackLen: trackLen,
        maxLateral: 1.42,
      );

      final truckRes = CircuitCollisionDetector.resolveCircuitHit(
        hit: hit,
        vehicle: VehicleType.titanTruck,
        playerSpeedKmh: 300.0,
        playerX: 0.0,
        currNormZ: 3000.0,
        oppZ: 3050.0,
        oppLane: 0.0,
        oppSpeedKmh: 100.0,
        oppMass: 1.0,
        oppHalfWidth: 0.17,
        zBandMin: zMin,
        zBandMax: zMax,
        trackLen: trackLen,
        maxLateral: 1.42,
      );

      expect(truckRes.newPlayerSpeedKmh, greaterThan(formulaRes.newPlayerSpeedKmh));
      expect(truckRes.hullDamage, lessThan(formulaRes.hullDamage));
    });

    test('near-miss triggers only when passing close without overlapping', () {
      final isNear = CircuitCollisionDetector.isNearMiss(
        prevRelZ: 120.0,
        currRelZ: -40.0,
        trackLen: trackLen,
        playerX: 0.44,
        oppLane: 0.0,
        playerHalfWidth: VehicleType.apexGt.roadHalfWidth, // 0.18
        oppHalfWidth: OpponentVehicleKind.coupe.roadHalfWidth, // 0.17 -> sum 0.35
        playerSpeedKmh: 210.0,
      );
      expect(isNear, isTrue);

      final tooFar = CircuitCollisionDetector.isNearMiss(
        prevRelZ: 120.0,
        currRelZ: -40.0,
        trackLen: trackLen,
        playerX: 0.72,
        oppLane: 0.0,
        playerHalfWidth: VehicleType.apexGt.roadHalfWidth,
        oppHalfWidth: OpponentVehicleKind.coupe.roadHalfWidth,
        playerSpeedKmh: 210.0,
      );
      expect(tooFar, isFalse);
    });
  });

  group('ObbCollisionDetector (Open-World SAT)', () {
    test('detects overlapping angled vehicles and separates via MTV', () {
      const boxA = Obb2D(
        center: Offset(100, 100),
        headingRad: math.pi / 4,
        halfWidth: 18,
        halfLength: 35,
      );
      const boxB = Obb2D(
        center: Offset(125, 110),
        headingRad: -math.pi / 6,
        halfWidth: 15,
        halfLength: 29,
      );

      final result = ObbCollisionDetector.testObbVsObb(boxA, boxB);
      expect(result, isNotNull);
      expect(result!.overlap, greaterThan(0));

      // Applying MTV completely separates the boxes
      final separatedA = Obb2D(
        center: boxA.center + result.mtv * 1.02,
        headingRad: boxA.headingRad,
        halfWidth: boxA.halfWidth,
        halfLength: boxA.halfLength,
      );
      expect(ObbCollisionDetector.testObbVsObb(separatedA, boxB), isNull);
    });

    test('detects OBB vs Circle monument impact and resolves cleanly', () {
      const player = Obb2D(
        center: Offset(180, 0),
        headingRad: 0,
        halfWidth: 18,
        halfLength: 35,
      );
      final hit = ObbCollisionDetector.testObbVsCircle(player, Offset.zero, 168.0);
      expect(hit, isNotNull);
      expect(hit!.overlap, greaterThan(0));

      final pushed = Obb2D(
        center: player.center + hit.mtv * 1.02,
        headingRad: player.headingRad,
        halfWidth: player.halfWidth,
        halfLength: player.halfLength,
      );
      expect(
        ObbCollisionDetector.testObbVsCircle(pushed, Offset.zero, 168.0),
        isNull,
      );
    });
  });
}
