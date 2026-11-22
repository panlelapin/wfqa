import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wf_quick_add/ui/capture_window.dart';

void main() {
  testWidgets('Ajouter attend la sauvegarde et empêche une double validation', (
    t,
  ) async {
    final disk = Completer<void>();
    final saved = <String>[];
    int closed = 0;
    await t.pumpWidget(
      MaterialApp(
        home: CaptureWindow(
          save: (text) {
            saved.add(text);
            return disk.future;
          },
          close: () async {
            closed++;
          },
          settings: () async {},
          linux: true,
        ),
      ),
    );
    await t.enterText(find.byType(TextField), 'A\n-\nB');
    await t.tap(find.text('Ajouter'));
    await t.pump();
    await t.tap(find.text('Ajouter'));
    expect(closed, 0);
    expect(saved, ['A\n-\nB']);
    disk.complete();
    await t.pumpAndSettle();
    expect(closed, 1);
  });
  testWidgets(
    'Ctrl+Entrée enregistre ; une erreur garde le texte ; Échap abandonne',
    (t) async {
      int writes = 0, closed = 0;
      await t.pumpWidget(
        MaterialApp(
          home: CaptureWindow(
            save: (_) async {
              writes++;
              throw StateError('disk');
            },
            close: () async {
              closed++;
            },
            settings: () async {},
            linux: true,
          ),
        ),
      );
      await t.enterText(find.byType(TextField), 'garder');
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pumpAndSettle();
      expect(writes, 1);
      expect(closed, 0);
      expect(find.text('garder'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(closed, 1);
      expect(writes, 1);
    },
  );
}
