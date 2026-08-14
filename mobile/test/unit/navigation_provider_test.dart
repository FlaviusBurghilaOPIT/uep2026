import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/providers/app_providers.dart';

void main() {
  test(
    'setTab moves across all 5 tabs (0-4) and rejects out-of-range indices',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(navigationProvider.notifier);
      expect(container.read(navigationProvider).currentIndex, 0);

      notifier.setTab(4);
      expect(container.read(navigationProvider).currentIndex, 4);

      notifier.setTab(5);
      expect(container.read(navigationProvider).currentIndex, 4);

      notifier.setTab(-1);
      expect(container.read(navigationProvider).currentIndex, 4);

      notifier.setTab(1);
      expect(container.read(navigationProvider).currentIndex, 1);
    },
  );
}
