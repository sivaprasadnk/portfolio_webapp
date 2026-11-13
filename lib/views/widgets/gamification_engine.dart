import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';

class QuestItem {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final IconData icon;

  const QuestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.icon,
  });
}

class GamificationController extends ChangeNotifier {
  static final GamificationController instance = GamificationController._();
  GamificationController._();

  int _xp = 25;
  int _miniGameHighScore = 0;
  final Set<String> _unlockedQuests = {};
  final Set<String> _awardedActions = {};
  final Map<String, int> _skillBoosts = {};

  String? _toastTitle;
  String? _toastSubtitle;
  int? _toastXp;
  Timer? _toastTimer;

  static const List<QuestItem> allQuests = [
    QuestItem(
      id: 'first_scroll',
      title: 'Lights Out!',
      description: 'Accelerate off the Starting Grid or warp to a track sector',
      xpReward: 30,
      icon: Icons.sports_motorsports_rounded,
    ),
    QuestItem(
      id: 'style_shifter',
      title: 'Custom Livery',
      description: 'Switch your car & track livery (Glass, Spatial, or Cyber)',
      xpReward: 40,
      icon: Icons.palette_rounded,
    ),
    QuestItem(
      id: 'lore_reader',
      title: 'Origin Chicane',
      description: 'Pass or inspect the Origin Bio Chicane & Driver Perks',
      xpReward: 40,
      icon: Icons.badge_rounded,
    ),
    QuestItem(
      id: 'skill_inspector',
      title: 'ECU Dyno Tuner',
      description: 'Tune any Skill Engine on the Dyno Straight or Pit Bay',
      xpReward: 50,
      icon: Icons.speed_rounded,
    ),
    QuestItem(
      id: 'career_chronicler',
      title: 'Hairpin Apex',
      description: 'Carve through Career Hairpins or inspect a Season Stage',
      xpReward: 50,
      icon: Icons.flag_rounded,
    ),
    QuestItem(
      id: 'boss_raider',
      title: 'Showroom Test Driver',
      description: 'Launch any Championship Project from the Showroom',
      xpReward: 60,
      icon: Icons.rocket_launch_rounded,
    ),
    QuestItem(
      id: 'loot_collector',
      title: 'Podium Trophy',
      description: 'Claim the CV Trophy or connect in the Social Paddock',
      xpReward: 75,
      icon: Icons.emoji_events_rounded,
    ),
    QuestItem(
      id: 'bug_hunter',
      title: 'Grand Prix Champion',
      description: 'Hit 360+ KM/H with Nitro Overdrive or complete a full lap',
      xpReward: 100,
      icon: Icons.local_fire_department_rounded,
    ),
  ];

  int get xp => _xp;
  int get miniGameHighScore => _miniGameHighScore;
  Set<String> get unlockedQuests => _unlockedQuests;
  String? get toastTitle => _toastTitle;
  String? get toastSubtitle => _toastSubtitle;
  int? get toastXp => _toastXp;

  int get level => (_xp ~/ 100) + 1;

  double get levelProgress => (_xp % 100) / 100.0;

  int get xpInCurrentLevel => _xp % 100;

  String get rankTitle {
    final lvl = level;
    if (lvl <= 1) return 'Rookie Qualifier';
    if (lvl == 2) return 'Apex Contender';
    if (lvl == 3) return 'Flutter GT Pro';
    if (lvl == 4) return 'Telemetry Architect';
    return 'Grand Prix Legend';
  }

  int getSkillBoost(String skillTitle) => _skillBoosts[skillTitle] ?? 0;

  void boostSkill(String skillTitle) {
    final current = _skillBoosts[skillTitle] ?? 0;
    if (current < 5) {
      _skillBoosts[skillTitle] = current + 1;
      addXp(15, reason: '$skillTitle ECU Tuned (Stage ${current + 1})');
    }
    completeQuest('skill_inspector');
    notifyListeners();
  }

