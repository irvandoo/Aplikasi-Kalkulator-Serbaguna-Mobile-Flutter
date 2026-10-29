/// Creator credit shown in "Tentang & Kredit". Kept in one place so a contact
/// detail can be corrected without touching any screen.
class DeveloperInfo {
  DeveloperInfo._();

  static const String name = 'Irvando Demas Arifiandani';

  /// Display form, as the owner wrote it.
  static const String whatsappDisplay = '0857-4747-6308';

  /// International form (no "+", no leading zero) for wa.me links.
  static const String whatsappNumber = '6285747476308';
  static const String email = 'irvando.d.a@gmai.com';
  static const String website = 'irvandoda.web.id';

  static const String whatsappGreeting =
      'Halo Irvando, saya pengguna aplikasi Kalkulator Serbaguna.';

  static Uri get whatsappUri => Uri.https('wa.me', '/$whatsappNumber', {
        'text': whatsappGreeting,
      });

  static Uri get emailUri => Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {'subject': 'Kalkulator Serbaguna'},
      );

  static Uri get websiteUri => Uri.https(website);
}
