import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'view/emr_sign_off_list_view.dart';
import 'model/emr_sign_off_workflow_item.dart';
import 'view/emr_sign_off_detail_view.dart';

final List<RouteBase> clinicalReportRoutes = [
  GoRoute(
    path: '/clinical-report/sign-offs',
    name: 'emrSignOffList',
    builder: (context, state) {
      return const EmrSignOffListView();
    },
  ),

  GoRoute(
    path: '/clinical-report/sign-offs/detail',
    name: 'emrSignOffDetail',
    builder: (context, state) {
      final extra = state.extra;

      if (extra is! EmrSignOffWorkflowItem) {
        return const Scaffold(
          body: Center(child: Text('SIGN OFF 상세 정보가 없습니다.')),
        );
      }

      return EmrSignOffDetailView(item: extra);
    },
  ),
];
