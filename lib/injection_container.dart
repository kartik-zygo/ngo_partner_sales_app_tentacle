import 'package:get_it/get_it.dart';
import 'core/network/dio_client.dart';
import 'core/services/secure_storage_service.dart';
import 'core/services/socket_service.dart';
import 'data/datasources/remote_data_source.dart';
import 'data/repositories/admin_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/community_repository_impl.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'data/repositories/sales_repository_impl.dart';
import 'domain/repositories/admin_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/community_repository.dart';
import 'domain/repositories/notification_repository.dart';
import 'domain/repositories/sales_repository.dart';
import 'domain/usecases/admin_usecases.dart';
import 'domain/usecases/auth_usecases.dart';
import 'domain/usecases/community_usecases.dart';
import 'domain/usecases/notification_usecases.dart';
import 'domain/usecases/sales_usecases.dart';
import 'presentation/blocs/admin_reports/admin_reports_bloc.dart';
import 'presentation/blocs/admin_services/admin_services_bloc.dart';
import 'presentation/blocs/admin_team/admin_team_bloc.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/community/community_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/blocs/leads/leads_bloc.dart';
import 'presentation/blocs/notifications/notifications_bloc.dart';
import 'presentation/blocs/orders/orders_bloc.dart';
import 'presentation/blocs/payment_approvals/payment_approvals_bloc.dart';
import 'presentation/blocs/quotations/quotations_bloc.dart';
import 'presentation/blocs/tasks/tasks_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core infrastructure
  sl.registerLazySingleton<SecureStorageService>(SecureStorageService.new);
  sl.registerLazySingleton<SocketService>(SocketService.new);
  sl.registerLazySingleton(() => DioClient.instance.dio);

  // Remote data source
  sl.registerLazySingleton<RemoteDataSource>(() => RemoteDataSource(sl(), sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<SalesRepository>(() => SalesRepositoryImpl(sl()));
  sl.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(sl()));
  sl.registerLazySingleton<NotificationRepository>(() => NotificationRepositoryImpl(sl()));
  sl.registerLazySingleton<CommunityRepository>(() => CommunityRepositoryImpl(sl()));

  sl.registerLazySingleton(() => CheckSessionUseCase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAccountUseCase(sl()));

  sl.registerLazySingleton(() => GetSalesDashboardUseCase(sl()));
  sl.registerLazySingleton(() => GetLeadsUseCase(sl()));
  sl.registerLazySingleton(() => UpsertLeadUseCase(sl()));
  sl.registerLazySingleton(() => DeleteLeadUseCase(sl()));
  sl.registerLazySingleton(() => UpdateLeadStatusUseCase(sl()));
  sl.registerLazySingleton(() => AddLeadNoteUseCase(sl()));
  sl.registerLazySingleton(() => GetTasksUseCase(sl()));
  sl.registerLazySingleton(() => AddTaskUseCase(sl()));
  sl.registerLazySingleton(() => CompleteTaskUseCase(sl()));
  sl.registerLazySingleton(() => RescheduleTaskUseCase(sl()));
  sl.registerLazySingleton(() => GetClientCasesUseCase(sl()));
  sl.registerLazySingleton(() => CreateClientCaseUseCase(sl()));
  sl.registerLazySingleton(() => CreateLeadFromUserActionUseCase(sl()));
  sl.registerLazySingleton(() => SyncCaseStatusUseCase(sl()));
  sl.registerLazySingleton(() => RequestCaseDocumentsUseCase(sl()));
  sl.registerLazySingleton(() => MarkDocumentsResubmittedUseCase(sl()));
  sl.registerLazySingleton(() => PushUserNotificationEventUseCase(sl()));
  sl.registerLazySingleton(() => GetQueuedUserNotificationEventsUseCase(sl()));
  sl.registerLazySingleton(() => GetSupportTicketsUseCase(sl()));
  sl.registerLazySingleton(() => GetTicketByIdUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSupportTicketUseCase(sl()));
  sl.registerLazySingleton(() => AddTicketUpdateUseCase(sl()));
  sl.registerLazySingleton(() => EscalateTicketUseCase(sl()));
  sl.registerLazySingleton(() => GetSupportCallsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSupportCallStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetAgoraTokenUseCase(sl()));
  sl.registerLazySingleton(() => GetCollaborationOpportunitiesUseCase(sl()));

  sl.registerLazySingleton(() => GetAdminDashboardUseCase(sl()));
  sl.registerLazySingleton(() => GetIntegrationDashboardMetricsUseCase(sl()));
  sl.registerLazySingleton(() => GetAllLeadsUseCase(sl()));
  sl.registerLazySingleton(() => AssignLeadUseCase(sl()));
  sl.registerLazySingleton(() => ReassignLeadUseCase(sl()));
  sl.registerLazySingleton(() => GetTeamMembersUseCase(sl()));
  sl.registerLazySingleton(() => UpsertTeamMemberUseCase(sl()));
  sl.registerLazySingleton(() => SetTeamMemberActiveUseCase(sl()));
  sl.registerLazySingleton(() => GetServicePackagesUseCase(sl()));
  sl.registerLazySingleton(() => GetServiceCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => UpsertServicePackageUseCase(sl()));
  sl.registerLazySingleton(() => ToggleServicePackageUseCase(sl()));
  sl.registerLazySingleton(() => DeleteServicePackageUseCase(sl()));
  sl.registerLazySingleton(() => GetApprovalRequestsUseCase(sl()));
  sl.registerLazySingleton(() => DecideApprovalUseCase(sl()));
  sl.registerLazySingleton(() => GetRevenueRecordsUseCase(sl()));
  sl.registerLazySingleton(() => ExportReportUseCase(sl()));
  sl.registerLazySingleton(() => GetReportExportHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetAssignmentHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetAdminSupportTicketsUseCase(sl()));
  sl.registerLazySingleton(() => GetAdminTicketByIdUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAdminSupportTicketUseCase(sl()));
  sl.registerLazySingleton(() => AddAdminTicketUpdateUseCase(sl()));
  sl.registerLazySingleton(() => EscalateAdminTicketUseCase(sl()));
  sl.registerLazySingleton(() => AssignTicketUseCase(sl()));
  sl.registerLazySingleton(() => GetAdminCollaborationOpportunitiesUseCase(sl()));
  sl.registerLazySingleton(() => GetOrdersUseCase(sl()));
  sl.registerLazySingleton(() => GetOrderByIdUseCase(sl()));
  sl.registerLazySingleton(() => UpdateOrderFulfillmentUseCase(sl()));
  sl.registerLazySingleton(() => GetPaymentRequestsUseCase(sl()));
  sl.registerLazySingleton(() => GetPaymentRequestByIdUseCase(sl()));
  sl.registerLazySingleton(() => DecidePaymentRequestUseCase(sl()));

  sl.registerLazySingleton(() => GetQuotationsUseCase(sl()));
  sl.registerLazySingleton(() => GetQuotationByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetSalesRepsUseCase(sl()));
  sl.registerLazySingleton(() => AssignQuotationUseCase(sl()));
  sl.registerLazySingleton(() => UpdateQuotationStatusUseCase(sl()));
  sl.registerLazySingleton(() => AddQuotationNoteUseCase(sl()));

  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => MarkNotificationReadUseCase(sl()));

  sl.registerLazySingleton(() => GetCommunityPostsUseCase(sl()));
  sl.registerLazySingleton(() => GetCommunityPostUseCase(sl()));
  sl.registerLazySingleton(() => AddCommunityAnswerUseCase(sl()));
  sl.registerLazySingleton(() => VoteCommunityPostUseCase(sl()));
  sl.registerLazySingleton(() => VoteCommunityAnswerUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCommunityPostUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCommunityAnswerUseCase(sl()));
  sl.registerLazySingleton(() => SetCommunityPostClosedUseCase(sl()));
  sl.registerLazySingleton(() => GetCommunityTagsUseCase(sl()));

  sl.registerFactory(
    () => AuthBloc(
      checkSessionUseCase: sl(),
      loginUseCase: sl(),
      logoutUseCase: sl(),
      changePasswordUseCase: sl(),
      secureStorage: sl(),
      socketService: sl(),
    ),
  );

  sl.registerFactory(
    () => DashboardBloc(
      getSalesDashboardUseCase: sl(),
      getAdminDashboardUseCase: sl(),
      getIntegrationDashboardMetricsUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => LeadsBloc(
      getLeadsUseCase: sl(),
      upsertLeadUseCase: sl(),
      deleteLeadUseCase: sl(),
      updateLeadStatusUseCase: sl(),
      addLeadNoteUseCase: sl(),
      getClientCasesUseCase: sl(),
      createClientCaseUseCase: sl(),
      addTaskUseCase: sl(),
      createLeadFromUserActionUseCase: sl(),
      syncCaseStatusUseCase: sl(),
      requestCaseDocumentsUseCase: sl(),
      markDocumentsResubmittedUseCase: sl(),
      pushUserNotificationEventUseCase: sl(),
      getQueuedUserNotificationEventsUseCase: sl(),
      getSupportTicketsUseCase: sl(),
      getTicketByIdUseCase: sl(),
      updateSupportTicketUseCase: sl(),
      addTicketUpdateUseCase: sl(),
      escalateTicketUseCase: sl(),
      getSupportCallsUseCase: sl(),
      updateSupportCallStatusUseCase: sl(),
      getCollaborationOpportunitiesUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => TasksBloc(
      getTasksUseCase: sl(),
      completeTaskUseCase: sl(),
      rescheduleTaskUseCase: sl(),
      addTaskUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => NotificationsBloc(
      getNotificationsUseCase: sl(),
      markNotificationReadUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => AdminTeamBloc(
      getAllLeadsUseCase: sl(),
      getTeamMembersUseCase: sl(),
      upsertTeamMemberUseCase: sl(),
      setTeamMemberActiveUseCase: sl(),
      assignLeadUseCase: sl(),
      reassignLeadUseCase: sl(),
      getAssignmentHistoryUseCase: sl(),
      getAdminSupportTicketsUseCase: sl(),
      getAdminTicketByIdUseCase: sl(),
      updateAdminSupportTicketUseCase: sl(),
      addAdminTicketUpdateUseCase: sl(),
      escalateAdminTicketUseCase: sl(),
      assignTicketUseCase: sl(),
      getAdminCollaborationOpportunitiesUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => AdminServicesBloc(
      getServicePackagesUseCase: sl(),
      getServiceCategoriesUseCase: sl(),
      upsertServicePackageUseCase: sl(),
      toggleServicePackageUseCase: sl(),
      deleteServicePackageUseCase: sl(),
      getApprovalRequestsUseCase: sl(),
      decideApprovalUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => OrdersBloc(
      getOrdersUseCase: sl(),
      getOrderByIdUseCase: sl(),
      updateOrderFulfillmentUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => PaymentApprovalsBloc(
      getPaymentRequestsUseCase: sl(),
      getPaymentRequestByIdUseCase: sl(),
      decidePaymentRequestUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => QuotationsBloc(
      getQuotationsUseCase: sl(),
      getQuotationByIdUseCase: sl(),
      getSalesRepsUseCase: sl(),
      assignQuotationUseCase: sl(),
      updateQuotationStatusUseCase: sl(),
      addQuotationNoteUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => AdminReportsBloc(
      getRevenueRecordsUseCase: sl(),
      exportReportUseCase: sl(),
      getReportExportHistoryUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => CommunityBloc(
      getPosts: sl(),
      getTags: sl(),
    ),
  );
}
