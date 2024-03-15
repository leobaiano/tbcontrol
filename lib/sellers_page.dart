import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo_dart;
import 'package:tbcontrol/all_report_page.dart';
import 'package:tbcontrol/custom_drawer.dart';
import 'mongo_db_service.dart';
import 'package:tbcontrol/user_data.dart';
import 'seller_report_page.dart';

class SellersPage extends StatefulWidget {
  final UserData userData;

  const SellersPage({Key? key, required this.userData}) : super(key: key);

  @override
  _SellersPageState createState() => _SellersPageState();
}

class _SellersPageState extends State<SellersPage> {
  List<Map<String, dynamic>> sellers = [];

  @override
  void initState() {
    super.initState();
    _loadSellers();
    _calculateTotalSaldo();
  }

  double totalSaldo = 0;

  Future<void> _calculateTotalSaldo() async {
    try {
      DBConnection dbConnection = DBConnection.getInstance();
      mongo_dart.Db db = await dbConnection.getConnection();

      var transactionsCollection = db.collection('transactions');

      double total = 0;

      DateTime hoje = DateTime.now();
      DateTime inicioDoDia = DateTime(hoje.year, hoje.month, hoje.day);
      DateTime finalDoDia = inicioDoDia
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      var vendas = await transactionsCollection
          .find(mongo_dart.where
              .eq('type', 'Venda')
              .and(mongo_dart.where.gte('created_at', inicioDoDia))
              .and(mongo_dart.where.lte('created_at', finalDoDia)))
          .toList();

      for (var venda in vendas) {
        total += venda['amount'];
      }

      setState(() {
        totalSaldo = total;
      });
    } catch (e) {
      print('Erro ao calcular saldo total: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendedores'),
      ),
      drawer: CustomDrawer(
        userData: widget.userData,
        onMenuTap: () {
          Navigator.pop(context);
        },
        nomeUsuario: '',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () {
                _abrirRelatorioGeral();
              },
              child: Container(
                width: 100,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.attach_money,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$totalSaldo saldo do dia', // Substitua pelo valor real
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: sellers.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sellers[index]['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () {
                                  _viewSeller(index);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSellers() async {
    try {
      DBConnection dbConnection = DBConnection.getInstance();
      mongo_dart.Db db = await dbConnection.getConnection();

      var collection = db.collection('users');

      var allSellers = await collection
          .find(mongo_dart.where.eq('role', 'Vendedor'))
          .toList();

      setState(() {
        sellers = allSellers;
      });
    } catch (e) {
      print('Erro ao carregar usuários: $e');
      // TODO: Adicionar lógica de tratamento de erro
    }
  }

  Future<void> _viewSeller(int index) async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SellerReportPage(sellerData: sellers[index]),
        ),
      );
    } catch (e) {
      print('Erro ao abrir a página do relatório: $e');
    }
  }

  Future<void> _abrirRelatorioGeral() async {
    Map<String, dynamic> seller = {
      '_id': widget.userData.id,
      'name': widget.userData.nome,
      'role': widget.userData.cargo
    };
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AllReportPage(sellerData: seller),
        ),
      );
    } catch (e) {
      print('Erro ao abrir a página do relatório: $e');
    }
  }
}
