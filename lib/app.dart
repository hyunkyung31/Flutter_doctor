import 'package:doctor_app/core/storage/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routes/app_router.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/security/screen_protection/privacy_shield.dart';

import 'features/auth/repository/auth_repository.dart';
import 'features/auth/service/auth_service.dart';
import 'features/auth/service/biometric_auth_service.dart';
import 'features/auth/service/sensitive_auth_service.dart';
import 'features/auth/view_model/auth_view_model.dart';

import 'features/patient/repository/patient_repository.dart';
import 'features/patient/service/patient_service.dart';
import 'features/patient/view_model/patient_list_view_model.dart';

import 'features/settings/view_model/settings_view_model.dart';

import 'features/calendar/view_model/calendar_view_model.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (_) => ApiClient(),
        ),

        Provider<SecureStorage>(
          create: (_) => SecureStorage(),
        ),

        Provider<AuthService>(
          create: (context) => AuthService(
            context.read<ApiClient>(),
          ),
        ),

        Provider<AuthRepository>(
          create: (context) => AuthRepository(
            context.read<AuthService>(),
            context.read<SecureStorage>(),
          ),
        ),

        Provider<BiometricAuthService>(
          create: (_) => BiometricAuthService(),
        ),

        Provider<SensitiveAuthService>(
          create: (context) => SensitiveAuthService(
            context.read<BiometricAuthService>(),
          ),
        ),

        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthRepository>(),
            context.read<BiometricAuthService>(),
            context.read<SensitiveAuthService>(),
          ),
        ),

        Provider<PatientService>(
          create: (context) => PatientService(
            context.read<ApiClient>(),
          ),
        ),

        Provider<PatientRepository>(
          create: (context) => PatientRepository(
            patientService:
                context.read<PatientService>(),
            secureStorage:
                context.read<SecureStorage>(),
          ),
        ),

        ChangeNotifierProvider<PatientListViewModel>(
          create: (context) => PatientListViewModel(
            patientRepository:
                context.read<PatientRepository>(),
          ),
        ),

        ChangeNotifierProvider<SettingsViewModel>(
          create: (_) => SettingsViewModel(),
        ),

        ChangeNotifierProvider<CalendarViewModel>(
          create: (_) => CalendarViewModel(),
        ),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Doctor App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                context.watch<SettingsViewModel>().themeMode,
            builder: (context, child) {
              return PrivacyShield(
                child:
                    child ?? const SizedBox.shrink(),
              );
            },
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}