// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison
// -*- coding: utf-8 -*-

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo_dart;
import 'package:tbcontrol/custom_drawer.dart';
import 'mongo_db_service.dart';
import 'package:tbcontrol/user_data.dart';

class SellerPage extends StatefulWidget {
  final UserData userData;

  const SellerPage({Key? key, required this.userData}) : super(key: key);

  @override
  _SellerPageState createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  List<Map<String, dynamic>> produtos = []; // Lista para armazenar os produtos

  @override
  void initState() {
    super.initState();

    _carregarProdutos(widget.userData.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // _showAddProductDialog(context);
            },
          ),
        ],
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
                                  '${produtos[index]['quantity']} Itens no valor de R\$ ${produtos[index]['value']} cada.',
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
                                  })
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

  Future<void> _carregarProdutos(mongo_dart.ObjectId sellerId) async {
    try {
      var entregas = await _entregas(sellerId);
      var vendas = await _vendas(sellerId);

      int totalEntregas = entregas.length;
      int totalVendas = vendas.length;

      List<Map<String, dynamic>> produtosDisponiveis = [];
      if (totalEntregas > totalVendas) {
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
            itemVenda['amount'] =
                (itemVenda['amount'] ?? 0) - entregaCorrespondente['amount'];

            itemVenda['quantity'] = (itemVenda['quantity'] ?? 0) -
                entregaCorrespondente['quantity'];
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

      print(produtos[index]);

      await transactionsCollection.insertOne({
        'user_id': vendedorId,
        'product_id': produtos[index]['_id'],
        'quantity': quantidade,
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
}