  void completeQuest(String questId) {
    if (_unlockedQuests.contains(questId)) return;
    final quest = allQuests.where((q) => q.id == questId).firstOrNull;
    if (quest == null) return;

    _unlockedQuests.add(questId);
    _xp += quest.xpReward;
    _showToast(
      title: '🏁 TROPHY UNLOCKED: ${quest.title.toUpperCase()}',
      subtitle: quest.description,
      xp: quest.xpReward,
    );
    notifyListeners();
  }

  void addXp(int amount, {required String reason, String? uniqueKey}) {
    if (uniqueKey != null) {
      if (_awardedActions.contains(uniqueKey)) return;
      _awardedActions.add(uniqueKey);
    }
    _xp += amount;
    _showToast(
      title: '+$amount TELEMETRY XP',
      subtitle: reason,
      xp: amount,
    );
    notifyListeners();
  }

  void recordMiniGameScore(int score) {
    if (score > _miniGameHighScore) {
      _miniGameHighScore = score;
    }
    if (score >= 5) {
      completeQuest('bug_hunter');
    } else if (score > 0) {
      addXp(score * 5, reason: 'Intercepted $score anomalies on Radar!');
    }
    notifyListeners();
  }

  void _showToast({
    required String title,
    required String subtitle,
    required int xp,
  }) {
    _toastTitle = title;
    _toastSubtitle = subtitle;
    _toastXp = xp;
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 2800), () {
      _toastTitle = null;
      _toastSubtitle = null;
      _toastXp = null;
      notifyListeners();
    });
  }
}

/// Containerless Open-Air Circular Reactor HUD
class GamificationHudPill extends StatelessWidget {
  const GamificationHudPill({
    super.key,
    required this.onOpenQuests,
    this.compact = false,
  });

  final VoidCallback onOpenQuests;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final accent = themeState.accentColor;
        final secondary = themeState.secondaryAccent;

