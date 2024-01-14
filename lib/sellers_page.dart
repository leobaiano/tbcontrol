import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo_dart;
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
}
