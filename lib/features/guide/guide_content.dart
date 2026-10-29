import 'package:flutter/material.dart';

/// One how-to topic in the user guide.
class GuideTopic {
  const GuideTopic({
    required this.id,
    required this.title,
    required this.icon,
    required this.summary,
    required this.steps,
    this.tips = const [],
  });

  final String id;
  final String title;
  final IconData icon;
  final String summary;
  final List<String> steps;
  final List<String> tips;
}

class GuideFaq {
  const GuideFaq(this.question, this.answer);
  final String question;
  final String answer;
}

/// Guide texts. They describe only features that exist in the app; update
/// them together with the screens.
class GuideContent {
  GuideContent._();

  static const List<String> quickStart = [
    'Pilih alat lewat menu bawah (Beranda, Kalkulator, Diskon, Belanja, Banding) atau dari kartu "Alat Favorit" di Beranda.',
    'Isi angka. Pemisah ribuan otomatis mengikuti format di Pengaturan.',
    'Hasil tampil langsung saat Anda mengetik, tanpa tombol hitung.',
    'Ketuk Simpan untuk menaruh hasil di Riwayat, Salin untuk menyalin, atau Bagikan untuk mengirim ke aplikasi lain.',
  ];

  static const List<GuideTopic> tools = [
    GuideTopic(
      id: 'calculator',
      title: 'Kalkulator Dasar',
      icon: Icons.calculate_outlined,
      summary:
          'Kalkulator harian untuk tambah, kurang, kali, bagi, persen, kurung, dan akar.',
      steps: [
        'Ketuk angka dan operator seperti kalkulator biasa. Gunakan ( ) untuk mengatur urutan hitung.',
        'Ketuk = untuk melihat hasil. Perhitungan masuk ke "Pita Hitung Terakhir".',
        'Tombol % punya dua aturan: "200 + 10%" berarti 200 ditambah 10% dari 200 (hasil 220), sedangkan "50%" berdiri sendiri berarti 0,5.',
        'Tombol ± membalik tanda angka yang sedang diketik, ⌫ menghapus satu karakter, dan C menghapus semuanya.',
        'Tombol √, x², dan π tersedia di baris ilmiah.',
        'Memori: M+ menambah, M− mengurangi, MR memanggil, MC menghapus memori.',
        'Ketuk Pita untuk membuka atau menutup riwayat perhitungan, lalu ketuk salah satunya untuk memakainya lagi.',
      ],
      tips: [
        'Ketuk Simpan agar perhitungan muncul di Riwayat dan bisa dihitung ulang.',
        'Tahan tombol ⌫ untuk menghapus semua, sama seperti C.',
        'Pembagian dengan nol akan ditolak dengan pesan, perhitungan Anda tidak rusak.',
      ],
    ),
    GuideTopic(
      id: 'discount',
      title: 'Diskon & Promo',
      icon: Icons.percent,
      summary:
          'Hitung harga akhir setelah diskon tunggal atau bertingkat, pajak, dan biaya tambahan.',
      steps: [
        'Isi Harga Asli / Label Barang, atau ketuk pilihan cepat (Rp50rb, Rp100rb, Rp250rb, Rp500rb).',
        'Pilih Diskon Tahap 1 dengan chip cepat (10%, 20%, 30%, 50%, 70%) atau ketik sendiri.',
        'Ketuk Tambah tahap untuk diskon bertingkat (sampai 4 tahap), misalnya 30% lalu tambah 10%. Tiap tahap dihitung dari sisa harga sebelumnya. Ketuk ikon hapus untuk membuang satu tahap.',
        'Aktifkan Tambah Pajak PPN (11%) bila perlu. Pajak dikenakan setelah semua diskon.',
        'Isi Biaya Layanan / Parkir bila ada biaya tetap tambahan.',
        'Lihat Rincian Penghematan: potongan tiap tahap, pajak, total hemat, dan harga akhir.',
      ],
      tips: [
        'Diskon bertingkat tidak dijumlahkan: 50% lalu 20% menghemat 60%, bukan 70%.',
        'Ketuk Bandingkan Penawaran untuk membandingkan beberapa promo sekaligus (lihat topik di bawah).',
        'Salin Rincian atau Bagikan rincian untuk mengirimnya ke teman atau keluarga.',
      ],
    ),
    GuideTopic(
      id: 'discount_compare',
      title: 'Bandingkan Penawaran',
      icon: Icons.compare_arrows,
      summary:
          'Bandingkan beberapa promo (misal toko A vs toko B) untuk tahu mana yang harga akhirnya paling murah.',
      steps: [
        'Di Diskon & Promo, ketuk Bandingkan Penawaran.',
        'Untuk tiap penawaran (A, B, ...), isi Harga asli, Diskon 1, Diskon 2 bila ada, dan Biaya tambahan bila ada.',
        'Aktifkan "Tambah PPN 11% pada semua penawaran" bila harga belum termasuk pajak.',
        'Ketuk Tambah Penawaran untuk menambah pembanding (maksimal 4, minimal 2). Ikon hapus membuang satu penawaran.',
        'Penawaran dengan harga akhir terendah ditandai "Paling Hemat", dan ringkasan di bawah menyebut harga akhir terendahnya.',
      ],
      tips: [
        'Bandingkan harga akhir, bukan besar persen diskonnya: diskon 50% dari harga yang sudah dinaikkan bisa lebih mahal daripada diskon 30%.',
      ],
    ),
    GuideTopic(
      id: 'shopping',
      title: 'Total Belanja',
      icon: Icons.shopping_cart_outlined,
      summary:
          'Daftar belanja dengan anggaran, sisa uang, centang barang, dan penghematan diskon.',
      steps: [
        'Ketuk Tambah Barang Belanja, isi nama barang, harga satuan, jumlah, dan diskon (opsional).',
        'Ketuk Atur anggaran untuk mengisi Batas Anggaran. Kartu menampilkan Terpakai, persentase terpakai, dan Sisa Uang.',
        'Centang barang saat sudah masuk keranjang. "Di Keranjang" menampilkan total yang sudah dicentang, "Estimasi Semua Barang" total seluruhnya.',
        'Ubah jumlah dengan tombol + dan −. Ketuk barang untuk membuka formulirnya: ubah nama, harga, jumlah, atau diskon, atau hapus barangnya (akan diminta konfirmasi).',
        'Reset Cek menghapus semua centang untuk belanja berikutnya.',
        'Ketuk Ganti Daftar untuk memilih daftar lain. Di layar itu, Daftar Baru membuat daftar, ikon pensil mengubah nama dan anggarannya, dan ikon sampah menghapusnya.',
      ],
      tips: [
        'Setiap perubahan tersimpan otomatis dan tetap ada setelah aplikasi ditutup.',
        'Ketuk Simpan ke Riwayat untuk menyimpan ringkasan belanja.',
      ],
    ),
    GuideTopic(
      id: 'unit_price',
      title: 'Banding Satuan',
      icon: Icons.balance_outlined,
      summary:
          'Cari kemasan yang paling hemat dengan membandingkan harga per gram, ml, atau pcs.',
      steps: [
        'Pilih jenis ukuran: Berat, Volume, atau Jumlah.',
        'Untuk Pilihan A dan B, isi Harga total dan Ukuran / isi, lalu pilih satuannya (misal gram atau kg).',
        'Harga Satuan Unit tiap pilihan muncul otomatis, dan yang paling hemat diberi tanda.',
        'Baca Analisis & Penghematan untuk selisih harga per satuan dan persentase hematnya.',
        'Ketuk Tambah Opsi untuk membandingkan lebih dari dua kemasan (sampai 5 pilihan). Ikon hapus membuang satu pilihan, minimal tersisa dua.',
      ],
      tips: [
        'Tukar A/B menukar isian kedua kemasan, Reset Nilai mengosongkan semuanya.',
        'Satuan berbeda (kg vs gram) otomatis disamakan sebelum dibandingkan.',
      ],
    ),
    GuideTopic(
      id: 'percentage',
      title: 'Persentase',
      icon: Icons.query_stats,
      summary:
          'Enam mode: persen dari nilai, berapa persen, kenaikan, penurunan, selisih, dan perubahan persen.',
      steps: [
        'Buka dari Beranda lewat Alat Favorit atau Semua Alat.',
        'Pilih mode di bagian atas. Petunjuk di bawahnya menjelaskan arti tiap kolom.',
        'Isi dua kolom. Hasil dan rumusnya tampil langsung.',
        'Contoh: mode "Perubahan persen" dengan 80.000 ke 100.000 menghasilkan 25%.',
      ],
      tips: [
        'Angka negatif diperbolehkan, misalnya untuk menghitung kerugian.',
        'Mode yang membagi dengan nol akan menampilkan pesan, bukan hasil salah.',
      ],
    ),
    GuideTopic(
      id: 'bill_split',
      title: 'Patungan Rame',
      icon: Icons.group_outlined,
      summary:
          'Bagi tagihan makan atau acara ke beberapa orang, lengkap dengan pajak, tip, dan pembulatan.',
      steps: [
        'Isi Total tagihan.',
        'Atur Jumlah orang dengan tombol + dan −.',
        'Pilih Tip / Service dan Pajak lewat chip cepat, atau ketik persentase sendiri.',
        'Pilih Bulatkan ke atas per orang (100, 500, atau 1.000) bila ingin uang pas.',
        'Lihat "Setiap orang bayar" beserta rincian tagihan, pajak, tip, total, dan kelebihan karena pembulatan.',
      ],
      tips: [
        'Tip dihitung dari tagihan sebelum pajak.',
        'Pembulatan selalu ke atas, jadi uang yang terkumpul tidak pernah kurang dari tagihan.',
        'Ketuk Bagikan untuk mengirim rincian ke grup chat, atau Simpan agar bisa dihitung ulang dari Riwayat (filter "Patungan").',
        'Ikon panah melingkar di kanan atas mengosongkan semua isian.',
      ],
    ),
  ];

