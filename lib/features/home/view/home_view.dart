import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../patient/view_model/patient_list_view_model.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../calendar/widgets/schedule_bottom_sheet.dart';
import '../../settings/view_model/settings_view_model.dart';
import '../widgets/Doctor_briefing_card.dart';
import '../widgets/patient_status_card.dart';
// import '../widgets/recent_patient_section.dart';
// import '../widgets/today_schedule_section.dart';
// import '../widgets/today_todo_section.dart';

final class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

final class _HomeViewState extends State<HomeView> {
  static const String _todoStorageKey = 'doctor_todo_items';

  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _todoItems = [];

  @override
  void initState() {
    super.initState();
    _loadTodoItems();
  }

  Future<void> _loadTodoItems() async {
    final preferences = SharedPreferencesAsync();

    final savedJson = await preferences.getString(_todoStorageKey);

    if (!mounted) {
      return;
    }

    if (savedJson == null || savedJson.isEmpty) {
      setState(() {
        _todoItems = [];
      });
      return;
    }

    try {
      final decodedData = jsonDecode(savedJson) as List<dynamic>;

      final loadedItems = decodedData.map((item) {
        final map = Map<String, dynamic>.from(item as Map);

        return <String, dynamic>{
          'title': map['title']?.toString() ?? '',
          'isCompleted': map['isCompleted'] as bool? ?? false,
        };
      }).toList();

      setState(() {
        _todoItems = loadedItems;
      });
    } catch (_) {
      setState(() {
        _todoItems = [];
      });
    }
  }

  Future<void> _saveTodoItems() async {
    final preferences = SharedPreferencesAsync();

    await preferences.setString(_todoStorageKey, jsonEncode(_todoItems));
  }

  Future<void> _logout(BuildContext context) async {
    final authViewModel = context.read<AuthViewModel>();

    final isSuccess = await authViewModel.logout();

    if (!context.mounted) {
      return;
    }

    if (isSuccess) {
      context.go('/login');
    }
  }

