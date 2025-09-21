import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/transaction_item.dart';
import '../../services/export_service.dart';

enum ExportType { month, year }

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final fs = FirestoreService();
  List<TransactionItem> _txs = [];
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
  );

  DateTime _selectedDate = DateTime.now();
  ExportType _exportType = ExportType.month;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Pengguna belum masuk")));
    }
    final uid = user.uid;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 1,
        title: Text(
          'Laporan',
          style: TextStyle(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onBackground),
      ),
      body: StreamBuilder<List<TransactionItem>>(
        stream: fs.watchTransactions(uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return _buildCenteredMessage(
              icon: Icons.error_outline,
              title: "Terjadi Kesalahan",
              subtitle: "Gagal memuat data laporan.",
              color: Colors.red,
            );
          }
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1)),
              ),
            );
          }

          _txs = snap.data ?? [];

          List<TransactionItem> filteredTxs;
          if (_exportType == ExportType.month) {
            filteredTxs =
                _txs
                    .where(
                      (t) =>
                          t.date.year == _selectedDate.year &&
                          t.date.month == _selectedDate.month,
                    )
                    .toList();
          } else {
            filteredTxs =
                _txs.where((t) => t.date.year == _selectedDate.year).toList();
          }

          final byCat = <String, int>{};
          for (final t in filteredTxs.where((t) => t.type == TxType.expense)) {
            byCat[t.category] = (byCat[t.category] ?? 0) + t.amount;
          }
          final total = byCat.values.fold<int>(0, (a, b) => a + b);
          final pie =
              byCat.entries
                  .map(
                    (e) => PieChartSectionData(
                      value: e.value.toDouble(),
                      title:
                          '${e.key}\n${(e.value / (total == 0 ? 1 : total) * 100).toStringAsFixed(0)}%',
                      radius: 60,
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                  )
                  .toList();

          final spots =
              _exportType == ExportType.month
                  ? _buildDailySpots(filteredTxs)
                  : _buildMonthlySpots(filteredTxs);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildExportTypeSelector(),
              const SizedBox(height: 16),

              // Pie chart
              _buildCard(
                title: "Pengeluaran per Kategori",
                child: SizedBox(
                  height: 240,
                  child:
                      pie.isEmpty
                          ? _buildCenteredMessage(
                            icon: Icons.insert_chart_outlined,
                            title: "Tidak ada data pengeluaran",
                            subtitle: "Catat transaksi untuk melihat laporan.",
                            color: theme.hintColor,
                          )
                          : PieChart(
                            PieChartData(
                              sections: pie,
                              centerSpaceRadius: 30,
                              sectionsSpace: 2,
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                ),
              ),

              // Line chart
              _buildCard(
                title:
                    _exportType == ExportType.month
                        ? "Tren Pengeluaran Harian"
                        : "Tren Pengeluaran Bulanan",
                child: Column(
                  children: [
                    if (_exportType == ExportType.month) _buildMonthSelector(),
                    const SizedBox(height: 16),
                    spots.isEmpty
                        ? _buildCenteredMessage(
                          icon: Icons.show_chart,
                          title: "Belum ada data tren",
                          subtitle: "Data pengeluaran masih kosong.",
                          color: theme.hintColor,
                        )
                        : SizedBox(
                          height: 280,
                          child: LineChart(
                            LineChartData(
                              minX: 0,
                              maxX:
                                  (spots.isEmpty ? 0 : spots.length - 1)
                                      .toDouble(),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: const Color(0xFF6366F1),
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                ),
                              ],
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 60,
                                    getTitlesWidget:
                                        (value, meta) => Text(
                                          currencyFormatter.format(value),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                theme.colorScheme.onBackground,
                                          ),
                                        ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval:
                                        _exportType == ExportType.month ? 3 : 1,
                                    getTitlesWidget: (value, meta) {
                                      if (_exportType == ExportType.month) {
                                        return Text(
                                          '${value.toInt() + 1}',
                                          style: TextStyle(
                                            color:
                                                theme.colorScheme.onBackground,
                                            fontSize: 10,
                                          ),
                                        );
                                      }
                                      const months = [
                                        'Jan',
                                        'Feb',
                                        'Mar',
                                        'Apr',
                                        'Mei',
                                        'Jun',
                                        'Jul',
                                        'Agu',
                                        'Sep',
                                        'Okt',
                                        'Nov',
                                        'Des',
                                      ];
                                      final idx = value.toInt();
                                      if (idx >= 0 && idx < 12) {
                                        return Text(
                                          months[idx],
                                          style: TextStyle(
                                            color:
                                                theme.colorScheme.onBackground,
                                            fontSize: 10,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                              ),
                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(
                                  color: theme.dividerColor,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Export PDF button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                ),
                onPressed: _confirmExportPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Ekspor PDF'),
              ),
            ],
          );
        },
      ),
    );
  }

  List<FlSpot> _buildDailySpots(List<TransactionItem> filteredTxs) {
    final monthlyTxs =
        filteredTxs.where((t) => t.type == TxType.expense).toList();
    final daysInMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    return List.generate(daysInMonth, (i) {
      final day = i + 1;
      final dayTotal = monthlyTxs
          .where((t) => t.date.day == day)
          .fold<int>(0, (sum, t) => sum + t.amount);
      return FlSpot(i.toDouble(), dayTotal.toDouble());
    });
  }

  List<FlSpot> _buildMonthlySpots(List<TransactionItem> filteredTxs) {
    return List.generate(12, (i) {
      final month = i + 1;
      final total = filteredTxs
          .where((t) => t.type == TxType.expense && t.date.month == month)
          .fold<int>(0, (sum, t) => sum + t.amount);
      return FlSpot(i.toDouble(), total.toDouble());
    });
  }

  Widget _buildExportTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text("Per Bulan"),
          selected: _exportType == ExportType.month,
          onSelected: (_) => setState(() => _exportType = ExportType.month),
        ),
        const SizedBox(width: 12),
        ChoiceChip(
          label: const Text("Per Tahun"),
          selected: _exportType == ExportType.year,
          onSelected: (_) => setState(() => _exportType = ExportType.year),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          color: theme.colorScheme.onBackground,
          onPressed:
              () => setState(
                () =>
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month - 1,
                      1,
                    ),
              ),
        ),
        Text(
          DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate),
          style: TextStyle(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          color: theme.colorScheme.onBackground,
          onPressed:
              () => setState(
                () =>
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month + 1,
                      1,
                    ),
              ),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCenteredMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    List<TransactionItem> filteredTxs =
        _exportType == ExportType.month
            ? _txs
                .where(
                  (t) =>
                      t.date.year == _selectedDate.year &&
                      t.date.month == _selectedDate.month,
                )
                .toList()
            : _txs.where((t) => t.date.year == _selectedDate.year).toList();

    if (filteredTxs.isEmpty) {
      _showNoDataDialog();
      return;
    }

    final file = await ExportService.exportPdf(
      filteredTxs,
      _selectedDate,
      _exportType,
    );
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> _confirmExportPdf() async {
    final exportLabel =
        _exportType == ExportType.month ? "bulan ini" : "tahun ini";

    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: theme.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    color: Color(0xFFEF4444),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Konfirmasi Ekspor",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Apakah Anda ingin mengekspor laporan transaksi $exportLabel ke PDF?",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.hintColor),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.dividerColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          "Tidak",
                          style: TextStyle(
                            color: theme.colorScheme.onBackground,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await _exportPdf();
                        },
                        child: const Text(
                          "Ya",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showNoDataDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: theme.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "Data Tidak Tersedia",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tidak ada transaksi yang dapat diekspor.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.hintColor),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
