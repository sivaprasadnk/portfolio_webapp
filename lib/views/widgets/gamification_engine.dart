import 'dart:async';
import 'dart:math';

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
      title: 'World Explorer',
      description: 'Navigate or scroll through the portfolio map',
      xpReward: 30,
      icon: Icons.explore_rounded,
    ),
    QuestItem(
      id: 'style_shifter',
      title: 'Dimension Shifter',
      description: 'Switch between Glass, Bento, or Cyber visual styles',
      xpReward: 40,
      icon: Icons.auto_awesome_rounded,
    ),
    QuestItem(
      id: 'lore_reader',
      title: 'Lore Seeker',
      description: 'Inspect a Character Attribute in About Me',
      xpReward: 40,
      icon: Icons.menu_book_rounded,
    ),
    QuestItem(
      id: 'skill_inspector',
      title: 'Tech Collector',
      description: 'Power up any Skill Card in the Skill Tree',
      xpReward: 50,
      icon: Icons.bolt_rounded,
    ),
    QuestItem(
      id: 'career_chronicler',
      title: 'Time Traveler',
      description: 'Inspect a Campaign Stage in Experience',
      xpReward: 50,
      icon: Icons.timeline_rounded,
    ),
    QuestItem(
      id: 'boss_raider',
      title: 'Dungeon Raider',
      description: 'Launch or inspect a Featured Project mission',
      xpReward: 60,
      icon: Icons.rocket_launch_rounded,
    ),
    QuestItem(
      id: 'loot_collector',
      title: 'Loot Hunter',
      description: 'Claim the CV Scroll or tap an Orbiting Social Planet',
      xpReward: 75,
      icon: Icons.workspace_premium_rounded,
    ),
    QuestItem(
      id: 'bug_hunter',
      title: 'Bug Squasher Champion',
      description: 'Score 5+ points in the Dash Bug-Squasher Arcade',
      xpReward: 100,
      icon: Icons.sports_esports_rounded,
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
    if (lvl <= 1) return 'Novice Explorer';
    if (lvl == 2) return 'Code Adventurer';
    if (lvl == 3) return 'Flutter Knight';
    if (lvl == 4) return 'Architecture Mage';
    return 'Grandmaster Legend';
  }

  int getSkillBoost(String skillTitle) => _skillBoosts[skillTitle] ?? 0;

  void boostSkill(String skillTitle) {
    final current = _skillBoosts[skillTitle] ?? 0;
    if (current < 5) {
      _skillBoosts[skillTitle] = current + 1;
      addXp(15, reason: '$skillTitle Boosted (Lv.${current + 1})');
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
      title: '🏆 QUEST UNLOCKED: ${quest.title}',
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
      title: '+$amount XP EARNED',
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
      addXp(score * 5, reason: 'Squashed $score bugs in Arcade!');
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
        final isCyber = themeState.portfolioStyle == PortfolioStyle.cyber;

        return ListenableBuilder(
          listenable: GamificationController.instance,
          builder: (context, _) {
            final game = GamificationController.instance;

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onOpenQuests,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 14,
                    vertical: compact ? 6 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: themeState.cardSurfaceColor,
                    borderRadius: BorderRadius.circular(isCyber ? 6 : 999),
                    border: Border.all(
                      color: accent.withOpacity(0.55),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.16),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent, secondary],
                          ),
                          borderRadius: BorderRadius.circular(isCyber ? 4 : 999),
                        ),
                        child: Text(
                          'LVL ${game.level}',
                          style: context.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: compact ? 48 : 70,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${game.xp} XP',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.bodySmall.copyWith(
                                fontSize: 11,
                                height: 1.0,
                                fontWeight: FontWeight.bold,
                                color: accent,
                              ),
                            ),
                            const SizedBox(height: 3),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: game.levelProgress,
                                minHeight: 5,
                                backgroundColor:
                                    context.primaryColor.withOpacity(0.12),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(accent),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.emoji_events_rounded,
                        size: 16,
                        color: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${game.unlockedQuests.length}/${GamificationController.allQuests.length}',
                        style: context.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
              bottom: 24,
              right: 20,
              left: context.isMobileDevice ? 20 : null,
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey('$title-${game.xp}'),
                    constraints: const BoxConstraints(maxWidth: 340),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: themeState.isDark
                          ? const Color(0xFF0F172A).withOpacity(0.95)
                          : Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFFF59E0B),
                            size: 24,
                          ),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                              if (game.toastSubtitle != null)
                                Text(
                                  game.toastSubtitle!,
                                  style: context.bodySmall.copyWith(
                                    fontSize: 13,
                                    color:
                                        context.primaryColor.withOpacity(0.85),
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
            );
          },
        );
      },
    );
  }
}

