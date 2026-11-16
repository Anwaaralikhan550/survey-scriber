p = r'E:/survey-scriber/lib/features/report_editing/presentation/pages/desktop_editing_page.dart'
t = open(p, encoding='utf-8').read()


def rep(a, b):
    global t
    assert a in t, a[:70]
    t = t.replace(a, b, 1)


rep("import '../providers/desktop_editing_providers.dart';", "import '../../data/report_editing_api.dart';\nimport '../providers/desktop_editing_providers.dart';")

# dialogs + actions in the state class
rep("  @override\n  Widget build(BuildContext context) {\n    final s = ref.watch(desktopEditingProvider(_args));", '''  Future<void> _confirmApprove() async {
    final version = ref.read(desktopEditingProvider(_args)).cloudVersion;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Give final approval to version $version?'),
        content: const Text('You approve exactly the version this phone has. Only you can do this. If anyone changes the report afterwards, the approval no longer stands.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not yet')),
          FilledButton(key: const Key('confirm_approve'), onPressed: () => Navigator.pop(ctx, true), child: const Text('Approve')),
        ],
      ),
    );
    if (ok ?? false) await ref.read(desktopEditingProvider(_args).notifier).approveFinal();
  }

  Future<void> _askChanges() async {
    final controller = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Send back with a comment'),
          content: TextField(
            key: const Key('changes_comment'),
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'What needs to change?', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              key: const Key('confirm_changes'),
              onPressed: controller.text.trim().isEmpty ? null : () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Send back'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (comment != null) await ref.read(desktopEditingProvider(_args).notifier).requestChanges(comment);
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start the review again?'),
        content: const Text('The report goes back to Draft and every approval is withdrawn. Nothing is deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep as it is')),
          FilledButton(key: const Key('confirm_reset'), onPressed: () => Navigator.pop(ctx, true), child: const Text('Back to Draft')),
        ],
      ),
    );
    if (ok ?? false) await ref.read(desktopEditingProvider(_args).notifier).resetReview();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(desktopEditingProvider(_args));''')

rep("                  const SizedBox(height: 12),\n                  card([\n                    Text('Edit link'", '''                  const SizedBox(height: 12),
                  if (s.review != null)
                    card([
                      Text('Review', key: const Key('review_card'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      _ReviewSummary(review: s.review!, appVersion: s.appVersion),
                      if (!s.review!.finalised) ...[
                        const SizedBox(height: 12),
                        if (s.updateAvailable || s.appVersion != s.cloudVersion)
                          const Text('Synchronise first, so you approve exactly what you have read.', key: Key('approve_needs_sync')),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (!s.review!.ownerApproved)
                              FilledButton.icon(
                                key: const Key('approve_final'),
                                onPressed: s.busy || s.updateAvailable || s.appVersion != s.cloudVersion ? null : _confirmApprove,
                                icon: const Icon(Icons.verified_rounded),
                                label: const Text('Give final approval'),
                              ),
                            if (s.review!.status != 'DRAFT')
                              OutlinedButton.icon(
                                key: const Key('request_changes'),
                                onPressed: s.busy || s.updateAvailable || s.appVersion != s.cloudVersion ? null : _askChanges,
                                icon: const Icon(Icons.reply_rounded),
                                label: const Text('Send back'),
                              ),
                            if (s.review!.status != 'DRAFT')
                              OutlinedButton.icon(
                                key: const Key('reset_review'),
                                onPressed: s.busy || s.updateAvailable || s.appVersion != s.cloudVersion ? null : _confirmReset,
                                icon: const Icon(Icons.restart_alt_rounded),
                                label: const Text('Back to Draft'),
                              ),
                          ],
                        ),
                      ],
                    ]),
                  const SizedBox(height: 12),
                  card([
                    Text('Edit link\'''')

t += '''

String _statusName(String status) => const {
      'DRAFT': 'Draft',
      'SUBMITTED_FOR_REVIEW': 'Submitted for review',
      'UNDER_REVIEW': 'Under review',
      'AMENDMENTS_REQUIRED': 'Changes requested',
      'REVIEWER_APPROVED': 'Approved by a reviewer',
      'OWNER_FINAL_APPROVAL': 'Final approval given',
      'FINALISING': 'Being finalised',
      'FINALISED': 'Finalised',
    }[status] ??
    status;

String _statusText(ReviewInfo r) {
  switch (r.status) {
    case 'DRAFT':
      return 'Nobody has asked for a review yet. You can give final approval yourself when you are happy with the report.';
    case 'SUBMITTED_FOR_REVIEW':
      return 'Submitted for review at version ${r.submittedVersion ?? r.version}. A reviewer has not decided yet.';
    case 'UNDER_REVIEW':
      return 'A reviewer is looking at the report.';
    case 'AMENDMENTS_REQUIRED':
      return 'Changes were requested. The editors need to make them and submit the report again.';
    case 'REVIEWER_APPROVED':
      return 'A reviewer approved version ${r.reviewerApprovalVersion ?? r.version}. The final approval is yours.';
    case 'OWNER_FINAL_APPROVAL':
      return 'You gave final approval to version ${r.ownerApprovalVersion ?? r.version}.';
    default:
      return 'This report has been finalised and can no longer be changed.';
  }
}

class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({required this.review, required this.appVersion});
  final ReviewInfo review;
  final int? appVersion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final good = review.status == 'REVIEWER_APPROVED' || review.status == 'OWNER_FINAL_APPROVAL' || review.finalised;
    final warn = review.status == 'AMENDMENTS_REQUIRED';
    final colour = warn ? scheme.error : (good ? const Color(0xFF1F7A46) : scheme.primary);
    final amend = review.lastAmendment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: colour.withOpacity(0.1), borderRadius: BorderRadius.circular(999), border: Border.all(color: colour.withOpacity(0.5))),
          child: Text(_statusName(review.status), key: const Key('review_status'), style: TextStyle(color: colour, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        Text(_statusText(review), key: const Key('review_text')),
        if (amend != null && review.status == 'AMENDMENTS_REQUIRED') ...[
          const SizedBox(height: 8),
          Container(
            key: const Key('review_amend'),
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: scheme.errorContainer.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
            child: Text('"${amend.comment ?? ''}" (${amend.by == 'owner' ? 'you' : 'a reviewer'}, version ${amend.version})'),
          ),
        ],
        const SizedBox(height: 8),
        Text('Report version ${review.version}${appVersion != null && appVersion != review.version ? ' (this phone has $appVersion)' : ''}', style: TextStyle(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}
'''
open(p, 'w', encoding='utf-8').write(t)
print('ok')
