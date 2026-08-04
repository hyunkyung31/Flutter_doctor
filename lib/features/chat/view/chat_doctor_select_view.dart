import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../model/chat_models.dart';
import '../view_model/chat_view_model.dart';

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
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '의사 이름 또는 진료과 검색',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
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
                              itemCount: doctors.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final doctor = doctors[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      doctor.name.isEmpty
                                          ? '?'
                                          : doctor.name.substring(0, 1),
                                    ),
                                  ),
                                  title: Text(
                                    doctor.name.isEmpty
                                        ? '이름 미등록 의사'
                                        : doctor.name,
                                  ),
                                  subtitle: Text(
                                    '${doctor.department} · ${doctor.hospital}',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () async {
                                    final room = await viewModel.openRoom(doctor);
                                    if (!context.mounted || room == null) return;
                                    context.go('/chat/${room.id}');
                                  },
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
