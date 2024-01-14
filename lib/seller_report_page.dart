// seller_report_page.dart
import 'package:flutter/material.dart';

class SellerReportPage extends StatelessWidget {
  final Map<String, dynamic> sellerData;

  const SellerReportPage({Key? key, required this.sellerData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de vendas'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Center(
                child: Text(
                  sellerData['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
              ),
            ],
          )),
    );
  }
}
