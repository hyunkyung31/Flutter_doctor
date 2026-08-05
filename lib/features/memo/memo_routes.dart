import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../patient/model/patient.dart';
import 'model/patient_memo.dart';
import 'view/memo_detail_view.dart';
import 'view/memo_form_view.dart';
import 'view/memo_list_view.dart';

final List<RouteBase> memoRoutes = [
  GoRoute(
    path: '/patient/:patientId/memos',
    name: 'memoList',
    builder: (context, state) {
      final patient = state.extra;

      if (patient is! Patient) {
        return const _MemoRouteErrorView(
          message: '환자 정보가 없어 메모 목록을 열 수 없습니다.',
        );
      }

      return MemoListView(
        patient: patient,
      );
    },
  ),

  GoRoute(
    path: '/patient/:patientId/memos/new',
    name: 'memoCreate',
    builder: (context, state) {
      final patient = state.extra;

      if (patient is! Patient) {
        return const _MemoRouteErrorView(
          message: '환자 정보가 없어 메모를 작성할 수 없습니다.',
        );
      }

      return MemoFormView(
        patient: patient,
      );
    },
  ),

  GoRoute(
    path: '/memos/:memoId',
    name: 'memoDetail',
    builder: (context, state) {
      final extra = state.extra;

      if (extra is! Map<String, dynamic>) {
        return const _MemoRouteErrorView(
          message: '메모 정보를 찾을 수 없습니다.',
        );
      }

      final patient = extra['patient'];
      final memo = extra['memo'];

      if (patient is! Patient || memo is! PatientMemo) {
        return const _MemoRouteErrorView(
          message: '메모 상세 정보가 올바르지 않습니다.',
        );
      }

      return MemoDetailView(
        patient: patient,
        memo: memo,
      );
    },
  ),

  GoRoute(
    path: '/memos/:memoId/edit',
    name: 'memoEdit',
    builder: (context, state) {
      final extra = state.extra;

      if (extra is! Map<String, dynamic>) {
        return const _MemoRouteErrorView(
          message: '수정할 메모 정보를 찾을 수 없습니다.',
        );
      }

      final patient = extra['patient'];
      final memo = extra['memo'];

      if (patient is! Patient || memo is! PatientMemo) {
        return const _MemoRouteErrorView(
          message: '수정할 메모 정보가 올바르지 않습니다.',
        );
      }

      return MemoFormView(
        patient: patient,
        memo: memo,
      );
    },
  ),
];

final class _MemoRouteErrorView extends StatelessWidget {
  const _MemoRouteErrorView({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('메모'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}