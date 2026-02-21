abstract final class Routes {
  // Auth routes
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String register = '/register';

  // Main app routes
  static const String dashboard = '/';
  static const String forms = '/forms';
  static const String reports = '/reports';
  static const String search = '/search';
  static const String newSurvey = '/new-survey';
  static const String surveyDetail = '/survey/:id';
  static const String surveyOverview = '/survey/:id/overview';
  static const String surveyReport = '/survey/:id/report';
  static const String inspectionDetail = '/survey/:id/inspection';
  static const String inspectionSection = '/survey/:id/inspection/section/:sectionId';
  static const String inspectionNode = '/survey/:id/inspection/section/:sectionId/node/:nodeId';
  static const String inspectionScreen = '/survey/:id/inspection/section/:sectionId/screen/:screenId';
  static const String inspectionCompass = '/survey/:id/inspection/compass';

  // Valuation routes
  static const String valuationDetail = '/survey/:id/valuation';
  static const String valuationSection = '/survey/:id/valuation/section/:sectionId';
  static const String valuationNode = '/survey/:id/valuation/section/:sectionId/node/:nodeId';
  static const String valuationScreen = '/survey/:id/valuation/section/:sectionId/screen/:screenId';

  static const String surveyMedia = '/survey/:id/media';
  static const String surveySignatures = '/survey/:id/signatures';
  static const String surveyAttachments = '/survey/:id/attachments';
  static const String signatureCapture = '/survey/:id/signature/capture';
  static const String reinspectionOverview = '/survey/:id/reinspection';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/change-password';

  // Admin routes
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  // V1 legacy routes — removed, functionality moved to V2 Tree Manager (/admin/trees)
  static const String adminExports = '/admin/exports';
  static const String adminIntegrations = '/admin/integrations';
  static const String adminWebhooks = '/admin/webhooks';
  static const String adminWebhooksCreate = '/admin/webhooks/create';
  static const String adminWebhookDetail = '/admin/webhooks/:id';
  static const String adminAutomation = '/admin/automation';
  static const String adminInvoices = '/admin/invoices';
  static const String adminInvoicesCreate = '/admin/invoices/new';
  static const String adminInvoiceDetail = '/admin/invoices/:id';
  static const String adminAuditLogs = '/admin/audit-logs';
  static const String adminClients = '/admin/clients';
  static const String adminClientDetail = '/admin/clients/:id';
  static const String adminBookingRequests = '/admin/booking-requests';
  static const String adminChangeRequests = '/admin/change-requests';
  static const String adminTrees = '/admin/trees';

  // Scheduling routes
  static const String scheduling = '/scheduling';
  static const String schedulingCalendar = '/scheduling/calendar';
  static const String schedulingBook = '/scheduling/book';
  static const String bookingsList = '/scheduling/bookings';
  static const String bookingDetail = '/scheduling/bookings/:id';
  static const String availabilitySettings = '/scheduling/availability';

  // Invoices routes
  static const String invoices = '/invoices';
  static const String invoicesCreate = '/invoices/create';
  static const String invoiceDetail = '/invoices/:id';

  // Client Portal routes
  static const String clientLogin = '/client/login';
  static const String clientMagicLinkSent = '/client/magic-link-sent';
  static const String clientVerify = '/client/verify';
  static const String clientDashboard = '/client/dashboard';
  static const String clientBookings = '/client/bookings';
  static const String clientBookingDetail = '/client/bookings/:id';
  static const String clientReports = '/client/reports';
  static const String clientReportDetail = '/client/reports/:id';
  static const String clientInvoices = '/client/invoices';
  static const String clientInvoiceDetail = '/client/invoices/:id';
  static const String clientBookingRequests = '/client/booking-requests';
  static const String clientBookingRequestNew = '/client/booking-requests/new';
  static const String clientChangeRequests = '/client/change-requests';
  static const String clientRequestChange = '/client/bookings/:id/request-change';

  // PDF History
  static const String pdfHistory = '/pdf-history';

  // Report Preview
  static const String reportPreview = '/report-preview/:reportId';
  static String reportPreviewPath(String reportId) => '/report-preview/$reportId';

  // Notifications
  static const String notifications = '/notifications';

  // Helper methods for dynamic routes
  static String surveyDetailPath(String id) => '/survey/$id';
  static String surveyOverviewPath(String id) => '/survey/$id/overview';
  static String surveyReportPath(String id) => '/survey/$id/report';
  static String inspectionDetailPath(String id) => '/survey/$id/inspection';
  static String inspectionSectionPath(String id, String sectionId) =>
      '/survey/$id/inspection/section/$sectionId';
  static String inspectionNodePath(String id, String sectionId, String nodeId) =>
      '/survey/$id/inspection/section/$sectionId/node/$nodeId';
  static String inspectionScreenPath(String id, String sectionId, String screenId) =>
      '/survey/$id/inspection/section/$sectionId/screen/$screenId';
  static String inspectionCompassPath(String id) => '/survey/$id/inspection/compass';

  // Valuation path helpers
  static String valuationDetailPath(String id) => '/survey/$id/valuation';
  static String valuationSectionPath(String id, String sectionId) =>
      '/survey/$id/valuation/section/$sectionId';
  static String valuationNodePath(String id, String sectionId, String nodeId) =>
      '/survey/$id/valuation/section/$sectionId/node/$nodeId';
  static String valuationScreenPath(String id, String sectionId, String screenId) =>
      '/survey/$id/valuation/section/$sectionId/screen/$screenId';

  static String surveyMediaPath(String id) => '/survey/$id/media';
  static String surveySignaturesPath(String id) => '/survey/$id/signatures';
  static String surveyAttachmentsPath(String id) => '/survey/$id/attachments';
  static String signatureCapturePath(String id) => '/survey/$id/signature/capture';
  static String reinspectionOverviewPath(String id) => '/survey/$id/reinspection';
  static String clientRequestChangePath(String bookingId) =>
      '/client/bookings/$bookingId/request-change';
  static String bookingDetailPath(String id) => '/scheduling/bookings/$id';
  static String invoiceDetailPath(String id) => '/invoices/$id';
  static String clientBookingDetailPath(String id) => '/client/bookings/$id';
  static String clientReportDetailPath(String id) => '/client/reports/$id';
  static String clientInvoiceDetailPath(String id) => '/client/invoices/$id';
  static String webhookDetailPath(String id) => '/admin/webhooks/$id';
  static String adminInvoiceDetailPath(String id) => '/admin/invoices/$id';
  static String adminClientDetailPath(String id) => '/admin/clients/$id';
}
