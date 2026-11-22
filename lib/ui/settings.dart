import 'package:material_ui/material_ui.dart';

import '../workflowy/client.dart';

class KeyDialog extends StatefulWidget {
  const KeyDialog({
    super.key,
    required this.read,
    required this.check,
    required this.write,
  });
  final Future<String?> Function() read;
  final Future<void> Function(String) check, write;
  @override
  State<KeyDialog> createState() => _KeyDialogState();
}

class _KeyDialogState extends State<KeyDialog> {
  final text = TextEditingController();
  bool loading = true, checking = false, saving = false;
  int revision = 0;
  String? verified, error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final stored = await widget.read();
      if (mounted) text.text = stored ?? '';
    } catch (_) {
      error = 'Impossible de lire le trousseau de clés.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void edited(String _) => setState(() {
    revision++;
    verified = null;
    error = null;
    checking = false;
  });

  Future<void> check() async {
    final key = text.text.trim(), attempt = revision;
    if (key.isEmpty || checking || loading || saving) return;
    setState(() {
      checking = true;
      verified = null;
      error = null;
    });
    String? message;
    try {
      await widget.check(key);
    } on ApiFailure catch (e) {
      message = e.status == 401 || e.status == 403
          ? 'Clé refusée par WorkFlowy.'
          : 'WorkFlowy est indisponible. Réessaie plus tard.';
    } catch (_) {
      message = 'Vérification impossible. Vérifie la connexion et réessaie.';
    }
    if (!mounted || attempt != revision) return;
    setState(() {
      checking = false;
      error = message;
      verified = message == null ? key : null;
    });
  }

  Future<void> save() async {
    final key = verified;
    if (key == null || key != text.text.trim() || saving) return;
    setState(() => saving = true);
    try {
      await widget.write(key);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = 'Enregistrement impossible dans le trousseau de clés.';
        });
      }
    }
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Préférences'),
    scrollable: true,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clé API WorkFlowy',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        TextField(
          controller: text,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          readOnly: loading || saving,
          onChanged: edited,
          decoration: InputDecoration(
            labelText: 'Clé API',
            errorText: error,
            errorMaxLines: 3,
            suffixIcon: verified == null
                ? null
                : const Icon(
                    Icons.close,
                    color: Colors.green,
                    semanticLabel: 'Clé reconnue',
                  ),
          ),
        ),
        ButtonBarSection(
          checking: checking,
          onCheck: loading || saving || checking || text.text.trim().isEmpty
              ? null
              : check,
          onSave: verified == null || saving ? null : save,
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Fermer'),
      ),
    ],
  );
}

class ButtonBarSection extends StatelessWidget {
  const ButtonBarSection({
    super.key,
    required this.checking,
    required this.onCheck,
    required this.onSave,
  });
  final bool checking;
  final VoidCallback? onCheck, onSave;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      OutlinedButton(
        onPressed: onCheck,
        child: Text(checking ? 'Vérification…' : 'Check'),
      ),
      FilledButton(onPressed: onSave, child: const Text('Save')),
    ],
  );
}