  void _showPreparingMessage(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('현재 준비 중인 기능입니다.')));
  }

  Future<void> _addTodoItem() async {
    String todoTitle = '';

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            '할 일 추가',
            style: TextStyle(
              color: Theme.of(dialogContext).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '할 일을 입력하세요.',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              todoTitle = value.trim();
            },
            onSubmitted: (value) {
              final todo = value.trim();

              if (todo.isNotEmpty) {
                Navigator.of(dialogContext).pop(todo);
              }

              Navigator.of(dialogContext).pop(todo);
            },
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
                if (todoTitle.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(todoTitle);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('추가'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null || result.trim().isEmpty) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) {
      return;
    }

    setState(() {
      _todoItems.add({'title': result.trim(), 'isCompleted': false});
    });

    await _saveTodoItems();
  }

  Future<void> _toggleTodoItem(int index, bool? value) async {
    setState(() {
      _todoItems[index]['isCompleted'] = value ?? false;
    });

    await _saveTodoItems();
  }

  Future<void> _removeTodoItem(int index) async {
    final removedItem = Map<String, dynamic>.from(_todoItems[index]);

    setState(() {
      _todoItems.removeAt(index);
    });

    await _saveTodoItems();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          persist: false,
          content: Text('${removedItem['title']} 항목을 삭제했습니다.'),
          action: SnackBarAction(
            label: '되돌리기',
            onPressed: () async {
              if (!mounted) {
                return;
              }

              final insertIndex = index.clamp(0, _todoItems.length);

              setState(() {
                _todoItems.insert(insertIndex, removedItem);
              });

              await _saveTodoItems();
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    final settingsViewModel = context.watch<SettingsViewModel>();

    final calendarViewModel = context.watch<CalendarViewModel>();

    final patientListViewModel = context.watch<PatientListViewModel>();

    final patientCount = patientListViewModel.patientCount;

    final doctorName = authViewModel.doctorName ?? '의료진';

    // 실제 데이터 ViewModel을 연결하면 아래 값을 변경하면 됨.
    const consultationCount = 0;
    const originalVideoCount = 0;
    const analyzedPatientCount = 0;

    // 예약·대기 환자 역시 실제 데이터 연결 전 임시값.
    const reservationCount = 0;
    const waitingCount = 0;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        title: Text(
          'VENA',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: '채팅',
                onPressed: () {
                  _showPreparingMessage(context);
                },
                icon: const Icon(Icons.chat_bubble_outline),
              ),
              Positioned(
                right: 6,
                top: 5,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: '알림',
                onPressed: () {
                  _showPreparingMessage(context);
                },
                icon: const Icon(Icons.notifications_none),
              ),
              const Positioned(
                right: 10,
                top: 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 8, height: 8),
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: settingsViewModel.isDarkMode ? '라이트 모드로 변경' : '다크 모드로 변경',
            onPressed: settingsViewModel.toggleTheme,
            icon: Icon(
              settingsViewModel.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {},
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              DoctorBriefingCard(
                doctorName: doctorName,
                schedules: calendarViewModel.schedules,
                todoItems: _todoItems,
              ),
              const SizedBox(height: 20),
              PatientStatusSection(
                reservationCount: reservationCount,
                waitingCount: waitingCount,
                onReservationTap: () {
                  _showPreparingMessage(context);
                },
                onWaitingTap: () {
                  _showPreparingMessage(context);
                },
              ),
              const SizedBox(height: 26),
              Text(
                '메인 메뉴',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,

                // 카드 높이를 고정해서 overflow 방지
                mainAxisExtent: 90,

                children: [
                  _QuickMenuCard(
                    title: '환자 목록',
                    icon: Icons.people_alt_outlined,
                    iconColor: AppColors.primary,
                    count: patientCount,
                    unit: '명',
                    onTap: () {
                      context.push('/patient');
                    },
                  ),
                  _QuickMenuCard(
                    title: '협진 요청',
                    icon: Icons.groups_outlined,
                    iconColor: AppColors.secondary,
                    count: consultationCount,
                    unit: '건',
                    onTap: () {
                      context.pushNamed('consultationRequest');
                    },
                  ),
                  _QuickMenuCard(
                    title: '새로운 분석',
                    icon: Icons.video_library_outlined,
                    iconColor: AppColors.primary,
                    count: originalVideoCount,
                    unit: '건',
                    onTap: () {
                      // 추후 ai 분석 요청 화면으로 연결
                      _showPreparingMessage(context);
                    },
                  ),
                  _QuickMenuCard(
                    title: '분석 완료',
                    icon: Icons.analytics_outlined,
                    iconColor: AppColors.secondary,
                    count: analyzedPatientCount,
                    unit: '명',
                    onTap: () {
                      // 추후 분석 완료 화면으로 연결
                      _showPreparingMessage(context);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '캘린더',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      context.pushNamed('calendar');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                    ),
                    icon: const Icon(Icons.calendar_month_outlined, size: 19),
                    label: const Text(
                      '전체보기',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 홈 미니 캘린더
              _HomeCalendar(
                selectedDate: _selectedDate,
                schedules: calendarViewModel.schedules,
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });

                  calendarViewModel.selectDate(date);
                },
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'To-do List',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addTodoItem,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                    ),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('추가'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _TodoListSection(
                todoItems: _todoItems,
                onChanged: _toggleTodoItem,
                onDelete: _removeTodoItem,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: colorScheme.surface,

          // 선택된 메뉴의 둥근 배경
          indicatorColor: colorScheme.primary,

          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            final isSelected = states.contains(WidgetState.selected);

            return IconThemeData(
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface.withValues(alpha: 0.90),
              size: isSelected ? 25 : 23,
            );
          }),

          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            final isSelected = states.contains(WidgetState.selected);

            return TextStyle(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.90),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: 0,
          height: 72,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/home');
                break;

              case 1:
                context.go('/patient');
                break;

              case 2:
                _showPreparingMessage(context);
                break;

              case 3:
                _showPreparingMessage(context);
                break;
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '홈',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: '환자',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.chat_bubble),
              label: '채팅',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '마이페이지',
            ),
          ],
        ),
      ),
    );
  }
}

final class _QuickMenuCard extends StatelessWidget {
  const _QuickMenuCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.unit,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final int count;
  final String unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isDarkMode = theme.brightness == Brightness.dark;

