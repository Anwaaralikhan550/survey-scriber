import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../report_export/domain/models/export_config.dart';
import '../providers/company_branding_provider.dart';

/// Company name and logo for the report's first page and footer.
class CompanyBrandingPage extends ConsumerStatefulWidget {
  const CompanyBrandingPage({super.key});

  @override
  ConsumerState<CompanyBrandingPage> createState() =>
      _CompanyBrandingPageState();
}

class _CompanyBrandingPageState extends ConsumerState<CompanyBrandingPage> {
  static const _maxLogoSide = 600;
  static const _maxLogoBytes = 1024 * 1024;

  late final TextEditingController _name;
  Uint8List? _logo;
  bool _saving = false;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(companyBrandingProvider);
    _name = TextEditingController(text: saved.name)
      ..addListener(() => setState(() {}));
    _logo = saved.logo;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Every logo is stored as a PNG of at most [_maxLogoSide], so any picture
  /// the phone can open works in both the PDF and the Word report.
  static Future<Uint8List> _toLogoPng(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final longest = descriptor.width > descriptor.height
        ? descriptor.width
        : descriptor.height;
    final scale = longest > _maxLogoSide ? _maxLogoSide / longest : 1.0;
    final codec = await descriptor.instantiateCodec(
      targetWidth: (descriptor.width * scale).round(),
      targetHeight: (descriptor.height * scale).round(),
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    return data!.buffer.asUint8List();
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _pickLogo() async {
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final png = await _toLogoPng(await picked.readAsBytes());
      if (!mounted) return;
      if (png.length > _maxLogoBytes) {
        _say('This picture is too detailed for a logo. Please choose a simpler one.');
        return;
      }
      setState(() => _logo = png);
    } catch (_) {
      if (mounted) _say('This picture could not be opened. Please choose another one.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final reachedServer = await ref
        .read(companyBrandingProvider.notifier)
        .save(name: _name.text, logo: _logo);
    if (!mounted) return;
    setState(() => _saving = false);
    _say(reachedServer
        ? 'Company details saved'
        : 'Saved on this phone. It will upload when you are back online.');
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Company Details'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Shown on the first page and in the footer of your reports.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapVerticalMd,
            _ReportBarPreview(name: _name.text.trim(), logo: _logo),
            AppSpacing.gapVerticalLg,
            TextField(
              controller: _name,
              maxLength: 255,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Company name',
                hintText: 'e.g. Francis Blackstone Surveyor',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            AppSpacing.gapVerticalMd,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _picking || _saving ? null : _pickLogo,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(_logo == null ? 'Upload logo' : 'Change logo'),
                  ),
                ),
                if (_logo != null) ...[
                  AppSpacing.gapHorizontalSm,
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _picking || _saving
                          ? null
                          : () => setState(() => _logo = null),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Remove logo'),
                    ),
                  ),
                ],
              ],
            ),
            AppSpacing.gapVerticalLg,
            FilledButton(
              onPressed: _picking || _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The report's blue bar, as it will print.
class _ReportBarPreview extends StatelessWidget {
  const _ReportBarPreview({required this.name, required this.logo});

  final String name;
  final Uint8List? logo;

  @override
  Widget build(BuildContext context) {
    final accent = const ExportConfig().accentColor;
    final logo = this.logo;
    const white = TextStyle(color: Colors.white);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Color.fromARGB(
          255,
          (accent.red * 255).round(),
          (accent.green * 255).round(),
          (accent.blue * 255).round(),
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 44,
            child: logo == null
                ? null
                : Image.memory(
                    logo,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
          ),
          Expanded(
            child: Column(
              children: [
                if (name.isNotEmpty)
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: white.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                Text(
                  'Home Buyer Report',
                  style: white.copyWith(
                    fontSize: name.isEmpty ? 15 : 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text('Level 2 Home Survey', style: white.copyWith(fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }
}
