import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_spacing.dart';
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
