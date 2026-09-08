import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart';
import 'presentation/blocs/admin_reports/admin_reports_bloc.dart';
import 'presentation/blocs/admin_services/admin_services_bloc.dart';
import 'presentation/blocs/admin_team/admin_team_bloc.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/blocs/leads/leads_bloc.dart';
import 'presentation/blocs/notifications/notifications_bloc.dart';
import 'presentation/blocs/orders/orders_bloc.dart';
import 'presentation/blocs/payment_approvals/payment_approvals_bloc.dart';
import 'presentation/blocs/tasks/tasks_bloc.dart';
import 'presentation/pages/admin/admin_shell_page.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/sales/sales_shell_page.dart';
import 'presentation/pages/splash/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const NgoPartnerSalesApp());
}

class NgoPartnerSalesApp extends StatelessWidget {
  const NgoPartnerSalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()..add(const AuthStarted())),
        BlocProvider(create: (_) => sl<DashboardBloc>()),
        BlocProvider(create: (_) => sl<LeadsBloc>()),
        BlocProvider(create: (_) => sl<TasksBloc>()),
        BlocProvider(create: (_) => sl<NotificationsBloc>()),
        BlocProvider(create: (_) => sl<AdminTeamBloc>()),
        BlocProvider(create: (_) => sl<AdminServicesBloc>()),
        BlocProvider(create: (_) => sl<AdminReportsBloc>()),
        BlocProvider(create: (_) => sl<OrdersBloc>()),
        BlocProvider(create: (_) => sl<PaymentApprovalsBloc>()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const _RootRouter(),
      ),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        Widget child;
        switch (state.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            child = const SplashPage();
          case AuthStatus.unauthenticated:
          case AuthStatus.failure:
            child = const LoginPage();
          case AuthStatus.authenticated:
            final user = state.user!;
            child = user.role.name == 'sales'
                ? SalesShellPage(user: user)
                : AdminShellPage(user: user);
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey(state.status.name + (state.user?.role.name ?? 'guest')),
            child: child,
          ),
        );
      },
    );
  }
}