void showQuestLogModal(BuildContext context, {VoidCallback? onJumpToArcade}) {
  showDialog(
    context: context,
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
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 540,
                    maxHeight: MediaQuery.of(context).size.height * 0.86,
                  ),
                  child: PortfolioStyledCard(
                    cyberHeader: '~/spnk/quest_log.exe',
                    padding: EdgeInsets.all(context.isMobileDevice ? 18 : 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.emoji_events_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'PLAYER QUEST LOG',
                                          style: context.displaySmall.copyWith(
                                            fontSize: context.isMobileDevice
                                                ? 19
                                                : 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Rank: ${game.rankTitle} • Level ${game.level} (${game.xp} XP)',
                                          style: context.bodySmall.copyWith(
                                            fontSize: 13,
                                            color: accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: Icon(
                                Icons.close_rounded,
                                color: context.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: game.levelProgress,
                            minHeight: 9,
                            backgroundColor:
                                context.primaryColor.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${game.xpInCurrentLevel} / 100 XP to Level ${game.level + 1} • ${game.unlockedQuests.length}/${GamificationController.allQuests.length} Quests Completed',
                          style: context.bodySmall.copyWith(
                            fontSize: 13,
                            color: context.primaryColor.withOpacity(0.65),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children:
                                  GamificationController.allQuests.map((q) {
                                final unlocked =
                                    game.unlockedQuests.contains(q.id);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: unlocked
                                        ? accent.withOpacity(0.12)
                                        : context.primaryColor
                                            .withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: unlocked
                                          ? accent.withOpacity(0.5)
                                          : context.primaryColor
                                              .withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        unlocked
                                            ? Icons.check_circle_rounded
                                            : q.icon,
                                        color: unlocked
                                            ? const Color(0xFF10B981)
                                            : context.primaryColor
                                                .withOpacity(0.45),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              q.title,
                                              style:
                                                  context.bodyMedium.copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: unlocked
                                                    ? context.primaryColor
                                                    : context.primaryColor
                                                        .withOpacity(0.65),
                                              ),
                                            ),
                                            Text(
                                              q.description,
                                              style: context.bodySmall.copyWith(
                                                fontSize: 13,
                                                color: context.primaryColor
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: unlocked
                                              ? const Color(0xFF10B981)
                                                  .withOpacity(0.18)
                                              : secondary.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          unlocked
                                              ? 'CLAIMED'
                                              : '+${q.xpReward} XP',
                                          style: context.bodySmall.copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: unlocked
                                                ? const Color(0xFF10B981)
                                                : secondary,
                                          ),
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
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: themeState.isDark
                                    ? const Color(0xFF090D16)
                                    : Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                onJumpToArcade();
                              },
                              icon: const Icon(Icons.videogame_asset_rounded),
                              label: const Text(
                                'PLAY DASH BUG-SQUASHER ARCADE',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ],
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

class DashBugHuntGameSection extends StatefulWidget {
  const DashBugHuntGameSection({super.key});

  @override
  State<DashBugHuntGameSection> createState() => _DashBugHuntGameSectionState();
}

class _DashBugHuntGameSectionState extends State<DashBugHuntGameSection> {
  final Random _rng = Random();
  bool _isPlaying = false;
  int _score = 0;
  int _combo = 1;
  int _timeLeft = 15;
  double _targetX = 0.5;
  double _targetY = 0.5;
  int _targetType = 0; // 0: Bug, 1: Overflow Bug, 2: Golden Flutter Gem
  Timer? _gameTimer;
  Timer? _moveTimer;

  static const List<(String, String, Color)> _targets = [
    ('🐛', 'NullPointer Bug', Color(0xFFEF4444)),
    ('💥', 'RenderFlex Overflow', Color(0xFFF59E0B)),
    ('💎', 'Flutter Super Gem (+2)', Color(0xFF38BDF8)),
  ];

  @override
  void dispose() {
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
    _targetX = 0.12 + _rng.nextDouble() * 0.76;
    _targetY = 0.16 + _rng.nextDouble() * 0.68;
    _targetType = _rng.nextInt(10) >= 8 ? 2 : _rng.nextInt(2);
  }

  void _hitTarget() {
    if (!_isPlaying) return;
    final bonus = _targetType == 2 ? 2 : 1;
    setState(() {
      _score += bonus;
      _combo = min(_combo + 1, 5);
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
                cyberHeader: '~/arcade/dash_bug_squasher.exe',
                padding: EdgeInsets.all(context.isMobileDevice ? 18 : 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accent.withOpacity(0.25),
                                    secondary.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.videogame_asset_rounded,
                                color: accent,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "DASH'S BUG-SQUASHER ARCADE",
                                    style: context.displaySmall.copyWith(
                                      fontSize:
                                          context.isMobileDevice ? 19 : 23,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Squash 5+ production bugs in 15s to unlock the Champion Quest (+100 XP)!',
                                    style: context.bodySmall.copyWith(
                                      fontSize: 14,
                                      color:
                                          context.primaryColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _StatBadge(
                              label: 'SCORE',
                              value: '$_score',
                              color: accent,
                            ),
                            _StatBadge(
                              label: 'COMBO',
                              value: '${_combo}x',
                              color: secondary,
                            ),
                            _StatBadge(
                              label: 'TIME',
                              value: '${_timeLeft}s',
                              color: _timeLeft <= 5
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981),
                            ),
                            _StatBadge(
                              label: 'BEST',
                              value: '${game.miniGameHighScore}',
                              color: const Color(0xFFF59E0B),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: _isPlaying ? 230 : null,
                      constraints: const BoxConstraints(minHeight: 230),
                      width: double.infinity,
                      padding: _isPlaying
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                      decoration: BoxDecoration(
                        color: themeState.isDark
                            ? Colors.black.withOpacity(0.38)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isPlaying
                              ? accent.withOpacity(0.6)
                              : themeState.cardBorderColor,
                          width: 1.5,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (!_isPlaying) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/dash/dash1.png',
                                    height: 64,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _score > 0
                                        ? 'Mission Complete! You squashed $_score bugs!'
                                        : 'Ready to defend the Flutter build from bugs?',
                                    textAlign: TextAlign.center,
                                    style: context.bodyMedium.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: _startGame,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [accent, secondary],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          boxShadow: [
                                            BoxShadow(
                                              color: accent.withOpacity(0.35),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.play_arrow_rounded,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                _score > 0
                                                    ? 'PLAY AGAIN (+XP)'
                                                    : 'START ARCADE MISSION',
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    context.bodySmall.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final left =
                              (_targetX * (constraints.maxWidth - 130))
                                  .clamp(12.0, constraints.maxWidth - 130);
                          final top =
                              (_targetY * (constraints.maxHeight - 54))
                                  .clamp(12.0, constraints.maxHeight - 54);

                          return Stack(
                            children: [
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutBack,
                                left: left,
                                top: top,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTapDown: (_) => _hitTarget(),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: currentTarget.$3
                                            .withOpacity(0.22),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: currentTarget.$3,
                                          width: 1.8,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: currentTarget.$3
                                                .withOpacity(0.45),
                                            blurRadius: 16,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            currentTarget.$1,
                                            style:
                                                const TextStyle(fontSize: 20),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'TAP!',
                                            style: context.bodySmall.copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: currentTarget.$3,
                                            ),
                                          ),
                                        ],
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

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: context.bodySmall.copyWith(
              fontSize: 12,
              color: context.primaryColor.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: context.bodySmall.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
