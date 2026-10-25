import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/change_password_screen.dart';
import '../../features/auth/screens/first_login_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/password_changed_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/attendance/screens/attendance_screen.dart';
import '../../features/complaints/screens/complaint_detail_screen.dart';
import '../../features/complaints/screens/complaint_submitted_screen.dart';
import '../../features/complaints/screens/complaints_screen.dart';
import '../../features/complaints/screens/submit_complaint_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/home_shell.dart';
import '../../features/inbox/screens/announcement_detail_screen.dart';
import '../../features/inbox/screens/inbox_screen.dart';
import '../../features/passes/screens/going_home_screen.dart';
import '../../features/passes/screens/pass_confirmation_screens.dart';
import '../../features/passes/screens/pass_detail_screen.dart';
import '../../features/passes/screens/passes_screen.dart';
import '../../features/passes/screens/request_late_access_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/qr/models/scan_result.dart';
import '../../features/qr/screens/my_qr_screen.dart';
import '../../features/qr/screens/scan_result_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const firstLogin = '/first-login';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const changePassword = '/change-password';
  static const passwordChanged = '/password-changed';
  static const home = '/home';
  static const passes = '/passes';
  static const requestLateAccess = '/passes/request';
  static const goingHome = '/going-home';
  static const goingHomeRecorded = '/going-home/recorded';
  static const inbox = '/inbox';
  static const profile = '/profile';
  static const attendance = '/attendance';
  static const complaints = '/complaints';
  static const newComplaint = '/complaints/new';
  static const qr = '/qr';
  static const scanResult = '/scan-result';

  /// Screens a signed-out student may open.
  static const publicRoutes = {
    login,
    forgotPassword,
    resetPassword,
    passwordChanged,
  };
}

/// Decides where a student must be sent for the current session.
/// Returns null when the requested [location] is allowed.
String? authRedirect({required AuthState auth, required String location}) {
  final isPublic = AppRoutes.publicRoutes.contains(location);

  switch (auth.status) {
    case AuthStatus.unknown:
      return null;
    case AuthStatus.unauthenticated:
      if (isPublic) return null;
      return AppRoutes.login;
    case AuthStatus.authenticated:
      if (auth.mustChangePassword) {
        return location == AppRoutes.firstLogin ? null : AppRoutes.firstLogin;
      }
      if (isPublic || location == AppRoutes.firstLogin) return AppRoutes.home;
      return null;
  }
}

class _AuthRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh();
  ref.listen<AuthState>(authControllerProvider, (_, _) => refresh.refresh());
  ref.onDispose(refresh.dispose);

  final rootKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.login,
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(
      auth: ref.read(authControllerProvider),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.firstLogin,
        builder: (context, state) => const FirstLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          token:
              state.uri.queryParameters['token'] ??
              MockAuthRepository.demoResetToken,
        ),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.passwordChanged,
        builder: (context, state) => const PasswordChangedScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.passes,
                builder: (context, state) => const PassesScreen(),
                routes: [
                  GoRoute(
                    parentNavigatorKey: rootKey,
                    path: 'request',
                    builder: (context, state) =>
                        const RequestLateAccessScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: rootKey,
                    path: ':id',
                    builder: (context, state) =>
                        PassDetailScreen(passId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        parentNavigatorKey: rootKey,
                        path: 'submitted',
                        builder: (context, state) => LateAccessSubmittedScreen(
                          passId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.inbox,
                builder: (context, state) => const InboxScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.goingHome,
        builder: (context, state) => const GoingHomeScreen(),
        routes: [
          GoRoute(
            path: 'recorded',
            builder: (context, state) => const GoingHomeRecordedScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.complaints,
        builder: (context, state) => const ComplaintsScreen(),
      ),
      GoRoute(
        path: AppRoutes.newComplaint,
        builder: (context, state) => const SubmitComplaintScreen(),
      ),
      GoRoute(
        path: '/complaints/:id',
        builder: (context, state) =>
            ComplaintDetailScreen(complaintId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/complaints/:id/submitted',
        builder: (context, state) =>
            ComplaintSubmittedScreen(complaintId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/inbox/:id',
        builder: (context, state) =>
            AnnouncementDetailScreen(itemId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.attendance,
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.qr,
        builder: (context, state) => const MyQrScreen(),
      ),
      GoRoute(
        path: AppRoutes.scanResult,
        redirect: (context, state) =>
            state.extra is ScanResult ? null : AppRoutes.home,
        builder: (context, state) =>
            ScanResultScreen(result: state.extra! as ScanResult),
      ),
    ],
  );
});
