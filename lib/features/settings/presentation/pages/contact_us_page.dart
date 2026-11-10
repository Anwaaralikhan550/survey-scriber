import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/presentation/widgets/safe_page_padding.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

/// Sends a message to the support team: the person's email, a subject and a message.
class ContactUsPage extends ConsumerStatefulWidget {
  const ContactUsPage({super.key});

  @override
  ConsumerState<ContactUsPage> createState() => _ContactUsPageState();

  /// What the person should read when the server or the network said no.
  static String messageFor(Object error) {
    if (error is NetworkException) {
      return 'No internet connection. Please connect and try again.';
    }
    if (error is RateLimitException) {
      return 'You have sent several messages already. Please try again later.';
    }
    if (error is ServerException && (error.message ?? '').isNotEmpty) {
      return error.message!;
    }
    if (error is ValidationException && (error.message ?? '').isNotEmpty) {
      return error.message!;
    }
    return 'Your message could not be sent. Please try again.';
  }

}

class _ContactUsPageState extends ConsumerState<ContactUsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(
      text: ref.read(authNotifierProvider).user?.email ?? '',
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  static final _emailShape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> _send() async {
    if (_sending || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).post<void>(
        'contact',
        data: {
          'email': _email.text.trim(),
          'subject': _subject.text.trim(),
          'message': _message.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you. Your message has been sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.canPop() ? context.pop() : context.go(Routes.settings);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = ContactUsPage.messageFor(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: safePagePadding(context, AppSpacing.md),
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'Please enter your email';
                  if (!_emailShape.hasMatch(text)) return 'Please enter a valid email';
                  return null;
                },
              ),
              AppSpacing.gapVerticalMd,
              TextFormField(
                controller: _subject,
                textInputAction: TextInputAction.next,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Please enter a subject' : null,
              ),
              AppSpacing.gapVerticalMd,
              TextFormField(
                controller: _message,
                minLines: 5,
                maxLines: 10,
                maxLength: 5000,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Please enter a message' : null,
              ),
              if (_error != null) ...[
                AppSpacing.gapVerticalSm,
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                ),
              ],
              AppSpacing.gapVerticalLg,
              FilledButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
