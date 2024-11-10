import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter/material.dart';

class TaskExporter {
  // Export tasks to PDF
  static Future<void> exportToPDF(List<Map<String, dynamic>> tasks, BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('Task List', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Title', 'Description', 'Due Date', 'Status'],
                data: tasks.map((task) {
                  return [
                    task['title'],
                    task['description'],
                    task['dueDate'],
                    task['isCompleted'] ? 'Completed' : 'Pending',
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/tasks.pdf");
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF exported to ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting PDF: $e')),
      );
    }
  }

  // Export tasks to CSV
  static Future<void> exportToCSV(List<Map<String, dynamic>> tasks, BuildContext context) async {
    List<List<dynamic>> rows = [
      ['Title', 'Description', 'Due Date', 'Status']
    ];

    for (var task in tasks) {
      rows.add([
        task['title'],
        task['description'],
        task['dueDate'],
        task['isCompleted'] ? 'Completed' : 'Pending',
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    try {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/tasks.csv");
      await file.writeAsString(csvData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV exported to ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting CSV: $e')),
      );
    }
  }

  // Export tasks via email
  static Future<void> exportToEmail(List<Map<String, dynamic>> tasks, BuildContext context) async {
    String subject = 'Task List';
    String body = 'Here is the list of tasks:\n\n';

    for (var task in tasks) {
      body += 'Title: ${task['title']}\n';
      body += 'Description: ${task['description']}\n';
      body += 'Due Date: ${task['dueDate']}\n';
      body += 'Status: ${task['isCompleted'] ? 'Completed' : 'Pending'}\n\n';
    }

    final email = Email(
      subject: subject,
      body: body,
      recipients: ['example@example.com'], // Replace with the actual recipient
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending email: $e')),
      );
    }
  }
}
