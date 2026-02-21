import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';

/// A reusable page for displaying static content like Privacy Policy,
/// Terms of Service, and About.
class StaticContentPage extends StatelessWidget {
  const StaticContentPage({
    required this.title,
    required this.content,
    this.icon,
    this.lastUpdated,
    super.key,
  });

  final String title;
  final String content;
  final IconData? icon;
  final String? lastUpdated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              if (icon != null)
                Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                ),

              // Title
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),

              // Last updated
              if (lastUpdated != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'Last updated: $lastUpdated',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.xl),

              // Content
              Text(
                content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.7,
                  color: colorScheme.onSurface.withOpacity(0.9),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Footer
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'If you have any questions, please contact our support team.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Static content data for common pages
abstract class StaticContent {
  static const privacyPolicy = '''
Your privacy is important to us. This Privacy Policy explains how SurveyScriber collects, uses, and protects your personal information.

Information We Collect

We collect information you provide directly to us, such as when you create an account, complete surveys, or contact us for support. This may include:
- Name and email address
- Survey responses and property inspection data
- Device information and usage statistics

How We Use Your Information

We use the information we collect to:
- Provide, maintain, and improve our services
- Process and complete your survey inspections
- Send you technical notices and support messages
- Respond to your comments and questions

Data Security

We implement appropriate technical and organizational measures to protect your personal data against unauthorized access, alteration, disclosure, or destruction. All data is encrypted in transit and at rest.

Data Retention

We retain your personal data only for as long as necessary to fulfill the purposes for which it was collected, including to satisfy legal, accounting, or reporting requirements.

Your Rights

You have the right to:
- Access your personal data
- Correct inaccurate data
- Request deletion of your data
- Export your data in a portable format

Contact Us

If you have any questions about this Privacy Policy, please contact us at privacy@surveyscriber.com.
''';

  static const termsOfService = '''
Welcome to SurveyScriber. By using our application, you agree to these Terms of Service.

Acceptance of Terms

By accessing or using SurveyScriber, you agree to be bound by these Terms. If you do not agree, please do not use our services.

Use of Services

SurveyScriber provides property inspection and survey management tools. You agree to use our services only for lawful purposes and in accordance with these Terms.

Account Responsibilities

You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use.

Intellectual Property

SurveyScriber and its original content, features, and functionality are owned by SurveyScriber Ltd and are protected by international copyright, trademark, and other intellectual property laws.

User Content

You retain ownership of any content you submit through our services. By submitting content, you grant us a license to use, modify, and display that content in connection with providing our services.

Limitation of Liability

SurveyScriber shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of our services.

Changes to Terms

We reserve the right to modify these Terms at any time. We will notify you of any changes by posting the new Terms on this page.

Governing Law

These Terms shall be governed by the laws of the United Kingdom, without regard to its conflict of law provisions.

Contact Us

If you have any questions about these Terms, please contact us at legal@surveyscriber.com.
''';

  static const about = '''
SurveyScriber is a professional property inspection and survey management application designed for surveyors, inspectors, and property professionals.

Our Mission

We aim to streamline the property inspection process by providing intuitive tools that help professionals work more efficiently in the field and deliver high-quality reports to their clients.

Key Features

- Comprehensive property inspection forms
- Offline-first architecture for field work
- Photo and media capture with annotations
- Digital signature collection
- Professional PDF report generation
- Cloud synchronization and backup

Built with Quality

SurveyScriber is built using modern technologies and follows industry best practices for security, reliability, and performance. Our team is committed to continuous improvement based on user feedback.

Version Information

App Version: 1.0.0
Build: 1
Platform: Flutter/Dart

Support

For technical support or feature requests, please contact us at support@surveyscriber.com.

Follow Us

Stay updated with the latest features and news:
- Website: www.surveyscriber.com
- Twitter: @surveyscriber
- LinkedIn: SurveyScriber

Thank you for choosing SurveyScriber!
''';
}
