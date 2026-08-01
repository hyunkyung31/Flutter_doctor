import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class VenaLogo extends StatefulWidget {
  const VenaLogo({
    super.key,
    this.onCompleted,
  });

  final VoidCallback? onCompleted;

  @override
  State<VenaLogo> createState() => _VenaLogoState();
}

class _VenaLogoState extends State<VenaLogo>
    with SingleTickerProviderStateMixin {
  // 심전도가 왼쪽부터 오른쪽까지 채워지는 시간
  static const Duration _ecgFillDuration = Duration(
    milliseconds: 2000,
  );

  // 심전도 완성 후 화면을 유지하는 시간
  static const Duration _completedHoldDuration = Duration(
    milliseconds: 700,
  );

  late final AnimationController _ecgController;

  bool _showHeart = false;
  bool _didComplete = false;

  @override
  void initState() {
    super.initState();

    _ecgController = AnimationController(
      vsync: this,
      duration: _ecgFillDuration,
      animationBehavior: AnimationBehavior.preserve,
    );

    _ecgController.addStatusListener(_handleAnimationStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      );

      if (!mounted) {
        return;
      }

      _ecgController.forward(from: 0);
    });
  }

  Future<void> _handleAnimationStatus(
    AnimationStatus status,
  ) async {
    if (status != AnimationStatus.completed || _didComplete) {
      return;
    }

    // 심전도가 모두 채워진 다음 하트 표시
    setState(() {
      _showHeart = true;
    });

    await Future<void>.delayed(
      _completedHoldDuration,
    );

    if (!mounted || _didComplete) {
      return;
    }

    _didComplete = true;
    widget.onCompleted?.call();
  }

  @override
  void dispose() {
    _ecgController
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // vena 글자는 움직이지 않고 정중앙에 표시
          Image.asset(
            'assets/images/vena_text.png',
            width: 235,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 2),

          // 심전도와 하트를 하나의 영역으로 중앙에 배치
          SizedBox(
            width: 248,
            height: 56,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 195,
                  height: 50,
                  child: CustomPaint(
                    painter: _EcgFillPainter(
                      progress: _ecgController,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 하트 영역  처음부터 확보 - 정렬이 움직이지 않게
                SizedBox(
                  width: 41,
                  height: 41,
                  child: AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 280,
                    ),
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                    ) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      );
                    },
                    child: _showHeart
                        ? const Icon(
                            Icons.favorite_rounded,
                            key: ValueKey<String>('heart'),
                            color: AppColors.accent,
                            size: 41,
                          )
                        : const SizedBox(
                            key: ValueKey<String>('empty-heart'),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EcgFillPainter extends CustomPainter {
  _EcgFillPainter({
    required this.progress,
  }) : super(repaint: progress);

  final Animation<double> progress;


  Path _createEcgPath(Size size) {
  final double centerY = size.height / 2;
  final double width = size.width;

  return Path()
    ..moveTo(0, centerY)
    ..lineTo(width * 0.16, centerY)
    ..lineTo(width * 0.22, centerY)
    ..lineTo(width * 0.27, centerY - 4)
    ..lineTo(width * 0.32, centerY + 6)
    ..lineTo(width * 0.39, 2)
    ..lineTo(width * 0.47, size.height - 2)
    ..lineTo(width * 0.55, centerY - 8)
    ..lineTo(width * 0.63, centerY + 4)
    ..lineTo(width * 0.70, centerY)
    ..lineTo(width, centerY);
}


  @override
void paint(Canvas canvas, Size size) {
  final Path ecgPath = _createEcgPath(size);

  final Paint activePaint = Paint()
    ..color = AppColors.accent
    ..strokeWidth = 3.8
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  final double normalizedProgress =
      progress.value.clamp(0.0, 1.0).toDouble();

  final double filledWidth =
      size.width * normalizedProgress;

  canvas.save();

  canvas.clipRect(
    Rect.fromLTWH(
      0,
      0,
      filledWidth,
      size.height,
    ),
  );

  canvas.drawPath(ecgPath, activePaint);
  canvas.restore();
}

  @override
  bool shouldRepaint(
    covariant _EcgFillPainter oldDelegate,
  ) {
    return false;
  }
}