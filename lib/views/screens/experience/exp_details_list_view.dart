import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
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

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(10, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    Future.delayed(Duration.zero, () async {
      for (int i = 0; i < _controllers.length; i++) {
        await Future.delayed(const Duration(milliseconds: 120));
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
    final horizontalPad =
        context.isMobileDevice ? 16.0 : context.screenWidth * 0.08;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
      child: BlocBuilder<ExpDetailsBloc, ExpDetailsState>(
        builder: (context, state) {
          return Wrap(
            spacing: 20,
            runSpacing: 20,
            children: state.isLoading
                ? List.generate(3, (index) {
                    return FadeTransition(
                      opacity: _fadeAnimations[index % _fadeAnimations.length],
                      child: const LoadingExpContainer(),
                    );
                  })
                : List.generate(state.expList.length, (index) {
                    return FadeTransition(
                      opacity: _fadeAnimations[index % _fadeAnimations.length],
                      child: ExpContainer(
                        experience: state.expList[index],
                      ),
                    );
                  }),
          );
        },
      ),
    );
  }
}