        return ListenableBuilder(
          listenable: GamificationController.instance,
          builder: (context, _) {
            final game = GamificationController.instance;

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onOpenQuests,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circular XP Arc Ring (Zero Box Container)
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: CustomPaint(
                        painter: _HudXpRingPainter(
                          progress: game.levelProgress,
                          accent: accent,
                          secondary: secondary,
                          trackColor:
                              context.primaryColor.withValues(alpha: 0.14),
                        ),
                        child: Center(
                          child: Text(
                            'L${game.level}',
                            style: context.bodySmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${game.xp} XP',
                              style: context.bodySmall.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: accent,
                              ),
                            ),
                            if (!compact) ...[
                              Text(
                                ' // ${game.rankTitle.toUpperCase()}',
                                style: context.bodySmall.copyWith(
                                  fontSize: 10.5,
                                  letterSpacing: 1.1,
                                  color: context.primaryColor
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              size: 12,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${game.unlockedQuests.length}/${GamificationController.allQuests.length} TROPHIES',
                              style: context.bodySmall.copyWith(
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HudXpRingPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final Color secondary;
  final Color trackColor;

  _HudXpRingPainter({
    required this.progress,
    required this.accent,
    required this.secondary,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2.5;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [accent, secondary, accent],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.08, 1.0),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HudXpRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}

/// Containerless Open-Air Holographic Achievement Banner
class AchievementToastBanner extends StatelessWidget {
  const AchievementToastBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final accent = themeState.accentColor;

        return ListenableBuilder(
          listenable: GamificationController.instance,
          builder: (context, _) {
            final game = GamificationController.instance;
            final title = game.toastTitle;
            if (title == null) return const SizedBox.shrink();

            return Positioned(
              top: context.isMobileDevice ? 112 : 76,
              right: 20,
              left: context.isMobileDevice ? 20 : null,
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: ClipRect(
                    key: ValueKey('$title-${game.xp}'),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: CustomPaint(
                        painter: _OpenAirBannerReticlePainter(color: accent),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flare_rounded,
                                color: const Color(0xFFF59E0B),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: context.bodySmall.copyWith(
                                        fontSize: 13.5,
                                        letterSpacing: 1.4,
                                        fontWeight: FontWeight.bold,
                                        color: accent,
                                        shadows: [
                                          Shadow(
                                            color:
                                                accent.withValues(alpha: 0.7),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (game.toastSubtitle != null)
                                      Text(
                                        game.toastSubtitle!,
                                        style: context.bodySmall.copyWith(
                                          fontSize: 13,
                                          color: context.primaryColor
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OpenAirBannerReticlePainter extends CustomPainter {
  final Color color;
  _OpenAirBannerReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Top and bottom laser lines
    canvas.drawLine(const Offset(0, 0), Offset(size.width * 0.4, 0), paint);
    canvas.drawLine(
      Offset(size.width * 0.6, size.height),
      Offset(size.width, size.height),
      paint,
    );
    // Left vertical bar
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _OpenAirBannerReticlePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Containerless Open-Air Star-Log Overlay Modal
void showQuestLogModal(BuildContext context, {VoidCallback? onJumpToArcade}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.82),
    builder: (ctx) {
      return BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final accent = themeState.accentColor;
          final secondary = themeState.secondaryAccent;

          return ListenableBuilder(
            listenable: GamificationController.instance,
            builder: (context, _) {
              final game = GamificationController.instance;

              return Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 580,
                    maxHeight: MediaQuery.of(context).size.height * 0.86,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: PortfolioStyledCard(
                      cyberHeader:
                          'SPNK GRAND PRIX // SUPER LICENSE & TROPHIES',
                      padding: EdgeInsets.all(context.isMobileDevice ? 16 : 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DRIVER SUPER-LICENSE // LVL ${game.level}',
                                      style: context.displaySmall.copyWith(
                                        fontSize:
                                            context.isMobileDevice ? 20 : 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'CLASS: ${game.rankTitle.toUpperCase()} • ${game.xp} TELEMETRY XP • ${game.unlockedQuests.length}/${GamificationController.allQuests.length} TROPHIES WON',
                                      style: context.bodySmall.copyWith(
                                        fontSize: 12,
                                        letterSpacing: 1.3,
                                        color: accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(ctx),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children:
                                    GamificationController.allQuests.map((q) {
                                  final unlocked =
                                      game.unlockedQuests.contains(q.id);
                                  final nodeColor = unlocked
                                      ? const Color(0xFF10B981)
                                      : accent;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          unlocked
                                              ? Icons.auto_awesome_rounded
                                              : q.icon,
                                          color: unlocked
                                              ? const Color(0xFF10B981)
                                              : accent.withValues(alpha: 0.55),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                q.title.toUpperCase(),
                                                style:
                                                    context.bodyMedium.copyWith(
                                                  fontSize: 15,
                                                  letterSpacing: 1.2,
                                                  fontWeight: FontWeight.bold,
                                                  color: unlocked
                                                      ? const Color(0xFF10B981)
                                                      : Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                q.description,
                                                style:
                                                    context.bodySmall.copyWith(
                                                  fontSize: 13,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.72),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          unlocked
                                              ? '🏁 WON'
                                              : '+${q.xpReward} XP',
                                          style: context.bodySmall.copyWith(
                                            fontSize: 11.5,
                                            letterSpacing: 1.1,
                                            fontWeight: FontWeight.bold,
                                            color: unlocked
                                                ? nodeColor
                                                : secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          if (onJumpToArcade != null) ...[
                            const SizedBox(height: 14),
                            Center(
                              child: OpenAirActionTrigger(
                                label: 'Hit Nitro Overdrive on Track',
                                icon: Icons.local_fire_department_rounded,
                                color: accent,
                                isPrimary: true,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  onJumpToArcade();
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

/// Containerless Open-Air Astral Bug-Interceptor Radar Simulator
class DashBugHuntGameSection extends StatefulWidget {
  const DashBugHuntGameSection({super.key});

  @override
  State<DashBugHuntGameSection> createState() => _DashBugHuntGameSectionState();
}

class _DashBugHuntGameSectionState extends State<DashBugHuntGameSection>
    with SingleTickerProviderStateMixin {
  final math.Random _rng = math.Random();
  late final AnimationController _radarSweepController;
  bool _isPlaying = false;
  int _score = 0;
  int _combo = 1;
  int _timeLeft = 15;
  double _targetX = 0.5;
  double _targetY = 0.5;
  int _targetType = 0;
  Timer? _gameTimer;
  Timer? _moveTimer;

  static const List<(String, String, Color)> _targets = [
    ('🐛', 'NULL_ANOMALY', Color(0xFFEF4444)),
    ('💥', 'OVERFLOW_GLITCH', Color(0xFFF59E0B)),
    ('💎', 'ASTRAL_CORE (+2)', Color(0xFF38BDF8)),
  ];

  @override
  void initState() {
    super.initState();
    _radarSweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _radarSweepController.dispose();
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    setState(() {
      _isPlaying = true;
      _score = 0;
      _combo = 1;
      _timeLeft = 15;
      _randomizeTarget();
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft <= 1) {
        timer.cancel();
        _moveTimer?.cancel();
        setState(() {
          _isPlaying = false;
          _timeLeft = 0;
        });
        GamificationController.instance.recordMiniGameScore(_score);
      } else {
        setState(() {
          _timeLeft--;
        });
      }
    });

    _moveTimer = Timer.periodic(const Duration(milliseconds: 1150), (_) {
      if (mounted && _isPlaying) {
        setState(() {
          _combo = 1;
          _randomizeTarget();
        });
      }
    });
  }

  void _randomizeTarget() {
    _targetX = 0.15 + _rng.nextDouble() * 0.70;
    _targetY = 0.18 + _rng.nextDouble() * 0.64;
    _targetType = _rng.nextInt(10) >= 8 ? 2 : _rng.nextInt(2);
  }

  void _hitTarget() {
    if (!_isPlaying) return;
    final bonus = _targetType == 2 ? 2 : 1;
    setState(() {
      _score += bonus;
      _combo = math.min(_combo + 1, 5);
      _randomizeTarget();
    });
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPad =
        context.isMobileDevice ? 16.0 : context.screenWidth * 0.08;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final accent = themeState.accentColor;
          final secondary = themeState.secondaryAccent;

          return ListenableBuilder(
            listenable: GamificationController.instance,
            builder: (context, _) {
              final game = GamificationController.instance;
              final currentTarget = _targets[_targetType];

              return PortfolioStyledCard(
                width: double.infinity,
                cyberHeader: 'ASTRAL ANOMALY INTERCEPTOR // COMBAT RADAR',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Open-Air Telemetry Header (Zero Box Containers)
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OPEN-AIR ANOMALY INTERCEPTOR',
                              style: context.displaySmall.copyWith(
                                fontSize: context.isMobileDevice ? 20 : 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Lock onto 5+ anomalies in 15s on the open-air radar to ignite the Apex Star (+100 XP)',
                              style: context.bodySmall.copyWith(
                                fontSize: 14,
                                color: context.primaryColor
                                    .withValues(alpha: 0.68),
                              ),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 22,
                          runSpacing: 8,
                          children: [
                            _OpenAirTelemetryStat(
                              label: 'LOCKS',
                              value: '0$_score',
                              color: accent,
                            ),
                            _OpenAirTelemetryStat(
                              label: 'MULTIPLIER',
                              value: '${_combo}X',
                              color: secondary,
                            ),
                            _OpenAirTelemetryStat(
                              label: 'WINDOW',
                              value: '${_timeLeft}S',
                              color: _timeLeft <= 5
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981),
                            ),
                            _OpenAirTelemetryStat(
                              label: 'APEX',
                              value: '0${game.miniGameHighScore}',
                              color: const Color(0xFFF59E0B),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Open-Air Custom-Painted Radar & Laser Crosshair Field (Zero Box Container)
                    SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _radarSweepController,
                                  builder: (context, _) {
                                    return CustomPaint(
                                      painter: _OpenAirBugRadarPainter(
                                        sweep: _radarSweepController.value *
                                            2 *
                                            math.pi,
                                        accent: accent,
                                        secondary: secondary,
                                        isPlaying: _isPlaying,
                                        targetPos: _isPlaying
                                            ? Offset(
                                                _targetX * constraints.maxWidth,
                                                _targetY *
                                                    constraints.maxHeight,
                                              )
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (!_isPlaying)
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/images/dash/dash1.png',
                                      height: 60,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _score > 0
                                          ? 'RADAR SWEEP COMPLETE // $_score ANOMALIES INTERCEPTED'
                                          : 'RADAR STANDBY // INITIALIZE TARGETING MATRIX',
                                      textAlign: TextAlign.center,
                                      style: context.bodySmall.copyWith(
                                        fontSize: 13,
                                        letterSpacing: 1.6,
                                        fontWeight: FontWeight.bold,
                                        color: accent,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    OpenAirActionTrigger(
                                      label: _score > 0
                                          ? 'Re-Engage Radar (+XP)'
                                          : 'Initialize Radar Sweep',
                                      icon: Icons.radar_rounded,
                                      color: accent,
                                      isPrimary: true,
                                      onTap: _startGame,
                                    ),
                                  ],
                                )
                              else
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutBack,
                                  left: (_targetX *
                                          (constraints.maxWidth - 140))
                                      .clamp(8.0, constraints.maxWidth - 140),
                                  top: (_targetY * (constraints.maxHeight - 64))
                                      .clamp(8.0, constraints.maxHeight - 64),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTapDown: (_) => _hitTarget(),
                                      behavior: HitTestBehavior.opaque,
                                      child: CustomPaint(
                                        painter: _TargetCrosshairPainter(
                                          color: currentTarget.$3,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                currentTarget.$1,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'LOCK ON',
                                                style:
                                                    context.bodySmall.copyWith(
                                                  fontSize: 12,
                                                  letterSpacing: 1.4,
                                                  fontWeight: FontWeight.bold,
                                                  color: currentTarget.$3,
                                                  shadows: [
                                                    Shadow(
                                                      color: currentTarget.$3,
                                                      blurRadius: 10,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OpenAirTelemetryStat extends StatelessWidget {
  const _OpenAirTelemetryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.bodySmall.copyWith(
            fontSize: 10,
            letterSpacing: 1.6,
            color: context.primaryColor.withValues(alpha: 0.55),
          ),
        ),
        Text(
          value,
          style: context.displaySmall.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OpenAirBugRadarPainter extends CustomPainter {
  final double sweep;
  final Color accent;
  final Color secondary;
  final bool isPlaying;
  final Offset? targetPos;

  _OpenAirBugRadarPainter({
    required this.sweep,
    required this.accent,
    required this.secondary,
    required this.isPlaying,
    required this.targetPos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width * 0.42, size.height * 0.46);

    final ringPaint = Paint()
      ..color = accent.withValues(alpha: isPlaying ? 0.24 : 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, maxR, ringPaint);
    canvas.drawCircle(center, maxR * 0.65, ringPaint);
    canvas.drawCircle(center, maxR * 0.32, ringPaint);

    // Horizon axis lines across open space
    final axisPaint = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      axisPaint,
    );

    // Rotating sweep line
    final sweepEnd = Offset(
      center.dx + maxR * math.cos(sweep),
      center.dy + maxR * math.sin(sweep),
    );
    canvas.drawLine(
      center,
      sweepEnd,
      Paint()
        ..color = accent.withValues(alpha: 0.55)
        ..strokeWidth = 1.6,
    );

    // Laser lock-on tether when playing
    if (isPlaying && targetPos != null) {
      canvas.drawLine(
        center,
        targetPos!,
        Paint()
          ..color = secondary.withValues(alpha: 0.35)
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OpenAirBugRadarPainter oldDelegate) =>
      oldDelegate.sweep != sweep ||
      oldDelegate.isPlaying != isPlaying ||
      oldDelegate.targetPos != targetPos;
}

class _TargetCrosshairPainter extends CustomPainter {
  final Color color;
  _TargetCrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final cy = size.height / 2;
    canvas.drawCircle(Offset(26, cy), 22, paint);
    // Reticle ticks
    canvas.drawLine(Offset(26, cy - 28), Offset(26, cy - 18), paint);
    canvas.drawLine(Offset(26, cy + 18), Offset(26, cy + 28), paint);
    canvas.drawLine(Offset(0, cy), Offset(8, cy), paint);
  }

  @override
  bool shouldRepaint(covariant _TargetCrosshairPainter oldDelegate) =>
      oldDelegate.color != color;
}
