import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../settings/view_model/settings_view_model.dart';
import '../widgets/patient_status_card.dart';
import '../widgets/recent_patient_section.dart';
import '../widgets/today_schedule_section.dart';
import '../widgets/today_todo_section.dart';
import '../widgets/welcome_card.dart';

final class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

final class _HomeViewState extends State<HomeView> {
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _todoItems = [
    {
      'title': 'AI 분석 결과 확인',
      'isCompleted': false,
    },
    {
      'title': '담당 환자 진료 기록 검토',
      'isCompleted': false,
    },
    {
      'title': '협진 요청 답변',
      'isCompleted': false,
    },
  ];

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('현재 준비 중인 기능입니다.'),
      ),
    );
  }

  Future<void> _addTodoItem() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            '할 일 추가',
            style: TextStyle(
              color: Theme.of(
                dialogContext,
              ).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '할 일을 입력하세요.',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              final todo = value.trim();

              if (todo.isNotEmpty) {
                Navigator.of(
                  dialogContext,
                ).pop(todo);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final todo = controller.text.trim();

                if (todo.isNotEmpty) {
                  Navigator.of(
                    dialogContext,
                  ).pop(todo);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('추가'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted ||
        result == null ||
        result.trim().isEmpty) {
      return;
    }

    setState(() {
      _todoItems.add({
        'title': result.trim(),
        'isCompleted': false,
      });
    });
  }

  void _toggleTodoItem(
    int index,
    bool? value,
  ) {
    setState(() {
      _todoItems[index]['isCompleted'] =
          value ?? false;
    });
  }

  void _removeTodoItem(int index) {
    final removedItem =
        Map<String, dynamic>.from(
          _todoItems[index],
        );

    setState(() {
      _todoItems.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${removedItem['title']} 항목을 삭제했습니다.',
        ),
        action: SnackBarAction(
          label: '되돌리기',
          onPressed: () {
            setState(() {
              _todoItems.insert(
                index,
                removedItem,
              );
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel =
        context.watch<AuthViewModel>();

    final settingsViewModel =
        context.watch<SettingsViewModel>();

    final doctorName =
        authViewModel.doctorName ?? '의료진';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,

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
          // 채팅
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: '채팅',
                onPressed: () {
                  _showPreparingMessage(
                    context,
                  );
                },
                icon: const Icon(
                  Icons.chat_bubble_outline,
                ),
              ),
              Positioned(
                right: 6,
                top: 5,
                child: Container(
                  constraints:
                      const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                  padding:
                      const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                  alignment: Alignment.center,
                  decoration:
                      const BoxDecoration(
                        color:
                            AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 일반 알림
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: '알림',
                onPressed: () {
                  _showPreparingMessage(
                    context,
                  );
                },
                icon: const Icon(
                  Icons.notifications_none,
                ),
              ),
              const Positioned(
                right: 10,
                top: 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 8,
                    height: 8,
                  ),
                ),
              ),
            ],
          ),

          // 라이트 모드 / 다크 모드
          IconButton(
            tooltip:
                settingsViewModel.isDarkMode
                    ? '라이트 모드로 변경'
                    : '다크 모드로 변경',
            onPressed:
                settingsViewModel.toggleTheme,
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
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              WelcomeCard(
                doctorName: doctorName,
              ),

              const SizedBox(height: 20),

              PatientStatusSection(
                reservationCount: 0,
                waitingCount: 0,
                onReservationTap: () {
                  _showPreparingMessage(
                    context,
                  );
                },
                onWaitingTap: () {
                  _showPreparingMessage(
                    context,
                  );
                },
              ),

              const SizedBox(height: 26),

              Text(
                '메인 메뉴',
                style:
                    textTheme.titleLarge?.copyWith(
                      color:
                          colorScheme.onSurface,
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
                children: [
                  _QuickMenuCard(
                    title: '환자 목록\n주의 환자',
                    description:
                        '담당 환자와 주의 환자를 확인합니다.',
                    icon:
                        Icons.people_alt_outlined,
                    iconColor:
                        AppColors.primary,
                    onTap: () {
                      context.push('/patient');
                    },
                  ),
                  _QuickMenuCard(
                    title: '새로운 분석',
                    description:
                        '새로운 AI 분석을 요청합니다.',
                    icon:
                        Icons.add_chart_outlined,
                    iconColor:
                        AppColors.secondary,
                    onTap: () {
                      _showPreparingMessage(
                        context,
                      );
                    },
                  ),
                  _QuickMenuCard(
                    title: '원본 영상 확인',
                    description:
                        '혈관조영 원본 영상을 확인합니다.',
                    icon:
                        Icons.video_library_outlined,
                    iconColor:
                        AppColors.primary,
                    onTap: () {
                      _showPreparingMessage(
                        context,
                      );
                    },
                  ),
                  _QuickMenuCard(
                    title: 'AI 분석 환자',
                    description:
                        'AI 분석이 완료된 환자를 확인합니다.',
                    icon:
                        Icons.analytics_outlined,
                    iconColor:
                        AppColors.secondary,
                    onTap: () {
                      _showPreparingMessage(
                        context,
                      );
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
                      style: textTheme
                          .titleLarge
                          ?.copyWith(
                            color:
                                colorScheme
                                    .onSurface,
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),
                  ),

                  // 전체 캘린더 화면으로 이동
                  TextButton.icon(
                    onPressed: () {
                      context.pushNamed(
                        'calendar',
                      );
                    },
                    style:
                        TextButton.styleFrom(
                          foregroundColor:
                              colorScheme.primary,
                        ),
                    icon: const Icon(
                      Icons
                          .calendar_month_outlined,
                      size: 19,
                    ),
                    label: const Text(
                      '전체보기',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 홈 미니 캘린더
              //
              // 캘린더 내부를 누르면
              // 전체 CalendarView로 이동
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(20),
                  onTap: () {
                    context.pushNamed(
                      'calendar',
                    );
                  },
                  child: IgnorePointer(
                    child: _HomeCalendar(
                      selectedDate:
                          _selectedDate,
                      onDateChanged: (date) {
                        setState(() {
                          _selectedDate =
                              date;
                        });
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'To-do List',
                      style: textTheme
                          .titleLarge
                          ?.copyWith(
                            color:
                                colorScheme
                                    .onSurface,
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addTodoItem,
                    style:
                        TextButton.styleFrom(
                          foregroundColor:
                              AppColors
                                  .secondary,
                        ),
                    icon: const Icon(
                      Icons.add,
                      size: 20,
                    ),
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

      bottomNavigationBar:
          NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor:
                  colorScheme.surface,
              indicatorColor:
                  colorScheme.primaryContainer,
              iconTheme:
                  WidgetStateProperty.resolveWith<
                    IconThemeData
                  >((states) {
                    return IconThemeData(
                      color:
                          states.contains(
                            WidgetState
                                .selected,
                          )
                          ? colorScheme.primary
                          : colorScheme
                              .onSurface
                              .withValues(
                                alpha: 0.6,
                              ),
                    );
                  }),
              labelTextStyle:
                  WidgetStateProperty.resolveWith<
                    TextStyle
                  >((states) {
                    return TextStyle(
                      color:
                          states.contains(
                            WidgetState
                                .selected,
                          )
                          ? colorScheme.primary
                          : colorScheme
                              .onSurface
                              .withValues(
                                alpha: 0.6,
                              ),
                      fontWeight:
                          states.contains(
                            WidgetState
                                .selected,
                          )
                          ? FontWeight.w700
                          : FontWeight.w500,
                    );
                  }),
            ),
            child: NavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (
                index,
              ) {
                switch (index) {
                  case 0:
                    context.go('/home');
                    break;

                  case 1:
                    context.go('/patient');
                    break;

                  case 2:
                    _showPreparingMessage(
                      context,
                    );
                    break;

                  case 3:
                    _showPreparingMessage(
                      context,
                    );
                    break;
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(
                    Icons.home_outlined,
                  ),
                  selectedIcon: Icon(
                    Icons.home,
                  ),
                  label: '홈',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.people_outline,
                  ),
                  selectedIcon: Icon(
                    Icons.people,
                  ),
                  label: '환자',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons
                        .analytics_outlined,
                  ),
                  selectedIcon: Icon(
                    Icons.analytics,
                  ),
                  label: '분석',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.person_outline,
                  ),
                  selectedIcon: Icon(
                    Icons.person,
                  ),
                  label: '마이페이지',
                ),
              ],
            ),
          ),
    );
  }
}

final class _QuickMenuCard
    extends StatelessWidget {
  const _QuickMenuCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: iconColor,
                ),
              ),

              const Spacer(),

              Text(
                title,
                style: textTheme
                    .titleMedium
                    ?.copyWith(
                      color:
                          colorScheme.onSurface,
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 6),

              Text(
                description,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: textTheme.bodySmall
                    ?.copyWith(
                      color: colorScheme
                          .onSurface
                          .withValues(
                            alpha: 0.65,
                          ),
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
    required this.onDateChanged,
  });

  final DateTime selectedDate;
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

    if (!isSameDay(
      oldWidget.selectedDate,
      widget.selectedDate,
    )) {
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
      padding: const EdgeInsets.fromLTRB(
        8,
        8,
        8,
        12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar<void>(
        firstDay: DateTime(2020, 1, 1),
        lastDay: DateTime(2035, 12, 31),
        focusedDay: _focusedDate,

        locale: 'ko_KR',

        startingDayOfWeek: StartingDayOfWeek.sunday,

        calendarFormat: CalendarFormat.month,

        availableCalendarFormats: const {
          CalendarFormat.month: '월',
        },

        /// 일요일만 주말로 지정
        weekendDays: const [
          DateTime.sunday,
        ],

        selectedDayPredicate: (day) {
          return isSameDay(
            widget.selectedDate,
            day,
          );
        },

        onDaySelected: (
          selectedDay,
          focusedDay,
        ) {
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
          headerPadding: const EdgeInsets.symmetric(
            vertical: 10,
          ),
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
            color: colorScheme.onSurface.withValues(
              alpha: 0.7,
            ),
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w700,
          ),
        ),

        calendarBuilders: CalendarBuilders<void>(
          defaultBuilder: (
            context,
            day,
            focusedDay,
          ) {
            final isSunday = _isSunday(day);

            return Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isSunday
                      ? Colors.red
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },

          outsideBuilder: (
            context,
            day,
            focusedDay,
          ) {
            final isSunday = _isSunday(day);

            return Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isSunday
                      ? Colors.red.withValues(
                          alpha: 0.3,
                        )
                      : colorScheme.onSurface.withValues(
                          alpha: 0.25,
                        ),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },

          selectedBuilder: (
            context,
            day,
            focusedDay,
          ) {
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

          todayBuilder: (
            context,
            day,
            focusedDay,
          ) {
            final isSunday = _isSunday(day);

            return Center(
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(
                    alpha: 0.16,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isSunday
                        ? Colors.red
                        : AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),

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

          outsideTextStyle: TextStyle(
            color: colorScheme.onSurface.withValues(
              alpha: 0.25,
            ),
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
            color: AppColors.secondary.withValues(
              alpha: 0.16,
            ),
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

final class _TodoListSection
    extends StatelessWidget {
  const _TodoListSection({
    required this.todoItems,
    required this.onChanged,
    required this.onDelete,
  });

  final List<Map<String, dynamic>>
  todoItems;

  final void Function(
    int index,
    bool? value,
  )
  onChanged;

  final void Function(int index)
  onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (todoItems.isEmpty) {
      return Container(
        padding:
            const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: theme.dividerColor,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent
                    .withValues(
                      alpha: 0.16,
                    ),
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
                color:
                    colorScheme.onSurface,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(),
        itemCount: todoItems.length,
        separatorBuilder: (
          context,
          index,
        ) {
          return Divider(
            height: 1,
            indent: 56,
            color: colorScheme.onSurface
                .withValues(
                  alpha: 0.08,
                ),
          );
        },
        itemBuilder: (
          context,
          index,
        ) {
          final item =
              todoItems[index];

          final title =
              item['title'] as String;

          final isCompleted =
              item['isCompleted'] as bool;

          return Dismissible(
            key: ValueKey(
              '$title-$index',
            ),
            direction:
                DismissDirection
                    .endToStart,
            onDismissed: (_) {
              onDelete(index);
            },
            background: Container(
              alignment:
                  Alignment.centerRight,
              padding:
                  const EdgeInsets.only(
                    right: 22,
                  ),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius:
                    BorderRadius.circular(
                      18,
                    ),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
              ),
            ),
            child: CheckboxListTile(
              value: isCompleted,
              onChanged: (value) {
                onChanged(
                  index,
                  value,
                );
              },
              activeColor:
                  AppColors.accent,
              checkColor: Colors.white,
              controlAffinity:
                  ListTileControlAffinity
                      .leading,
              contentPadding:
                  const EdgeInsets.only(
                    left: 10,
                    right: 8,
                  ),
              title: Text(
                title,
                style: TextStyle(
                  color: isCompleted
                      ? colorScheme
                          .onSurface
                          .withValues(
                            alpha: 0.45,
                          )
                      : colorScheme
                          .onSurface,
                  fontWeight:
                      FontWeight.w500,
                  decoration: isCompleted
                      ? TextDecoration
                          .lineThrough
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
                  color: colorScheme
                      .onSurface
                      .withValues(
                        alpha: 0.45,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}