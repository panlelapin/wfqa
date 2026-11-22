import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wf_quick_add/ui/settings.dart';
import 'package:wf_quick_add/workflowy/client.dart';

void main() {
  testWidgets(
    'Save ne stocke que la clé reconnue, jamais une réponse périmée',
    (t) async {
      final counts = StreamController<int>();
      addTearDown(counts.close);
      final results = <Completer<void>>[],
          checked = <String>[],
          saved = <String>[];
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => KeyDialog(
                  pendingCounts: counts.stream,
                  read: () async => 'ancienne',
                  check: (key) {
                    checked.add(key);
                    final r = Completer<void>();
                    results.add(r);
                    return r.future;
                  },
                  write: (key) async {
                    saved.add(key);
                  },
                ),
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      );
      await t.tap(find.text('Ouvrir'));
      await t.pumpAndSettle();
      expect(find.text('Envois en attente'), findsOneWidget);
      counts.add(2);
      await t.pumpAndSettle();
      expect(find.text('2 entrées en attente'), findsOneWidget);
      counts.add(0);
      await t.pumpAndSettle();
      expect(find.text('Aucune entrée en attente'), findsOneWidget);
      bool canSave() =>
          t
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
              .onPressed !=
          null;
      expect(canSave(), false);
      expect(t.widget<TextField>(find.byType(TextField)).obscureText, true);
      await t.tap(find.text('Check'));
      await t.pump();
      await t.enterText(find.byType(TextField), 'modifiée');
      results.first.complete();
      await t.pumpAndSettle();
      expect(canSave(), false);
      await t.tap(find.text('Check'));
      await t.pump();
      results.last.completeError(const ApiFailure(401, null));
      await t.pumpAndSettle();
      expect(canSave(), false);
      expect(find.text('Clé refusée par WorkFlowy.'), findsOneWidget);
      await t.tap(find.text('Check'));
      await t.pump();
      results.last.complete();
      await t.pumpAndSettle();
      expect(canSave(), true);
      expect(find.bySemanticsLabel('Clé reconnue'), findsOneWidget);
      expect(saved, isEmpty);
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(checked, ['ancienne', 'modifiée', 'modifiée']);
      expect(saved, ['modifiée']);
    },
  );
}
