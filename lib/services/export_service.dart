import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/transaction_item.dart';
import '../screens/reports/reports_page.dart';

class ExportService {
  static Future<File> exportPdf(
    List<TransactionItem> items,
    DateTime date,
    ExportType exportType,
  ) async {
    final doc = pw.Document();
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    );

    final totalExpense = items
        .where((t) => t.type == TxType.expense)
        .fold<int>(0, (sum, t) => sum + t.amount);

    String title;
    String fileName;

    if (exportType == ExportType.month) {
      final monthName = DateFormat('MMMM yyyy', 'id_ID').format(date);
      title = 'Laporan Transaksi CashQ - $monthName';
      fileName = 'cashq_report_${date.month}_${date.year}.pdf';
    } else {
      final year = date.year;
      title = 'Laporan Transaksi CashQ - Tahun $year';
      fileName = 'cashq_report_${year}.pdf';
    }

    doc.addPage(
      pw.Page(
        build:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  headers: ['Tanggal', 'Tipe', 'Kategori', 'Jumlah', 'Catatan'],
                  data:
                      items.map((t) {
                        return [
                          DateFormat('yyyy-MM-dd').format(t.date),
                          t.type == TxType.expense
                              ? 'Pengeluaran'
                              : 'Pemasukan',
                          t.category,
                          currencyFormatter.format(t.amount),
                          t.notes ?? '',
                        ];
                      }).toList(),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Total Pengeluaran: ${currencyFormatter.format(totalExpense)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file;
  }
}
