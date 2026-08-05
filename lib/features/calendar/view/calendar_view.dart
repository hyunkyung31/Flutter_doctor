import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/calendar_view_model.dart';
import '../widgets/monthly_calendar.dart';
import '../widgets/schedule_bottom_sheet.dart';

const List<Color> _scheduleColors = [
  Color(0xFF24459A),
  Color(0xFF2E8B57),
  Color(0xFF7E57C2),
  Color(0xFFF39C12),
  Color(0xFFE74C3C),
  Color(0xFF78909C),
];

enum _CalendarPanelMode {
  calendarExpanded,
  balanced,
  scheduleExpanded,
}

final class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

final class _CalendarViewState extends State<CalendarView> {
  _CalendarPanelMode _panelMode = _CalendarPanelMode.balanced;

  /// 세로 드래그 누적 거리
  double _verticalDragDistance = 0;

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    _verticalDragDistance += details.delta.dy;
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    const dragThreshold = 40.0;

    if (_verticalDragDistance > dragThreshold) {
      setState(() {
        _panelMode = switch (_panelMode) {
          _CalendarPanelMode.scheduleExpanded => _CalendarPanelMode.balanced,
          _ => _CalendarPanelMode.calendarExpanded,
        };
      });
    } else if (_verticalDragDistance < -dragThreshold) {
      setState(() {
        _panelMode = switch (_panelMode) {
          _CalendarPanelMode.calendarExpanded => _CalendarPanelMode.balanced,
          _ => _CalendarPanelMode.scheduleExpanded,
        };
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
    Color selectedColor = _scheduleColors.first;

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
                    const SizedBox(height: 12),
                    _ScheduleColorPicker(
                      selectedColor: selectedColor,
                      onSelected: (color) {
                        setDialogState(() => selectedColor = color);
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
                        color: selectedColor,
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
    Color selectedColor = oldSchedule.color;

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
                    const SizedBox(height: 12),
                    _ScheduleColorPicker(
                      selectedColor: selectedColor,
                      onSelected: (color) {
                        setDialogState(() => selectedColor = color);
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
                        color: selectedColor,
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
            if (_panelMode == _CalendarPanelMode.calendarExpanded)
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
            if (_panelMode == _CalendarPanelMode.balanced) ...[
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
                  onVerticalDragUpdate: _handleVerticalDragUpdate,
                  onVerticalDragEnd: _handleVerticalDragEnd,
                  onVerticalDragCancel: _handleVerticalDragCancel,
                ),
              ),
            ],
            if (_panelMode == _CalendarPanelMode.scheduleExpanded)
              Expanded(
                child: ScheduleBottomSheet(
                  selectedDate: viewModel.selectedDate,
                  schedules: viewModel.selectedSchedules,
                  onEdit: _showEditScheduleDialog,
                  onDelete: _deleteSchedule,
                  onVerticalDragUpdate: _handleVerticalDragUpdate,
                  onVerticalDragEnd: _handleVerticalDragEnd,
                  onVerticalDragCancel: _handleVerticalDragCancel,
                ),
              ),
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

final class _ScheduleColorPicker extends StatelessWidget {
  const _ScheduleColorPicker({
    required this.selectedColor,
    required this.onSelected,
  });

  final Color selectedColor;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '일정 색상',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: _scheduleColors.map((color) {
            final isSelected = selectedColor == color;

            return Tooltip(
              message: _colorName(color),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => onSelected(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  String _colorName(Color color) {
    final index = _scheduleColors.indexOf(color);
    const names = ['파랑', '초록', '보라', '주황', '빨강', '회색'];
    return index >= 0 ? names[index] : '일정 색상';
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
        ],
      ),
    );
  }
}
