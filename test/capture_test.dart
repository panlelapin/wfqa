import 'package:flutter_test/flutter_test.dart';
import 'package:wf_quick_add/capture.dart';

void main() {
  test('seul le séparateur exact découpe un lot', () {
    expect(parseCapture('A\r\nB\r\n-\r\nC'), ['A\nB', 'C']);
    expect(parseCapture('-\n \n-\n'), isEmpty);
    expect(parseCapture('rendez-vous\n\n- texte\n - '), [
      'rendez-vous\n- texte\n - ',
    ]);
  });

  test('deux textes identiques ont deux identités mais une même minute', () {
    final batch = captureBatch('A\n-\nA', DateTime(2025, 11, 25, 9, 5));
    expect(batch.first.path, ['2025', '11', '25', '0905']);
    expect(batch.last.path, batch.first.path);
    expect(batch.last.id, isNot(batch.first.id));
  });
}
