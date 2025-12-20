import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ExportService {
  static Future<void> exportToPdf({
    required String title,
    required Map<String, dynamic> details,
    required double totalPremium,
  }) async {
    final pdf = pw.Document();
    final date = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Quick Insure',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red900,
                      ),
                    ),
                    pw.Text(date, style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 2, color: PdfColors.red900),
                pw.SizedBox(height: 30),
                pw.Text(
                  'Insurance Premium Receipt',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Type: $title', style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 40),
                pw.Text(
                  'Calculation Details',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headers: ['Description', 'Value'],
                  data: details.entries
                      .map((e) => [e.key, e.value.toString()])
                      .toList(),
                ),
                pw.SizedBox(height: 40),
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Premium',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'BDT ${NumberFormat("#,##0", "en_US").format(totalPremium)}',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red900,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Generated via Quick Insure App',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${title.replaceAll(' ', '_')}_Premium.pdf',
    );
  }
}
