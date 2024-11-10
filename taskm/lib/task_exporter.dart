import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

class TaskExporter {
  // Function to export tasks to CSV
  static void exportTasksToCSV(List<Map<String, dynamic>> tasks) {
    // Define CSV headers
    String csv = 'Title,Description,Due Date,Completed,Repeat Interval\n';

    // Loop through tasks to add each as a CSV row
    for (var task in tasks) {
      String title = task['title'] ?? '';
      String description = task['description'] ?? '';
      String dueDate = task['dueDate'] ?? '';
      String completed = task['isCompleted'] ? 'Yes' : 'No';
      String repeatInterval = task['repeatInterval'] ?? 'None';

      // Format each task entry as a CSV row
      csv += '$title,$description,$dueDate,$completed,$repeatInterval\n';
    }

    // Create a Blob to hold CSV data
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);

    // Generate a download link
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'tasks.csv')
      ..click();

    // Clean up after download
    html.Url.revokeObjectUrl(url);
  }

  // Function to export tasks to JSON
  static void exportTasksToJson(List<Map<String, dynamic>> tasks) {
    // Convert tasks to JSON string format
    String json = jsonEncode(tasks);

    // Create a Blob for JSON data
    final bytes = utf8.encode(json);
    final blob = html.Blob([bytes]);

    // Generate a download link
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'tasks.json')
      ..click();

    // Clean up URL after download
    html.Url.revokeObjectUrl(url);
  }

  // Function to display export options in a dialog
  static void showExportDialog(BuildContext context, List<Map<String, dynamic>> tasks) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Export Tasks'),
          content: Text('Choose export format:'),
          actions: [
            TextButton(
              onPressed: () {
                exportTasksToCSV(tasks);
                Navigator.pop(context); // Close dialog
              },
              child: Text('Export as CSV'),
            ),
            TextButton(
              onPressed: () {
                exportTasksToJson(tasks);
                Navigator.pop(context); // Close dialog
              },
              child: Text('Export as JSON'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cancel export
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
