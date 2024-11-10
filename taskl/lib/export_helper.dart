import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart'; // For DateFormat

// Task model definition
class Task {
  final String title;
  final String description;
  final DateTime date;
  bool isFavorite;
  bool isRepeated;

  Task({
    required this.title,
    required this.description,
    required this.date,
    this.isFavorite = false,
    this.isRepeated = false,
  });
}

class ExportHelper {
  // Export tasks to CSV
  static Future<void> exportToCSV(List<Task> tasks) async {
    List<List<dynamic>> rows = [];
    
    // Add headers for CSV
    rows.add(['Title', 'Description', 'Date', 'Is Favorite', 'Is Repeated']);
    
    // Add task details to rows
    for (var task in tasks) {
      rows.add([
        task.title,
        task.description,
        DateFormat('yyyy-MM-dd – kk:mm').format(task.date),  // Correct date formatting
        task.isFavorite ? 'Yes' : 'No',
        task.isRepeated ? 'Yes' : 'No',
      ]);
    }

    // Convert rows to CSV string
    String csv = const ListToCsvConverter().convert(rows);
    
    // Get the directory to save the file
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File('$path/tasks.csv');
    
    // Write the CSV string to the file
    await file.writeAsString(csv);
    
    // Optionally, open the file
    OpenFile.open(file.path);
  }

  // Export tasks to PDF
  static Future<void> exportToPDF(List<Task> tasks) async {
    final pdf = pw.Document();
    
    // Add a page to the PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(
                'Task List',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              ...tasks.map((task) {
                return pw.Column(
                  children: [
                    pw.Text('Title: ${task.title}'),
                    pw.Text('Description: ${task.description}'),
                    pw.Text('Date: ${DateFormat('yyyy-MM-dd – kk:mm').format(task.date)}'),
                    pw.Text('Favorite: ${task.isFavorite ? "Yes" : "No"}'),
                    pw.Text('Repeated: ${task.isRepeated ? "Yes" : "No"}'),
                    pw.Divider(),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );

    // Save the PDF file
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/tasks.pdf');

    // Write the PDF to file
    await file.writeAsBytes(await pdf.save());

    // Optionally, open the PDF file
    OpenFile.open(file.path);
  }
}
