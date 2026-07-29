import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_providers.freezed.dart';
part 'app_providers.g.dart';

// ---------------------------------------------------------------------------
// Navigation state — tracks the selected bottom-nav tab.
// ---------------------------------------------------------------------------

@freezed
abstract class NavigationState with _$NavigationState {
  const factory NavigationState({@Default(0) int currentIndex}) =
      _NavigationState;
}

@Riverpod(keepAlive: true)
class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() => const NavigationState();

  int get currentIndex => state.currentIndex;

  void setTab(int index, {bool notify = true}) {
    if (index < 0 || index > 4 || state.currentIndex == index) return;
    state = NavigationState(currentIndex: index);
  }
}
