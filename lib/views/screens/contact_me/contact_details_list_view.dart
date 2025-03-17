import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/utils/is_mobile_platform.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_bloc.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_state.dart';
import 'package:spnk/views/screens/contact_me/contact_container.dart';
import 'package:spnk/views/screens/contact_me/loading_contact_container.dart';

class ContactDetailsListView extends StatefulWidget {
  const ContactDetailsListView({super.key});

  @override
  State<ContactDetailsListView> createState() => _ContactDetailsListViewState();
}

class _ContactDetailsListViewState extends State<ContactDetailsListView>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers = [];
  late List<Animation<double>> _flipAnimations = [];

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

    // Create flip animations
    _flipAnimations = _controllers.map((controller) {
      return Tween<double>(begin: -1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Trigger staggered animations
    Future.delayed(Duration.zero, () async {
      for (int i = 0; i < _controllers.length; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
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
    return BlocBuilder<ContactDetailsBloc, ContactDetailsState>(
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
                      return AnimatedBuilder(
                        animation:
                            _flipAnimations[index % _flipAnimations.length],
                        builder: (context, child) {
                          return Transform(
                            transform: Matrix4.rotationY(
                              _flipAnimations[index % _flipAnimations.length]
                                  .value,
                            ),
                            alignment: Alignment.center,
                            child: const LoadingContactContainer(),
                          );
                        },
                      );
                    })
                  : List.generate(state.contactDetailList.length, (index) {
                      final item = state.contactDetailList[index];
                      return AnimatedBuilder(
                        animation:
                            _flipAnimations[index % _flipAnimations.length],
                        builder: (context, child) {
                          return Transform(
                            transform: Matrix4.rotationY(
                              _flipAnimations[index % _flipAnimations.length]
                                  .value,
                            ),
                            alignment: Alignment.center,
                            child: ContactContainer(contactDetails: item),
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
