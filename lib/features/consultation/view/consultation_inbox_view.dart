import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../model/consultation_request.dart';
import '../view_model/consultation_view_model.dart';

final class ConsultationInboxView extends StatefulWidget {
  const ConsultationInboxView({super.key});

  @override
  State<ConsultationInboxView> createState() => _ConsultationInboxViewState();
}

final class _ConsultationInboxViewState extends State<ConsultationInboxView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ConsultationViewModel>().loadReceivedRequests();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ConsultationViewModel>();
    final requests = viewModel.receivedRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('받은 협진 요청'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _buildBody(context, viewModel, requests),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('consultationRequest'),
        icon: const Icon(Icons.add),
        label: const Text('새 협진 요청'),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ConsultationViewModel viewModel,
    List<ConsultationRequest> requests,
  ) {
    if (viewModel.isRequestsLoading && requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null && requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 12),
              Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: viewModel.loadReceivedRequests,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.refreshReceivedRequests,
      child: requests.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: const [
                SizedBox(height: 120),
                Icon(Icons.inbox_outlined, size: 72),
                SizedBox(height: 16),
                Text(
                  '받은 협진 요청이 없습니다.',
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _ConsultationRequestCard(
                request: requests[index],
                onTap: () async {
                  final request = await viewModel.markAsReviewing(
                    requests[index].consultationId,
                  );

                  if (!context.mounted) {
                    return;
                  }

                  if (request == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          viewModel.errorMessage ??
                              '협진 검토 상태로 변경하지 못했습니다.',
                        ),
                      ),
                    );
                    return;
                  }

                  context.pushNamed(
                    'consultationDetail',
                    extra: request,
                  );
                },
              ),
            ),
    );
  }
}

final class _ConsultationRequestCard extends StatelessWidget {
  const _ConsultationRequestCard({
    required this.request,
    required this.onTap,
  });

  final ConsultationRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.patientName.isEmpty
                          ? '환자 ${request.patientId}'
                          : request.patientName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusChip(request: request),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.senderName.isEmpty
                    ? '요청 의료진 정보 없음'
                    : '${request.senderName} 의료진 요청',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              if (request.reason.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  request.reason,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (request.createdAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  _dateText(request.createdAt!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _dateText(DateTime date) {
    final local = date.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${local.year}.${twoDigits(local.month)}.${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}

final class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.request});

  final ConsultationRequest request;

  @override
  Widget build(BuildContext context) {
    final isPending = request.isPending;
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(isPending ? '대기' : _statusLabel(request.status)),
      backgroundColor: isPending
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainerHighest,
    );
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'accepted':
        return '수락됨';
      case 'in_progress':
        return '검토중';
      case 'completed':
        return '완료';
      case 'rejected':
        return '거절됨';
      default:
        return status.trim().isEmpty ? '상태 없음' : status;
    }
  }
}
