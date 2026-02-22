import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/session_expiry_handler.dart';
import '../../core/permissions/route_permissions.dart';
import '../../core/utils/logger.dart';
import '../../features/admin/clients/presentation/pages/admin_client_detail_page.dart';
import '../../features/admin/clients/presentation/pages/admin_clients_list_page.dart';
import '../../features/admin/invoices/presentation/pages/admin_create_invoice_page.dart';
import '../../features/admin/invoices/presentation/pages/admin_invoice_detail_page.dart';
import '../../features/admin/invoices/presentation/pages/admin_invoices_list_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_exports_page.dart';
import '../../features/admin/presentation/pages/admin_integrations_page.dart';
import '../../features/admin/presentation/pages/audit_logs_page.dart';
import '../../features/admin/presentation/pages/automation_guide_page.dart';
import '../../features/admin/presentation/pages/user_management_page.dart';
import '../../features/admin/presentation/pages/tree_browser_page.dart';
import '../../features/admin/presentation/pages/webhook_create_page.dart';
import '../../features/admin/presentation/pages/webhook_detail_page.dart';
import '../../features/admin/presentation/pages/webhooks_list_page.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/booking_change_requests/presentation/pages/change_requests_admin_page.dart';
import '../../features/booking_change_requests/presentation/pages/my_change_requests_page.dart';
import '../../features/booking_change_requests/presentation/pages/request_change_page.dart';
import '../../features/booking_requests/presentation/pages/booking_requests_admin_page.dart';
import '../../features/booking_requests/presentation/pages/my_booking_requests_page.dart';
import '../../features/booking_requests/presentation/pages/request_booking_page.dart';
import '../../features/client_portal/presentation/pages/client_booking_detail_page.dart';
import '../../features/client_portal/presentation/pages/client_bookings_page.dart';
import '../../features/client_portal/presentation/pages/client_dashboard_page.dart';
import '../../features/client_portal/presentation/pages/client_invoice_detail_page.dart';
import '../../features/client_portal/presentation/pages/client_invoices_page.dart';
import '../../features/client_portal/presentation/pages/client_login_page.dart';
import '../../features/client_portal/presentation/pages/client_report_detail_page.dart';
import '../../features/client_portal/presentation/pages/client_reports_page.dart';
import '../../features/client_portal/presentation/pages/client_verify_page.dart';
import '../../features/client_portal/presentation/pages/magic_link_sent_page.dart';
import '../../features/client_portal/presentation/providers/client_portal_providers.dart'
    show clientAuthNotifierProvider;
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/forms/presentation/pages/forms_page.dart';
import '../../features/invoices/presentation/pages/invoice_detail_page.dart';
import '../../features/invoices/presentation/pages/invoices_list_page.dart';
import '../../features/property_inspection/presentation/pages/inspection_overview_page.dart';
import '../../features/property_inspection/presentation/pages/inspection_compass_page.dart';
import '../../features/property_inspection/presentation/pages/inspection_screen_page.dart';
import '../../features/property_inspection/presentation/pages/inspection_section_page.dart';
import '../../features/property_valuation/presentation/pages/valuation_overview_page.dart';
import '../../features/property_valuation/presentation/pages/valuation_screen_page.dart';
import '../../features/property_valuation/presentation/pages/valuation_section_page.dart';
import '../../features/media/presentation/pages/survey_media_gallery_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/report_export/presentation/pages/pdf_history_page.dart';
import '../../features/report_export/presentation/pages/report_preview_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/reinspection/presentation/pages/reinspection_overview_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/scheduling/presentation/pages/availability_settings_page.dart';
import '../../features/scheduling/presentation/pages/booking_detail_page.dart';
import '../../features/scheduling/presentation/pages/bookings_list_page.dart';
import '../../features/scheduling/presentation/pages/create_booking_page.dart';
import '../../features/scheduling/presentation/pages/scheduling_page.dart';
import '../../features/scheduling/presentation/pages/slot_calendar_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/signature/presentation/pages/signature_capture_page.dart';
import '../../features/signature/presentation/pages/survey_signatures_page.dart';
import '../../features/survey_overview/presentation/pages/survey_overview_page.dart';
import '../../shared/presentation/pages/attachments_signatures_page.dart';
import '../../features/surveys/presentation/pages/create_survey_page.dart';
import '../../features/surveys/presentation/pages/survey_detail_page.dart';
import '../shell/main_shell.dart';
import 'routes.dart';

