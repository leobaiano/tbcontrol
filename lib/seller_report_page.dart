import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo_dart;
import 'mongo_db_service.dart';

class SellerReportPage extends StatelessWidget {
  final Map<String, dynamic> sellerData;
  late final Future<List<Map<String, dynamic>>> deliveries;

  final List<Map<String, dynamic>> payments = [
    {'date': '2022-01-02', 'value': 40.0},
    {'date': '2022-01-06', 'value': 20.0},
  ];

  SellerReportPage({Key? key, required this.sellerData}) : super(key: key) {
    deliveries = _initializeData();
  }

  Future<List<Map<String, dynamic>>> _initializeData() async {
    print(await _getTransactions(sellerData['_id']));
    return await _getTransactions(sellerData['_id']);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: deliveries,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Erro: ${snapshot.error}');
        } else {
          double totalDeliveries = snapshot.data!.fold(0, (sum, delivery) {
            var amount = delivery['amount'];
            if (amount != null) {
              if (amount is num) {
                return sum + amount;
              } else if (amount is String) {
                var parsedAmount = double.tryParse(amount);
                return sum + (parsedAmount ?? 0);
              } else {
                return sum;
              }
            } else {
              return sum;
            }
          });

          double totalPayments =
              payments.fold(0, (sum, payment) => sum + payment['value']);

          double totalDue = totalDeliveries - totalPayments;

          TextStyle textStyleStatus;
          String statusDoDebito = 'Não está devendo nada.';

          if (totalDue > 0) {
            statusDoDebito =
                'Está devendo: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(totalDue)}.';

            textStyleStatus = const TextStyle(
              fontSize: 18,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            );
          } else {
            textStyleStatus = const TextStyle(
              fontSize: 18,
              color: Colors.black,
            );
          }

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
                  const SizedBox(height: 8),
                  Text(
                    statusDoDebito,
                    style: textStyleStatus,
                  ),
                  const Divider(thickness: 2),
                  const SizedBox(height: 16),
                  const Text(
                    'Entregas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  _buildDataTable(snapshot.data!),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> deliveries) {
    double totalAmount = 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(
            label: SizedBox(
              child: Text('Data'),
            ),
          ),
          DataColumn(
            label: SizedBox(
              child: Text('Produto'),
            ),
          ),
          DataColumn(
            label: SizedBox(
              child: Text('Quantidade'),
            ),
          ),
          DataColumn(
            label: SizedBox(
              child: Text('Valor'),
            ),
          ),
        ],
        rows: deliveries.map((entry) {
          totalAmount += entry['amount'] ?? 0;

          return DataRow(
            cells: [
              DataCell(_buildCellText(
                  DateFormat('dd/MM/yyyy').format(entry['date']))),
              DataCell(_buildCellText(entry['product'].toString())),
              DataCell(_buildCellText(entry['quantity'].toString())),
              DataCell(_buildCellText(
                entry['amount'] != null
                    ? NumberFormat.currency(
                        locale: 'pt_BR',
                        symbol: 'R\$',
                      ).format(entry['amount'])
                    : 'N/A', // Ou qualquer valor padrão que você deseja exibir para nulo
              )),
            ],
          );
        }).toList()
          ..add(DataRow(
            cells: [
              const DataCell(Text(
                'Total:',
                style: TextStyle(fontWeight: FontWeight.bold),
              )),
              DataCell(SizedBox.shrink()),
              DataCell(SizedBox.shrink()),
              DataCell(
                Text(
                    NumberFormat.currency(
                      locale: 'pt_BR',
                      symbol: 'R\$',
                    ).format(totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          )),
      ),
    );
  }

  Widget _buildCellText(String text) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getTransactions(sellerId) async {
    try {
      DBConnection dbConnection = DBConnection.getInstance();
      mongo_dart.Db db = await dbConnection.getConnection();

      var transactionsCollection = db.collection('transactions');

      var transactions = await transactionsCollection
          .find(
            mongo_dart.where.eq('user_id', sellerId),
          )
          .toList();

      List<Map<String, dynamic>> formattedTransactions = [];

      if (transactions != null) {
        for (var transaction in transactions) {
          var productName = await _getProductName(transaction['product_id']);
          var formattedTransaction = {
            'date': transaction['created_at'],
            'product': productName,
            'quantity': transaction['quantity'],
            'amount': transaction['amount'],
          };

          formattedTransactions.add(formattedTransaction);
        }

        return formattedTransactions;
      }

      return [];
    } catch (e) {
      print('Erro ao consultar transações: $e');
      return [];
    }
  }

  Future<String> _getProductName(productId) async {
    try {
      DBConnection dbConnection = DBConnection.getInstance();
      mongo_dart.Db db = await dbConnection.getConnection();

      var transactionsCollection = db.collection('products');

      var product = await transactionsCollection.findOne(
        mongo_dart.where.eq('_id', productId),
      );

      if (product != null) {
        return product['name'];
      }

      return '-';
    } catch (e) {
      print('Erro ao consultar o produto: $e');
      return '-';
    }
  }
}
