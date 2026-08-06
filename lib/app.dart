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

import 'features/diagnosis/repository/diagnosis_repository.dart';
import 'features/diagnosis/service/diagnosis_service.dart';

import 'features/settings/view_model/settings_view_model.dart';
import 'features/calendar/view_model/calendar_view_model.dart';

import 'features/consultation/repository/consultation_repository.dart';
import 'features/consultation/service/consultation_service.dart';
import 'features/consultation/view_model/consultation_view_model.dart';
import 'features/appointment/repository/appointment_repository.dart';
import 'features/appointment/service/appointment_service.dart';
import 'features/appointment/view_model/appointment_view_model.dart';
import 'features/chat/view_model/chat_view_model.dart';
import 'features/chat/service/chat_service.dart';
import 'features/chat/repository/chat_repository.dart';
import 'features/memo/repository/memo_repository.dart';
import 'features/memo/service/memo_service.dart';
import 'features/memo/view_model/memo_view_model.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),

        Provider<SecureStorage>(create: (_) => SecureStorage()),

        Provider<AuthService>(
          create: (context) => AuthService(context.read<ApiClient>()),
        ),

        Provider<AuthRepository>(
          create: (context) => AuthRepository(
            context.read<AuthService>(),
            context.read<SecureStorage>(),
          ),
        ),

        Provider<BiometricAuthService>(create: (_) => BiometricAuthService()),

        Provider<SensitiveAuthService>(
          create: (context) =>
              SensitiveAuthService(context.read<BiometricAuthService>()),
        ),

        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthRepository>(),
            context.read<BiometricAuthService>(),
            context.read<SensitiveAuthService>(),
          ),
        ),

        Provider<PatientService>(
          create: (context) => PatientService(context.read<ApiClient>()),
        ),

        Provider<PatientRepository>(
          create: (context) => PatientRepository(
            patientService: context.read<PatientService>(),
            secureStorage: context.read<SecureStorage>(),
          ),
        ),

        Provider<DiagnosisService>(
          create: (context) => DiagnosisService(context.read<ApiClient>()),
        ),

        Provider<DiagnosisRepository>(
          create: (context) => DiagnosisRepository(
            context.read<DiagnosisService>(),
            context.read<SecureStorage>(),
          ),
        ),
        ChangeNotifierProvider<PatientListViewModel>(
          create: (context) => PatientListViewModel(
            patientRepository: context.read<PatientRepository>(),
          )..loadPatients(),
        ),

        ChangeNotifierProvider<SettingsViewModel>(
          create: (_) => SettingsViewModel(),
        ),

        ChangeNotifierProvider<CalendarViewModel>(
          create: (_) => CalendarViewModel(),
        ),

        Provider<ConsultationService>(
          create: (context) => ConsultationService(context.read<ApiClient>()),
        ),

        Provider<ConsultationRepository>(
          create: (context) => ConsultationRepository(
            consultationService: context.read<ConsultationService>(),
            secureStorage: context.read<SecureStorage>(),
          ),
        ),
        ChangeNotifierProvider<ConsultationViewModel>(
          create: (context) => ConsultationViewModel(
            consultationRepository: context.read<ConsultationRepository>(),
          ),
        ),
        Provider<AppointmentService>(
          create: (context) => AppointmentService(context.read<ApiClient>()),
        ),
        Provider<AppointmentRepository>(
          create: (context) => AppointmentRepository(
            appointmentService: context.read<AppointmentService>(),
            secureStorage: context.read<SecureStorage>(),
          ),
        ),
        ChangeNotifierProvider<AppointmentViewModel>(
          create: (context) => AppointmentViewModel(
            appointmentRepository: context.read<AppointmentRepository>(),
          ),
        ),
        Provider<ChatService>(
          create: (context) => ChatService(context.read<ApiClient>()),
        ),
        Provider<ChatRepository>(
          create: (context) => ChatRepository(
            service: context.read<ChatService>(),
            storage: context.read<SecureStorage>(),
          ),
        ),
        ChangeNotifierProvider<ChatViewModel>(
          create: (context) => ChatViewModel(
            chatRepository: context.read<ChatRepository>(),
            consultationRepository: context.read<ConsultationRepository>(),
          ),
        ),
        Provider<MemoService>(
          create: (context) => MemoService(context.read<ApiClient>()),
        ),
        Provider<MemoRepository>(
          create: (context) => MemoRepository(
            memoService: context.read<MemoService>(),
            secureStorage: context.read<SecureStorage>(),
          ),
        ),
        ChangeNotifierProvider<MemoViewModel>(
          create: (context) => MemoViewModel(
            memoRepository: context.read<MemoRepository>(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Doctor App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: context.watch<SettingsViewModel>().themeMode,
            builder: (context, child) {
              return PrivacyShield(child: child ?? const SizedBox.shrink());
            },
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