/// Root navigator key - shared with SessionExpiryHandler for global navigation access.
/// Used by NotFoundHandler to pop when 404 errors occur on detail screens.
final _rootNavigatorKey = SessionExpiryHandler.instance.navigatorKey;

/// F2 FIX: Navigator keys for each shell branch.
/// Each branch needs its own key to properly manage back-stack and prevent memory leaks.
final _dashboardNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _formsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'forms');
final _reportsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'reports');
final _searchNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'search');

/// F5 FIX: Standardized parameter extraction utilities.
/// All route parameter access should use these helpers for consistency.

/// Safely extracts a required path parameter, redirecting to error page if missing.
/// This prevents null crash when deep links or programmatic navigation is malformed.
String? _safeParam(GoRouterState state, String key) {
  final value = state.pathParameters[key];
  if (value == null || value.isEmpty) {
    AppLogger.e('Router', 'Missing required path parameter: $key for ${state.matchedLocation}');
    return null;
  }
  return value;
}

/// F5/F6 FIX: Safely extracts a query parameter, returning null for empty strings.
/// This ensures consistent null semantics (empty string == null).
String? _safeQueryParam(GoRouterState state, String key) {
  final value = state.uri.queryParameters[key];
  // F6 FIX: Treat empty string as null for proper downstream handling
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

/// Route builder wrapper that handles missing parameters gracefully.
/// Returns an error page with navigation back to dashboard if params are missing.
Widget _buildWithRequiredParam({
  required GoRouterState state,
  required String paramKey,
  required Widget Function(String id) builder,
}) {
  final id = _safeParam(state, paramKey);
  if (id == null) {
    return _MissingParamErrorPage(paramKey: paramKey);
  }
  return builder(id);
}

/// Route builder wrapper for routes with two required parameters.
Widget _buildWithTwoParams({
  required GoRouterState state,
  required String param1Key,
  required String param2Key,
  required Widget Function(String param1, String param2) builder,
}) {
  final param1 = _safeParam(state, param1Key);
  final param2 = _safeParam(state, param2Key);
  if (param1 == null || param2 == null) {
    return _MissingParamErrorPage(paramKey: param1 == null ? param1Key : param2Key);
  }
  return builder(param1, param2);
}

/// A ChangeNotifier that bridges Riverpod auth state to GoRouter's refreshListenable.
/// When auth state changes, this notifies GoRouter to re-evaluate its redirect logic.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    // Listen to staff auth state changes
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      AppLogger.d('Router',
          'Auth state changed: ${previous?.status} -> ${next.status}',);
      notifyListeners();
    });
    // Listen to client auth state changes
    ref.listen(clientAuthNotifierProvider, (previous, next) {
      AppLogger.d('Router', 'Client auth state changed');
      notifyListeners();
    });
  }
}

/// Provider for the auth refresh notifier - kept alive for the app's lifetime
final _authRefreshNotifierProvider =
    Provider<_AuthRefreshNotifier>(_AuthRefreshNotifier.new);

