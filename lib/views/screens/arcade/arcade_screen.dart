import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';

class ArcadeScreen extends StatefulWidget {
  const ArcadeScreen({super.key});

  static const routeName = '/arcade';

  @override
  State<ArcadeScreen> createState() => _ArcadeScreenState();
}

enum _ArcadeGame {
  snake(
    title: 'Neon Snake',
    subtitle: 'Classic cyber serpent',
    icon: Icons.timeline_rounded,
  ),
  puzzle2048(
    title: '2048 Grid',
    subtitle: 'Power-of-two merge puzzle',
    icon: Icons.grid_4x4_rounded,
  ),
  breaker(
    title: 'Cyber Breaker',
    subtitle: 'Arcade brick smasher',
    icon: Icons.view_week_rounded,
  ),
  memory(
    title: 'Memory Matrix',
    subtitle: ' Neural pair matching',
    icon: Icons.memory_rounded,
  );

  const _ArcadeGame({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _ArcadeScreenState extends State<ArcadeScreen> {
  _ArcadeGame _selectedGame = _ArcadeGame.snake;

  @override
  void initState() {
    super.initState();
    final gameParam = Uri.base.queryParameters['game']?.toLowerCase();
    if (gameParam == '2048') {
      _selectedGame = _ArcadeGame.puzzle2048;
    } else if (gameParam == 'breaker') {
      _selectedGame = _ArcadeGame.breaker;
    } else if (gameParam == 'memory') {
      _selectedGame = _ArcadeGame.memory;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileDevice;

    return PortfolioStyleBackground(
      child: Theme(
        data: Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sports_esports_rounded,
                  size: 24,
                  color: context.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'SPNK Arcade Hub',
                  style: context.displaySmall.copyWith(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          body: BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              final accent = themeState.accentColor;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 14 : 24,
                    vertical: isMobile ? 12 : 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      decoration: BoxDecoration(
                        color: themeState.cardSurfaceColor,
                        borderRadius:
                            BorderRadius.circular(themeState.cardRadius),
                        border: Border.all(
                          color: themeState.cardBorderColor,
                          width: 1.1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildGameSelector(themeState, accent, isMobile),
                          const SizedBox(height: 20),
                          _buildActiveGame(themeState, accent),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGameSelector(
    ThemeState themeState,
    Color accent,
    bool isMobile,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _ArcadeGame.values.map((game) {
        final selected = _selectedGame == game;
        final itemWidth = isMobile
            ? (MediaQuery.of(context).size.width - 72) / 2
            : 146.0;
        return GestureDetector(
          onTap: () => setState(() => _selectedGame = game),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: itemWidth,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: themeState.isDark ? 0.2 : 0.14)
                    : context.primaryColor
                        .withValues(alpha: themeState.isDark ? 0.04 : 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? accent : themeState.cardBorderColor,
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    game.icon,
                    size: 18,
                    color: selected
                        ? accent
                        : context.primaryColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      game.title,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodySmall.copyWith(
                        fontSize: 13.5,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w600,
                        color: selected
                            ? (themeState.isDark ? Colors.white : accent)
                            : context.primaryColor.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActiveGame(ThemeState themeState, Color accent) {
    switch (_selectedGame) {
      case _ArcadeGame.snake:
        return _NeonSnakeGame(accent: accent, themeState: themeState);
      case _ArcadeGame.puzzle2048:
        return _Game2048Widget(accent: accent, themeState: themeState);
      case _ArcadeGame.breaker:
        return _CyberBreakerGame(accent: accent, themeState: themeState);
      case _ArcadeGame.memory:
        return _MemoryMatrixGame(accent: accent, themeState: themeState);
    }
  }
}

// ============================================================================
// 1. NEON SNAKE GAME
// ============================================================================

class _NeonSnakeGame extends StatefulWidget {
  const _NeonSnakeGame({
    required this.accent,
    required this.themeState,
  });

  final Color accent;
  final ThemeState themeState;

  @override
  State<_NeonSnakeGame> createState() => _NeonSnakeGameState();
}

class _NeonSnakeGameState extends State<_NeonSnakeGame> {
  static const int _gridSize = 16;
  final Random _rng = Random();
  final FocusNode _focusNode = FocusNode();

  List<Point<int>> _snake = [
    const Point(8, 8),
    const Point(7, 8),
    const Point(6, 8),
  ];
  Point<int> _direction = const Point(1, 0);
  Point<int> _nextDirection = const Point(1, 0);
  Point<int> _food = const Point(12, 8);

  bool _isRunning = false;
  bool _isGameOver = false;
  int _score = 0;
  int _bestScore = 0;
  Timer? _tickTimer;

  @override
  void dispose() {
    _tickTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startOrResume() {
    if (_isGameOver) {
      _resetGame();
    }
    setState(() {
      _isRunning = true;
    });
    _focusNode.requestFocus();
    _scheduleTimer();
  }

  void _pauseGame() {
    _tickTimer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetGame() {
    _tickTimer?.cancel();
    setState(() {
      _snake = [
        const Point(8, 8),
        const Point(7, 8),
        const Point(6, 8),
      ];
      _direction = const Point(1, 0);
      _nextDirection = const Point(1, 0);
      _score = 0;
      _isGameOver = false;
      _isRunning = false;
      _spawnFood();
    });
  }

  void _scheduleTimer() {
    _tickTimer?.cancel();
    final speedMs = max(75, 155 - (_score ~/ 25) * 8);
    _tickTimer = Timer.periodic(Duration(milliseconds: speedMs), (_) => _tick());
  }

  void _spawnFood() {
    while (true) {
      final candidate = Point(_rng.nextInt(_gridSize), _rng.nextInt(_gridSize));
      if (!_snake.contains(candidate)) {
        _food = candidate;
        break;
      }
    }
  }

  void _changeDirection(Point<int> newDir) {
    if (_direction.x + newDir.x == 0 && _direction.y + newDir.y == 0) {
      return;
    }
    _nextDirection = newDir;
    if (!_isRunning && !_isGameOver) {
      _startOrResume();
    }
  }

  void _tick() {
    if (!_isRunning || _isGameOver || !mounted) return;
    _direction = _nextDirection;
    final head = _snake.first;
    final nextHead = Point(head.x + _direction.x, head.y + _direction.y);

    if (nextHead.x < 0 ||
        nextHead.x >= _gridSize ||
        nextHead.y < 0 ||
        nextHead.y >= _gridSize ||
        _snake.contains(nextHead)) {
      _tickTimer?.cancel();
      setState(() {
        _isRunning = false;
        _isGameOver = true;
        if (_score > _bestScore) {
          _bestScore = _score;
        }
      });
      return;
    }

    setState(() {
      _snake.insert(0, nextHead);
      if (nextHead == _food) {
        _score += 10;
        if (_score > _bestScore) {
          _bestScore = _score;
        }
        _spawnFood();
        _scheduleTimer();
      } else {
        _snake.removeLast();
      }
    });
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      _changeDirection(const Point(0, -1));
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      _changeDirection(const Point(0, 1));
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA) {
      _changeDirection(const Point(-1, 0));
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      _changeDirection(const Point(1, 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Column(
        children: [
          _ScoreHeaderBar(
            title: 'Neon Snake',
            scoreLabel: 'SCORE: $_score',
            bestLabel: 'BEST: $_bestScore',
            accent: accent,
            actionButton: ElevatedButton.icon(
              onPressed: _isRunning ? _pauseGame : _startOrResume,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: widget.themeState.isDark
                    ? const Color(0xFF090D16)
                    : Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: Icon(
                _isRunning
                    ? Icons.pause_rounded
                    : (_isGameOver
                        ? Icons.replay_rounded
                        : Icons.play_arrow_rounded),
                size: 18,
              ),
              label: Text(
                _isRunning
                    ? 'Pause'
                    : (_isGameOver ? 'Play Again' : 'Start'),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              onVerticalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v < -50) _changeDirection(const Point(0, -1));
                if (v > 50) _changeDirection(const Point(0, 1));
              },
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v < -50) _changeDirection(const Point(-1, 0));
                if (v > 50) _changeDirection(const Point(1, 0));
              },
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFF090D16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.themeState.cardBorderColor,
                    width: 1.4,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _SnakeBoardPainter(
                        gridSize: _gridSize,
                        snake: _snake,
                        food: _food,
                        accent: accent,
                      ),
                    ),
                    if (!_isRunning)
                      Container(
                        color: Colors.black.withValues(alpha: 0.58),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isGameOver ? 'GAME OVER' : 'NEON SNAKE',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _isGameOver
                                    ? const Color(0xFFF87171)
                                    : Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Use Arrow keys, WASD, swipe, or D-pad below',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _startOrResume,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: const Color(0xFF090D16),
                              ),
                              child: Text(
                                _isGameOver ? 'Play Again' : 'Start Game',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
          const SizedBox(height: 14),
          _DirectionalPad(
            accent: accent,
            borderColor: widget.themeState.cardBorderColor,
            onUp: () => _changeDirection(const Point(0, -1)),
            onDown: () => _changeDirection(const Point(0, 1)),
            onLeft: () => _changeDirection(const Point(-1, 0)),
            onRight: () => _changeDirection(const Point(1, 0)),
          ),
        ],
      ),
    );
  }
}

class _SnakeBoardPainter extends CustomPainter {
  _SnakeBoardPainter({
    required this.gridSize,
    required this.snake,
    required this.food,
    required this.accent,
  });

  final int gridSize;
  final List<Point<int>> snake;
  final Point<int> food;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / gridSize;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    for (int i = 1; i < gridSize; i++) {
      canvas.drawLine(
        Offset(i * cell, 0),
        Offset(i * cell, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, i * cell),
        Offset(size.width, i * cell),
        gridPaint,
      );
    }

    // Draw food
    final foodPaint = Paint()..color = const Color(0xFFF43F5E);
    canvas.drawCircle(
      Offset((food.x + 0.5) * cell, (food.y + 0.5) * cell),
      cell * 0.38,
      foodPaint,
    );

    // Draw snake
    for (int i = 0; i < snake.length; i++) {
      final p = snake[i];
      final isHead = i == 0;
      final paint = Paint()
        ..color = isHead
            ? accent
            : accent.withValues(alpha: max(0.35, 0.9 - (i * 0.03)));
      final rect = Rect.fromLTWH(
        p.x * cell + 1.2,
        p.y * cell + 1.2,
        cell - 2.4,
        cell - 2.4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SnakeBoardPainter oldDelegate) => true;
}

// ============================================================================
// 2. 2048 CYBER GRID GAME
// ============================================================================

class _Game2048Widget extends StatefulWidget {
  const _Game2048Widget({
    required this.accent,
    required this.themeState,
  });

  final Color accent;
  final ThemeState themeState;

  @override
  State<_Game2048Widget> createState() => _Game2048WidgetState();
}

class _Game2048WidgetState extends State<_Game2048Widget> {
  final Random _rng = Random();
  final FocusNode _focusNode = FocusNode();
  late List<List<int>> _board;
  int _score = 0;
  int _bestScore = 0;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _initBoard();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _initBoard() {
    _board = List.generate(4, (_) => List.filled(4, 0));
    _score = 0;
    _gameOver = false;
    _addRandomTile();
    _addRandomTile();
  }

  void _addRandomTile() {
    final empty = <Point<int>>[];
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (_board[r][c] == 0) empty.add(Point(r, c));
      }
    }
    if (empty.isEmpty) return;
    final pick = empty[_rng.nextInt(empty.length)];
    _board[pick.x][pick.y] = _rng.nextDouble() < 0.9 ? 2 : 4;
  }

  bool _canMove() {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (_board[r][c] == 0) return true;
        if (c < 3 && _board[r][c] == _board[r][c + 1]) return true;
        if (r < 3 && _board[r][c] == _board[r + 1][c]) return true;
      }
    }
    return false;
  }

  List<int> _slideAndMergeRow(List<int> row) {
    final nonZero = row.where((v) => v != 0).toList();
    final merged = <int>[];
    int i = 0;
    while (i < nonZero.length) {
      if (i + 1 < nonZero.length && nonZero[i] == nonZero[i + 1]) {
        final val = nonZero[i] * 2;
        merged.add(val);
        _score += val;
        if (_score > _bestScore) _bestScore = _score;
        i += 2;
      } else {
        merged.add(nonZero[i]);
        i++;
      }
    }
    while (merged.length < 4) {
      merged.add(0);
    }
    return merged;
  }

  void _move(String dir) {
    if (_gameOver) return;
    bool changed = false;

    setState(() {
      if (dir == 'left' || dir == 'right') {
        for (var r = 0; r < 4; r++) {
          final current = List<int>.from(_board[r]);
          final input = dir == 'right' ? current.reversed.toList() : current;
          final res = _slideAndMergeRow(input);
          final finalRow = dir == 'right' ? res.reversed.toList() : res;
          for (var c = 0; c < 4; c++) {
            if (_board[r][c] != finalRow[c]) changed = true;
            _board[r][c] = finalRow[c];
          }
        }
      } else {
        for (var c = 0; c < 4; c++) {
          final col = [_board[0][c], _board[1][c], _board[2][c], _board[3][c]];
          final input = dir == 'down' ? col.reversed.toList() : col;
          final res = _slideAndMergeRow(input);
          final finalCol = dir == 'down' ? res.reversed.toList() : res;
          for (var r = 0; r < 4; r++) {
            if (_board[r][c] != finalCol[r]) changed = true;
            _board[r][c] = finalCol[r];
          }
        }
      }

      if (changed) {
        _addRandomTile();
        if (!_canMove()) {
          _gameOver = true;
        }
      }
    });
  }

  Color _tileColor(int val) {
    switch (val) {
      case 0:
        return const Color(0xFF161F30);
      case 2:
        return const Color(0xFF1E293B);
      case 4:
        return const Color(0xFF334155);
      case 8:
        return const Color(0xFF0284C7);
      case 16:
        return const Color(0xFF2563EB);
      case 32:
        return const Color(0xFF4F46E5);
      case 64:
        return const Color(0xFF7C3AED);
      case 128:
        return const Color(0xFF9333EA);
      case 256:
        return const Color(0xFFC026D3);
      case 512:
        return const Color(0xFFE11D48);
      case 1024:
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        final k = event.logicalKey;
        if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW) {
          _move('up');
        } else if (k == LogicalKeyboardKey.arrowDown ||
            k == LogicalKeyboardKey.keyS) {
          _move('down');
        } else if (k == LogicalKeyboardKey.arrowLeft ||
            k == LogicalKeyboardKey.keyA) {
          _move('left');
        } else if (k == LogicalKeyboardKey.arrowRight ||
            k == LogicalKeyboardKey.keyD) {
          _move('right');
        }
      },
      child: Column(
        children: [
          _ScoreHeaderBar(
            title: '2048 Grid',
            scoreLabel: 'SCORE: $_score',
            bestLabel: 'BEST: $_bestScore',
            accent: accent,
            actionButton: ElevatedButton.icon(
              onPressed: () => setState(_initBoard),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: widget.themeState.isDark
                    ? const Color(0xFF090D16)
                    : Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'New Game',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              onVerticalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < -40) _move('up');
                if (v > 40) _move('down');
              },
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < -40) _move('left');
                if (v > 40) _move('right');
              },
              child: Container(
                width: 296,
                height: 296,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF090D16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.themeState.cardBorderColor,
                    width: 1.4,
                  ),
                ),
                child: Stack(
                  children: [
                    Column(
                      children: List.generate(4, (r) {
                        return Expanded(
                          child: Row(
                            children: List.generate(4, (c) {
                              final val = _board[r][c];
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _tileColor(val),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    val == 0 ? '' : '$val',
                                    style: TextStyle(
                                      fontSize: val >= 1000 ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                    if (_gameOver)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'NO MORE MOVES',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF87171),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => setState(_initBoard),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: const Color(0xFF090D16),
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _DirectionalPad(
            accent: accent,
            borderColor: widget.themeState.cardBorderColor,
            onUp: () => _move('up'),
            onDown: () => _move('down'),
            onLeft: () => _move('left'),
            onRight: () => _move('right'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. CYBER BREAKER (BREAKOUT) GAME
// ============================================================================

class _Brick {
  _Brick({required this.rect, required this.color});
  final Rect rect;
  final Color color;
  bool alive = true;
}

class _CyberBreakerGame extends StatefulWidget {
  const _CyberBreakerGame({
    required this.accent,
    required this.themeState,
  });

  final Color accent;
  final ThemeState themeState;

  @override
  State<_CyberBreakerGame> createState() => _CyberBreakerGameState();
}

class _CyberBreakerGameState extends State<_CyberBreakerGame> {
  static const double _arenaW = 300;
  static const double _arenaH = 300;
  static const double _paddleW = 68;
  static const double _paddleH = 10;

  double _paddleX = (_arenaW - _paddleW) / 2;
  Offset _ball = const Offset(_arenaW / 2, _arenaH - 42);
  Offset _ballVel = const Offset(2.8, -3.2);

  final List<_Brick> _bricks = [];
  bool _running = false;
  bool _gameOver = false;
  bool _won = false;
  int _score = 0;
  int _bestScore = 0;
  Timer? _loop;

  @override
  void initState() {
    super.initState();
    _setupLevel();
  }

  @override
  void dispose() {
    _loop?.cancel();
    super.dispose();
  }

  void _setupLevel() {
    _loop?.cancel();
    _bricks.clear();
    const rows = 4;
    const cols = 6;
    const pad = 6.0;
    const topOffset = 24.0;
    final brickW = (_arenaW - pad * (cols + 1)) / cols;
    const brickH = 14.0;
    const rowColors = [
      Color(0xFFF43F5E),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFF38BDF8),
    ];

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final left = pad + c * (brickW + pad);
        final top = topOffset + r * (brickH + pad);
        _bricks.add(
          _Brick(
            rect: Rect.fromLTWH(left, top, brickW, brickH),
            color: rowColors[r % rowColors.length],
          ),
        );
      }
    }

    _paddleX = (_arenaW - _paddleW) / 2;
    _ball = const Offset(_arenaW / 2, _arenaH - 42);
    _ballVel = const Offset(2.7, -3.1);
    _score = 0;
    _gameOver = false;
    _won = false;
    _running = false;
  }

  void _toggleStart() {
    if (_gameOver || _won) {
      setState(_setupLevel);
    }
    if (_running) {
      _loop?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _loop = Timer.periodic(const Duration(milliseconds: 16), (_) => _step());
    }
  }

  void _step() {
    if (!_running || !mounted) return;
    setState(() {
      var next = _ball + _ballVel;
      var vx = _ballVel.dx;
      var vy = _ballVel.dy;

      if (next.dx <= 6 || next.dx >= _arenaW - 6) {
        vx = -vx;
        next = Offset(next.dx.clamp(6.0, _arenaW - 6.0), next.dy);
      }
      if (next.dy <= 6) {
        vy = -vy;
        next = Offset(next.dx, 6);
      }

      // Paddle collision
      final paddleRect = Rect.fromLTWH(
        _paddleX,
        _arenaH - 24,
        _paddleW,
        _paddleH,
      );
      if (vy > 0 && paddleRect.inflate(5).contains(next)) {
        final hitOffset =
            ((next.dx - (_paddleX + _paddleW / 2)) / (_paddleW / 2))
                .clamp(-1.0, 1.0);
        vx = hitOffset * 3.8;
        vy = -vy.abs();
        next = Offset(next.dx, _arenaH - 30);
      }

      // Brick collision
      for (final b in _bricks) {
        if (!b.alive) continue;
        if (b.rect.inflate(4).contains(next)) {
          b.alive = false;
          vy = -vy;
          _score += 15;
          if (_score > _bestScore) _bestScore = _score;
          break;
        }
      }

      if (_bricks.every((b) => !b.alive)) {
        _won = true;
        _running = false;
        _loop?.cancel();
        return;
      }

      if (next.dy >= _arenaH - 4) {
        _gameOver = true;
        _running = false;
        _loop?.cancel();
        return;
      }

      _ball = next;
      _ballVel = Offset(vx, vy);
    });
  }

  void _movePaddleBy(double delta) {
    setState(() {
      _paddleX = (_paddleX + delta).clamp(0.0, _arenaW - _paddleW);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;

    return Column(
      children: [
        _ScoreHeaderBar(
          title: 'Cyber Breaker',
          scoreLabel: 'SCORE: $_score',
          bestLabel: 'BEST: $_bestScore',
          accent: accent,
          actionButton: ElevatedButton.icon(
            onPressed: _toggleStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: widget.themeState.isDark
                  ? const Color(0xFF090D16)
                  : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: Icon(
              _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 18,
            ),
            label: Text(
              _running
                  ? 'Pause'
                  : (_gameOver || _won ? 'Play Again' : 'Start'),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: MouseRegion(
            onHover: (e) {
              setState(() {
                _paddleX = (e.localPosition.dx - _paddleW / 2)
                    .clamp(0.0, _arenaW - _paddleW);
              });
            },
            child: GestureDetector(
              onHorizontalDragUpdate: (d) {
                setState(() {
                  _paddleX = (d.localPosition.dx - _paddleW / 2)
                      .clamp(0.0, _arenaW - _paddleW);
                });
              },
              child: Container(
                width: _arenaW,
                height: _arenaH,
                decoration: BoxDecoration(
                  color: const Color(0xFF090D16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.themeState.cardBorderColor,
                    width: 1.4,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _BreakerPainter(
                        bricks: _bricks,
                        paddleX: _paddleX,
                        paddleW: _paddleW,
                        paddleH: _paddleH,
                        ball: _ball,
                        accent: accent,
                      ),
                    ),
                    if (!_running)
                      Container(
                        color: Colors.black.withValues(alpha: 0.58),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _won
                                  ? 'STAGE CLEARED!'
                                  : (_gameOver ? 'GAME OVER' : 'CYBER BREAKER'),
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: _won
                                    ? const Color(0xFF10B981)
                                    : (_gameOver
                                        ? const Color(0xFFF87171)
                                        : Colors.white),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Move mouse or drag horizontally to control paddle',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _toggleStart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: const Color(0xFF090D16),
                              ),
                              child: Text(
                                _gameOver || _won ? 'Play Again' : 'Launch Ball',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.outlined(
              onPressed: () => _movePaddleBy(-28),
              icon: Icon(Icons.chevron_left_rounded, color: accent),
            ),
            const SizedBox(width: 16),
            IconButton.outlined(
              onPressed: () => _movePaddleBy(28),
              icon: Icon(Icons.chevron_right_rounded, color: accent),
            ),
          ],
        ),
      ],
    );
  }
}

class _BreakerPainter extends CustomPainter {
  _BreakerPainter({
    required this.bricks,
    required this.paddleX,
    required this.paddleW,
    required this.paddleH,
    required this.ball,
    required this.accent,
  });

  final List<_Brick> bricks;
  final double paddleX;
  final double paddleW;
  final double paddleH;
  final Offset ball;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bricks) {
      if (!b.alive) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(b.rect, const Radius.circular(4)),
        Paint()..color = b.color,
      );
    }

    // Paddle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(paddleX, size.height - 24, paddleW, paddleH),
        const Radius.circular(6),
      ),
      Paint()..color = accent,
    );

    // Ball
    canvas.drawCircle(
      ball,
      6,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _BreakerPainter oldDelegate) => true;
}

// ============================================================================
// 4. MEMORY MATRIX GAME
// ============================================================================

class _MemoryMatrixGame extends StatefulWidget {
  const _MemoryMatrixGame({
    required this.accent,
    required this.themeState,
  });

  final Color accent;
  final ThemeState themeState;

  @override
  State<_MemoryMatrixGame> createState() => _MemoryMatrixGameState();
}

class _MemoryMatrixGameState extends State<_MemoryMatrixGame> {
  static const List<IconData> _icons = [
    Icons.bolt_rounded,
    Icons.rocket_launch_rounded,
    Icons.terminal_rounded,
    Icons.qr_code_2_rounded,
    Icons.memory_rounded,
    Icons.auto_awesome_rounded,
    Icons.shield_rounded,
    Icons.public_rounded,
  ];

  late List<IconData> _deck;
  late List<bool> _revealed;
  late List<bool> _matched;
  int? _firstIndex;
  bool _busy = false;
  int _moves = 0;
  int? _bestMoves;

  @override
  void initState() {
    super.initState();
    _resetDeck();
  }

  void _resetDeck() {
    _deck = [..._icons, ..._icons]..shuffle(Random());
    _revealed = List.filled(16, false);
    _matched = List.filled(16, false);
    _firstIndex = null;
    _busy = false;
    _moves = 0;
  }

  void _onTileTap(int index) {
    if (_busy || _revealed[index] || _matched[index]) return;

    setState(() {
      _revealed[index] = true;
    });

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    final first = _firstIndex!;
    _firstIndex = null;
    _moves++;

    if (_deck[first] == _deck[index]) {
      setState(() {
        _matched[first] = true;
        _matched[index] = true;
        if (_matched.every((m) => m)) {
          if (_bestMoves == null || _moves < _bestMoves!) {
            _bestMoves = _moves;
          }
        }
      });
    } else {
      _busy = true;
      Future.delayed(const Duration(milliseconds: 550), () {
        if (!mounted) return;
        setState(() {
          _revealed[first] = false;
          _revealed[index] = false;
          _busy = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final pairsFound = _matched.where((m) => m).length ~/ 2;

    return Column(
      children: [
        _ScoreHeaderBar(
          title: 'Memory Matrix',
          scoreLabel: 'MOVES: $_moves ($pairsFound/8)',
          bestLabel: 'BEST: ${_bestMoves ?? '-'}',
          accent: accent,
          actionButton: ElevatedButton.icon(
            onPressed: () => setState(_resetDeck),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: widget.themeState.isDark
                  ? const Color(0xFF090D16)
                  : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Reset',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: SizedBox(
            width: 296,
            height: 296,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 16,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final isOpen = _revealed[index] || _matched[index];
                final isDone = _matched[index];
                return GestureDetector(
                  onTap: () => _onTileTap(index),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: isDone
                            ? accent.withValues(alpha: 0.24)
                            : (isOpen
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF0F172A)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOpen
                              ? accent
                              : widget.themeState.cardBorderColor,
                          width: isOpen ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: isOpen
                          ? Icon(
                              _deck[index],
                              size: 26,
                              color: isDone ? accent : Colors.white,
                            )
                          : Icon(
                              Icons.question_mark_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SHARED UI HELPERS
// ============================================================================

class _ScoreHeaderBar extends StatelessWidget {
  const _ScoreHeaderBar({
    required this.title,
    required this.scoreLabel,
    required this.bestLabel,
    required this.accent,
    required this.actionButton,
  });

  final String title;
  final String scoreLabel;
  final String bestLabel;
  final Color accent;
  final Widget actionButton;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                scoreLabel,
                style: context.bodySmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                bestLabel,
                style: context.bodySmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: context.primaryColor.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
        actionButton,
      ],
    );
  }
}

class _DirectionalPad extends StatelessWidget {
  const _DirectionalPad({
    required this.accent,
    required this.borderColor,
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
  });

  final Color accent;
  final Color borderColor;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PadBtn(
          icon: Icons.keyboard_arrow_left_rounded,
          onTap: onLeft,
          borderColor: borderColor,
        ),
        const SizedBox(width: 6),
        Column(
          children: [
            _PadBtn(
              icon: Icons.keyboard_arrow_up_rounded,
              onTap: onUp,
              borderColor: borderColor,
            ),
            const SizedBox(height: 6),
            _PadBtn(
              icon: Icons.keyboard_arrow_down_rounded,
              onTap: onDown,
              borderColor: borderColor,
            ),
          ],
        ),
        const SizedBox(width: 6),
        _PadBtn(
          icon: Icons.keyboard_arrow_right_rounded,
          onTap: onRight,
          borderColor: borderColor,
        ),
      ],
    );
  }
}

class _PadBtn extends StatelessWidget {
  const _PadBtn({
    required this.icon,
    required this.onTap,
    required this.borderColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 22, color: context.primaryColor),
      ),
    );
  }
}
