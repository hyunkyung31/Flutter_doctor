import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final class ScreenProtectionNotice extends StatelessWidget {
  const ScreenProtectionNotice({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kReleaseMode) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF5C9B8)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFDE6DD),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 16,
              color: Color(0xFFB76047),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '환자 개인정보 보호를 위해 이 화면의 캡처 및 녹화가 제한됩니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10.0,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
