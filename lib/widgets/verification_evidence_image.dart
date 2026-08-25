import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:isdalink/services/supplier_verification_storage_service.dart';

class VerificationEvidenceImage extends StatefulWidget {
  const VerificationEvidenceImage({
    super.key,
    this.storagePath = '',
    this.legacyUrl = '',
    this.fit = BoxFit.cover,
    this.onAspectRatioChanged,
  });

  final String storagePath;
  final String legacyUrl;
  final BoxFit fit;
  final ValueChanged<double>? onAspectRatioChanged;

  bool get hasEvidence =>
      storagePath.trim().isNotEmpty || legacyUrl.trim().isNotEmpty;

  @override
  State<VerificationEvidenceImage> createState() =>
      _VerificationEvidenceImageState();
}

class _VerificationEvidenceImageState
    extends State<VerificationEvidenceImage> {
  final storageService = const SupplierVerificationStorageService();
  Future<Uint8List?>? evidenceFuture;

  @override
  void initState() {
    super.initState();
    prepareEvidence();
  }

  @override
  void didUpdateWidget(VerificationEvidenceImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.storagePath.trim() != widget.storagePath.trim()) {
      prepareEvidence();
    }
  }

  void prepareEvidence() {
    final path = widget.storagePath.trim();
    evidenceFuture = path.isEmpty
        ? null
        : storageService.loadEvidenceBytes(path);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasEvidence) {
      return const _EvidencePlaceholder(
        icon: Icons.image_outlined,
      );
    }

    if (evidenceFuture == null) {
      return _legacyImage();
    }

    return FutureBuilder<Uint8List?>(
      future: evidenceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _EvidencePlaceholder(
            icon: Icons.shield_outlined,
            loading: true,
          );
        }

        final bytes = snapshot.data;

        if (!snapshot.hasError && bytes != null && bytes.isNotEmpty) {
          return _AspectAwareEvidenceImage(
            provider: MemoryImage(bytes),
            fit: widget.fit,
            onAspectRatioChanged: widget.onAspectRatioChanged,
          );
        }

        return _legacyImage();
      },
    );
  }

  Widget _legacyImage() {
    final url = widget.legacyUrl.trim();

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return const _EvidencePlaceholder(
        icon: Icons.lock_outline_rounded,
      );
    }

    return _AspectAwareEvidenceImage(
      provider: NetworkImage(url),
      fit: widget.fit,
      onAspectRatioChanged: widget.onAspectRatioChanged,
    );
  }
}

class _AspectAwareEvidenceImage extends StatefulWidget {
  const _AspectAwareEvidenceImage({
    required this.provider,
    required this.fit,
    this.onAspectRatioChanged,
  });

  final ImageProvider provider;
  final BoxFit fit;
  final ValueChanged<double>? onAspectRatioChanged;

  @override
  State<_AspectAwareEvidenceImage> createState() =>
      _AspectAwareEvidenceImageState();
}

class _AspectAwareEvidenceImageState
    extends State<_AspectAwareEvidenceImage> {
  ImageStream? imageStream;
  ImageStreamListener? imageListener;
  double? lastAspectRatio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    resolveImage();
  }

  @override
  void didUpdateWidget(_AspectAwareEvidenceImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.provider != widget.provider) {
      resolveImage();
    }
  }

  void resolveImage() {
    final nextStream = widget.provider.resolve(
      createLocalImageConfiguration(context),
    );

    if (nextStream.key == imageStream?.key) {
      return;
    }

    if (imageStream != null && imageListener != null) {
      imageStream!.removeListener(imageListener!);
    }

    final nextListener = ImageStreamListener(
      handleImage,
    );

    imageStream = nextStream;
    imageListener = nextListener;
    imageStream!.addListener(nextListener);
  }

  void handleImage(
    ImageInfo imageInfo,
    bool synchronousCall,
  ) {
    final image = imageInfo.image;
    final aspectRatio = image.width / image.height;

    if (lastAspectRatio == aspectRatio) {
      return;
    }

    lastAspectRatio = aspectRatio;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onAspectRatioChanged?.call(aspectRatio);
      }
    });
  }

  @override
  void dispose() {
    if (imageStream != null && imageListener != null) {
      imageStream!.removeListener(imageListener!);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image(
      image: widget.provider,
      fit: widget.fit,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }

        return const _EvidencePlaceholder(
          icon: Icons.image_outlined,
          loading: true,
        );
      },
      errorBuilder: (_, _, _) => const _EvidencePlaceholder(
        icon: Icons.broken_image_outlined,
      ),
    );
  }
}

class _EvidencePlaceholder extends StatelessWidget {
  const _EvidencePlaceholder({
    required this.icon,
    this.loading = false,
  });

  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFEAF7FB),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : Icon(icon, color: const Color(0xFF6F8CA1)),
      ),
    );
  }
}

Future<void> showVerificationEvidenceViewer(
  BuildContext context, {
  required String title,
  required IconData icon,
  String storagePath = '',
  String legacyUrl = '',
}) async {
  double? imageAspectRatio;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withAlpha(190),
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final screenSize = MediaQuery.sizeOf(context);
          final dialogWidth = math.min(
            screenSize.width - 28,
            720.0,
          );
          final maximumImageHeight = screenSize.height * 0.74;
          final naturalImageHeight = imageAspectRatio == null
              ? dialogWidth * 0.72
              : dialogWidth / imageAspectRatio!;
          final imageHeight = naturalImageHeight
              .clamp(160.0, maximumImageHeight)
              .toDouble();

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 24,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 58,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              icon,
                              size: 20,
                              color: const Color(0xFF146BFF),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFDDE8EF),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: dialogWidth,
                    height: imageHeight,
                    color: const Color(0xFFF4F8FA),
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 5,
                        boundaryMargin: const EdgeInsets.all(48),
                        child: SizedBox.expand(
                          child: VerificationEvidenceImage(
                            storagePath: storagePath,
                            legacyUrl: legacyUrl,
                            fit: BoxFit.contain,
                            onAspectRatioChanged: (value) {
                              if (imageAspectRatio == value) {
                                return;
                              }

                              setDialogState(() {
                                imageAspectRatio = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
