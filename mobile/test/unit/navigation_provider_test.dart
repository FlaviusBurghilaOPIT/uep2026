import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/providers/app_providers.dart';

void main() {
  test(
    'setTab moves across all 5 tabs (0-4) and rejects out-of-range indices',
    () {
      final notifier = NavigationNotifier();
      expect(notifier.currentIndex, 0);

      notifier.setTab(4);
      expect(notifier.currentIndex, 4);

      notifier.setTab(5);
      expect(notifier.currentIndex, 4);

      notifier.setTab(-1);
      expect(notifier.currentIndex, 4);

      notifier.setTab(1);
      expect(notifier.currentIndex, 1);
    },
  );
}
