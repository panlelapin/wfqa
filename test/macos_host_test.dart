import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wf_quick_add/platform/app_host.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'macOS utilise Application Support fourni par le runner natif',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AppHost.channel, (call) async {
            expect(call.method, 'filesDir');
            return '/sandbox/Library/Application Support/wf_quick_add';
          });
      expect(
        (await AppHost.directory()).path,
        '/sandbox/Library/Application Support/wf_quick_add',
      );
    },
    skip: !Platform.isMacOS,
  );
}
