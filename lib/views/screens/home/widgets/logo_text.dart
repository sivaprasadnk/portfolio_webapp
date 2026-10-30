import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';

class LogoText extends StatefulWidget {
  const LogoText({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  State<LogoText> createState() => _LogoTextState();
}

class _LogoTextState extends State<LogoText> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isCompact = context.screenWidth < 520;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final accent = state.accentColor;
        final secondary = state.secondaryAccent;
        final isCyber = state.portfolioStyle == PortfolioStyle.cyber;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _hovered
                    ? accent.withValues(alpha: state.isDark ? 0.14 : 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(isCyber ? 6 : 12),
                border: Border.all(
                  color: _hovered
                      ? accent.withValues(alpha: 0.45)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent,
                          secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isCyber ? 5 : 10),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'SP',
                      style: context.displaySmall.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: state.isDark
                            ? const Color(0xFF090D16)
                            : Colors.white,
                      ),
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: 10),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: isCyber ? 'SPNK' : 'spnk',
                            style: context.displaySmall.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: isCyber ? 1.2 : 0.4,
                              color: context.primaryColor,
                            ),
                          ),
                          TextSpan(
                            text: isCyber ? '_OS' : '.dev',
                            style: context.displaySmall.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ],
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
  }
}
