import 'dart:typed_data';

import 'package:html/parser.dart' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Renders server receipt HTML and sends it to the system printer.
class ReceiptPrinter {
  static Future<void> printReceiptHtml(String htmlContent) async {
    final parsed = html.parse(htmlContent);
    final bodyText = parsed.body?.text.trim() ?? '';
    final receiptLines = bodyText
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (receiptLines.isEmpty) {
      throw StateError('Receipt has no printable content.');
    }

    Future<Uint8List> buildPdf(PdfPageFormat format) async {
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final line in receiptLines)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    line,
                    style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.2),
                  ),
                ),
            ],
          ),
        ),
      );
      return doc.save();
    }

    final printers = await Printing.listPrinters();
    if (printers.isNotEmpty) {
      await Printing.directPrintPdf(
        printer: printers.first,
        onLayout: buildPdf,
        format: PdfPageFormat.roll80,
      );
      return;
    }

    await Printing.layoutPdf(
      onLayout: buildPdf,
      format: PdfPageFormat.roll80,
    );
  }
}
