import 'dart:html' as html;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart'; // For CSV export

class TaskExporter {
  // Export tasks to PDF
  static Future<void> exportToPDF(List<Map<String, dynamic>> tasks, BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              var task = tasks[index];
              return pw.Text('Task: ${task['title']} - Due: ${task['dueDate']}');
            },
          );
        },
      ),
    );

    // Save PDF to file (Web-specific behavior)
    final file = await html.Blob([pdf.save()]);
    final fileUrl = html.Url.createObjectUrlFromBlob(file);
    final anchor = html.AnchorElement(href: fileUrl)
      ..target = 'blank'
      ..download = 'tasks.pdf'
      ..click();
  }

  // Export tasks to CSV
  static Future<void> exportToCSV(List<Map<String, dynamic>> tasks, BuildContext context) async {
    List<List<String>> rows = [
      ['Title', 'Description', 'Due Date', 'Completed'],
    ];

    for (var task in tasks) {
      rows.add([
        task['title'],
        task['description'],
        task['dueDate'],
        task['isCompleted'] ? 'Yes' : 'No',
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final blob = html.Blob([csvData]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = 'tasks.csv'
      ..click();
  }

  // Export tasks via Email
  static Future<void> exportToEmail(List<Map<String, dynamic>> tasks, BuildContext context) async {
    String subject = 'Task List';
    String body = '';

    for (var task in tasks) {
      body += 'Task: ${task['title']}\nDue: ${task['dueDate']}\nDescription: ${task['description']}\n\n';
    }

    final mailtoUrl = Uri.encodeFull('mailto:?subject=$subject&body=$body');
    html.window.open(mailtoUrl, '_blank');
  }
}
