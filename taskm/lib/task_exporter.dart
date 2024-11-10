// task_exporter.dart

import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

class TaskExporter {
  final List<Map<String, dynamic>> tasks;

  TaskExporter(this.tasks);

  // Method to export tasks to CSV
  void exportToCSV() {
    final StringBuffer csvBuffer = StringBuffer();
    csvBuffer.writeln('Title,Description,Due Date,Status');
    for (var task in tasks) {
      String title = task['title'];
      String description = task['description'];
      String dueDate = task['dueDate'];
      String status = task['isCompleted'] ? 'Completed' : 'Pending';

      csvBuffer.writeln('$title,$description,$dueDate,$status');
    }

    final csvData = const Utf8Encoder().convert(csvBuffer.toString());
    final blob = html.Blob([csvData], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "tasks.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // Method to export tasks to PDF
  void exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text("Task List", style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Title: ${task['title']}',
                          style: pw.TextStyle(fontSize: 18)),
                      pw.Text('Description: ${task['description']}'),
                      pw.Text(
                          'Due Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(task['dueDate']))}'),
                      pw.Text('Status: ${task['isCompleted'] ? 'Completed' : 'Pending'}'),
                      pw.Divider(),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "tasks.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // Method to share tasks via email
  void exportToEmail() {
    String emailBody = "Task List:\n\n";
    for (var task in tasks) {
      String title = task['title'];
      String description = task['description'];
      String dueDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(task['dueDate']));
      String status = task['isCompleted'] ? 'Completed' : 'Pending';

      emailBody += "Title: $title\nDescription: $description\nDue Date: $dueDate\nStatus: $status\n\n";
    }

    final emailUri = Uri(
      scheme: 'mailto',
      queryParameters: {
        'subject': 'Exported Task List',
        'body': emailBody,
      },
    );

    html.window.open(emailUri.toString(), '_blank');
  }
}