  static const List<GuideTopic> features = [
    GuideTopic(
      id: 'favorites',
      title: 'Alat Favorit',
      icon: Icons.star_outline,
      summary: 'Atur alat yang tampil di Beranda sesuai kebutuhan Anda.',
      steps: [
        'Di Beranda, ketuk Atur pada bagian Alat Favorit.',
        'Tahan dan geser alat untuk mengubah urutan.',
        'Ketuk bintang untuk menghapus alat dari favorit, atau tambahkan dari daftar "Tambah ke favorit".',
        'Di Semua Alat, ketuk bintang pada alat mana pun untuk menjadikannya favorit.',
        'Atur ulang mengembalikan semua alat ke urutan awal.',
      ],
    ),
    GuideTopic(
      id: 'history',
      title: 'Riwayat',
      icon: Icons.history,
      summary:
          'Semua hasil yang Anda simpan, bisa disaring, dibagikan, dan dihitung ulang.',
      steps: [
        'Ketuk ikon jam di kanan atas untuk membuka Riwayat.',
        'Pilih chip jenis (Kalkulator, Diskon, Belanja, dan seterusnya) untuk menyaring.',
        'Ketuk Hitung ulang untuk membuka alatnya dengan isian yang sama.',
        'Salin hasil atau Bagikan untuk mengirimkannya, Hapus untuk menghapus satu item.',
        'Hapus semua riwayat dilakukan lewat tombol di Riwayat atau di Pengaturan.',
      ],
      tips: [
        'Kartu "Hemat Pekan Ini" di Beranda menjumlahkan penghematan dari riwayat tujuh hari terakhir.',
      ],
    ),
    GuideTopic(
      id: 'settings',
      title: 'Pengaturan',
      icon: Icons.settings_outlined,
      summary: 'Tema, format angka, dan data aplikasi.',
      steps: [
        'Ketuk ikon profil di kanan atas untuk membuka Pengaturan.',
        'Tema: ikuti Sistem, Terang, atau Gelap.',
        'Pemisah angka: format Indonesia (1.234,56) atau Internasional (1,234.56).',
        'Angka desimal: jumlah angka di belakang koma untuk persen dan harga satuan.',
        'Hapus semua riwayat menghapus riwayat saja. Daftar belanja tidak ikut terhapus.',
        'Panduan Penggunaan (halaman ini) juga dapat dibuka dari sini.',
      ],
    ),
    GuideTopic(
      id: 'about',
      title: 'Tentang & Kredit',
      icon: Icons.info_outline,
      summary:
          'Informasi versi aplikasi dan cara menghubungi pengembang untuk saran atau laporan masalah.',
      steps: [
        'Buka Pengaturan, lalu ketuk Tentang & Kredit.',
        'Ketuk Kirim WhatsApp untuk langsung membuka chat dengan pengembang beserta pesan sapaan.',
        'Ketuk baris WhatsApp, Email, atau Website untuk membukanya. Ikon salin di kanan menyalin kontaknya.',
        'Jika tautan tidak bisa dibuka (misal WhatsApp belum terpasang), aplikasi memberi tahu dan Anda tetap bisa menyalin kontaknya.',
      ],
    ),
  ];

