// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison
// -*- coding: utf-8 -*-

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo_dart;
import 'package:tbcontrol/custom_drawer.dart';
import 'mongo_db_service.dart';
import 'package:tbcontrol/user_data.dart';

import 'seller_report_page.dart';

class SellerPage extends StatefulWidget {
  final UserData userData;

  const SellerPage({Key? key, required this.userData}) : super(key: key);

  @override
  _SellerPageState createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  List<Map<String, dynamic>> produtos = []; // Lista para armazenar os produtos
  double saldo = 0;

  @override
  void initState() {
    super.initState();

    _carregarProdutos(widget.userData.id);
    _calcularSaldo(widget.userData.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [],
      ),
      drawer: CustomDrawer(
        userData: widget.userData,
        onMenuTap: () {
          // Lógica para lidar com o toque no ícone do menu
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
                // Adicione a lógica da função que você deseja chamar aqui
                _abrirRelatorio();
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
                      '$saldo saldo do dia', // Substitua pelo valor real
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
            Container(
              alignment: Alignment.center,
              child: const Text(
                'Produtos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: produtos.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // Coluna da esquerda
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  produtos[index]['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${produtos[index]['quantity'].toInt()} Itens no valor de R\$ ${produtos[index]['value']} cada.',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: () {
                                  _venderProduto(index, widget.userData.id);
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

  Future<void> _calcularSaldo(mongo_dart.ObjectId sellerId) async {
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
              .eq('user_id', sellerId)
              .and(mongo_dart.where.eq('type', 'Venda'))
              .and(mongo_dart.where.gte('created_at', inicioDoDia))
              .and(mongo_dart.where.lte('created_at', finalDoDia)))
          .toList();

      for (var venda in vendas) {
        total += venda['amount'];
      }

      setState(() {
        saldo = total;
      });
    } catch (e) {
      print('Erro ao carregar saldo: $e');
    }
  }

  Future<void> _carregarProdutos(mongo_dart.ObjectId sellerId) async {
    try {
      var entregas = await _entregas(sellerId);
      var vendas = await _vendas(sellerId);

      int totalEntregas = entregas.length;
      int totalVendas = vendas.length;

      List<Map<String, dynamic>> produtosDisponiveis = [];
      if (totalEntregas >= totalVendas) {
        for (var itemEntrega in entregas) {
          var vendaCorrespondente = vendas.firstWhere(
              (itemVenda) =>
                  itemVenda['product_id'] == itemEntrega['product_id'],
              orElse: () => {});

          if (vendaCorrespondente.isNotEmpty) {
            double amountEntrega =
                double.parse((itemEntrega['amount'] ?? 0).toString());
            double quantityEntrega =
                double.parse((itemEntrega['quantity'] ?? 0).toString());

            double amountVenda =
                double.parse((vendaCorrespondente['amount'] ?? 0).toString());
            double quantityVenda =
                double.parse((vendaCorrespondente['quantity'] ?? 0).toString());

            itemEntrega['amount'] = amountEntrega - amountVenda;
            itemEntrega['quantity'] = quantityEntrega - quantityVenda;

            produtosDisponiveis.add(Map<String, dynamic>.from(itemEntrega));
          } else {
            produtosDisponiveis.add(Map<String, dynamic>.from(itemEntrega));
          }
        }
      } else {
        for (var itemVenda in vendas) {
          var entregaCorrespondente = entregas.firstWhere(
              (itemEntrega) =>
                  itemEntrega['product_id'] == itemVenda['product_id'],
              orElse: () => {});

          if (entregaCorrespondente.isNotEmpty) {
            double amountEntrega =
                double.parse((itemVenda['amount'] ?? 0).toString());
            double quantityEntrega =
                double.parse((itemVenda['quantity'] ?? 0).toString());

            double amountVenda =
                double.parse((entregaCorrespondente['amount'] ?? 0).toString());
            double quantityVenda = double.parse(
                (entregaCorrespondente['quantity'] ?? 0).toString());

            itemVenda['amount'] = amountEntrega - amountVenda;

            itemVenda['quantity'] = quantityEntrega - quantityVenda;

            produtosDisponiveis.add(Map<String, dynamic>.from(itemVenda));
          } else {
            produtosDisponiveis.add(Map<String, dynamic>.from(itemVenda));
          }
        }
      }

      await _criarListaDeProdutos(produtosDisponiveis).then((allProdutos) {
        setState(() {
          produtos = allProdutos;
        });
      });
    } catch (e) {
      print('Erro ao carregar produtos: $e');
    }
  }

  Future<void> _venderProduto(int index, mongo_dart.ObjectId sellerId) async {
    TextEditingController quantidadeController = TextEditingController();

    try {
      var result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enviar Produto'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: quantidadeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      );

      if (result == true) {
        await _registrarVenda(
          index,
          sellerId,
          quantidadeController.text,
        );
      }
    } catch (e) {
      print('Erro ao carregar vendedores: $e');
    }
  }

  Future<void> _registrarVenda(
      int index, mongo_dart.ObjectId vendedorId, String quantidade) async {
    try {
      DBConnection dbConnection = DBConnection.getInstance();
      mongo_dart.Db db = await dbConnection.getConnection();

      var transactionsCollection = db.collection('transactions');

      // double amountEntrega =
      //           double.parse((itemEntrega['amount'] ?? 0).toString());

      double quantidadeDouble = double.parse(quantidade);
      double produtoValue = double.parse(produtos[index]['value'].toString());

      double total = quantidadeDouble * produtoValue;

      await transactionsCollection.insertOne({
        'user_id': vendedorId,
        'product_id': produtos[index]['_id'],
        'quantity': int.parse(quantidade),
        'unit_value': produtos[index]['value'],
        'amount': total,
        'type': 'Venda',
        'created_at': DateTime.now().toLocal(),
      });

      Fluttertoast.showToast(
        msg: 'Venda realizada com sucesso!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      await _carregarProdutos(vendedorId);
      await _calcularSaldo(vendedorId);
    } catch (e) {
      print('Erro ao enviar produto: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _criarListaDeProdutos(
      List<Map<String, dynamic>> produtos) async {
    List<Map<String, dynamic>> produtosFormatados = [];

    for (var itemProduto in produtos) {
      var name = await _pegarNomeDoProduto(itemProduto['product_id']);

      produtosFormatados.add({
        '_id': itemProduto['product_id'],
        'name': name,
        "quantity": itemProduto['quantity'],
        "value": itemProduto['unit_value']
      });
    }

    return produtosFormatados;
  }

  Future<String> _pegarNomeDoProduto(mongo_dart.ObjectId productId) async {
    DBConnection dbConnection = DBConnection.getInstance();
    mongo_dart.Db db = await dbConnection.getConnection();
    var productsCollection = db.collection('products');

    var produto = await productsCollection.findOne(
      mongo_dart.where.eq('_id', productId),
    );

    if (produto != null) {
      return produto["name"] as String;
    }

    return '';
  }

  Future<List<Map<String, dynamic>>> _entregas(
      mongo_dart.ObjectId sellerId) async {
    DBConnection dbConnection = DBConnection.getInstance();
    mongo_dart.Db db = await dbConnection.getConnection();
    var transactionsCollection = db.collection('transactions');

    var entregas = await transactionsCollection
        .find(mongo_dart.where
            .eq('user_id', sellerId)
            .and(mongo_dart.where.eq('type', 'Entrega')))
        .toList();

    List<Map<String, dynamic>> entregasUnicas = [];
    for (var itemEntrega in entregas) {
      var itemExistente = entregasUnicas.firstWhere(
        (entrega) => entrega['product_id'] == itemEntrega['product_id'],
        orElse: () => <String, dynamic>{},
      );

      if (itemExistente.isNotEmpty) {
        // Se existe, atualiza o valor da propriedade 'amount'
        itemExistente['amount'] =
            (itemExistente['amount'] ?? 0) + itemEntrega['amount'];

        itemExistente['quantity'] =
            (itemExistente['quantity'] ?? 0) + itemEntrega['quantity'];
      } else {
        // Se não existe, adiciona o item inteiro em entregasUnicas
        entregasUnicas.add(Map<String, dynamic>.from(itemEntrega));
      }
    }

    return entregasUnicas;
  }

  Future<List<Map<String, dynamic>>> _vendas(
      mongo_dart.ObjectId sellerId) async {
    DBConnection dbConnection = DBConnection.getInstance();
    mongo_dart.Db db = await dbConnection.getConnection();
    var transactionsCollection = db.collection('transactions');

    var entregas = await transactionsCollection
        .find(mongo_dart.where
            .eq('user_id', sellerId)
            .and(mongo_dart.where.eq('type', 'Venda')))
        .toList();

    List<Map<String, dynamic>> entregasUnicas = [];
    for (var itemEntrega in entregas) {
      var itemExistente = entregasUnicas.firstWhere(
        (entrega) => entrega['product_id'] == itemEntrega['product_id'],
        orElse: () => <String, dynamic>{},
      );

      if (itemExistente.isNotEmpty) {
        // Se existe, atualiza o valor da propriedade 'amount'
        itemExistente['amount'] =
            (itemExistente['amount'] ?? 0) + itemEntrega['amount'];

        itemExistente['quantity'] =
            (itemExistente['quantity'] ?? 0) + itemEntrega['quantity'];
      } else {
        // Se não existe, adiciona o item inteiro em entregasUnicas
        entregasUnicas.add(Map<String, dynamic>.from(itemEntrega));
      }
    }

    return entregasUnicas;
  }

  Future<void> _abrirRelatorio() async {
    Map<String, dynamic> seller = {
      '_id': widget.userData.id,
      'name': widget.userData.nome,
      'role': widget.userData.cargo
    };
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SellerReportPage(sellerData: seller),
        ),
      );
    } catch (e) {
      print('Erro ao abrir a página do relatório: $e');
    }
  }
}
