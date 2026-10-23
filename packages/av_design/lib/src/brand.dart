import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Brand marks: Avalon's own app icon (the ladder mark on its tile, D90),
/// and the sign-in buttons' marks (D65). The Apple mark takes the
/// button's foreground color; the Google "G" keeps its four brand colors.
class AvBrandMark extends StatelessWidget {
  /// The app icon as the desktop shells show it (the larger mark): for
  /// the title bar, the sidebar and the About page.
  const AvBrandMark.avalon({super.key, this.size = 32})
    : _asset = 'assets/brand/avalon.svg',
      color = null;

  const AvBrandMark.apple({
    super.key,
    this.size = 20,
    required Color this.color,
  }) : _asset = 'assets/brand/apple.svg';

  const AvBrandMark.google({super.key, this.size = 20})
    : _asset = 'assets/brand/google_g.svg',
      color = null;

  final String _asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _asset,
      package: 'av_design',
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
