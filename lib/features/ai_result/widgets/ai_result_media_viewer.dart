import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../model/integrated_analysis_result.dart';
import 'ai_bounding_box_painter.dart';

// AI 분석 결과의 원본 Key Frame 또는 Grad-CAM 결과 영상을 표시
// BBox를 그리지 않고 원본 영상과 서버에서 생성한 Grad-CAM Overlay 영상의 조회·전환·확대 기능만 담당
final class AiResultMediaViewer extends StatelessWidget {
  const AiResultMediaViewer({
    super.key,
    required this.keyFrameSource,
    required this.gradcamSource,
    required this.headers,
    required this.resolveMediaUrl,
    required this.showHeatmap,
    required this.canShowHeatmap,
    required this.onHeatmapChanged,
    required this.boundingBoxData,
    required this.showBoundingBox,
    required this.canShowBoundingBox,
    required this.onOriginalSelected,
    required this.onBoundingBoxChanged,
  });

  // 선택한 검사의 원본 Key Frame URL 또는 GCS 경로
  final String? keyFrameSource;

  // 분석 결과의 Grad-CAM URL 또는 GCS 경로
  final String? gradcamSource;

  // 보호된 의료영상 요청에 전달할 JWT 인증 헤더
  final Map<String, String> headers;

  // 상대 경로와 GCS 경로를 실제 HTTP 요청 주소로 변환
  final String Function(String?) resolveMediaUrl;

  // 현재 Grad-CAM 영상을 표시할지
  final bool showHeatmap;

  // 현재 분석 결과에 표시 가능한 Grad-CAM 영상이 있는지
  final bool canShowHeatmap;

  // 사용자가 Grad-CAM 표시 상태를 변경했을 때 호출
  final ValueChanged<bool> onHeatmapChanged;

  /// YOLO가 반환한 전체 탐지 결과
  final AiBoundingBoxData boundingBoxData;

  /// 현재 원본 영상 위에 BBox를 표시할지
  final bool showBoundingBox;

  final bool canShowBoundingBox;

  final VoidCallback onOriginalSelected;

  final ValueChanged<bool> onBoundingBoxChanged;

  @override
  Widget build(BuildContext context) {
    final originalUrl = resolveMediaUrl(keyFrameSource);

    final heatmapUrl = resolveMediaUrl(gradcamSource);

    final hasOriginal = originalUrl.trim().isNotEmpty;

    final hasHeatmap = canShowHeatmap && heatmapUrl.trim().isNotEmpty;

    final hasBoundingBox =
        canShowBoundingBox && hasOriginal && boundingBoxData.hasDetections;

    final isHeatmapFallback = !hasOriginal && hasHeatmap;

    final isDisplayingHeatmap =
        (showHeatmap && hasHeatmap) || isHeatmapFallback;

    final isDisplayingBoundingBox =
        !isDisplayingHeatmap && showBoundingBox && hasBoundingBox;

    final activeUrl = isDisplayingHeatmap
        ? heatmapUrl
        : hasOriginal
        ? originalUrl
        : heatmapUrl;

    final displayMode = isDisplayingHeatmap
        ? _AiMediaDisplayMode.gradcam
        : isDisplayingBoundingBox
        ? _AiMediaDisplayMode.boundingBox
        : _AiMediaDisplayMode.original;

    final imageWidth = boundingBoxData.imageWidth;

    final imageHeight = boundingBoxData.imageHeight;

    final mediaAspectRatio =
        imageWidth != null &&
            imageHeight != null &&
            imageWidth > 0 &&
            imageHeight > 0
        ? imageWidth / imageHeight
        : 1.0;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ViewerHeader(
            displayMode: displayMode,
            hasOriginal: hasOriginal,
            hasBoundingBox: hasBoundingBox,
            hasHeatmap: hasHeatmap,
            onOriginalSelected: onOriginalSelected,
            onBoundingBoxChanged: onBoundingBoxChanged,
            onHeatmapChanged: onHeatmapChanged,
          ),
          AspectRatio(
            aspectRatio: mediaAspectRatio,
            child: ColoredBox(
              color: Colors.black,
              child: activeUrl.isEmpty
                  ? const _EmptyMediaView()
                  : _InteractiveNetworkImage(
                      imageUrl: activeUrl,
                      headers: headers,
                      boundingBoxData: boundingBoxData,
                      showBoundingBox: isDisplayingBoundingBox,
                    ),
            ),
          ),
          const _ViewerGuide(),
        ],
      ),
    );
  }
}

enum _AiMediaDisplayMode { original, boundingBox, gradcam }

