import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

// Export tasks to CSV
void exportToCSV(List<Map<String, dynamic>> tasks) {
  List<List<dynamic>> rows = [];
  rows.add(['ID', 'Title', 'Description', 'Due Date', 'Completed', 'Repeating']); // CSV headers

  tasks.forEach((task) {
    rows.add([
      task['id'],
      task['title'],
      task['description'],
      task['dueDate'],
      task['isCompleted'] ? 'Yes' : 'No',
      task['repeatInterval']
    ]);
  });

  String csvData = const ListToCsvConverter().convert(rows);
  final blob = html.Blob([csvData]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..target = 'blank'
    ..download = 'tasks.csv'
    ..click();
  html.Url.revokeObjectUrl(url);
}

// Export tasks to PDF
void exportToPDF(List<Map<String, dynamic>> tasks) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Text('Task List', style: pw.TextStyle(fontSize: 24)),
            pw.Table.fromTextArray(headers: ['ID', 'Title', 'Description', 'Due Date', 'Completed', 'Repeating'],
              data: tasks.map((task) {
                return [
                  task['id'],
                  task['title'],
                  task['description'],
                  task['dueDate'],
                  task['isCompleted'] ? 'Yes' : 'No',
                  task['repeatInterval'],
                ];
              }).toList(),
            ),
          ],
        );
      },
    ),
  );

  final output = await pdf.save();
  final blob = html.Blob([output]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..target = 'blank'
    ..download = 'tasks.pdf'
    ..click();
  html.Url.revokeObjectUrl(url);
}

// Export tasks via Email
Future<void> exportViaEmail(List<Map<String, dynamic>> tasks, String recipientEmail) async {
  final smtpServer = gmail('your_email@gmail.com', 'your_password'); // Use environment variables for security
  final message = Message()
    ..from = Address('your_email@gmail.com', 'Task Manager')
    ..recipients.add(recipientEmail)
    ..subject = 'Task Export'
    ..text = 'Please find the attached task list.';

  final csvData = const ListToCsvConverter().convert([
    ['ID', 'Title', 'Description', 'Due Date', 'Completed', 'Repeating'],
    ...tasks.map((task) => [
      task['id'],
      task['title'],
      task['description'],
      task['dueDate'],
      task['isCompleted'] ? 'Yes' : 'No',
      task['repeatInterval']
    ])
  ]);
  
  final attachment = Attachment.fromBytes('tasks.csv', utf8.encode(csvData));
  message.attachments.add(attachment);

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: ' + sendReport.toString());
  } on MailerException catch (e) {
    print('Message not sent. Exception: ' + e.toString());
  }
}
