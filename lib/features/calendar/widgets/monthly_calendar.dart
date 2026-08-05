import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_colors.dart';
import 'schedule_bottom_sheet.dart';

final class MonthlyCalendar extends StatefulWidget {
  const MonthlyCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.schedules,
    required this.isExpanded,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  /// 전체 일정 목록
  final List<ScheduleItem> schedules;

  /// false: 축소형 달력
  /// true: 확장형 달력
  final bool isExpanded;

  @override
  State<MonthlyCalendar> createState() => _MonthlyCalendarState();
}

final class _MonthlyCalendarState extends State<MonthlyCalendar> {
  late DateTime _focusedDate;

  /// 화면 확인용 임시 공휴일
  final Set<DateTime> _holidays = {
    DateTime(2026, 1, 1),
    DateTime(2026, 3, 1),
    DateTime(2026, 5, 5),
    DateTime(2026, 6, 6),
    DateTime(2026, 8, 15),
    DateTime(2026, 10, 3),
    DateTime(2026, 10, 9),
    DateTime(2026, 12, 25),
  };

  @override
  void initState() {
    super.initState();
    _focusedDate = widget.selectedDate;
  }

  @override
  void didUpdateWidget(covariant MonthlyCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      _focusedDate = widget.selectedDate;
    }
  }

  /// 일요일인지 확인
  bool _isSunday(DateTime day) {
    return day.weekday == DateTime.sunday;
  }

  /// 공휴일인지 확인
  bool _isHoliday(DateTime day) {
    return _holidays.any((holiday) => isSameDay(holiday, day));
  }

  /// 해당 날짜의 일정 반환
  List<ScheduleItem> _getSchedulesForDay(DateTime day) {
    final targetDay = DateUtils.dateOnly(day);

    final schedules = widget.schedules.where((schedule) {
      final startDay = DateUtils.dateOnly(schedule.date);

      final endDay = DateUtils.dateOnly(schedule.endDate);

      return !targetDay.isBefore(startDay) && !targetDay.isAfter(endDay);
    }).toList();

    schedules.sort((first, second) {
      return first.time.compareTo(second.time);
    });
    return schedules;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar<ScheduleItem>(
        /// 선택 가능한 날짜 범위
        firstDay: DateTime(2020, 1, 1),
        lastDay: DateTime(2035, 12, 31),

        /// 현재 보고 있는 월
        focusedDay: _focusedDate,

        /// 확장 여부에 따른 날짜 행 높이
        rowHeight: widget.isExpanded ? 92 : 54,

        /// 요일 영역 높이
        daysOfWeekHeight: 38,

        /// 한글 표시
        locale: 'ko_KR',

        /// 일요일부터 시작
        startingDayOfWeek: StartingDayOfWeek.sunday,

        /// 월간 달력 고정
        calendarFormat: CalendarFormat.month,

        /// 좌우 월 이동만 캘린더가 처리하고 세로 제스처는 부모에 전달
        availableGestures: AvailableGestures.horizontalSwipe,

        availableCalendarFormats: const {CalendarFormat.month: '월'},

        /// 일요일만 주말로 지정
        weekendDays: const [DateTime.sunday],

        /// 공휴일 확인
        holidayPredicate: _isHoliday,

        /// 날짜별 일정 연결
        eventLoader: _getSchedulesForDay,

        /// 선택 날짜 확인
        selectedDayPredicate: (day) {
          return isSameDay(widget.selectedDate, day);
        },

        /// 날짜 선택
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _focusedDate = focusedDay;
          });

          widget.onDateChanged(selectedDay);
        },

        /// 좌우로 월 이동
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDate = focusedDay;
          });
        },

        /// 상단 연도·월 영역
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          headerPadding: const EdgeInsets.symmetric(vertical: 12),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: colorScheme.onSurface,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: colorScheme.onSurface,
          ),
          titleTextStyle: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        /// 요일 글자 스타일
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w700,
          ),
        ),

        /// 날짜 셀과 일정 표시
        calendarBuilders: CalendarBuilders<ScheduleItem>(
          /// 현재 월 일반 날짜
          defaultBuilder: (context, day, focusedDay) {
            final isRedDay = _isSunday(day) || _isHoliday(day);

            return Align(
              alignment: widget.isExpanded
                  ? Alignment.topCenter
                  : Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(top: widget.isExpanded ? 8 : 0),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isRedDay ? Colors.red : colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },

          /// 앞달·다음 달 날짜
          outsideBuilder: (context, day, focusedDay) {
            final isRedDay = _isSunday(day) || _isHoliday(day);

            return Align(
              alignment: widget.isExpanded
                  ? Alignment.topCenter
                  : Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(top: widget.isExpanded ? 8 : 0),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isRedDay
                        ? Colors.red.withValues(alpha: 0.3)
                        : colorScheme.onSurface.withValues(alpha: 0.25),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },

          /// 선택된 날짜
          selectedBuilder: (context, day, focusedDay) {
            return Align(
              alignment: widget.isExpanded
                  ? Alignment.topCenter
                  : Alignment.center,
              child: Container(
                width: 38,
                height: 38,
                margin: EdgeInsets.only(top: widget.isExpanded ? 2 : 0),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },

          /// 오늘 날짜
          todayBuilder: (context, day, focusedDay) {
            final isRedDay = _isSunday(day) || _isHoliday(day);

            return Align(
              alignment: widget.isExpanded
                  ? Alignment.topCenter
                  : Alignment.center,
              child: Container(
                width: 38,
                height: 38,
                margin: EdgeInsets.only(top: widget.isExpanded ? 2 : 0),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isRedDay ? Colors.red : AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },

          /// 일정 표시
          markerBuilder: (context, day, events) {
            if (events.isEmpty) {
              return null;
            }

            final schedule = events.first;
            final isSingleDay = isSameDay(schedule.date, schedule.endDate);
            final startsSegment = isSameDay(day, schedule.date) ||
                day.weekday == DateTime.sunday;
            final endsSegment = isSameDay(day, schedule.endDate) ||
                day.weekday == DateTime.saturday;

            /// 한 날짜 일정은 점, 연속 일정은 가로선으로 표시
            if (!widget.isExpanded) {
              return Positioned(
                left: 0,
                right: 0,
                bottom: 4,
                height: 6,
                child: isSingleDay
                    ? Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: schedule.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : Container(
                        margin: EdgeInsets.only(
                          left: startsSegment ? 10 : 0,
                          right: endsSegment ? 10 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: schedule.color,
                          borderRadius: BorderRadius.horizontal(
                            left: startsSegment
                                ? const Radius.circular(4)
                                : Radius.zero,
                            right: endsSegment
                                ? const Radius.circular(4)
                                : Radius.zero,
                          ),
                        ),
                      ),
              );
            }

            /// 확장형에서도 연속 일정의 셀 경계를 연결
            return Positioned(
              left: isSingleDay || startsSegment ? 3 : 0,
              right: isSingleDay || endsSegment ? 3 : 0,
              bottom: 7,
              child: Container(
                height: 24,
                padding: EdgeInsets.symmetric(
                  horizontal: startsSegment || isSingleDay ? 5 : 0,
                ),
                decoration: BoxDecoration(
                  color: schedule.color,
                  borderRadius: BorderRadius.horizontal(
                    left: isSingleDay || startsSegment
                        ? const Radius.circular(4)
                        : Radius.zero,
                    right: isSingleDay || endsSegment
                        ? const Radius.circular(4)
                        : Radius.zero,
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  isSingleDay || startsSegment
                      ? events.length > 1
                          ? '${schedule.title} 외 ${events.length - 1}개'
                          : schedule.title
                      : '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),

        /// 기본 스타일
        calendarStyle: CalendarStyle(
          outsideDaysVisible: true,

          defaultTextStyle: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),

          weekendTextStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),

          holidayTextStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),

          outsideTextStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.25),
          ),

          selectedDecoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),

          selectedTextStyle: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),

          todayDecoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.secondary, width: 1.5),
          ),

          todayTextStyle: const TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),

          cellMargin: const EdgeInsets.all(4),
          markersMaxCount: 1,
        ),
      ),
    );
  }
}
