import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../data/report_editing_api.dart';
import '../providers/desktop_editing_providers.dart';

/// Owner screen for desktop editing (spec section 7 Screen H): make, copy, share and cancel the edit link,
/// see the cloud and phone versions, and synchronise the browser's edits into this phone's reports.
class DesktopEditingPage extends ConsumerStatefulWidget {
  const DesktopEditingPage({required this.surveyId, required this.isValuation, this.surveyTitle = 'Survey', super.key});

  final String surveyId;
  final bool isValuation;
  final String surveyTitle;

  @override
  ConsumerState<DesktopEditingPage> createState() => _DesktopEditingPageState();
}

class _DesktopEditingPageState extends ConsumerState<DesktopEditingPage> with WidgetsBindingObserver {
  late final DesktopEditingArgs _args = DesktopEditingArgs(surveyId: widget.surveyId, isValuation: widget.isValuation);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(desktopEditingProvider(_args).notifier);
      c.refresh();
      c.startPolling();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.read(desktopEditingProvider(_args).notifier).refresh(quiet: true);
  }

  static String _when(DateTime d) {
    final l = d.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = l.hour.toString().padLeft(2, '0');
    final m = l.minute.toString().padLeft(2, '0');
    return '${l.day} ${months[l.month - 1]} $h:$m';
  }

  static String _left(DateTime to, DateTime now) {
    final d = to.difference(now);
    if (d.isNegative) return 'expired';
    if (d.inHours >= 24) return '${d.inDays}d ${d.inHours % 24}h left';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m left';
    return '${d.inMinutes}m left';
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel the link?'),
        content: const Text('The link stops working at once, for everyone who has it. Changes already saved stay in the report.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep link')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel link'),
          ),
        ],
      ),
    );
    if (ok ?? false) await ref.read(desktopEditingProvider(_args).notifier).cancelLink();
  }

  Future<void> _confirmDiscard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove the edited wording?'),
        content: const Text('Your PDF and Word reports go back to the wording the app writes from your answers. The report in SurveyScriber is not changed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok ?? false) await ref.read(desktopEditingProvider(_args).notifier).discardEdits();
  }

  Future<void> _confirmApprove() async {
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
    final comment = await showDialog<String>(context: context, builder: (ctx) => const _ChangesDialog());
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
    final s = ref.watch(desktopEditingProvider(_args));
    final c = ref.read(desktopEditingProvider(_args).notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();

    Widget card(List<Widget> children) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        );

    final linkLive = s.linkActive && (s.linkExpiresAt == null || s.linkExpiresAt!.isAfter(now));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit on a computer')),
      body: s.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => c.refresh(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(widget.surveyTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    'Make a private link that opens this report in a browser. Whoever has the link can edit the wording and ratings until it expires. You stay in charge: you can cancel it, and you decide when the report is final.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  if (s.offline)
                    _Banner(icon: Icons.cloud_off_rounded, color: scheme.errorContainer, onColor: scheme.onErrorContainer, text: 'You are offline. What you see may be out of date.'),
                  if (s.error != null) _Banner(icon: Icons.error_outline_rounded, color: scheme.errorContainer, onColor: scheme.onErrorContainer, text: s.error!, key: const Key('error_banner')),
                  if (s.notice != null) _Banner(icon: Icons.check_circle_outline_rounded, color: scheme.primaryContainer, onColor: scheme.onPrimaryContainer, text: s.notice!, key: const Key('notice_banner')),
                  card([
                    Text('Versions', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    _Row('In SurveyScriber', s.cloudVersion == null ? 'Not sent yet' : 'Version ${s.cloudVersion}'),
                    _Row('On this phone', s.appVersion == null ? 'Not sent yet' : 'Version ${s.appVersion}'),
                    if (s.finalised) const _Row('Report', 'Finalised'),
                    if (s.updateAvailable) ...[
                      const SizedBox(height: 8),
                      _Banner(
                        key: const Key('update_banner'),
                        icon: Icons.sync_rounded,
                        color: scheme.tertiaryContainer,
                        onColor: scheme.onTertiaryContainer,
                        text: 'A newer version (${s.cloudVersion}) was saved from the editor. This phone has version ${s.appVersion}.',
                      ),
                    ],
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      key: const Key('synchronise'),
                      onPressed: s.busy || !s.hasCloudReport ? null : c.synchronise,
                      icon: const Icon(Icons.sync_rounded),
                      label: Text(s.updateAvailable ? 'Synchronise (version ${s.cloudVersion})' : 'Synchronise'),
                    ),
                    if (s.hasEdits) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.edit_note_rounded, size: 18, color: scheme.primary),
                          const SizedBox(width: 6),
                          const Expanded(child: Text('Your PDF and Word reports use the edited wording.')),
                        ],
                      ),
                      TextButton(key: const Key('discard_edits'), onPressed: s.busy ? null : _confirmDiscard, child: const Text('Remove edited wording')),
                    ],
                  ]),
                  const SizedBox(height: 12),
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
                    Text('Edit link', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    if (!linkLive) ...[
                      const Text('No link is live. A link works for 72 hours.'),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const Key('generate_link'),
                        onPressed: s.busy || s.finalised ? null : c.generateLink,
                        icon: s.busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.link_rounded),
                        label: const Text('Generate link'),
                      ),
                    ] else ...[
                      _Row('Expires', s.linkExpiresAt == null ? '' : '${_when(s.linkExpiresAt!)} (${_left(s.linkExpiresAt!, now)})'),
                      const SizedBox(height: 8),
                      if (s.linkUrl != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                          child: SelectableText(s.linkUrl!, key: const Key('link_url'), style: theme.textTheme.bodySmall),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              key: const Key('copy_link'),
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: s.linkUrl!));
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied'), behavior: SnackBarBehavior.floating));
                              },
                              icon: const Icon(Icons.copy_rounded),
                              label: const Text('Copy'),
                            ),
                            OutlinedButton.icon(
                              key: const Key('share_link'),
                              onPressed: () => Share.share(s.linkUrl!, subject: 'Edit the report: ${widget.surveyTitle}'),
                              icon: const Icon(Icons.share_rounded),
                              label: const Text('Share'),
                            ),
                          ],
                        ),
                      ] else
                        const _Banner(
                          icon: Icons.info_outline_rounded,
                          color: Color(0xFFFFF4E5),
                          onColor: Color(0xFF7A4B00),
                          text: 'A link is live, but its address is not stored on this phone. Cancel it and make a new one to share it.',
                          key: Key('address_missing'),
                        ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            key: const Key('update_cloud'),
                            onPressed: s.busy ? null : c.updateCloudCopy,
                            icon: const Icon(Icons.cloud_upload_outlined),
                            label: const Text('Send my latest changes'),
                          ),
                          OutlinedButton.icon(
                            key: const Key('cancel_link'),
                            style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                            onPressed: s.busy ? null : _confirmCancel,
                            icon: const Icon(Icons.link_off_rounded),
                            label: const Text('Cancel link'),
                          ),
                        ],
                      ),
                    ],
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    'Only you can finalise the report. Anyone with the link can read and edit it while the link is live, so share it only with people you trust.',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.onColor, required this.text, super.key});
  final IconData icon;
  final Color color;
  final Color onColor;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: onColor),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(color: onColor))),
          ],
        ),
      );
}


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

/// Owns its text controller so it is disposed with the dialog, after the closing animation.
class _ChangesDialog extends StatefulWidget {
  const _ChangesDialog();

  @override
  State<_ChangesDialog> createState() => _ChangesDialogState();
}

class _ChangesDialogState extends State<_ChangesDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Send back with a comment'),
        content: TextField(
          key: const Key('changes_comment'),
          controller: _controller,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 2000,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'What needs to change?', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            key: const Key('confirm_changes'),
            onPressed: _controller.text.trim().isEmpty ? null : () => Navigator.pop(context, _controller.text.trim()),
            child: const Text('Send back'),
          ),
        ],
      );
}
