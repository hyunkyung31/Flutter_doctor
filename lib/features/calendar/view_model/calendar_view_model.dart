import 'package:flutter/material.dart';

import '../widgets/schedule_bottom_sheet.dart';

final class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel() {
    _initializeSchedules();
  }

  DateTime _selectedDate = DateTime.now();

  final List<ScheduleItem> _schedules = [];

  DateTime get selectedDate => _selectedDate;

  List<ScheduleItem> get schedules {
    return List.unmodifiable(_schedules);
  }

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

  void selectDate(DateTime date) {
    _selectedDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    notifyListeners();
  }

  void addSchedule(ScheduleItem schedule) {
    _schedules.add(schedule);
    notifyListeners();
  }

  void removeSchedule(ScheduleItem schedule) {
    _schedules.remove(schedule);
    notifyListeners();
  }

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

  bool _isSameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  void _initializeSchedules() {
    final today = DateTime.now();

    _schedules.addAll([
      ScheduleItem(
        date: DateTime(
          today.year,
          today.month,
          today.day,
        ),
        time: '09:30',
        title: '외래 진료',
        description: '김민수 환자 진료',
      ),
      ScheduleItem(
        date: DateTime(
          today.year,
          today.month,
          today.day,
        ),
        time: '13:00',
        title: '심장내과 협진',
        description: '3층 협진 회의실',
      ),
      ScheduleItem(
        date: DateTime(
          today.year,
          today.month,
          today.day + 1,
        ),
        time: '10:00',
        title: '검사 결과 확인',
        description: '혈관조영 검사 결과 검토',
      ),
      ScheduleItem(
        date: DateTime(
          today.year,
          today.month,
          today.day + 3,
        ),
        time: '14:00',
        title: '학회 일정',
        description: '심혈관 영상 학회',
      ),
    ]);
  }
}