import 'package:url_launcher/url_launcher.dart';

/// Opens external links (WhatsApp, e-mail, browser) behind an interface so
/// tests can fake it. Returns false when nothing could handle the link.
abstract class LinkService {
  Future<bool> open(Uri uri);
}

class SystemLinkService implements LinkService {
  const SystemLinkService();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
