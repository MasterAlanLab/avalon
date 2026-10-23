import 'package:url_launcher/url_launcher.dart';

/// Opens a page in the system browser (PRODUCT_SPEC §3.10).
abstract interface class Browser {
  Future<bool> open(Uri url);
}

final class SystemBrowser implements Browser {
  const SystemBrowser();

  @override
  Future<bool> open(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);
}
