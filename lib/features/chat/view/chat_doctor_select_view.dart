import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../model/chat_models.dart';
import '../view_model/chat_view_model.dart';
import '../../../core/widgets/profile/doctor_profile_avatar.dart';

final class ChatDoctorSelectView extends StatefulWidget {
  const ChatDoctorSelectView({super.key});

  @override
  State<ChatDoctorSelectView> createState() => _ChatDoctorSelectViewState();
}

final class _ChatDoctorSelectViewState extends State<ChatDoctorSelectView> {
  String query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().loadDoctors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();
    final doctors = viewModel.doctors.where(_matches).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('새 채팅')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SearchBar(
              autoFocus: true,
              hintText: '의사 이름 또는 진료과 검색',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (value) => setState(() => query = value.trim()),
            ),
          ),
          Expanded(
            child: viewModel.isDoctorsLoading && viewModel.doctors.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : viewModel.doctorsError != null && viewModel.doctors.isEmpty
                ? _DoctorLoadError(
                    message: viewModel.doctorsError!,
                    onRetry: () => viewModel.loadDoctors(force: true),
                  )
                : doctors.isEmpty
                ? const Center(child: Text('검색 결과가 없습니다.'))
                : RefreshIndicator(
                    onRefresh: () => viewModel.loadDoctors(force: true),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: doctors.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final doctor = doctors[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            leading: const DoctorProfileAvatar(radius: 22),
                            title: Text(
                              doctor.name.isEmpty ? '이름 미등록 의사' : doctor.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${doctor.department} · ${doctor.hospital}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              final room = await viewModel.openRoom(doctor);
                              if (!context.mounted) return;
                              if (room == null) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        viewModel.errorMessage ??
                                            '채팅방을 만들지 못했습니다.',
                                      ),
                                    ),
                                  );
                                return;
                              }
                              context.goNamed(
                                'chat-room',
                                pathParameters: {'roomId': room.id},
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  bool _matches(ChatDoctor doctor) {
    if (query.isEmpty) return true;
    final value = query.toLowerCase();
    return doctor.name.toLowerCase().contains(value) ||
        doctor.department.toLowerCase().contains(value);
  }
}

final class _DoctorLoadError extends StatelessWidget {
  const _DoctorLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
