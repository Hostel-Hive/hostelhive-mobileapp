import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/first_login_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/password_changed_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/qr/models/scan_result.dart';
import '../../features/qr/screens/my_qr_screen.dart';
import '../../features/qr/screens/scan_result_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const firstLogin = '/first-login';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const passwordChanged = '/password-changed';
  static const home = '/home';
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

  return GoRouter(
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
        path: AppRoutes.passwordChanged,
        builder: (context, state) => const PasswordChangedScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
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
