import 'package:flutter/material.dart';

import '../model/integrated_analysis_result.dart';

// AI 탐지 결과의 BBox를 원본 영상 위에 표시
// 서버가 제공하는 box_normalized 좌표를 우선 사용하고,
// 정규화 좌표가 없으면 픽셀 좌표와 원본 이미지 크기를 사용
final class AiBoundingBoxPainter
    extends CustomPainter {
  const AiBoundingBoxPainter({
    required this.boundingBoxData,
    required this.borderColor,
    required this.labelBackgroundColor,
    required this.labelTextColor,
  });

  final AiBoundingBoxData boundingBoxData;
  final Color borderColor;
  final Color labelBackgroundColor;
  final Color labelTextColor;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final imageWidth =
        boundingBoxData.imageWidth;

    final imageHeight =
        boundingBoxData.imageHeight;

    if (size.width <= 0 ||
        size.height <= 0 ||
        imageWidth == null ||
        imageHeight == null ||
        imageWidth <= 0 ||
        imageHeight <= 0) {
      return;
    }

    // BoxFit.contain으로 실제 영상이 표시되는 영역을 계산한다.
    final imageRect = _calculateContainedRect(
      canvasSize: size,
      sourceWidth: imageWidth.toDouble(),
      sourceHeight: imageHeight.toDouble(),
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final labelPaint = Paint()
      ..color = labelBackgroundColor;

    canvas.save();
    canvas.clipRect(imageRect);

    for (final detection
        in boundingBoxData.detections) {
      final normalizedRect =
          _resolveNormalizedRect(
        detection: detection,
        imageWidth: imageWidth.toDouble(),
        imageHeight: imageHeight.toDouble(),
      );

      if (normalizedRect == null) {
        continue;
      }

      final boxRect = _toDisplayRect(
        normalizedRect: normalizedRect,
        imageRect: imageRect,
      );

      if (boxRect.width <= 0 ||
          boxRect.height <= 0) {
        continue;
      }

      canvas.drawRect(
        boxRect,
        borderPaint,
      );

      _drawLabel(
        canvas: canvas,
        imageRect: imageRect,
        boxRect: boxRect,
        detection: detection,
        backgroundPaint: labelPaint,
      );
    }

    canvas.restore();
  }

  Rect _calculateContainedRect({
    required Size canvasSize,
    required double sourceWidth,
    required double sourceHeight,
  }) {
    final sourceAspectRatio =
        sourceWidth / sourceHeight;

    final canvasAspectRatio =
        canvasSize.width /
        canvasSize.height;

    if (canvasAspectRatio >
        sourceAspectRatio) {
      final displayedHeight =
          canvasSize.height;

      final displayedWidth =
          displayedHeight *
          sourceAspectRatio;

      final left =
          (canvasSize.width -
                  displayedWidth) /
              2;

      return Rect.fromLTWH(
        left,
        0,
        displayedWidth,
        displayedHeight,
      );
    }

    final displayedWidth =
        canvasSize.width;

    final displayedHeight =
        displayedWidth /
        sourceAspectRatio;

    final top =
        (canvasSize.height -
                displayedHeight) /
            2;

    return Rect.fromLTWH(
      0,
      top,
      displayedWidth,
      displayedHeight,
    );
  }

  Rect? _resolveNormalizedRect({
    required AiDetection detection,
    required double imageWidth,
    required double imageHeight,
  }) {
    final normalizedBox =
        detection.normalizedBox;

    if (normalizedBox != null &&
        normalizedBox.isNormalized) {
      return Rect.fromLTRB(
        normalizedBox.x1,
        normalizedBox.y1,
        normalizedBox.x2,
        normalizedBox.y2,
      );
    }

    final pixelBox = detection.box;

    if (pixelBox == null ||
        !pixelBox.isValid ||
        imageWidth <= 0 ||
        imageHeight <= 0) {
      return null;
    }

    return Rect.fromLTRB(
      pixelBox.x1 / imageWidth,
      pixelBox.y1 / imageHeight,
      pixelBox.x2 / imageWidth,
      pixelBox.y2 / imageHeight,
    );
  }

  Rect _toDisplayRect({
    required Rect normalizedRect,
    required Rect imageRect,
  }) {
    final left = (
      imageRect.left +
      normalizedRect.left *
          imageRect.width
    ).clamp(
      imageRect.left,
      imageRect.right,
    ).toDouble();

    final top = (
      imageRect.top +
      normalizedRect.top *
          imageRect.height
    ).clamp(
      imageRect.top,
      imageRect.bottom,
    ).toDouble();

    final right = (
      imageRect.left +
      normalizedRect.right *
          imageRect.width
    ).clamp(
      imageRect.left,
      imageRect.right,
    ).toDouble();

    final bottom = (
      imageRect.top +
      normalizedRect.bottom *
          imageRect.height
    ).clamp(
      imageRect.top,
      imageRect.bottom,
    ).toDouble();

    return Rect.fromLTRB(
      left,
      top,
      right,
      bottom,
    );
  }

  void _drawLabel({
    required Canvas canvas,
    required Rect imageRect,
    required Rect boxRect,
    required AiDetection detection,
    required Paint backgroundPaint,
  }) {
    final className =
        detection.className?.trim();

    final displayClassName =
        className == null ||
                className.isEmpty
            ? 'lesion'
            : className;

    final confidence =
        detection.confidence;

    final confidenceText =
        confidence != null &&
                confidence.isFinite
            ? ' ${(confidence * 100).toStringAsFixed(1)}%'
            : '';

    final labelText =
        '$displayClassName$confidenceText';

    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: labelTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );

    final maximumLabelWidth =
        imageRect.width - 12;

    if (maximumLabelWidth <= 0) {
      return;
    }

    textPainter.layout(
      maxWidth: maximumLabelWidth,
    );

    const horizontalPadding = 6.0;
    const verticalPadding = 4.0;

    final labelWidth =
        textPainter.width +
        horizontalPadding * 2;

    final labelHeight =
        textPainter.height +
        verticalPadding * 2;

    final maximumLeft =
        imageRect.right -
        labelWidth;

    final labelLeft = boxRect.left
        .clamp(
          imageRect.left,
          maximumLeft < imageRect.left
              ? imageRect.left
              : maximumLeft,
        )
        .toDouble();

    var labelTop =
        boxRect.top -
        labelHeight -
        4;

    if (labelTop < imageRect.top) {
      labelTop =
          boxRect.top + 4;
    }

    final maximumTop =
        imageRect.bottom -
        labelHeight;

    labelTop = labelTop
        .clamp(
          imageRect.top,
          maximumTop < imageRect.top
              ? imageRect.top
              : maximumTop,
        )
        .toDouble();

    final labelRect = Rect.fromLTWH(
      labelLeft,
      labelTop,
      labelWidth,
      labelHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        labelRect,
        const Radius.circular(4),
      ),
      backgroundPaint,
    );

    textPainter.paint(
      canvas,
      Offset(
        labelRect.left +
            horizontalPadding,
        labelRect.top +
            verticalPadding,
      ),
    );
  }

  @override
  bool shouldRepaint(
    covariant AiBoundingBoxPainter
        oldDelegate,
  ) {
    return oldDelegate.boundingBoxData !=
            boundingBoxData ||
        oldDelegate.borderColor !=
            borderColor ||
        oldDelegate
                .labelBackgroundColor !=
            labelBackgroundColor ||
        oldDelegate.labelTextColor !=
            labelTextColor;
  }
}