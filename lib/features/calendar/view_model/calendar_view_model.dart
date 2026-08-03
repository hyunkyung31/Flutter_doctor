import 'package:flutter/material.dart';

import '../widgets/schedule_bottom_sheet.dart';

final class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel();

  /// 현재 선택된 날짜
  DateTime _selectedDate = DateTime.now();

  /// 사용자가 추가한 일정만 저장
  final List<ScheduleItem> _schedules = [];

  /// 현재 선택된 날짜
  DateTime get selectedDate => _selectedDate;

  /// 전체 일정 목록
  List<ScheduleItem> get schedules {
    return List.unmodifiable(_schedules);
  }

  /// 선택한 날짜의 일정만 반환
  List<ScheduleItem> get selectedSchedules {
    final result = _schedules.where((schedule) {
      return _isSameDate(
        schedule.date,
        _selectedDate,
      );
    }).toList();

    result.sort((first, second) {
      return first.time.compareTo(second.time);
    });

    return result;
  }

  /// 날짜 선택
  void selectDate(DateTime date) {
    _selectedDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    notifyListeners();
  }

  /// 일정 추가
  void addSchedule(ScheduleItem schedule) {
    _schedules.add(schedule);

    notifyListeners();
  }

  /// 일정 삭제
  void removeSchedule(ScheduleItem schedule) {
    _schedules.remove(schedule);

    notifyListeners();
  }

  /// 선택 날짜의 일정 삭제
  void removeScheduleAt(int index) {
    final selectedDateSchedules = selectedSchedules;

    if (index < 0 || index >= selectedDateSchedules.length) {
      return;
    }

    final schedule = selectedDateSchedules[index];

    _schedules.remove(schedule);

    notifyListeners();
  }

  /// 일정 수정
  void updateSchedule({
    required ScheduleItem oldSchedule,
    required ScheduleItem newSchedule,
  }) {
    final index = _schedules.indexOf(oldSchedule);

    if (index == -1) {
      return;
    }

    _schedules[index] = newSchedule;

    notifyListeners();
  }

  /// 같은 날짜인지 확인
  bool _isSameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}