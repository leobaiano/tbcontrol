import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo_dart;
import 'mongo_db_service.dart';

class AllReportPage extends StatefulWidget {
  final Map<String, dynamic> sellerData;

  AllReportPage({Key? key, required this.sellerData}) : super(key: key);

  @override
  _SellerReportPageState createState() => _SellerReportPageState();
}

class _SellerReportPageState extends State<AllReportPage> {
  late DateTime startDate = DateTime.now();
  late DateTime endDate = DateTime.now();
  late List<Map<String, dynamic>> salesData = [];

  @override
  void initState() {
    super.initState();
    _filterTransactions(startDate, endDate); // Filtro inicial com o dia atual
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de vendas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.paid),
            onPressed: () {
              // _addPayment(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Text(
                widget.sellerData['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Filtrar por Período:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: DateFormat('dd/MM/yyyy').format(startDate),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Início',
                    ),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );

                      if (pickedDate != null) {
                        setState(() {
                          startDate = pickedDate;
                        });
                        _filterTransactions(startDate, endDate);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: DateFormat('dd/MM/yyyy').format(endDate),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Fim',
                    ),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );

                      if (pickedDate != null) {
                        setState(() {
                          endDate = pickedDate;
                        });
                        _filterTransactions(startDate, endDate);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    _filterTransactions(startDate, endDate);
                  },
                  child: const Text('Filtrar'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Vendas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            _buildDataTable(salesData),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> data) {
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
        rows: data.map((entry) {
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
                    : 'N/A',
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
              const DataCell(SizedBox.shrink()),
              const DataCell(SizedBox.shrink()),
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

  void _filterTransactions(DateTime startDate, DateTime endDate) async {
    try {
      mongo_dart.ObjectId sellerId = widget.sellerData['_id'];
      String type = 'Venda';

      List<Map<String, dynamic>> filteredSales = await _getTransactions(
        type,
        startDate,
        endDate,
      );

      setState(() {
        salesData = filteredSales;
      });
    } catch (e) {
      print('Erro ao filtrar transações: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getTransactions(
      type, DateTime startDate, DateTime endDate) async {
    try {
      DBConnection dbConnection = DBConnection.getInstance();
      mongo_dart.Db db = await dbConnection.getConnection();

      var transactionsCollection = db.collection('transactions');

      var transactions = await transactionsCollection
          .find(mongo_dart.where
              .eq('type', 'Venda')
              .and(mongo_dart.where.gte('created_at', startDate))
              .and(mongo_dart.where.lte('created_at', endDate)))
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
