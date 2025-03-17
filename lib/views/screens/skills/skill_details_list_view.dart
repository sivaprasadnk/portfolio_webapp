import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/utils/is_mobile_platform.dart';
import 'package:spnk/views/bloc/skills/skills_bloc.dart';
import 'package:spnk/views/bloc/skills/skills_state.dart';
import 'package:spnk/views/screens/skills/loading_skills_container.dart';
import 'package:spnk/views/screens/skills/skills_container.dart';

class SkillDetailsListView extends StatefulWidget {
  const SkillDetailsListView({super.key});

  @override
  State<SkillDetailsListView> createState() => _SkillDetailsListViewState();
}

class _SkillDetailsListViewState extends State<SkillDetailsListView>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers = [];
  late List<Animation<double>> _fadeAnimations = [];
  late List<Animation<Offset>> _slideAnimations = [];

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers and animations for each item
    _controllers = List.generate(10, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
    });

    _fadeAnimations = _controllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      );
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0.0, 0.5), // Slide from bottom
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    // Trigger animations with staggered delay
    Future.delayed(Duration.zero, () async {
      for (int i = 0; i < _controllers.length; i++) {
        await Future.delayed(
            const Duration(milliseconds: 150)); // Stagger delay
        if (mounted) {
          _controllers[i].forward();
        }
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SkillDetailsBloc, SkillsState>(
      builder: (_, state) {
        return SizedBox(
          height: context.isLargeDevice ? 570 : context.screenHeight - 200,
          width: double.infinity,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: state.isLoading
                  ? List.generate(3, (index) {
                      return FadeTransition(
                        opacity:
                            _fadeAnimations[index % _fadeAnimations.length],
                        child: const LoadingSkillsContainer(),
                      );
                    })
                  : List.generate(state.skillDetails.length, (index) {
                      final item = state.skillDetails[index];
                      return AnimatedBuilder(
                        animation: _controllers[index % _controllers.length],
                        builder: (context, child) {
                          return SlideTransition(
                            position: _slideAnimations[
                                index % _slideAnimations.length],
                            child: FadeTransition(
                              opacity: _fadeAnimations[
                                  index % _fadeAnimations.length],
                              child: SkillsContainer(skillDetails: item),
                            ),
                          );
                        },
                      );
                    }),
            ),
          ),
        );
      },
    )
        .addLeftPadding(isMobilePlatform ? 20 : context.screenWidth * 0.09)
        .addRightPadding(isMobilePlatform ? 20 : 50);
  }
}
