import 'package:flutter_driver/driver_extension.dart';
import 'package:remotecare/main.dart' as app;

void main() {
  enableFlutterDriverExtension(
    /*
     * Keep real browser/OS keyboard input enabled for manual testing.
     * Flutter Driver text entry emulation mocks SystemChannels.textInput;
     * when it is enabled, focusing a text field will not use the real
     * keyboard path. The tradeoff is that FlutterDriver.enterText and
     * MCP enter_text require text entry emulation to be enabled again.
     * See: https://api.flutter.dev/flutter/flutter_driver_extension/enableFlutterDriverExtension.html
     */
    enableTextEntryEmulation: false,
  );
  app.main();
}
