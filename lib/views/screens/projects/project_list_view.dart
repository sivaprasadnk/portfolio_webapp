import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/utils/is_mobile_platform.dart';
import 'package:spnk/views/bloc/project/project_bloc.dart';
import 'package:spnk/views/bloc/project/project_state.dart';
import 'package:spnk/views/screens/projects/loading_project_container.dart';
import 'package:spnk/views/screens/projects/project_container.dart';

class ProjectListView extends StatefulWidget {
  const ProjectListView({super.key});

  @override
  State<ProjectListView> createState() => _ProjectListViewState();
}

class _ProjectListViewState extends State<ProjectListView>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers = [];
  late List<Animation<double>> _fadeAnimations = [];
  late List<Animation<double>> _scaleAnimations = [];
  late List<Animation<Offset>> _slideAnimations = [];

  @override
  void initState() {
    super.initState();

    // Initialize controllers for each item
    _controllers = List.generate(10, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
    });

    // Create fade + scale + slide animations
    _fadeAnimations = _controllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      );
    }).toList();

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ));
    }).toList();

    _slideAnimations = List.generate(_controllers.length, (index) {
      bool isOdd = index.isOdd;

      return Tween<Offset>(
        begin: isMobilePlatform
            ? (isOdd ? const Offset(-1, 0) : const Offset(1, 0))
            : Offset.zero, // No slide on non-mobile devices
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controllers[index],
        curve: Curves.easeInOut,
      ));
    });

    // Start animations with a delay for each item
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
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          height: context.isLargeDevice ? 570 : context.screenHeight - 200,
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              child: Scrollbar(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1.0)
                            .animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: state.isLoading
                        ? List.generate(3, (index) {
                            return FadeTransition(
                              opacity: _fadeAnimations[
                                  index % _fadeAnimations.length],
                              child: const LoadingProjectContainer(),
                            );
                          })
                        : List.generate(state.projectList.length, (index) {
                            final project = state.projectList[index];
                  
                            return AnimatedBuilder(
                              animation:
                                  _controllers[index % _controllers.length],
                              builder: (context, child) {
                                return SlideTransition(
                                  position: _slideAnimations[
                                      index % _slideAnimations.length],
                                  child: ScaleTransition(
                                    scale: _scaleAnimations[
                                        index % _scaleAnimations.length],
                                    child: FadeTransition(
                                      opacity: _fadeAnimations[
                                          index % _fadeAnimations.length],
                                      child: ProjectContainer(
                                        project: project,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    )
        .addLeftPadding(isMobilePlatform ? 20 : context.screenWidth * 0.09)
        .addRightPadding(isMobilePlatform ? 20 : 50);
  }
}
