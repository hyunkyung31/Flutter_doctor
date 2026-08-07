import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/view_model/auth_view_model.dart';
import '../../settings/view_model/settings_view_model.dart';
import '../../../core/widgets/profile/doctor_profile_avatar.dart';

final class MyPageView extends StatefulWidget {
  const MyPageView({super.key});

  @override
  State<MyPageView> createState() => _MyPageViewState();
}

final class _MyPageViewState extends State<MyPageView> {
  bool _isAutoLoginEnabled = true;
  bool _isBiometricLoginEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final settingsViewModel = context.watch<SettingsViewModel>();
    final colorScheme = Theme.of(context).colorScheme;
    final doctorName = authViewModel.doctorName?.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _ProfileCard(
            doctorName: doctorName == null || doctorName.isEmpty
                ? '의료진'
                : doctorName,
            department: '진료과 정보 없음',
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            children: [
              _MenuTile(
                icon: Icons.calendar_month_outlined,
                title: '내 일정',
                onTap: () => context.pushNamed('calendar'),
              ),
              _MenuTile(
                icon: Icons.groups_outlined,
                title: '협진 내역',
                onTap: () => context.pushNamed('consultationInbox'),
              ),
              _MenuTile(
                icon: Icons.history,
                title: '최근 본 환자',
                onTap: () => context.push('/patient'),
              ),
              _MenuTile(
                icon: Icons.mic_none,
                title: '최근 녹음',
                onTap: () => context.pushNamed('recentVoiceMemos'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.login),
                title: const Text('자동 로그인'),
                value: _isAutoLoginEnabled,
                onChanged: (value) {
                  setState(() => _isAutoLoginEnabled = value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: const Text('생체인식 로그인'),
                value: _isBiometricLoginEnabled,
                onChanged: (value) {
                  setState(() => _isBiometricLoginEnabled = value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('다크 모드'),
                value: settingsViewModel.isDarkMode,
                onChanged: (_) => settingsViewModel.toggleTheme(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            children: [
              _MenuTile(
                icon: Icons.info_outline,
                title: '앱 정보',
                onTap: _showAppInfo,
              ),
              ListTile(
                leading: Icon(Icons.logout, color: colorScheme.error),
                title: Text('로그아웃', style: TextStyle(color: colorScheme.error)),
                onTap: _confirmLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAppInfo() {
    showAboutDialog(
      context: context,
      applicationName: 'VENA',
      applicationVersion: '1.0.0',
      applicationLegalese: '의료진용 환자 관리 및 협진 지원 서비스',
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    final success = await context.read<AuthViewModel>().logout();
    if (!mounted) {
      return;
    }

    if (success) {
      context.go('/login');
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('로그아웃하지 못했습니다. 다시 시도해 주세요.')));
  }
}

final class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.doctorName, required this.department});

  final String doctorName;
  final String department;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const DoctorProfileAvatar(radius: 30, scale: 1.7),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$doctorName 의사',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    department,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

final class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
