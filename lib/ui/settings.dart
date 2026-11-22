import 'package:material_ui/material_ui.dart';

class KeyDialog extends StatefulWidget {
  const KeyDialog({super.key, required this.write});
  final Future<void> Function(String) write;
  @override
  State<KeyDialog> createState() => _KeyDialogState();
}

class _KeyDialogState extends State<KeyDialog> {
  final keyText = TextEditingController();
  bool saving = false;
  String? error;
  @override
  void dispose() {
    keyText.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await widget.write(keyText.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = 'Le trousseau de clés est inaccessible.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Préférences WorkFlowy'),
    content: TextField(
      controller: keyText,
      autofocus: true,
      obscureText: true,
      enableSuggestions: false,
      autocorrect: false,
      readOnly: saving,
      decoration: InputDecoration(
        labelText: 'Nouvelle clé API',
        helperText: 'Remplace la clé enregistrée sur cet appareil.',
        errorText: error,
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: saving ? null : save,
        child: const Text('Enregistrer'),
      ),
    ],
  );
}
