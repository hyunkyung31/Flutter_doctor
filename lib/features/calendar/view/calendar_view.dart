import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/calendar_view_model.dart';
import '../widgets/monthly_calendar.dart';
import '../widgets/schedule_bottom_sheet.dart';

final class CalendarView extends StatefulWidget {
  const CalendarView({
    super.key,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

final class _CalendarViewState extends State<CalendarView> {
  /// false: 축소형 달력 + 선택 날짜 일정
  /// true: 확장형 달력 + 날짜별 일정 표시
  bool _isCalendarExpanded = false;

  /// 세로 드래그 누적 거리
  double _verticalDragDistance = 0;

  /// 손가락을 움직이는 동안 세로 이동 거리 누적
  void _handleVerticalDragUpdate(
    DragUpdateDetails details,
  ) {
    _verticalDragDistance += details.delta.dy;
  }

  /// 손가락을 뗐을 때 달력 확장 또는 축소
  void _handleVerticalDragEnd(
    DragEndDetails details,
  ) {
    const dragThreshold = 40.0;

    /// 아래로 드래그하면 달력 확장
    if (_verticalDragDistance > dragThreshold &&
        !_isCalendarExpanded) {
      setState(() {
        _isCalendarExpanded = true;
      });
    }

    /// 위로 드래그하면 달력 축소
    if (_verticalDragDistance < -dragThreshold &&
        _isCalendarExpanded) {
      setState(() {
        _isCalendarExpanded = false;
      });
    }

    _verticalDragDistance = 0;
  }

  /// 드래그가 취소된 경우 거리 초기화
  void _handleVerticalDragCancel() {
    _verticalDragDistance = 0;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CalendarViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,

      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,

        /// 왼쪽 닫기 버튼
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).maybePop();
          },
          icon: const Icon(
            Icons.close,
          ),
        ),

        /// 현재 선택된 날짜의 월
        title: Text(
          '${viewModel.selectedDate.month}월',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              /// 일정 목록 화면 연결 예정
            },
            icon: const Icon(
              Icons.calendar_view_month_outlined,
            ),
          ),
          IconButton(
            onPressed: () {
              /// 알림 화면 연결 예정
            },
            icon: const Icon(
              Icons.notifications_none,
            ),
          ),
          IconButton(
            onPressed: () {
              /// 메뉴 화면 연결 예정
            },
            icon: const Icon(
              Icons.menu,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            /// 확장 상태에서는 달력 전체가 화면 안에서 스크롤 가능
            if (_isCalendarExpanded)
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: _CalendarDragArea(
                    selectedDate: viewModel.selectedDate,
                    schedules: viewModel.schedules,
                    isExpanded: true,
                    onDateChanged: viewModel.selectDate,
                    onVerticalDragUpdate:
                        _handleVerticalDragUpdate,
                    onVerticalDragEnd:
                        _handleVerticalDragEnd,
                    onVerticalDragCancel:
                        _handleVerticalDragCancel,
                  ),
                ),
              ),

            /// 축소 상태에서는 달력 아래에 선택 날짜 일정 표시
            if (!_isCalendarExpanded) ...[
              _CalendarDragArea(
                selectedDate: viewModel.selectedDate,
                schedules: viewModel.schedules,
                isExpanded: false,
                onDateChanged: viewModel.selectDate,
                onVerticalDragUpdate:
                    _handleVerticalDragUpdate,
                onVerticalDragEnd:
                    _handleVerticalDragEnd,
                onVerticalDragCancel:
                    _handleVerticalDragCancel,
              ),

              Expanded(
                child: ScheduleBottomSheet(
                  selectedDate: viewModel.selectedDate,
                  schedules: viewModel.selectedSchedules,
                ),
              ),
            ],
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          /// 일정 등록 화면 연결 예정
        },
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}

/// 달력과 드래그 손잡이를 묶은 영역
final class _CalendarDragArea extends StatelessWidget {
  const _CalendarDragArea({
    required this.selectedDate,
    required this.schedules,
    required this.isExpanded,
    required this.onDateChanged,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.onVerticalDragCancel,
  });

  final DateTime selectedDate;
  final List<ScheduleItem> schedules;
  final bool isExpanded;

  final ValueChanged<DateTime> onDateChanged;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final GestureDragCancelCallback onVerticalDragCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      onVerticalDragCancel: onVerticalDragCancel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(
              milliseconds: 250,
            ),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              child: MonthlyCalendar(
                selectedDate: selectedDate,
                onDateChanged: onDateChanged,
                schedules: schedules,
                isExpanded: isExpanded,
              ),
            ),
          ),

          /// 위아래 드래그 손잡이
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(
                  alpha: 0.22,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}