class L10n {
  final String code; // 'id' or 'en'
  L10n(this.code);
  bool get isID => code == 'id';

  String get appName => 'CashQ';
  String get tagline =>
      isID
          ? 'Kelola Uangmu, Hidup Lebih Tenang'
          : 'Smart Finance for Smart Living';
  String get login => isID ? 'Masuk' : 'Login';
  String get register => isID ? 'Daftar' : 'Register';
  String get email => 'Email';
  String get password => isID ? 'Kata sandi' : 'Password';
  String get forgotPassword => isID ? 'Lupa kata sandi?' : 'Forgot password?';
  String get googleSignIn =>
      isID ? 'Masuk dengan Google' : 'Sign in with Google';
  String get logout => isID ? 'Keluar' : 'Logout';
  String get dashboard => isID ? 'Beranda' : 'Dashboard';
  String get transactions => isID ? 'Transaksi' : 'Transactions';
  String get categories => isID ? 'Kategori' : 'Categories';
  String get reports => isID ? 'Laporan' : 'Reports';
  String get profile => isID ? 'Profil' : 'Profile';
  String get income => isID ? 'Pendapatan' : 'Income';
  String get expense => isID ? 'Pengeluaran' : 'Expense';
  String get amount => isID ? 'Nominal' : 'Amount';
  String get notes => isID ? 'Catatan' : 'Notes';
  String get save => isID ? 'Simpan' : 'Save';
  String get delete => isID ? 'Hapus' : 'Delete';
  String get edit => isID ? 'Ubah' : 'Edit';
  String get add => isID ? 'Tambah' : 'Add';
  String get monthlyBudget => isID ? 'Budget Bulanan' : 'Monthly Budget';
  String get language => isID ? 'Bahasa' : 'Language';
  String get theme => isID ? 'Tema' : 'Theme';
}