    final effectiveIconColor = isDarkMode
        ? Color.lerp(iconColor, Colors.white, 0.35)!
        : iconColor;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: effectiveIconColor.withValues(
                        alpha: isDarkMode ? 0.20 : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 19, color: effectiveIconColor),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colorScheme.onSurface.withValues(
                      alpha: isDarkMode ? 0.70 : 0.35,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        color: effectiveIconColor,
                        fontSize: 20,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text(
                        unit,
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(
                            alpha: isDarkMode ? 0.85 : 0.68,
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _HomeCalendar extends StatefulWidget {
  const _HomeCalendar({
    required this.selectedDate,
    required this.schedules,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final List<ScheduleItem> schedules;
  final ValueChanged<DateTime> onDateChanged;

  @override
  State<_HomeCalendar> createState() => _HomeCalendarState();
}

final class _HomeCalendarState extends State<_HomeCalendar> {
  late DateTime _focusedDate;

  @override
  void initState() {
    super.initState();
    _focusedDate = widget.selectedDate;
  }

  @override
  void didUpdateWidget(covariant _HomeCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      _focusedDate = widget.selectedDate;
    }
  }

  bool _isSunday(DateTime day) {
    return day.weekday == DateTime.sunday;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
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
        firstDay: DateTime(2020, 1, 1),
        lastDay: DateTime(2035, 12, 31),
        focusedDay: _focusedDate,

        locale: 'ko_KR',

        startingDayOfWeek: StartingDayOfWeek.sunday,

        calendarFormat: CalendarFormat.month,

        availableCalendarFormats: const {CalendarFormat.month: '월'},

        /// 일요일만 주말로 지정
        weekendDays: const [DateTime.sunday],

        selectedDayPredicate: (day) {
          return isSameDay(widget.selectedDate, day);
        },

        eventLoader: (day) {
          final targetDay = DateUtils.dateOnly(day);

          return widget.schedules.where((schedule) {
            final startDay = DateUtils.dateOnly(schedule.date);

            final endDay = DateUtils.dateOnly(schedule.endDate);

            return !targetDay.isBefore(startDay) && !targetDay.isAfter(endDay);
          }).toList();
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _focusedDate = focusedDay;
          });

          widget.onDateChanged(selectedDay);
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDate = focusedDay;
          });
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          headerPadding: const EdgeInsets.symmetric(vertical: 10),
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w700,
          ),
        ),
        calendarBuilders: CalendarBuilders<ScheduleItem>(
          defaultBuilder: (context, day, focusedDay) {
            final isSunday = _isSunday(day);

            return Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isSunday ? Colors.red : colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
          outsideBuilder: (context, day, focusedDay) {
            final isSunday = _isSunday(day);

            return Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isSunday
                      ? Colors.red.withValues(alpha: 0.3)
                      : colorScheme.onSurface.withValues(alpha: 0.25),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            return Center(
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
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
          todayBuilder: (context, day, focusedDay) {
            final isSunday = _isSunday(day);

            return Center(
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary, width: 1.5),
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isSunday ? Colors.red : AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: true,
          markersMaxCount: 3,
          markerSize: 6,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1.5),
          markerDecoration: const BoxDecoration(
            color: Color(0xFFF0B52D),
            shape: BoxShape.circle,
          ),
          defaultTextStyle: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          weekendTextStyle: const TextStyle(
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
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
          cellMargin: const EdgeInsets.all(4),
        ),
      ),
    );
  }
}

final class _TodoListSection extends StatelessWidget {
  const _TodoListSection({
    required this.todoItems,
    required this.onChanged,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> todoItems;

  final void Function(int index, bool? value) onChanged;

  final void Function(int index) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (todoItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.checklist_outlined,
                color: AppColors.accent,
                size: 30,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              '등록된 할 일이 없습니다.',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: todoItems.length,
        separatorBuilder: (context, index) {
          return Divider(
            height: 1,
            indent: 56,
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          );
        },
        itemBuilder: (context, index) {
          final item = todoItems[index];

          final title = item['title'] as String;

          final isCompleted = item['isCompleted'] as bool;

          return Dismissible(
            key: ValueKey('$title-$index'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              onDelete(index);
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 22),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            child: CheckboxListTile(
              value: isCompleted,
              onChanged: (value) {
                onChanged(index, value);
              },
              activeColor: AppColors.accent,
              checkColor: Colors.white,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.only(left: 10, right: 8),
              title: Text(
                title,
                style: TextStyle(
                  color: isCompleted
                      ? colorScheme.onSurface.withValues(alpha: 0.45)
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  decoration: isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              secondary: IconButton(
                onPressed: () {
                  onDelete(index);
                },
                tooltip: '삭제',
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
