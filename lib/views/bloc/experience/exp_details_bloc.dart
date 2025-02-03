import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/domain/use_case/get_exp_details.dart';
import 'package:spnk/utils/locator.dart';
import 'package:spnk/views/bloc/experience/exp_details_event.dart';
import 'package:spnk/views/bloc/experience/exp_details_state.dart';

class ExpDetailsBloc extends Bloc<ExpDetailsEvent, ExpDetailsState> {
  ExpDetailsBloc() : super(const ExpDetailsState()) {
    on<FetchExpDetails>(_getExpDetails);
  }

  Future<void> _getExpDetails(
    FetchExpDetails event,
    Emitter<ExpDetailsState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    final list = await locator<GetExpDetails>().call();
    list.sort((a, b) => b.order.compareTo(a.order));
    emit(state.copyWith(loading: false, list: list));
  }
}
