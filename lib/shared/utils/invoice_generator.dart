import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/order_model.dart';

class InvoiceGenerator {
  static Future<Uint8List> generateInvoice(OrderModel order) async {
    final pdf = pw.Document();
    final currencyFormatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2, locale: 'en_IN');
    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('NAMKEEN WHOLESALE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Billed To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                    pw.Text(order.shopName.isNotEmpty ? order.shopName : order.retailerName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text(order.retailerName),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Order ID: ${order.id}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${dateFormatter.format(order.date)}'),
                    pw.Text('Status: ${order.status.name.toUpperCase()}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 32),
            pw.Table.fromTextArray(
              context: context,
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellAlignment: pw.Alignment.centerRight,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
              },
              headers: ['Item Description', 'Qty', 'Unit Price', 'Total'],
              data: [
                ...order.items.map((item) => [
                  item.product.name,
                  '${item.quantity} ${item.product.unit}',
                  currencyFormatter.format(item.product.price),
                  currencyFormatter.format(item.total),
                ]),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 200,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Divider(color: PdfColors.grey400),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Grand Total:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.Text(currencyFormatter.format(order.grandTotal), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 48),
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }
}
