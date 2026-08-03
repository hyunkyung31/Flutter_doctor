import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

final class WelcomeCard extends StatelessWidget {
  const WelcomeCard({
    super.key,
    required this.doctorName,
  });

  final String doctorName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      height: 170,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 24,
            right: 170,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$doctorName님,\n안녕하세요 👋',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '오늘도 파이팅하세요 🙂',
                  style: textTheme.bodyMedium?.copyWith(
                    color:
                        colorScheme.onPrimaryContainer.withOpacity(0.68),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -26,
            bottom: -62,
            child: SizedBox(
              width: 220,
              height: 220,
              child: ClipRect(
                child: Transform.scale(
                  scale: 1.65,
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    'assets/images/bomi_welcome.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const Icon(
                        Icons.image_not_supported_outlined,
                        size: 42,
                        color: AppColors.accent,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 118,
            top: 18,
            child: Icon(
              Icons.auto_awesome,
              size: 18,
              color: AppColors.accent.withOpacity(0.75),
            ),
          ),
          Positioned(
            right: 95,
            top: 42,
            child: Icon(
              Icons.auto_awesome,
              size: 11,
              color: AppColors.accent.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}