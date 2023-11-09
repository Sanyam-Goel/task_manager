

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
// ignore: library_prefixes
import 'package:pdf/widgets.dart' as pdfWid;
import 'package:printing/printing.dart';

class PDFView extends StatefulWidget {
  const PDFView({
    Key? key,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _PDFViewState createState() => _PDFViewState();
}

class _PDFViewState extends State<PDFView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generate PDF")),
      body: PdfPreview(
        build: (format) => _createPdf(
          format,
        ),
      ),
    );
  }

  Future<Uint8List> _createPdf(
  PdfPageFormat format,
) async {
  final pdf = pdfWid.Document(
    version: PdfVersion.pdf_1_4,
    compress: true,
  );
  pdf.addPage(
    pdfWid.Page(
      pageFormat: PdfPageFormat.standard,
      build: (context) {
        return pdfWid.Center(
          child: pdfWid.Column(
            mainAxisAlignment: pdfWid.MainAxisAlignment.center,
            children: [
              pdfWid.Text(
                "Follow #30FlutterTips",
                style: pdfWid.TextStyle(
                  fontSize: 24,
                  fontWeight: pdfWid.FontWeight.bold,
                ),
              ),
              pdfWid.SizedBox(height: 20),
              pdfWid.Text(
                "Lakshydeep Vikram",
                style: pdfWid.TextStyle(
                  fontSize: 18,
                  fontWeight: pdfWid.FontWeight.bold,
                ),
              ),
              pdfWid.SizedBox(height: 10),
              pdfWid.Text(
                "Follow on Medium, LinkedIn, GitHub",
                style: pdfWid.TextStyle(
                  fontSize: 18,
                  fontWeight: pdfWid.FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  return pdf.save();
}

}