import 'package:flutter/material.dart';

final class DoctorProfileAvatar extends StatelessWidget {
  const DoctorProfileAvatar({this.radius = 22, this.scale = 1.9, super.key});

  static const String _assetPath =
      'assets/images/profile/bomi_doctor_profile.png';

  final double radius;
  final double scale;

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
      clipBehavior: Clip.antiAlias,
      child: Transform.scale(
        scale: scale,
        alignment: const Alignment(0, 0.05),
        child: Image.asset(
          _assetPath,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return ColoredBox(
              color: colorScheme.primaryContainer,
              child: Icon(
                Icons.medical_services_outlined,
                size: radius,
                color: colorScheme.onPrimaryContainer,
              ),
            );
          },
        ),
      ),
    );
  }
}
