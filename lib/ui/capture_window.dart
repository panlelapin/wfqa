import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

class CaptureWindow extends StatefulWidget {
  const CaptureWindow({
    super.key,
    required this.save,
    required this.close,
    required this.settings,
    required this.linux,
  });
  final Future<void> Function(String) save;
  final Future<void> Function() close, settings;
  final bool linux;
  @override
  State<CaptureWindow> createState() => _CaptureWindowState();
}

class _CaptureWindowState extends State<CaptureWindow> {
  final text = TextEditingController();
  final focus = FocusNode();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    text.dispose();
    focus.dispose();
    super.dispose();
  }

  Future<void> finish(bool save) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    if (save) {
      try {
        await widget.save(text.text);
      } catch (_) {
        if (mounted) {
          setState(() {
            busy = false;
            error = 'Écriture locale impossible. Le texte a été conservé.';
          });
        }
        return;
      }
    }
    if (!mounted) return;
    text.clear();
    try {
      await widget.close();
    } catch (_) {
      error = 'Impossible de fermer la fenêtre.';
    }
    if (mounted) {
      setState(() => busy = false);
      focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () => finish(false),
      if (widget.linux)
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () =>
            finish(true),
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('WorkFlowy Quick Add'),
        actions: [
          IconButton(
            tooltip: 'Préférences',
            onPressed: busy ? null : widget.settings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  controller: text,
                  focusNode: focus,
                  readOnly: busy,
                  autofocus: true,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Saisir du texte…\nUne ligne avec - sépare deux entrées.',
                  ),
                ),
              ),
              if (error != null) Text(error!),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: busy ? null : () => finish(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: busy ? null : () => finish(true),
                    child: const Text('Ajouter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
