import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';

import 'capture.dart';
import 'platform/app_host.dart';
import 'settings/api_key_store.dart';
import 'storage/outbox.dart';
import 'sync/outbox_sender.dart';
import 'ui/capture_window.dart';
import 'ui/settings.dart';
import 'workflowy/client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final box = Outbox(await AppHost.directory());
  runApp(QuickAdd(box: box));
}

class QuickAdd extends StatefulWidget {
  const QuickAdd({super.key, required this.box});
  final Outbox box;
  @override
  State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  final keys = ApiKeyStore(), client = WorkflowyClient();
  late final sender = OutboxSender(widget.box, keys.read, client.sendEntry);
  late final AppLifecycleListener lifecycle;
  @override
  void initState() {
    super.initState();
    lifecycle = AppLifecycleListener(onResume: () => unawaited(sender.wake()));
    unawaited(sender.wake());
  }

  @override
  void dispose() {
    lifecycle.dispose();
    sender.dispose();
    client.close();
    super.dispose();
  }

  Future<void> save(String text) async {
    final entries = captureBatch(text, DateTime.now());
    if (entries.isEmpty) return;
    await widget.box.enqueueBatch(entries);
    unawaited(sender.wake());
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'WorkFlowy Quick Add',
    home: Builder(
      builder: (context) => CaptureWindow(
        linux: Platform.isLinux,
        save: save,
        close: AppHost.hide,
        settings: () async {
          final changed = await showDialog<bool>(
            context: context,
            builder: (_) => KeyDialog(write: keys.write),
          );
          if (changed == true) unawaited(sender.wake(credentialsChanged: true));
        },
      ),
    ),
  );
}