  /// Short, general money-saving habits shown after the tool topics.
  static const List<String> smartTips = [
    'Bandingkan harga per satuan (per gram atau per ml), bukan harga kemasan. Kemasan besar tidak selalu lebih murah.',
    'Diskon bertingkat tidak dijumlahkan. 50% lalu 20% menghemat 60%, bukan 70%.',
    'Cek apakah harga di label sudah termasuk PPN sebelum membandingkan dua toko.',
    'Isi anggaran di Total Belanja sebelum berangkat, lalu centang barang saat memasukkannya ke keranjang agar tidak melebihi budget.',
    'Untuk patungan, bulatkan ke atas per orang supaya uang yang terkumpul tidak kurang dari tagihan.',
  ];

  static const List<GuideFaq> faq = [
    GuideFaq('Apakah aplikasi ini butuh internet?',
        'Tidak. Semua perhitungan dan penyimpanan dilakukan di perangkat Anda. Internet hanya dipakai bila iklan dimuat atau Anda membuka tautan kontak.'),
    GuideFaq('Di mana data saya disimpan?',
        'Riwayat dan daftar belanja disimpan di penyimpanan lokal perangkat. Tidak ada akun dan tidak ada data yang dikirim ke server kami.'),
    GuideFaq('Kenapa hasil kadang dibulatkan?',
        'Perhitungan dilakukan dengan angka desimal presisi, bukan pecahan biner, jadi tidak ada selisih aneh seperti 0,1 + 0,2. Pembulatan hanya dilakukan pada tampilan akhir sesuai pengaturan desimal, dan pada nilai Rupiah.'),
    GuideFaq('Bagaimana cara mengganti format angka?',
        'Buka Pengaturan, lalu pilih Pemisah angka dan Angka desimal.'),
    GuideFaq('Apakah daftar belanja hilang saat aplikasi ditutup?',
        'Tidak. Setiap perubahan langsung tersimpan dan dimuat kembali saat aplikasi dibuka.'),
    GuideFaq('Bagaimana cara melapor masalah atau memberi saran?',
        'Buka Pengaturan, pilih Tentang & Kredit, lalu kirim pesan lewat WhatsApp atau email.'),
  ];
}
