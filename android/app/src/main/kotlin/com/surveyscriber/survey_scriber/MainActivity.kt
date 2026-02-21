package com.surveyscriber.survey_scriber

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * MainActivity for SurveyScriber app.
 *
 * IMPORTANT: Must extend FlutterFragmentActivity (not FlutterActivity)
 * to support plugins that require FragmentActivity, including:
 * - local_auth: BiometricPrompt requires FragmentActivity
 * - image_picker: May use fragment-based dialogs
 * - permission_handler: Fragment-based permission requests
 *
 * Reference: https://pub.dev/packages/local_auth#android-integration
 */
class MainActivity: FlutterFragmentActivity()
