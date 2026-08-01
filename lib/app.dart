import 'package:doctor_app/core/storage/secure_storage.dart';
import 'package:flutter/material.dart';
import 'routes/app_router.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/auth/service/auth_service.dart';
import 'features/auth/view_model/auth_view_model.dart';
// 앱 전체에서 공통으로 사용하는 Provider  등록
// MaterialApp과  GoRouter를 연결하는 역할
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ // Django REST API와 통신을 위한 Dio 클라이언트
        Provider<ApiClient>(create: (_) => ApiClient(),),
        Provider<SecureStorage>(create: (_) => SecureStorage(),),      // access, refresh Token 기기 보안 저장소에 저장,조회
        Provider<AuthService>(create: (context) => AuthService(        // 로그인 API 요청 수행
          context.read<ApiClient>(),),),
        Provider<AuthRepository>(create: (context) => AuthRepository(  // 인증서비스와 보안 저장소 연결
          context.read<AuthService>(),
          context.read<SecureStorage>(),),),
        ChangeNotifierProvider<AuthViewModel>(create: (context) => AuthViewModel(   // 인증 상태 관리
          context.read<AuthRepository>(),
        ),),
      ],
      child: MaterialApp.router( //  기존 코드 유지 부분
        debugShowCheckedModeBanner: false,
        title: 'Doctor App',
        routerConfig: AppRouter.router,
      ),
    );
  }
}
