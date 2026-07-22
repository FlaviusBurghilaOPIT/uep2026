import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/notifications/notification_service.dart';

void main() {
  group('NotificationService Tests', () {
    test('parseReminderId parses reminderId correctly from payload', () {
      expect(NotificationService.parseReminderId('rem_123:med_456:take_dose'), 'rem_123');
      expect(NotificationService.parseReminderId('rem_123'), 'rem_123');
      expect(NotificationService.parseReminderId(''), isNull);
    });

    test('reinitialize executes without throwing', () async {
      await expectLater(NotificationService.instance.reinitialize(), completes);
    });
  });
}
