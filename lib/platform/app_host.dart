import 'dart:io';

import 'package:flutter/services.dart';

class AppHost {
  static const channel = MethodChannel('wf_quick_add/host');
  static Future<Directory> directory() async {
    if (Platform.isAndroid || Platform.isMacOS) {
      return Directory((await channel.invokeMethod<String>('filesDir'))!);
    }
    final xdg = Platform.environment['XDG_DATA_HOME'];
    final home = Platform.environment['HOME'];
    return Directory(
      '${xdg != null && xdg.startsWith('/') ? xdg : '$home/.local/share'}/wf_quick_add',
    );
  }

  static Future<void> hide() => channel.invokeMethod<void>('hide');
}
