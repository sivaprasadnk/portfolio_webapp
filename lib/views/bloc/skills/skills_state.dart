import 'package:equatable/equatable.dart';
import 'package:spnk/domain/entity/skill_details.dart';

class SkillsState extends Equatable {
  final List<SkillDetails> skillDetails;
  final bool isLoading;

  const SkillsState({
    this.skillDetails = const [],
    this.isLoading = true,
  });

  SkillsState copyWith({
    List<SkillDetails>? details,
    bool? isLoading,
  }) {
    return SkillsState(
      skillDetails: details ?? skillDetails,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [skillDetails, isLoading];
}
