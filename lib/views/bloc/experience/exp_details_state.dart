import 'package:equatable/equatable.dart';
import 'package:spnk/domain/entity/experience_details.dart';

class ExpDetailsState extends Equatable {
  final List<ExperienceDetails> expList;
  final bool isLoading;
  const ExpDetailsState({
    this.expList = const [],
    this.isLoading = true,
  });

  @override
  List<Object?> get props => [expList, isLoading];

  ExpDetailsState copyWith({List<ExperienceDetails>? list, bool? loading}) {
    return ExpDetailsState(
      expList: list ?? expList,
      isLoading: loading ?? isLoading,
    );
  }
}
