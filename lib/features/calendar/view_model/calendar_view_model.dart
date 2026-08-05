import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/schedule_bottom_sheet.dart';

final class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel() {
    unawaited(_loadSchedules());
  }

  static const String _scheduleStorageKey = 'doctor_calendar_schedules';

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
      final selectedDay = DateUtils.dateOnly(_selectedDate);
      final startDay = DateUtils.dateOnly(schedule.date);
      final endDay = DateUtils.dateOnly(schedule.endDate);

      return !selectedDay.isBefore(startDay) &&
          !selectedDay.isAfter(endDay);
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
    unawaited(_saveSchedules());
  }

  /// 일정 삭제
  void removeSchedule(ScheduleItem schedule) {
    _schedules.remove(schedule);

    notifyListeners();
    unawaited(_saveSchedules());
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
    unawaited(_saveSchedules());
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
    unawaited(_saveSchedules());
  }

  Future<void> _loadSchedules() async {
    try {
      final preferences = SharedPreferencesAsync();
      final savedJson = await preferences.getString(_scheduleStorageKey);

      if (savedJson == null || savedJson.trim().isEmpty) {
        return;
      }

      final decoded = jsonDecode(savedJson);
      if (decoded is! List) {
        return;
      }

      final loadedSchedules = <ScheduleItem>[];
      for (final item in decoded) {
        if (item is! Map) continue;

        try {
          loadedSchedules.add(
            ScheduleItem.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (_) {
          // 손상된 일정 하나만 제외하고 나머지는 정상적으로 복원한다.
        }
      }

      _schedules
        ..clear()
        ..addAll(loadedSchedules);
      notifyListeners();
    } catch (_) {
      // 로컬 저장소를 읽지 못해도 빈 일정으로 앱을 계속 사용할 수 있다.
    }
  }

  Future<void> _saveSchedules() async {
    try {
      final preferences = SharedPreferencesAsync();
      final encoded = jsonEncode(
        _schedules.map((schedule) => schedule.toJson()).toList(),
      );
      await preferences.setString(_scheduleStorageKey, encoded);
    } catch (_) {
      // 저장 실패가 화면 동작을 중단시키지 않도록 한다.
    }
  }
}
