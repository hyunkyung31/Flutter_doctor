import 'package:flutter/material.dart';

final class PatientProfileAvatar extends StatelessWidget {
  const PatientProfileAvatar({this.radius = 22, super.key});

  static const String _assetPath =
      'assets/images/profile/bomi_patient_profile.png';

  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: ClipOval(
        child: Transform.scale(
          scale: 1.7,
          alignment: const Alignment(0, 0.05),
          child: Image.asset(
            _assetPath,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return ColoredBox(
                color: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_rounded,
                  size: radius,
                  color: colorScheme.onPrimaryContainer,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