// 원본 영상과 Grad-CAM 영상의 현재 표시 상태
final class _ViewerHeader extends StatelessWidget {
  const _ViewerHeader({
    required this.displayMode,
    required this.hasOriginal,
    required this.hasBoundingBox,
    required this.hasHeatmap,
    required this.onOriginalSelected,
    required this.onBoundingBoxChanged,
    required this.onHeatmapChanged,
  });

  final _AiMediaDisplayMode displayMode;
  final bool hasOriginal;
  final bool hasBoundingBox;
  final bool hasHeatmap;
  final VoidCallback onOriginalSelected;
  final ValueChanged<bool> onBoundingBoxChanged;
  final ValueChanged<bool> onHeatmapChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final title = switch (displayMode) {
      _AiMediaDisplayMode.original => '원본 Key Frame',
      _AiMediaDisplayMode.boundingBox => 'YOLOv11 BBox 분석 영상',
      _AiMediaDisplayMode.gradcam => 'Grad-CAM 분석 영상',
    };

    final titleIcon = switch (displayMode) {
      _AiMediaDisplayMode.original => Icons.image_outlined,
      _AiMediaDisplayMode.boundingBox => Icons.crop_free_rounded,
      _AiMediaDisplayMode.gradcam => Icons.gradient_rounded,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(90),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
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
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(titleIcon, size: 19, color: colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('원본'),
                  avatar: const Icon(Icons.image_outlined, size: 17),
                  selected: displayMode == _AiMediaDisplayMode.original,
                  onSelected: hasOriginal
                      ? (_) {
                          onOriginalSelected();
                        }
                      : null,
                ),
                if (hasBoundingBox) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('BBox'),
                    avatar: const Icon(Icons.crop_free_rounded, size: 17),
                    selected: displayMode == _AiMediaDisplayMode.boundingBox,
                    onSelected: onBoundingBoxChanged,
                  ),
                ],
                if (hasHeatmap) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Grad-CAM'),
                    avatar: const Icon(Icons.gradient_rounded, size: 17),
                    selected: displayMode == _AiMediaDisplayMode.gradcam,
                    onSelected: onHeatmapChanged,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// JWT 인증 헤더를 포함해 분석 영상을 불러오고 확대·이동 기능을 제공
final class _InteractiveNetworkImage extends StatelessWidget {
  const _InteractiveNetworkImage({
    required this.imageUrl,
    required this.headers,
    required this.boundingBoxData,
    required this.showBoundingBox,
  });

  final String imageUrl;
  final Map<String, String> headers;
  final AiBoundingBoxData boundingBoxData;
  final bool showBoundingBox;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CachedNetworkImage(
      imageUrl: imageUrl,
      httpHeaders: headers,
      fadeInDuration: const Duration(milliseconds: 200),
      imageBuilder: (context, imageProvider) {
        return InteractiveViewer(
          minScale: 1,
          maxScale: 6,
          panEnabled: true,
          scaleEnabled: true,
          boundaryMargin: const EdgeInsets.all(80),
          clipBehavior: Clip.hardEdge,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image(image: imageProvider, fit: BoxFit.contain),
                if (showBoundingBox)
                  IgnorePointer(
                    child: CustomPaint(
                      painter: AiBoundingBoxPainter(
                        boundingBoxData: boundingBoxData,
                        borderColor: colorScheme.error,
                        labelBackgroundColor: colorScheme.error,
                        labelTextColor: colorScheme.onError,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      placeholder: (context, url) {
        return const Center(child: CircularProgressIndicator());
      },
      errorWidget: (context, url, error) {
        debugPrint('AI 결과 이미지 요청 URL: $url');

        debugPrint('AI 결과 이미지 로드 오류: $error');

        return const _MediaErrorView();
      },
    );
  }
}

// 원본과 Grad-CAM 주소가 모두 없을 때 표시
final class _EmptyMediaView extends StatelessWidget {
  const _EmptyMediaView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white70,
              size: 42,
            ),
            SizedBox(height: 12),
            Text(
              '표시할 분석 영상이 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

// 주소 오류, 인증 오류 또는 서버 응답 오류로 영상을 불러오지 못할 때 표시
final class _MediaErrorView extends StatelessWidget {
  const _MediaErrorView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.white70, size: 42),
            SizedBox(height: 12),
            Text(
              '분석 영상을 불러오지 못했습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

// 의료진에게 영상 확대와 이동 방법을 안내
final class _ViewerGuide extends StatelessWidget {
  const _ViewerGuide();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          Icon(Icons.zoom_in, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '두 손가락으로 영상을 확대하거나 이동할 수 있습니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
