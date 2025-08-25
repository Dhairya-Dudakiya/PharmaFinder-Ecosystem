import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

class CsvRow {
  final int rowNumber;
  final Map<String, dynamic> data;
  String? errorMessage;

  CsvRow({required this.rowNumber, required this.data, this.errorMessage});
}

class BulkUploadViewModel extends ChangeNotifier {
  List<CsvRow> _parsedRows = [];
  List<CsvRow> get parsedRows => _parsedRows;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _fileName;
  String? get fileName => _fileName;

  int get validRowCount =>
      _parsedRows.where((row) => row.errorMessage == null).length;
  int get errorRowCount =>
      _parsedRows.where((row) => row.errorMessage != null).length;

  Future<void> pickAndParseCsv() async {
    _isLoading = true;
    _parsedRows = [];
    _fileName = null;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.bytes != null) {
        _fileName = result.files.single.name;
        final bytes = result.files.single.bytes!;
        final csvString = utf8.decode(bytes);

        final List<List<dynamic>> csvTable = const CsvToListConverter().convert(
          csvString,
        );

        if (csvTable.length < 2) {
          throw Exception(
            "CSV file must have a header row and at least one data row.",
          );
        }

        final header = csvTable[0].map((h) => h.toString().trim()).toList();

        for (int i = 1; i < csvTable.length; i++) {
          final row = csvTable[i];
          final rowData = <String, dynamic>{};
          for (int j = 0; j < header.length; j++) {
            rowData[header[j]] = row.length > j ? row[j] : null;
          }
          _parsedRows.add(CsvRow(rowNumber: i + 1, data: rowData));
        }
        _validateRows();
      }
    } catch (e) {
      _parsedRows = [
        CsvRow(
          rowNumber: 1,
          data: {},
          errorMessage: "Error parsing file: ${e.toString()}",
        ),
      ];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _validateRows() {
    for (var row in _parsedRows) {
      if (row.data['id'] == null || row.data['id'].toString().isEmpty) {
        row.errorMessage = "Missing 'id'";
      } else if (row.data['name'] == null ||
          row.data['name'].toString().isEmpty) {
        row.errorMessage = "Missing 'name'";
      } else if (double.tryParse(row.data['price']?.toString() ?? '') == null) {
        row.errorMessage = "Invalid 'price'";
      } else {
        row.errorMessage = null; // Row is valid
      }
    }
  }

  Future<String> uploadValidMedicines() async {
    _isLoading = true;
    notifyListeners();

    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      if (adminId == null) throw Exception("Admin not logged in.");

      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminId)
          .get();
      final storeName = doc.data()?['storeName'];
      if (storeName == null)
        throw Exception("Could not find admin's store name.");

      final validMedicines = _parsedRows.where(
        (row) => row.errorMessage == null,
      );
      if (validMedicines.isEmpty)
        throw Exception("No valid medicines to upload.");

      // Prepare a batch update for the Realtime Database
      final Map<String, dynamic> updates = {};
      for (var row in validMedicines) {
        final medId = row.data['id'].toString();
        final medicineData = {
          'name': row.data['name'],
          'price': double.parse(row.data['price'].toString()),
          'category': row.data['category'] ?? 'Uncategorized',
          'dosage': row.data['dosage'] ?? '',
          'manufacturer': row.data['manufacturer'] ?? '',
          'description': row.data['description'] ?? '',
          'requiresPrescription':
              (row.data['requiresPrescription']?.toString().toLowerCase() ==
              'true'),
        };
        updates['/medicines/$storeName/$medId'] = medicineData;
      }

      await FirebaseDatabase.instance.ref().update(updates);
      return "Successfully uploaded $validRowCount medicines.";
    } catch (e) {
      return "Upload failed: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class BulkUploadScreen extends StatelessWidget {
  const BulkUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BulkUploadViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bulk Upload Inventory'),
          backgroundColor: Colors.teal,
        ),
        body: Consumer<BulkUploadViewModel>(
          builder: (context, viewModel, child) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.file_upload_outlined),
                        label: const Text('Select CSV File'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: viewModel.isLoading
                            ? null
                            : viewModel.pickAndParseCsv,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Template columns: id, name, price, category, dosage, manufacturer, description, requiresPrescription (true/false)',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (viewModel.isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),

                if (viewModel.parsedRows.isNotEmpty && !viewModel.isLoading)
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Preview: ${viewModel.fileName ?? ''}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: _buildPreviewList(viewModel.parsedRows),
                        ),
                        _buildSummaryAndUploadButton(context, viewModel),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPreviewList(List<CsvRow> rows) {
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final bool hasError = row.errorMessage != null;
        return Card(
          color: hasError ? Colors.red.shade50 : Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: hasError ? Colors.red : Colors.teal,
              child: Text(
                row.rowNumber.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(row.data['name']?.toString() ?? 'No Name'),
            subtitle: hasError
                ? Text(
                    "Error: ${row.errorMessage!}",
                    style: const TextStyle(color: Colors.red),
                  )
                : Text("ID: ${row.data['id']} | Price: ₹${row.data['price']}"),
          ),
        );
      },
    );
  }

  Widget _buildSummaryAndUploadButton(
    BuildContext context,
    BulkUploadViewModel viewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                "Valid: ${viewModel.validRowCount}",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Errors: ${viewModel.errorRowCount}",
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: viewModel.validRowCount > 0
                ? () async {
                    final result = await viewModel.uploadValidMedicines();
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(result)));
                      Navigator.pop(context);
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text(
              'Upload Valid Items',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
