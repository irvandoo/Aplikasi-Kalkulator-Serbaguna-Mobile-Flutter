import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Clipboard and plain-text sharing, behind an interface so tests can fake it.
abstract class ShareService {
  Future<void> copy(String text);
  Future<void> share(String text, {String? subject});
}

class SystemShareService implements ShareService {
  const SystemShareService();

  @override
  Future<void> copy(String text) => Clipboard.setData(ClipboardData(text: text));

  @override
  Future<void> share(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }
}
