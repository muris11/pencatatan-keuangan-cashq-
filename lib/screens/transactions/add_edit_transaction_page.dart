import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/transaction_item.dart';
import '../../models/category.dart';

class AddEditTransactionPage extends StatefulWidget {
  final TransactionItem? existing;
  const AddEditTransactionPage({super.key, this.existing});

  @override
  State<AddEditTransactionPage> createState() => _AddEditTransactionPageState();
}

class _AddEditTransactionPageState extends State<AddEditTransactionPage> {
  final _formKey = GlobalKey<FormState>(); // Tambahan untuk form
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  String _category = '';
  TxType _type = TxType.expense;
  final fs = FirestoreService();

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _amount.text = t.amount.toString();
      _notes.text = t.notes ?? '';
      _date = t.date;
      _category = t.category;
      _type = t.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser!.uid;
    final isEditing = widget.existing != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Transaksi' : 'Tambah Transaksi',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: Form(
        // Form pembungkus semua field
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Jenis & Kategori
                  StreamBuilder<List<CategoryItem>>(
                    stream: fs.watchCategories(uid),
                    builder: (context, snap) {
                      final items = snap.data ?? <CategoryItem>[];
                      final names = items.map((e) => e.name).toList();

                      if (_category.isEmpty && names.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _category = names.first);
                        });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<TxType>(
                            value: _type,
                            decoration: _modernInputDecoration(
                              "Jenis",
                              Icons.swap_horiz,
                              isDark,
                              iconColor: Colors.blue,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: TxType.expense,
                                child: Text("Pengeluaran"),
                              ),
                              DropdownMenuItem(
                                value: TxType.income,
                                child: Text("Pemasukan"),
                              ),
                            ],
                            onChanged: (v) => setState(() => _type = v!),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value:
                                names.contains(_category)
                                    ? _category
                                    : (names.isNotEmpty ? names.first : null),
                            decoration: _modernInputDecoration(
                              "Kategori",
                              Icons.category,
                              isDark,
                              iconColor: Colors.deepPurple,
                            ),
                            items:
                                names
                                    .map(
                                      (n) => DropdownMenuItem(
                                        value: n,
                                        child: Text(n),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (v) => setState(() => _category = v ?? ''),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return "Kategori harus dipilih";
                              }
                              return null;
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Nominal
                  TextFormField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: _modernInputDecoration(
                      "Nominal",
                      Icons.attach_money,
                      isDark,
                      iconColor: Colors.green,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Nominal wajib diisi";
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return "Masukkan nominal yang valid (>0)";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Catatan
                  TextFormField(
                    controller: _notes,
                    decoration: _modernInputDecoration(
                      "Catatan",
                      Icons.note_alt,
                      isDark,
                      iconColor: Colors.orangeAccent,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Catatan tidak boleh kosong";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Tanggal
                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color:
                            isDark
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey.shade100,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Tanggal: ${_date.toLocal().toString().substring(0, 10)}",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.edit_calendar, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _validateAndSave(uid);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 6,
                      ),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        "Simpan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Tombol Hapus (hanya saat edit)
                  if (isEditing) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showDeleteTransactionDialog(uid),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 6,
                        ),
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Hapus Transaksi",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _modernInputDecoration(
    String label,
    IconData icon,
    bool isDark, {
    Color? iconColor,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : Colors.grey[700],
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? Colors.blue),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF6366F1),
              onPrimary: Colors.white,
              onSurface: isDark ? Colors.white : Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (d != null) setState(() => _date = d);
  }

  void _validateAndSave(String uid) {
    final value = _amount.text.trim();
    if (value.isEmpty || (int.tryParse(value) ?? 0) <= 0) {
      _showErrorDialog("Masukkan nominal yang valid (>0)");
      return;
    }
    _showSaveTransactionDialog(uid);
  }

  void _showErrorDialog(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Icon(Icons.error, color: Colors.red, size: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Kesalahan",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                      ),
                      child: const Text(
                        "OK",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showSaveTransactionDialog(String uid) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Simpan Transaksi",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Apakah Anda yakin ingin menyimpan transaksi ini?',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                          ),
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await _save();
                          },
                          child: const Text(
                            "Ya",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text(
                            "Tidak",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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

  void _showDeleteTransactionDialog(String uid) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Hapus Transaksi",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Apakah Anda yakin ingin menghapus transaksi ini?',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                          ),
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await fs.deleteTransaction(
                              uid,
                              widget.existing!.id,
                            );
                            if (mounted) Navigator.pop(context);
                          },
                          child: const Text(
                            "Ya",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text(
                            "Tidak",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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

  Future<void> _save() async {
    final uid = AuthService().currentUser!.uid;
    final data = TransactionItem(
      id: widget.existing?.id ?? '',
      amount: int.tryParse(_amount.text.trim()) ?? 0,
      category: _category,
      type: _type,
      date: _date,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    if (widget.existing == null) {
      await fs.addTransaction(uid, data);
    } else {
      await fs.updateTransaction(uid, data);
    }

    if (mounted) Navigator.pop(context);
  }
}
