p = 'E:/survey-scriber/lib/features/report_editing/presentation/pages/desktop_editing_page.dart'
t = open(p, encoding='utf-8', newline='').read()
crlf = '\r\n' in t
if crlf:
    t = t.replace('\r\n', '\n')


def rep(a, b):
    global t
    assert a in t, a[:80]
    t = t.replace(a, b, 1)


rep("import '../../data/report_editing_api.dart';", "import '../../../report_export/domain/models/report_document.dart';\nimport '../../../report_export/presentation/widgets/export_bottom_sheet.dart';\nimport '../../data/report_editing_api.dart';")

rep("  Future<void> _confirmReset() async {", '''  Future<void> _confirmFinalise() async {
    final version = ref.read(desktopEditingProvider(_args)).cloudVersion;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Finalise version $version?'),
        content: const Text('The report is locked. Every browser link ends at once and nobody can change the report unless you reopen it. Your PDF and Word reports are made from this version.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not yet')),
          FilledButton(key: const Key('confirm_finalise'), onPressed: () => Navigator.pop(ctx, true), child: const Text('Finalise')),
        ],
      ),
    );
    if (ok ?? false) await ref.read(desktopEditingProvider(_args).notifier).finaliseReport();
  }

  Future<void> _askReopen() async {
    final reason = await showDialog<String>(context: context, builder: (ctx) => const _ReopenDialog());
    if (reason != null) await ref.read(desktopEditingProvider(_args).notifier).reopenReport(reason);
  }

  void _export(String title) => ExportBottomSheet.show(
        context,
        surveyId: widget.surveyId,
        surveyTitle: title,
        reportType: widget.isValuation ? ReportType.valuation : ReportType.inspection,
      );

  Future<void> _confirmReset() async {''')

# finalise button in the review card
rep("                            if (s.review!.status != 'DRAFT')\n                              OutlinedButton.icon(\n                                key: const Key('request_changes'),", '''                            if (s.review!.ownerApproved)
                              FilledButton.icon(
                                key: const Key('finalise_report'),
                                onPressed: s.busy || s.updateAvailable || s.appVersion != s.cloudVersion ? null : _confirmFinalise,
                                icon: const Icon(Icons.lock_rounded),
                                label: const Text('Finalise report'),
                              ),
                            if (s.review!.status != 'DRAFT')
                              OutlinedButton.icon(
                                key: const Key('request_changes'),''')

# earlier rounds in the review card (when it is a draft again after a reopen) and the final card
rep("                    ]),\n                  const SizedBox(height: 12),\n                  card([\n                    Text('Edit link'", '''                      if (!s.finalised && s.review!.rounds.any((r) => r.reopenedAt != null)) ...[
                        const SizedBox(height: 12),
                        _Rounds(rounds: s.review!.rounds),
                      ],
                    ]),
                  const SizedBox(height: 12),
                  if (s.finalised && s.review != null) ...[
                    card([
                      Text('Final report', key: const Key('final_card'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Text(
                        'Version ${s.review!.finalVersion ?? s.review!.version} is final${s.review!.finalisedAt == null ? '' : ', finalised on ${_date(s.review!.finalisedAt!)}'}. Edit round ${s.review!.cycle}. The report is locked and no browser link is live.',
                        key: const Key('final_text'),
                      ),
                      if (s.appVersion != s.cloudVersion) ...[
                        const SizedBox(height: 8),
                        const Text('Synchronise first: the final reports must be made from the final version.', key: Key('final_needs_sync')),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            key: const Key('export_final'),
                            onPressed: s.busy || s.appVersion != s.cloudVersion ? null : () => _export(widget.surveyTitle),
                            icon: const Icon(Icons.picture_as_pdf_rounded),
                            label: const Text('Export PDF or Word'),
                          ),
                          OutlinedButton.icon(
                            key: const Key('reopen_report'),
                            onPressed: s.busy || s.appVersion != s.cloudVersion ? null : _askReopen,
                            icon: const Icon(Icons.lock_open_rounded),
                            label: const Text('Reopen report'),
                          ),
                        ],
                      ),
                      if (s.review!.rounds.any((r) => r.reopenedAt != null)) ...[
                        const SizedBox(height: 12),
                        _Rounds(rounds: s.review!.rounds),
                      ],
                    ]),
                    const SizedBox(height: 12),
                  ],
                  if (!s.finalised)
                  card([
                    Text('Edit link\'''')

rep("                    ],\n                  ]),\n                  const SizedBox(height: 12),\n                  Text(\n                    'Only you can finalise", "                    ],\n                  ]),\n                  if (!s.finalised) const SizedBox(height: 12),\n                  Text(\n                    'Only you can finalise")

t += '''
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String _date(DateTime d) {
  final l = d.toLocal();
  return '${l.day} ${_months[l.month - 1]} ${l.year}';
}

/// Earlier final versions that were reopened, newest first, with the reason.
class _Rounds extends StatelessWidget {
  const _Rounds({required this.rounds});
  final List<FinalRound> rounds;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reopened = rounds.where((r) => r.reopenedAt != null).toList();
    return Column(
      key: const Key('earlier_rounds'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Earlier final versions', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
        for (final r in reopened)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Round ${r.cycle}: version ${r.version}, finalised ${_date(r.finalisedAt)}, reopened ${_date(r.reopenedAt!)}. "${r.reopenReason ?? ''}"'),
          ),
      ],
    );
  }
}

/// Asks why a final report is being reopened. Owns its controller so it is disposed with the dialog.
class _ReopenDialog extends StatefulWidget {
  const _ReopenDialog();

  @override
  State<_ReopenDialog> createState() => _ReopenDialogState();
}

class _ReopenDialogState extends State<_ReopenDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Reopen this report?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('It becomes a draft again and a new edit round starts. The final version you made is kept. Previous approvals no longer stand.'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('reopen_reason'),
              controller: _controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Why are you reopening it?', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep it final')),
          FilledButton(
            key: const Key('confirm_reopen'),
            onPressed: _controller.text.trim().length < 3 ? null : () => Navigator.pop(context, _controller.text.trim()),
            child: const Text('Reopen'),
          ),
        ],
      );
}
'''
if crlf:
    t = t.replace('\n', '\r\n')
open(p, 'w', encoding='utf-8', newline='').write(t)
print('ok')
