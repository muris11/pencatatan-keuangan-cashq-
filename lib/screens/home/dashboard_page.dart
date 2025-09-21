import 'package:flutter/material.dart';
import 'package:casq1/screens/home/all_transaction_page.dart';
import '../../models/user_profile.dart' show UserProfile;
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/transaction_item.dart';
import '../../utils/formatters.dart';
import '../transactions/add_edit_transaction_page.dart';
import '../categories/categories_page.dart';
import '../reports/reports_page.dart';
import '../profile/profile_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  final fs = FirestoreService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 0;

  final PageController _incomePageController = PageController();
  final PageController _expensePageController = PageController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _incomePageController.dispose();
    _expensePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      const CategoriesPage(),
      const ReportsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditTransactionPage(),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah'),
              elevation: 6,
            )
          : null,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_rounded),
            label: 'Kategori',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_outlined),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profil',
          ),
        ],
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  Widget _buildHomePage() {
    final user = AuthService().currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Jika user null (belum login), tampilkan fallback
    if (user == null) {
      return Center(
        child: Text(
          'User belum login',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Beranda',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<UserProfile>(
        stream: fs.watchUser(user.uid),
        builder: (context, profileSnap) {
          if (profileSnap.hasError) {
            return Center(child: Text('Gagal load profile'));
          }
          if (!profileSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = profileSnap.data!;

          return StreamBuilder<List<TransactionItem>>(
            stream: fs.watchTransactions(user.uid),
            builder: (context, txSnap) {
              if (txSnap.hasError) {
                return Center(child: Text('Gagal load transaksi'));
              }
              if (!txSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final txs = txSnap.data!;
              final incomeTxs = txs.where((t) => t.type == TxType.income).toList();
              final expenseTxs = txs.where((t) => t.type == TxType.expense).toList();

              final incomeTotal = incomeTxs.fold<int>(0, (a, b) => a + b.amount);
              final expenseTotal = expenseTxs.fold<int>(0, (a, b) => a + b.amount);
              final balance = incomeTotal - expenseTotal;

              final Map<String, int> incomeByMonth = {};
              final Map<String, int> expenseByMonth = {};

              for (var t in incomeTxs) {
                final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
                incomeByMonth[key] = (incomeByMonth[key] ?? 0) + t.amount;
              }
              for (var t in expenseTxs) {
                final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
                expenseByMonth[key] = (expenseByMonth[key] ?? 0) + t.amount;
              }

              final recentTxs = [...txs]..sort((a, b) => b.date.compareTo(a.date));
              final topRecent = recentTxs.take(10).toList();

              return RefreshIndicator(
                color: const Color(0xFF6366F1),
                onRefresh: () async => setState(() {}),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 100),
                    children: [
                      _buildWelcomeSection(profile.name, isDark),
                      const SizedBox(height: 24),
                      _buildBalanceCard(balance, isDark),
                      const SizedBox(height: 24),
                      _buildMonthlySummary(
                        'Pemasukan',
                        incomeTotal,
                        incomeByMonth,
                        const Color(0xFF10B981),
                        _incomePageController,
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildMonthlySummary(
                        'Pengeluaran',
                        expenseTotal,
                        expenseByMonth,
                        const Color(0xFFEF4444),
                        _expensePageController,
                        isDark,
                      ),
                      const SizedBox(height: 24),
                      _buildRecentTransactions(context, topRecent, isDark),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Semua method lainnya (_buildWelcomeSection, _buildBalanceCard, _buildMonthlySummary, dll)
  // tetap sama, tapi perbaiki akses map jadi aman:
  // ganti: monthlyData[month]! -> monthlyData[month] ?? 0


  Widget _buildWelcomeSection(String name, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selamat Datang,',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(int balance, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                'Saldo Tersedia',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            idr(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(
    String title,
    int total,
    Map<String, int> monthlyData,
    Color color,
    PageController controller,
    bool isDark,
  ) {
    final months = [
      'Total',
      ...monthlyData.keys.toList()..sort((a, b) => b.compareTo(a)),
    ];

    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: PageView.builder(
                controller: controller,
                itemCount: months.length,
                itemBuilder: (context, index) {
                  final month = months[index];
                  int value;
                  String label;

                  if (month == 'Total') {
                    value = total;
                    label = 'Keseluruhan';
                  } else {
                    value = monthlyData[month]!;
                    final parts = month.split('-');
                    label = '${parts[1]}/${parts[0]}';
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          idr(value),
                          style: TextStyle(
                            color: color,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Bulan: $label',
                          style: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Tombol reset di pojok kanan atas container (total keseluruhan)
            if (total > 0)
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 48,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Reset Transaksi',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Apakah Anda yakin ingin menghapus semua transaksi $title?',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.grey[700],
                                            side: BorderSide(
                                              color: Colors.grey[400]!,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text('Batal'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text('Ya, Hapus'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                    );

                    if (confirm == true) {
                      final userId = AuthService().currentUser!.uid;
                      final type =
                          title.toLowerCase().contains('pemasukan')
                              ? TxType.income
                              : TxType.expense;
                      await fs.deleteAllTransactionsOfType(userId, type);
                      setState(() {});
                    }
                  },
                ),
              ),

          ],
        ),
        const SizedBox(height: 6),
        SmoothPageIndicator(
          controller: controller,
          count: months.length,
          effect: WormEffect(
            activeDotColor: const Color(0xFF6366F1),
            dotColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            dotHeight: 6,
            dotWidth: 6,
          ),
        ),
      ],
    );
  }


  Widget _buildRecentTransactions(
    BuildContext context,
    List<TransactionItem> txs,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaksi Terbaru',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AllTransactionsPage(),
                    ),
                  ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Lihat Semua'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (txs.isEmpty)
          _buildEmptyState(isDark)
        else
          ...txs.map((t) => _buildTransactionTile(context, t, isDark)),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Transaksi',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai catat transaksi pertama Anda',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    TransactionItem t,
    bool isDark,
  ) {
    final isExpense = t.type == TxType.expense;
    final color = isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditTransactionPage(existing: t),
              ),
            ),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isExpense
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.category,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (t.notes != null && t.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      t.notes!,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(t.date),
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isExpense ? '-' : '+'} ${idr(t.amount)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) return 'Hari ini';
    if (targetDate == today.subtract(const Duration(days: 1))) return 'Kemarin';
    return '${date.day}/${date.month}/${date.year}';
  }
}
