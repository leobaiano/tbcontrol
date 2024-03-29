// ignore_for_file: use_build_context_synchronously
// -*- coding: utf-8 -*-

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo_dart;
import 'package:tbcontrol/custom_drawer.dart';
import 'package:tbcontrol/seller_data.dart';
import 'mongo_db_service.dart';
import 'package:tbcontrol/user_data.dart';

class ProductsPage extends StatefulWidget {
  final UserData userData;

  const ProductsPage({Key? key, required this.userData}) : super(key: key);

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Map<String, dynamic>> produtos = []; // Lista para armazenar os produtos

  @override
  void initState() {
    super.initState();

    _carregarProdutos(); // Carrega os produtos ao iniciar a página
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
              _showAddProductDialog(context);
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
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _editProduct(index);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _deleteProduct(index);
                                },
                              ),
                              IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: () {
                                    _enviarProduto(index);
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

  Future<void> _carregarProdutos() async {
    try {
      DBConnection dbConnection = DBConnection.getInstance();
      mongo_dart.Db db = await dbConnection.getConnection();

      var collection = db.collection('products');

      var produtosDoBanco = await collection.find().toList();

      setState(() {
        produtos = produtosDoBanco;
      });
    } catch (e) {
      print('Erro ao carregar produtos: $e');
      // TODO: Adicionar lógica de tratamento de erro
    }
  }

  Future<void> _showAddProductDialog(BuildContext context) async {
    TextEditingController nomeController = TextEditingController();
    TextEditingController quantidadeController = TextEditingController();
    TextEditingController valorController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Novo Produto'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextFormField(
                  controller: quantidadeController,
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                ),
                TextFormField(
                  controller: valorController,
                  decoration: const InputDecoration(labelText: 'Valor'),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                int quantidade = int.parse(quantidadeController.text);
                double valor = double.parse(valorController.text);
                _adicionarProduto(nomeController.text, quantidade, valor);
                Navigator.of(context).pop();
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _adicionarProduto(
      String nome, int quantidade, double valor) async {
    try {
      DBConnection dbConnection = DBConnection.getInstance();
      mongo_dart.Db db = await dbConnection.getConnection();

      var collection = db.collection('products');

      await collection
          .insertOne({'name': nome, 'quantity': quantidade, 'value': valor});

      Fluttertoast.showToast(
        msg: "Produto adicionado com sucesso.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Recarregar a lista de produtos após a adição
      await _carregarProdutos();
    } catch (e) {
      print('Erro ao adicionar produto: $e');
    }
  }

  Future<void> _enviarProduto(int index) async {
    TextEditingController quantidadeController = TextEditingController();
    mongo_dart.ObjectId? vendedorSelecionado;
    try {
      DBConnection dbConnection = DBConnection.getInstance();
      mongo_dart.Db db = await dbConnection.getConnection();

      var vendedoresCollection = db.collection('users');
      var vendedores = await vendedoresCollection
          .find(mongo_dart.where.eq('role', 'Vendedor'))
          .toList();

      var result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enviar Produto'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<mongo_dart.ObjectId>(
                    value: vendedorSelecionado,
                    onChanged: (mongo_dart.ObjectId? value) {
                      setState(() {
                        vendedorSelecionado = value;
                      });
                    },
                    items: vendedores
                        .map<DropdownMenuItem<mongo_dart.ObjectId>>(
                          (vendedor) => DropdownMenuItem<mongo_dart.ObjectId>(
                            value: vendedor['_id'],
                            child: Text(vendedor['name'] as String),
                          ),
                        )
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Selecione o Vendedor',
                    ),
                  ),
                  TextFormField(
                    controller: quantidadeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade a enviar',
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
        await _enviarProdutoParaVendedor(
          index,
          vendedorSelecionado,
          quantidadeController.text,
        );
      }
    } catch (e) {
      print('Erro ao carregar vendedores: $e');
    }
  }

  Future<void> _enviarProdutoParaVendedor(
      int index, mongo_dart.ObjectId? vendedorId, String quantidade) async {
    try {
      DBConnection dbConnection = DBConnection.getInstance();
      mongo_dart.Db db = await dbConnection.getConnection();

      var produtosCollection = db.collection('products');
      var transactionsCollection = db.collection('transactions');
      // var vendedoresCollection = db.collection('users');

      var quantidadeAtual = produtos[index]['quantity'];
      var quantidadeEnviada = int.tryParse(quantidade);

      var produtoSelecionado = await produtosCollection
          .findOne(mongo_dart.where.id(produtos[index]['_id']));

      double total = 0;
      if (produtoSelecionado != null) {
        total = (quantidadeEnviada! * produtoSelecionado['value'] as double);
      }

      if (quantidadeEnviada != null && quantidadeAtual >= quantidadeEnviada) {
        // var vendedor = await vendedoresCollection.findOne(
        //   mongo_dart.where.id(vendedorId!),
        // );

        await transactionsCollection.insertOne({
          'user_id': vendedorId,
          'product_id': produtos[index]['_id'],
          'quantity': quantidadeEnviada,
          'unit_value': produtoSelecionado?['value'],
          'amount': total,
          'type': 'Entrega',
          'created_at': DateTime.now().toLocal(),
        });

        await produtosCollection.update(
          mongo_dart.where.eq('_id', produtos[index]['_id']),
          {
            r'$set': {
              'quantity': quantidadeAtual - quantidadeEnviada,
            },
          },
        );

        Fluttertoast.showToast(
          msg: 'Produto enviado com sucesso!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        await Future.delayed(const Duration(milliseconds: 500));

        await _carregarProdutos();
        // TODO: Adicionar lógica para notificar o vendedor
      } else {
        Fluttertoast.showToast(
          msg: 'Quantidade inválida ou insuficiente!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      print('Erro ao enviar produto: $e');
    }
  }

  Future<void> _deleteProduct(int index) async {
    bool confirmarExclusao = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Deseja realmente excluir este produto?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Sim'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Não'),
            ),
          ],
        );
      },
    );

    if (confirmarExclusao) {
      await _excluirProduto(index);
    }
  }

  Future<void> _excluirProduto(int index) async {
    try {
      DBConnection dbConnection = DBConnection.getInstance();
      mongo_dart.Db db = await dbConnection.getConnection();

      var collection = db.collection('products');

      await collection
          .remove(mongo_dart.where.eq('_id', produtos[index]['_id']));

      Fluttertoast.showToast(
        msg: "Produto excluído com sucesso.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      _carregarProdutos();
    } catch (e) {
      print('Erro ao excluir produto: $e');
      // TODO: Adicionar lógica de tratamento de erro
    }
  }

  Future<void> _editProduct(int index) async {
    TextEditingController nomeController = TextEditingController();
    TextEditingController quantidadeController = TextEditingController();
    TextEditingController valorController = TextEditingController();

    nomeController.text = produtos[index]['name'];
    quantidadeController.text = produtos[index]['quantity'].toString();
    valorController.text = produtos[index]['value'].toString();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Produto'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextFormField(
                  controller: quantidadeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                ),
                TextFormField(
                  controller: valorController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Valor'),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _editarProduto(index, nomeController.text,
                    quantidadeController.text, valorController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editarProduto(int index, String novoNome, String novaQuantidade,
      String novoValor) async {
    try {
      DBConnection dbConnection = DBConnection.getInstance();
      mongo_dart.Db db = await dbConnection.getConnection();

      var collection = db.collection('products');

      int quantidade = int.tryParse(novaQuantidade) ?? 0;
      double valor = double.tryParse(novoValor) ?? 0.0;

      await collection.update(
        mongo_dart.where.eq('_id', produtos[index]['_id']),
        {
          r'$set': {'name': novoNome, 'quantity': quantidade, 'value': valor},
        },
      );

      Fluttertoast.showToast(
        msg: "Produto editado com sucesso.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      _carregarProdutos();
    } catch (e) {
      print('Erro ao editar produto: $e');
      // TODO: Adicionar lógica de tratamento de erro
    }
  }
}
