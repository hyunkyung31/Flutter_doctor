import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

final class TodayTodoItem {
  const TodayTodoItem({
    required this.title,
    required this.isCompleted,
  });

  final String title;
  final bool isCompleted;

  TodayTodoItem copyWith({
    String? title,
    bool? isCompleted,
  }) {
    return TodayTodoItem(
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

final class TodayTodoSection extends StatelessWidget {
  const TodayTodoSection({
    super.key,
    required this.todoItems,
    required this.onChanged,
    required this.onAdd,
    required this.onViewAll,
  });

  final List<TodayTodoItem> todoItems;
  final void Function(int index, bool? value) onChanged;
  final VoidCallback onAdd;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '오늘의 To-do',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: '할 일 추가',
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              color: AppColors.secondary,
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text('전체보기'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.dividerColor,
            ),
          ),
          child: todoItems.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.checklist_outlined,
                        size: 34,
                        color: colorScheme.onSurface.withOpacity(0.35),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '등록된 할 일이 없습니다.',
                        style: textTheme.bodyMedium?.copyWith(
                          color:
                              colorScheme.onSurface.withOpacity(0.55),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todoItems.length,
                  separatorBuilder: (context, index) {
                    return Divider(
                      height: 1,
                      indent: 54,
                      color: colorScheme.onSurface.withOpacity(0.08),
                    );
                  },
                  itemBuilder: (context, index) {
                    final todo = todoItems[index];

                    return CheckboxListTile(
                      value: todo.isCompleted,
                      onChanged: (value) {
                        onChanged(index, value);
                      },
                      activeColor: AppColors.accent,
                      checkColor: Colors.white,
                      controlAffinity:
                          ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          color: todo.isCompleted
                              ? colorScheme.onSurface.withOpacity(0.4)
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}