def rw(p, fn):
    t = open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in t else '\n'
    t = fn(t.replace('\r\n', '\n'))
    open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', nl))


def sub(t, a, b):
    assert t.count(a) == 1, (t.count(a), a[:70])
    return t.replace(a, b, 1)


def page(t):
    t = sub(t, "  late final DesktopEditingArgs _args = DesktopEditingArgs(surveyId: widget.surveyId, isValuation: widget.isValuation);\n" if False else "  late final DesktopEditingArgs _args = DesktopEditingArgs(surveyId: widget.surveyId, isValuation: widget.isValuation);\n",
            "  late final DesktopEditingArgs _args = DesktopEditingArgs(surveyId: widget.surveyId, isValuation: widget.isValuation);\n  bool _conflictDialogOpen = false;\n")
    # open the decision dialog when a synchronise found screens changed on both sides
    t = sub(t, "    WidgetsBinding.instance.addPostFrameCallback((_) {\n      final c = ref.read(desktopEditingProvider(_args).notifier);\n      c.refresh();\n      c.startPolling();\n    });\n  }",
            """    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(desktopEditingProvider(_args).notifier);
      c.refresh();
      c.startPolling();
    });
    ref.listenManual(desktopEditingProvider(_args), (previous, next) {
      if (next.conflicts.isNotEmpty && !_conflictDialogOpen) _askAboutConflicts(next.conflicts);
    });
  }

  /// After a synchronise: screens changed on the computer and on the phone since they last agreed. The owner decides each one.
  Future<void> _askAboutConflicts(List<ScreenConflict> conflicts) async {
    _conflictDialogOpen = true;
    final keep = await showDialog<Set<String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ConflictDialog(conflicts: conflicts),
    );
    _conflictDialogOpen = false;
    if (keep != null && mounted) await ref.read(desktopEditingProvider(_args).notifier).resolveConflicts(keep);
  }""")
    t = sub(t, "                    if (s.updateAvailable) ...[\n                      const SizedBox(height: 8),\n                      _Banner(\n                        key: const Key('update_banner'),",
            """                    if (s.heldBackChanges > 0) ...[
                      const SizedBox(height: 8),
                      _Banner(
                        key: const Key('held_back_banner'),
                        icon: Icons.pause_circle_outline_rounded,
                        color: scheme.errorContainer,
                        onColor: scheme.onErrorContainer,
                        text: '${s.heldBackChanges} of your changes to this report were not sent, because it was edited on a computer first. '
                            'Nothing is lost. Tap Synchronise to take those edits; your changes are then sent.',
                      ),
                    ],
                    if (s.updateAvailable) ...[
                      const SizedBox(height: 8),
                      _Banner(
                        key: const Key('update_banner'),""")
    t = t.rstrip('\n') + """

/// "Changed on both sides": the owner chooses, per screen, whose wording stays. Nothing is decided silently.
class _ConflictDialog extends StatefulWidget {
  const _ConflictDialog({required this.conflicts});
  final List<ScreenConflict> conflicts;

  @override
  State<_ConflictDialog> createState() => _ConflictDialogState();
}

class _ConflictDialogState extends State<_ConflictDialog> {
  final Set<String> _keepMine = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('conflict_dialog'),
      title: const Text('Changed here and on the computer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('These screens were changed on the computer and also on this phone. Choose whose wording to use for each. You can change your mind by synchronising again.'),
            const SizedBox(height: 8),
            for (final c in widget.conflicts)
              SwitchListTile(
                key: Key('keep_${c.key}'),
                contentPadding: EdgeInsets.zero,
                title: Text(c.title),
                subtitle: Text(_keepMine.contains(c.key) ? 'Keep my wording' : "Use the computer's wording"),
                value: _keepMine.contains(c.key),
                onChanged: (v) => setState(() => v ? _keepMine.add(c.key) : _keepMine.remove(c.key)),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(key: const Key('conflicts_apply'), onPressed: () => Navigator.pop(context, _keepMine), child: const Text('Apply')),
      ],
    );
  }
}
"""
    return t


rw('lib/features/report_editing/presentation/pages/desktop_editing_page.dart', page)
print('ok')
