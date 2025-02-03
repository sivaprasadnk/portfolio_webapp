import 'package:equatable/equatable.dart';

class AboutMeState extends Equatable {
  final String content;
  final bool isLoading;
  const AboutMeState({
    this.content = "",
    this.isLoading = true,
  });

  @override
  List<Object?> get props => [content, isLoading];

  AboutMeState copyWith({
    String? content,
    bool? isLoading,
  }) {
    return AboutMeState(
      content: content ?? this.content,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
