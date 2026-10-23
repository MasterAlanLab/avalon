import 'package:av_design/av_design.dart';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_zxing/flutter_zxing.dart' show Format, ReaderWidget;

/// Why the camera cannot scan.
enum ScannerProblem {
  /// The user declined camera access (PRODUCT_SPEC §8: say so in place).
  denied,

  /// No camera, or it could not start (e.g. a simulator).
  unavailable,
}

/// A live camera view that reports the text of the first QR code it reads
/// (V3 3d «扫描二维码»). Decoding is zxing-cpp through flutter_zxing: open
/// source on every platform, unlike scanners built on Google ML Kit (D79).
class QrScanner extends StatefulWidget {
  const QrScanner({
    super.key,
    required this.onCode,
    required this.prompt,
    required this.problemText,
  });

  final ValueChanged<String> onCode;

  /// Under the frame: «将订阅二维码放入框内».
  final String prompt;
  final String Function(ScannerProblem problem) problemText;

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> {
  late final Future<bool> _hasCamera = availableCameras()
      .then((List<CameraDescription> cameras) => cameras.isNotEmpty)
      .catchError((Object _) => false);
  ScannerProblem? _problem;

  static ScannerProblem _problemOf(Exception error) =>
      error is CameraException && error.code.startsWith('CameraAccess')
      ? ScannerProblem.denied
      : ScannerProblem.unavailable;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: ColoredBox(
          color: const Color(0xFF111111),
          child: FutureBuilder<bool>(
            future: _hasCamera,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final problem =
                  _problem ??
                  (snapshot.data! ? null : ScannerProblem.unavailable);
              if (problem != null) return _Message(widget.problemText(problem));
              return Stack(
                fit: StackFit.expand,
                children: [
                  ReaderWidget(
                    codeFormat: Format.qrCode,
                    showScannerOverlay: false,
                    showFlashlight: false,
                    showGallery: false,
                    showToggleCamera: false,
                    allowPinchZoom: false,
                    cropPercent: 0.52,
                    tryHarder: true,
                    loading: const ColoredBox(color: Color(0xFF111111)),
                    onScan: (code) {
                      final text = code.text;
                      if (code.isValid && text != null && text.isNotEmpty) {
                        widget.onCode(text);
                      }
                    },
                    onControllerCreated: (_, error) {
                      if (error != null && mounted) {
                        setState(() => _problem = _problemOf(error));
                      }
                    },
                  ),
                  IgnorePointer(child: _Frame(prompt: widget.prompt)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// V3's viewfinder: the outside dimmed (CSS `box-shadow: 0 0 0 999px`,
/// which leaves the inside clear), a rounded white frame, and the prompt.
class _Frame extends StatelessWidget {
  const _Frame({required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _Dim()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Text(
            prompt,
            textAlign: TextAlign.center,
            style: AvType.s(14).copyWith(color: const Color(0xFFFFFFFF)),
          ),
        ),
      ],
    );
  }
}

/// The frame takes 52% of the width, centred, radius 24, 3 px border.
class _Dim extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width * 0.52;
    final frame = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: side,
        height: side,
      ),
      const Radius.circular(24),
    );
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(frame),
      Paint()..color = const Color(0x66000000),
    );
    canvas.drawRRect(
      frame.deflate(1.5),
      Paint()
        ..color = const Color(0xE6FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_Dim old) => false;
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AvType.s(14).copyWith(color: const Color(0xCCFFFFFF)),
      ),
    ),
  );
}