/// Provides the GoRouter instance for the app.
/// Uses refreshListenable to react to auth state changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Create the refresh notifier that will trigger redirect re-evaluation
  final refreshNotifier = ref.watch(_authRefreshNotifierProvider);

  // CRITICAL: Wire SessionExpiryHandler to AuthNotifier so that token refresh
  // failures clear auth state and trigger the router redirect to login.
  // Without this, onSessionExpired is null and the 401 dashboard loop occurs.
  SessionExpiryHandler.instance.onSessionExpired = () {
    ref.read(authNotifierProvider.notifier).setUnauthenticated();
  };

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.dashboard,
    // CRITICAL: refreshListenable triggers redirect re-evaluation when auth state changes
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // CRITICAL: Read fresh state inside redirect callback, not captured state
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authNotifierProvider);
      final clientAuthState = container.read(clientAuthNotifierProvider);

      final isAuthenticated = authState.isAuthenticated;
      final isClientAuthenticated = clientAuthState.isAuthenticated;
      final location = state.matchedLocation;

      AppLogger.d('Router',
          'Redirect check: location=$location, isAuthenticated=$isAuthenticated, status=${authState.status}',);

      // F1 FIX: Auth routes with exact matching to prevent auth bypass
      // Using exact route matching instead of startsWith to prevent
      // routes like /reset-password-admin from bypassing auth
      final isAuthRoute = location == Routes.login ||
          location == Routes.register ||
          location == Routes.forgotPassword ||
          location == Routes.resetPassword;

      // Client portal routes
      final isClientRoute = location.startsWith('/client');

      // F3 FIX: During auth resolution, redirect to splash/loading screen
      // This prevents protected content from flashing before auth is confirmed.
      // IMPORTANT: We must NOT return null here - that would allow the navigation
      // to proceed and potentially render protected content.
      final isAuthResolving = authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading;
      if (!isClientRoute && !isAuthRoute && isAuthResolving) {
        AppLogger.d('Router', 'Auth resolving, staying on current location');
        // If already at root/dashboard area, stay put (splash screen will show)
        // Otherwise redirect to root to show proper loading state
        if (location == Routes.dashboard || location == '/') {
          return null; // Dashboard will show loading state
        }
        // For any other protected route, redirect to dashboard which shows loading
        return Routes.dashboard;
      }
      final isClientAuthRoute = location == Routes.clientLogin ||
          location == Routes.clientMagicLinkSent ||
          location.startsWith('/client/verify');

      // Handle client portal routes
      if (isClientRoute) {
        // F4 FIX: Wait for client auth initialization before making redirect decisions
        if (clientAuthState.isInitializing) {
          AppLogger.d('Router', 'Client auth initializing, waiting...');
          // Stay on current client route while initializing
          // The login page will show a loading indicator
          return null;
        }

        // If on client auth route and already authenticated as client, go to client dashboard
        if (isClientAuthRoute && isClientAuthenticated) {
          return Routes.clientDashboard;
        }
        // If on protected client route and not authenticated, go to client login
        if (!isClientAuthRoute && !isClientAuthenticated) {
          return Routes.clientLogin;
        }
        // Allow client routes
        return null;
      }

      // Handle staff/admin routes
      // If on auth route and authenticated, redirect to dashboard
      if (isAuthRoute && isAuthenticated) {
        AppLogger.d('Router',
            'On auth route but authenticated, redirecting to dashboard',);
        return Routes.dashboard;
      }

      // If not on auth route and not authenticated, redirect to login
      if (!isAuthRoute && !isAuthenticated) {
        AppLogger.d('Router', 'Not authenticated, redirecting to login');
        return Routes.login;
      }

      // RBAC: Admin routes require admin or manager role
      final isAdminRoute = location.startsWith('/admin');
      if (isAdminRoute && isAuthenticated) {
        final userRole = authState.user?.role;
        final hasAdminAccess =
            userRole == UserRole.admin || userRole == UserRole.manager;
        if (!hasAdminAccess) {
          return Routes.dashboard;
        }
      }

      // Route-level permission check for granular RBAC
      // This enforces permissions defined in RoutePermissions._routePermissions
      if (isAuthenticated) {
        final permissionRedirect = checkRoutePermission(
          context,
          state,
          authState.user?.role,
        );
        if (permissionRedirect != null) {
          AppLogger.d('Router', 'Permission denied for $location, redirecting to $permissionRedirect');
          return permissionRedirect;
        }
      }

      return null;
    },
    routes: [
      // ==================== Auth Routes ====================
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: Routes.resetPassword,
        builder: (context, state) {
          // F5 FIX: Use standardized query param extraction
          final token = _safeQueryParam(state, 'token');
          return ResetPasswordPage(token: token);
        },
      ),

      // ==================== Client Portal Routes ====================
      GoRoute(
        path: Routes.clientLogin,
        builder: (context, state) => const ClientLoginPage(),
      ),
      GoRoute(
        path: Routes.clientMagicLinkSent,
        builder: (context, state) => const MagicLinkSentPage(),
      ),
      GoRoute(
        path: Routes.clientVerify,
        builder: (context, state) {
          // F5/F6 FIX: Use standardized extraction; null means missing token
          final token = _safeQueryParam(state, 'token');
          // If token is missing, show error page instead of passing empty string
          if (token == null) {
            return const _MissingParamErrorPage(paramKey: 'token');
          }
          return ClientVerifyPage(token: token);
        },
      ),
      GoRoute(
        path: Routes.clientDashboard,
        builder: (context, state) => const ClientDashboardPage(),
      ),
      GoRoute(
        path: Routes.clientBookings,
        builder: (context, state) => const ClientBookingsPage(),
      ),
      GoRoute(
        path: Routes.clientBookingDetail,
        builder: (context, state) => _buildWithRequiredParam(
          state: state,
          paramKey: 'id',
          builder: (id) => ClientBookingDetailPage(bookingId: id),
        ),
      ),
      GoRoute(
        path: Routes.clientReports,
        builder: (context, state) => const ClientReportsPage(),
      ),
      GoRoute(
        path: Routes.clientReportDetail,
        builder: (context, state) => _buildWithRequiredParam(
          state: state,
          paramKey: 'id',
          builder: (id) => ClientReportDetailPage(reportId: id),
        ),
      ),
      GoRoute(
        path: Routes.clientInvoices,
        builder: (context, state) => const ClientInvoicesPage(),
      ),
      GoRoute(
        path: Routes.clientInvoiceDetail,
        builder: (context, state) => _buildWithRequiredParam(
          state: state,
          paramKey: 'id',
          builder: (id) => ClientInvoiceDetailPage(invoiceId: id),
        ),
      ),
      GoRoute(
        path: Routes.clientBookingRequests,
        builder: (context, state) => const MyBookingRequestsPage(),
      ),
      GoRoute(
        path: Routes.clientBookingRequestNew,
        builder: (context, state) => const RequestBookingPage(),
      ),
      GoRoute(
        path: Routes.clientChangeRequests,
        builder: (context, state) => const MyChangeRequestsPage(),
      ),
      GoRoute(
        path: Routes.clientRequestChange,
        builder: (context, state) {
          final id = _safeParam(state, 'id');
          if (id == null) return const _MissingParamErrorPage(paramKey: 'id');
          final bookingDate = state.uri.queryParameters['date'];
          final bookingTime = state.uri.queryParameters['time'];
          final propertyAddress = state.uri.queryParameters['address'];
          return RequestChangePage(
            bookingId: id,
            bookingDate: bookingDate,
            bookingTime: bookingTime,
            propertyAddress: propertyAddress,
          );
        },
      ),

      // ==================== Main App Shell ====================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(
          navigationShell: navigationShell,
        ),
        branches: [
          // Dashboard branch
          // F2 FIX: Each branch has its own navigator key for proper back-stack management
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: Routes.dashboard,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          // Forms branch
          StatefulShellBranch(
            navigatorKey: _formsNavigatorKey,
            routes: [
              GoRoute(
                path: Routes.forms,
                builder: (context, state) => const FormsPage(),
              ),
            ],
          ),
          // Reports branch
          StatefulShellBranch(
            navigatorKey: _reportsNavigatorKey,
            routes: [
              GoRoute(
                path: Routes.reports,
                builder: (context, state) => const ReportsPage(),
              ),
            ],
          ),
          // Search branch
          StatefulShellBranch(
            navigatorKey: _searchNavigatorKey,
            routes: [
              GoRoute(
                path: Routes.search,
                builder: (context, state) => const SearchPage(),
              ),
            ],
          ),
        ],
      ),

      // ==================== Survey Routes ====================
      GoRoute(
        path: Routes.newSurvey,
        builder: (context, state) => const CreateSurveyPage(),
      ),
      GoRoute(
        path: Routes.surveyDetail,
        builder: (context, state) => _buildWithRequiredParam(
          state: state,
          paramKey: 'id',
          builder: (id) => SurveyDetailPage(surveyId: id),
        ),
      ),
      GoRoute(
        path: Routes.surveyOverview,
        builder: (context, state) => _buildWithRequiredParam(
          state: state,
          paramKey: 'id',
          builder: (id) => SurveyOverviewPage(surveyId: id),
        ),
      ),
      GoRoute(
        path: Routes.inspectionDetail,
        builder: (context, state) => _buildWithRequiredParam(
          state: state,
          paramKey: 'id',
          builder: (id) => InspectionOverviewPage(surveyId: id),
        ),
      ),
      GoRoute(
        path: Routes.inspectionSection,
        builder: (context, state) => _buildWithTwoParams(
          state: state,
          param1Key: 'id',
          param2Key: 'sectionId',
          builder: (surveyId, sectionId) => InspectionSectionPage(
            surveyId: surveyId,
            sectionKey: sectionId,
          ),
        ),
      ),
      GoRoute(
        path: Routes.inspectionNode,
        builder: (context, state) {
          final surveyId = _safeParam(state, 'id');
          final sectionId = _safeParam(state, 'sectionId');
          final nodeId = _safeParam(state, 'nodeId');
          if (surveyId == null || sectionId == null || nodeId == null) {
            return const _MissingParamErrorPage(paramKey: 'id/sectionId/nodeId');
          }
          return InspectionSectionPage(
            surveyId: surveyId,
            sectionKey: sectionId,
            parentNodeId: nodeId,
          );
        },
      ),
      GoRoute(
        path: Routes.inspectionScreen,
        builder: (context, state) => _buildWithTwoParams(
          state: state,
          param1Key: 'id',
          param2Key: 'screenId',
          builder: (surveyId, screenId) => InspectionScreenPage(
            surveyId: surveyId,
            screenId: screenId,
          ),
        ),
      ),
      GoRoute(
        path: Routes.inspectionCompass,
        builder: (context, state) => _buildWithRequiredParam(
          state: state,
          paramKey: 'id',
          builder: (id) => const InspectionCompassPage(),
        ),
      ),
      // Valuation routes
      GoRoute(
        path: Routes.valuationDetail,
        builder: (context, state) => _buildWithRequiredParam(
          state: state,
          paramKey: 'id',
          builder: (id) => ValuationOverviewPage(surveyId: id),
        ),
      ),
      GoRoute(
        path: Routes.valuationSection,
        builder: (context, state) => _buildWithTwoParams(
          state: state,
          param1Key: 'id',
          param2Key: 'sectionId',
          builder: (surveyId, sectionId) => ValuationSectionPage(
            surveyId: surveyId,
            sectionKey: sectionId,
          ),
        ),
      ),
      GoRoute(
        path: Routes.valuationNode,
        builder: (context, state) {
          final surveyId = _safeParam(state, 'id');
          final sectionId = _safeParam(state, 'sectionId');
          final nodeId = _safeParam(state, 'nodeId');
          if (surveyId == null || sectionId == null || nodeId == null) {
            return const _MissingParamErrorPage(paramKey: 'id/sectionId/nodeId');
          }
          return ValuationSectionPage(
            surveyId: surveyId,
            sectionKey: sectionId,
            parentNodeId: nodeId,
          );
        },
      ),
      GoRoute(
        path: Routes.valuationScreen,
        builder: (context, state) => _buildWithTwoParams(
          state: state,
          param1Key: 'id',
          param2Key: 'screenId',
          builder: (surveyId, screenId) => ValuationScreenPage(
            surveyId: surveyId,
            screenId: screenId,
          ),
        ),
      ),
      GoRoute(
        path: Routes.surveyMedia,
        builder: (context, state) {
          final id = _safeParam(state, 'id');
          if (id == null) return const _MissingParamErrorPage(paramKey: 'id');
          final title = state.uri.queryParameters['title'] ?? 'Survey';
          return SurveyMediaGalleryPage(surveyId: id, surveyTitle: title);
        },
      ),
      GoRoute(
        path: Routes.surveySignatures,
        builder: (context, state) {
          final id = _safeParam(state, 'id');
          if (id == null) return const _MissingParamErrorPage(paramKey: 'id');
          final title = state.uri.queryParameters['title'] ?? 'Survey';
          return SurveySignaturesPage(surveyId: id, surveyTitle: title);
        },
      ),
      GoRoute(
        path: Routes.surveyAttachments,
        builder: (context, state) {
          final id = _safeParam(state, 'id');
          if (id == null) return const _MissingParamErrorPage(paramKey: 'id');
          final title = state.uri.queryParameters['title'] ?? 'Survey';
          return AttachmentsSignaturesPage(surveyId: id, surveyTitle: title);
        },
      ),
      GoRoute(
        path: Routes.signatureCapture,
        builder: (context, state) {
          final id = _safeParam(state, 'id');
          if (id == null) return const _MissingParamErrorPage(paramKey: 'id');
          final sectionId = state.uri.queryParameters['sectionId'];
          final signerName = state.uri.queryParameters['signerName'];
          final signerRole = state.uri.queryParameters['signerRole'];
          return SignatureCapturePage(
            surveyId: id,
            sectionId: sectionId,
            initialSignerName: signerName,
            initialSignerRole: signerRole,
          );
        },
      ),
      GoRoute(
        path: Routes.reinspectionOverview,
        builder: (context, state) => _buildWithRequiredParam(
          state: state,
          paramKey: 'id',
          builder: (id) => ReinspectionOverviewPage(surveyId: id),
        ),
      ),
      GoRoute(
        path: Routes.surveyReport,
        redirect: (context, state) {
          // Redirect to survey overview which has proper PDF export functionality
          final id = state.pathParameters['id'];
          if (id == null || id.isEmpty) {
            AppLogger.e('Router', 'Missing id parameter for surveyReport redirect');
            return Routes.dashboard;
          }
          return Routes.surveyOverviewPath(id);
        },
      ),

      // ==================== Settings & Profile ====================
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: Routes.editProfile,
        redirect: (context, state) => Routes.profile,
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),

      // ==================== Scheduling Routes ====================
      GoRoute(
        path: Routes.scheduling,
        builder: (context, state) => const SchedulingPage(),
      ),
      GoRoute(
        path: Routes.schedulingCalendar,
        builder: (context, state) => const SlotCalendarPage(),
      ),
      GoRoute(
        path: Routes.schedulingBook,
        builder: (context, state) => const CreateBookingPage(),
      ),
      GoRoute(
        path: Routes.bookingsList,
        builder: (context, state) => const BookingsListPage(),
      ),
      GoRoute(
        path: Routes.bookingDetail,
        builder: (context, state) => _buildWithRequiredParam(
          state: state,
          paramKey: 'id',
          builder: (id) => BookingDetailPage(bookingId: id),
        ),
      ),
      GoRoute(
        path: Routes.availabilitySettings,
        builder: (context, state) => const AvailabilitySettingsPage(),
      ),

      // ==================== Invoices Routes ====================
      GoRoute(
        path: Routes.invoices,
        builder: (context, state) => const InvoicesListPage(),
      ),
      GoRoute(
        path: Routes.invoicesCreate,
        builder: (context, state) => const AdminCreateInvoicePage(),
      ),
      GoRoute(
        path: Routes.invoiceDetail,
        builder: (context, state) => _buildWithRequiredParam(
          state: state,
          paramKey: 'id',
          builder: (id) => InvoiceDetailPage(invoiceId: id),
        ),
      ),

      // ==================== PDF History ====================
      GoRoute(
        path: Routes.pdfHistory,
        builder: (context, state) => const PdfHistoryPage(),
      ),

      // ==================== Report Preview ====================
      GoRoute(
        path: Routes.reportPreview,
        builder: (context, state) => _buildWithRequiredParam(
          state: state,
          paramKey: 'reportId',
          builder: (reportId) => ReportPreviewPage(reportId: reportId),
        ),
      ),

      // ==================== Notifications ====================
      GoRoute(
        path: Routes.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),

      // ==================== Admin Routes ====================
      GoRoute(
        path: Routes.adminDashboard,
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: Routes.adminUsers,
        builder: (context, state) => const UserManagementPage(),
      ),
      // V1 legacy routes (phrases, fields, section-types) removed — use /admin/trees
      GoRoute(
        path: Routes.adminExports,
        builder: (context, state) => const AdminExportsPage(),
      ),
      GoRoute(
        path: Routes.adminIntegrations,
        builder: (context, state) => const AdminIntegrationsPage(),
      ),
      GoRoute(
        path: Routes.adminWebhooks,
        builder: (context, state) => const WebhooksListPage(),
      ),
      GoRoute(
        path: Routes.adminWebhooksCreate,
        builder: (context, state) => const WebhookCreatePage(),
      ),
      GoRoute(
        path: Routes.adminWebhookDetail,
        builder: (context, state) => _buildWithRequiredParam(
          state: state,
          paramKey: 'id',
          builder: (id) => WebhookDetailPage(webhookId: id),
        ),
      ),
      GoRoute(
        path: Routes.adminAutomation,
        builder: (context, state) => const AutomationGuidePage(),
      ),
      GoRoute(
        path: Routes.adminInvoices,
        builder: (context, state) => const AdminInvoicesListPage(),
      ),
      GoRoute(
        path: Routes.adminInvoicesCreate,
        builder: (context, state) => const AdminCreateInvoicePage(),
      ),
      GoRoute(
        path: Routes.adminInvoiceDetail,
        builder: (context, state) => _buildWithRequiredParam(
          state: state,
          paramKey: 'id',
          builder: (id) => AdminInvoiceDetailPage(invoiceId: id),
        ),
      ),
      GoRoute(
        path: Routes.adminAuditLogs,
        builder: (context, state) => const AuditLogsPage(),
      ),
      GoRoute(
        path: Routes.adminClients,
        builder: (context, state) => const AdminClientsListPage(),
      ),
      GoRoute(
        path: Routes.adminClientDetail,
        builder: (context, state) => _buildWithRequiredParam(
          state: state,
          paramKey: 'id',
          builder: (id) => AdminClientDetailPage(clientId: id),
        ),
      ),
      GoRoute(
        path: Routes.adminBookingRequests,
        builder: (context, state) => const BookingRequestsAdminPage(),
      ),
      GoRoute(
        path: Routes.adminChangeRequests,
        builder: (context, state) => const ChangeRequestsAdminPage(),
      ),
      GoRoute(
        path: Routes.adminTrees,
        builder: (context, state) => const TreeBrowserPage(),
      ),
    ],
    errorBuilder: (context, state) => _ErrorPage(error: state.error),
  );
});

class _ErrorPage extends StatelessWidget {
  const _ErrorPage({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Page Not Found',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'The page you are looking for does not exist.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  // F7 FIX: Explicitly use root GoRouter to ensure proper navigation
                  // from error pages that may be nested within shells
                  GoRouter.of(context).go(Routes.dashboard);
                },
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error page shown when a required route parameter is missing.
/// This provides graceful degradation instead of a crash.
class _MissingParamErrorPage extends StatelessWidget {
  const _MissingParamErrorPage({required this.paramKey});

  final String paramKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.link_off_rounded,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Invalid Link',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'This link is missing required information.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  // F7 FIX: Explicitly use root GoRouter to ensure proper navigation
                  // from error pages that may be nested within shells
                  GoRouter.of(context).go(Routes.dashboard);
                },
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
