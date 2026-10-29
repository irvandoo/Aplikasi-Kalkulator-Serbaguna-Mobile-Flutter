/// Route paths. Tab screens live in the bottom-navigation shell; the rest are
/// pushed on top of it.
class Routes {
  Routes._();

  // Tabs (bottom navigation, in order).
  static const home = '/';
  static const calculator = '/kalkulator';
  static const discount = '/diskon';
  static const shopping = '/belanja';
  static const unitPrice = '/banding';

  // Pushed screens.
  static const allTools = '/semua-alat';
  static const percentage = '/persentase';
  static const history = '/riwayat';
  static const settings = '/pengaturan';
  static const privacy = '/privasi';
  static const billSplit = '/patungan';
  static const guide = '/panduan';
  static const about = '/tentang';
  static const discountCompare = '/diskon/bandingkan';
  static const shoppingLists = '/belanja/daftar';
}
