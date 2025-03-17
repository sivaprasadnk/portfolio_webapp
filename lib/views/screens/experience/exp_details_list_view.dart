import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/utils/is_mobile_platform.dart';
import 'package:spnk/views/bloc/experience/exp_details_bloc.dart';
import 'package:spnk/views/bloc/experience/exp_details_state.dart';
import 'package:spnk/views/screens/experience/exp_container.dart';
import 'package:spnk/views/screens/experience/loading_exp_container.dart';

class ExpDetailsListView extends StatefulWidget {
  const ExpDetailsListView({super.key});

  @override
  State<ExpDetailsListView> createState() => _ExpDetailsListViewState();
}

class _ExpDetailsListViewState extends State<ExpDetailsListView>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(10, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 900),
        vsync: this,
      );
    });

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeIn),
      );
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
          .animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    // Trigger staggered animations
    Future.delayed(Duration.zero, () async {
      for (int i = 0; i < _controllers.length; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) _controllers[i].forward();
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
    return BlocBuilder<ExpDetailsBloc, ExpDetailsState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          height: context.isLargeDevice ? 570 : context.screenHeight - 200,
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              child: Scrollbar(
                child: context.isLargeDevice
                    ? Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: state.isLoading
                            ? List.generate(3, (index) {
                                return _buildAnimatedItem(
                                  index,
                                  const LoadingExpContainer(),
                                );
                              })
                            : List.generate(state.expList.length, (index) {
                                return _buildAnimatedItem(
                                  index,
                                  ExpContainer(
                                    experience: state.expList[index],
                                  ),
                                );
                              }),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: state.isLoading
                            ? List.generate(3, (index) {
                                return _buildAnimatedItem(
                                  index,
                                  const LoadingExpContainer(),
                                );
                              })
                            : List.generate(state.expList.length, (index) {
                                return _buildAnimatedItem(
                                  index,
                                  ExpContainer(
                                    experience: state.expList[index],
                                  ),
                                );
                              }),
                      ),
              ),
            ),
          ),
        );
      },
    )
        .addLeftPadding(
          isMobilePlatform ? 20 : context.screenWidth * 0.09,
        )
        .addRightPadding(
          isMobilePlatform ? 20 : 50,
        );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    return AnimatedBuilder(
      animation: _controllers[index % _controllers.length],
      builder: (context, _) {
        return Opacity(
          opacity: _fadeAnimations[index % _fadeAnimations.length].value,
          child: Transform.translate(
            offset: _slideAnimations[index % _slideAnimations.length].value,
            child: child,
          ),
        );
      },
    );
  }
}
