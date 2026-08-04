import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/calendar_view_model.dart';
import '../widgets/monthly_calendar.dart';
import '../widgets/schedule_bottom_sheet.dart';

final class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

final class _CalendarViewState extends State<CalendarView> {
  /// false: 축소형 달력 + 선택 날짜 일정
  /// true: 확장형 달력 + 날짜별 일정 표시
  bool _isCalendarExpanded = false;

  /// 세로 드래그 누적 거리
  double _verticalDragDistance = 0;

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    _verticalDragDistance += details.delta.dy;
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    const dragThreshold = 40.0;

    if (_verticalDragDistance > dragThreshold && !_isCalendarExpanded) {
      setState(() {
        _isCalendarExpanded = true;
      });
    }

    if (_verticalDragDistance < -dragThreshold && _isCalendarExpanded) {
      setState(() {
        _isCalendarExpanded = false;
      });
    }

    _verticalDragDistance = 0;
  }

  void _handleVerticalDragCancel() {
    _verticalDragDistance = 0;
  }

  /// HH:mm 문자열을 TimeOfDay로 변환
  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');

    if (parts.length != 2) {
      return TimeOfDay.now();
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return TimeOfDay.now();
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  /// TimeOfDay를 HH:mm 문자열로 변환
  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateRange(DateTimeRange range) {
    final start =
        '${range.start.year}년'
        '${range.start.month}월'
        '${range.start.day}일';

    final end =
        '${range.end.year}년'
        '${range.end.month}월'
        '${range.end.day}일';

    if (DateUtils.isSameDay(range.start, range.end)) {
      return start;
    }
    return '$start ~ $end';
  }

  /// 일정 추가
  Future<void> _showAddScheduleDialog() async {
    final calendarViewModel = context.read<CalendarViewModel>();

    final selectedDate = calendarViewModel.selectedDate;

    String title = '';
    String description = '';

    DateTimeRange selectedDateRange = DateTimeRange(
      start: selectedDate,
      end: selectedDate,
    );

    TimeOfDay selectedTime = TimeOfDay.now();

    final result = await showDialog<ScheduleItem>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('일정 추가'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: '일정 제목',
                        hintText: '일정 제목을 입력하세요.',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        title = value.trim();
                      },
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '일정 내용',
                        hintText: '내용을 입력하세요.',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        description = value.trim();
                      },
                    ),

                    const SizedBox(height: 12),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.date_range_outlined),
                      title: const Text('일정 기간'),
                      subtitle: Text(_formatDateRange(selectedDateRange)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final pickedRange = await showDateRangePicker(
                          context: dialogContext,
                          initialDateRange: selectedDateRange,
                          firstDate: DateTime(2000, 1, 1),
                          lastDate: DateTime(2060, 12, 31),
                          helpText: '일정 기간 선택',
                          cancelText: '취소',
                          confirmText: '선택',
                          saveText: '선택',
                          fieldStartLabelText: '시작일',
                          fieldEndLabelText: '종료일',
                        );

                        if (pickedRange == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedDateRange = pickedRange;
                        });
                      },
                    ),

                    const SizedBox(height: 4),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('시간'),
                      subtitle: Text(_formatTime(selectedTime)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedTime,
                        );

                        if (pickedTime == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedTime = pickedTime;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('일정 제목을 입력하세요.')),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      ScheduleItem(
                        date: selectedDateRange.start,
                        endDate: selectedDateRange.end,
                        time: _formatTime(selectedTime),
                        title: title,
                        description: description.isEmpty ? null : description,
                      ),
                    );
                  },
                  child: const Text('추가'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) {
      return;
    }

    calendarViewModel.addSchedule(result);
  }

  /// 일정 수정
  Future<void> _showEditScheduleDialog(ScheduleItem oldSchedule) async {
    final calendarViewModel = context.read<CalendarViewModel>();

    String title = oldSchedule.title;
    String description = oldSchedule.description ?? '';

    TimeOfDay selectedTime = _parseTime(oldSchedule.time);

    final result = await showDialog<ScheduleItem>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('일정 수정'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: oldSchedule.title,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: '일정 제목',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        title = value.trim();
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: oldSchedule.description ?? '',
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '일정 내용',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        description = value.trim();
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('시간'),
                      subtitle: Text(_formatTime(selectedTime)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedTime,
                        );

                        if (pickedTime == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedTime = pickedTime;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('일정 제목을 입력하세요.')),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      ScheduleItem(
                        date: oldSchedule.date,
                        endDate: oldSchedule.endDate,
                        time: _formatTime(selectedTime),
                        title: title,
                        description: description.isEmpty ? null : description,
                      ),
                    );
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) {
      return;
    }

    calendarViewModel.updateSchedule(
      oldSchedule: oldSchedule,
      newSchedule: result,
    );
  }

  /// 일정 삭제
  Future<void> _deleteSchedule(ScheduleItem schedule) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('일정 삭제'),
          content: Text('"${schedule.title}" 일정을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) {
      return;
    }

    context.read<CalendarViewModel>().removeSchedule(schedule);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CalendarViewModel>();

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).maybePop();
          },
          icon: const Icon(Icons.close),
        ),
        title: Text(
          '${viewModel.selectedDate.month}월',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              /// 일정 목록 화면 연결 예정
            },
            icon: const Icon(Icons.calendar_view_month_outlined),
          ),
          IconButton(
            onPressed: () {
              /// 알림 화면 연결 예정
            },
            icon: const Icon(Icons.notifications_none),
          ),
          IconButton(
            onPressed: () {
              /// 메뉴 화면 연결 예정
            },
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isCalendarExpanded)
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: _CalendarDragArea(
                    selectedDate: viewModel.selectedDate,
                    schedules: viewModel.schedules,
                    isExpanded: true,
                    onDateChanged: viewModel.selectDate,
                    onVerticalDragUpdate: _handleVerticalDragUpdate,
                    onVerticalDragEnd: _handleVerticalDragEnd,
                    onVerticalDragCancel: _handleVerticalDragCancel,
                  ),
                ),
              ),
            if (!_isCalendarExpanded) ...[
              _CalendarDragArea(
                selectedDate: viewModel.selectedDate,
                schedules: viewModel.schedules,
                isExpanded: false,
                onDateChanged: viewModel.selectDate,
                onVerticalDragUpdate: _handleVerticalDragUpdate,
                onVerticalDragEnd: _handleVerticalDragEnd,
                onVerticalDragCancel: _handleVerticalDragCancel,
              ),
              Expanded(
                child: ScheduleBottomSheet(
                  selectedDate: viewModel.selectedDate,
                  schedules: viewModel.selectedSchedules,
                  onEdit: _showEditScheduleDialog,
                  onDelete: _deleteSchedule,
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

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
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: MonthlyCalendar(
                selectedDate: selectedDate,
                onDateChanged: onDateChanged,
                schedules: schedules,
                isExpanded: isExpanded,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
