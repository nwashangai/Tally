import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/dimensions.dart';
import '../../design_system/widgets/tally_cancel_button.dart';

/// Modal dialog/sheet providing camera-based barcode scanning.
/// Returns the scanned barcode string or null if dismissed.
class BarcodeScannerSheet extends StatefulWidget {
  const BarcodeScannerSheet({super.key});

  /// Convenient helper to open the scanner
  static Future<String?> scan(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BarcodeScannerSheet(),
    );
  }

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  late final MobileScannerController _controller;
  bool _hasDetected = false;
  bool _isStarting = true;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScanner());
  }

  Future<void> _startScanner() async {
    try {
      await _controller.start();
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStarting = false;
          if (e is MissingPluginException) {
            _initializationError =
                'The camera native plugin requires a full rebuild/restart of the app.\n\nPlease stop the running app process and run `flutter run` or `make rebuild-android`.';
          } else {
            _initializationError =
                'Unable to initialize camera: ${e.toString()}';
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasDetected) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue ??
        capture.barcodes.firstOrNull?.displayValue;
    if (barcode != null && barcode.trim().isNotEmpty) {
      _hasDetected = true;
      Navigator.of(context).pop(barcode.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final sheetHeight = (size.height * 0.75).clamp(420.0, 680.0);

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle & Header
          const SizedBox(height: TallySpacing.sm),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TallySpacing.lg,
              vertical: TallySpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(TallySpacing.xs),
                  decoration: BoxDecoration(
                    color: TallyColors.primaryNavy.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: TallyColors.primaryNavy,
                    size: 22,
                  ),
                ),
                const SizedBox(width: TallySpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Barcode',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Align barcode within the frame',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scanner preview area
          Expanded(
            child: _buildScannerContent(theme),
          ),

          // Bottom dismiss button
          Padding(
            padding: const EdgeInsets.all(TallySpacing.md),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: TallyCancelButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerContent(ThemeData theme) {
    if (_initializationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(TallySpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(TallySpacing.md),
                decoration: BoxDecoration(
                  color: TallyColors.primaryNavy.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sync_problem_rounded,
                  size: 40,
                  color: TallyColors.primaryNavy,
                ),
              ),
              const SizedBox(height: TallySpacing.md),
              Text(
                'Full App Restart Required',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: TallySpacing.xs),
              Text(
                _initializationError!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isStarting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(TallySpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: TallySpacing.md),
                    Text(
                      'Camera Unavailable',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: TallySpacing.xs),
                    Text(
                      error.errorDetails?.message ??
                          'Unable to access device camera. Please check permissions or type the barcode manually.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Viewfinder / Reticle Overlay
        Center(
          child: Container(
            width: 260,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(
                color: TallyColors.primaryNavy,
                width: 2.5,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: TallyColors.primaryNavy.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Corner accent marks
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white,
                          width: 3.5,
                        ),
                        left: BorderSide(
                          color: Colors.white,
                          width: 3.5,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white,
                          width: 3.5,
                        ),
                        right: BorderSide(
                          color: Colors.white,
                          width: 3.5,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white,
                          width: 3.5,
                        ),
                        left: BorderSide(
                          color: Colors.white,
                          width: 3.5,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white,
                          width: 3.5,
                        ),
                        right: BorderSide(
                          color: Colors.white,
                          width: 3.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Controls Overlay (Flashlight & Camera Flip)
        Positioned(
          bottom: TallySpacing.md,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TallySpacing.sm,
                  vertical: TallySpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.flash_on, color: Colors.white),
                      tooltip: 'Toggle Flashlight',
                      onPressed: () async {
                        try {
                          await _controller.toggleTorch();
                        } catch (_) {}
                      },
                    ),
                    const SizedBox(width: TallySpacing.xs),
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios,
                          color: Colors.white),
                      tooltip: 'Switch Camera',
                      onPressed: () async {
                        try {
                          await _controller.switchCamera();
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
