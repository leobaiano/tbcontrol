import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo_dart;
import 'package:tbcontrol/custom_drawer.dart';
import 'package:tbcontrol/user_data.dart';
import 'mongo_db_service.dart';

class UsersPage extends StatefulWidget {
  final UserData userData;

  const UsersPage({Key? key, required this.userData}) : super(key: key);

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>> usuarios = []; // Lista para armazenar os usuários

  @override
  void initState() {
    super.initState();
    _carregarUsuarios(); // Carrega os usuários ao iniciar a página
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddUserDialog(context);
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
                itemCount: usuarios.length,
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
                                  usuarios[index]['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  usuarios[index]['role'],
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
                                  _editUser(index);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _deleteUser(index);
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

  Future<void> _showAddUserDialog(BuildContext context) async {
    TextEditingController usuarioController = TextEditingController();
    TextEditingController nomeController = TextEditingController();
    TextEditingController senhaController = TextEditingController();

    String? cargoSelecionado;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Novo Usuário'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: usuarioController,
                  decoration: const InputDecoration(labelText: 'Usuário'),
                ),
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                DropdownButtonFormField<String>(
                  value: cargoSelecionado,
                  onChanged: (value) {
                    setState(() {
                      cargoSelecionado = value;
                    });
                  },
                  items: ['Administrador', 'Vendedor']
                      .map((cargo) => DropdownMenuItem(
                            value: cargo,
                            child: Text(cargo),
                          ))
                      .toList(),
                  decoration: const InputDecoration(labelText: 'Cargo'),
                ),
                TextFormField(
                  controller: senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha'),
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
                _adicionarUsuario(
                  usuarioController.text,
                  nomeController.text,
                  cargoSelecionado,
                  senhaController.text,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _adicionarUsuario(
      String usuario, String nome, String? cargo, String senha) async {
    try {
      DBConnection dbConnection = DBConnection.getInstance();
      mongo_dart.Db db = await dbConnection.getConnection();

      var collection = db.collection('users');

      await collection.insertOne({
        'user': usuario,
        'name': nome,
        'password': senha,
        'role': cargo,
      });

      Fluttertoast.showToast(
        msg: "Usuário adicionado com sucesso.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      await _carregarUsuarios();
    } catch (e) {
      print('Erro ao adicionar usuário: $e');
      // TODO: Adicionar lógica de tratamento de erro
    }
  }

  Future<void> _carregarUsuarios() async {
    try {
      DBConnection dbConnection = DBConnection.getInstance();
      mongo_dart.Db db = await dbConnection.getConnection();

      var collection = db.collection('users');

      var usuariosDoBanco = await collection.find().toList();

      print(usuariosDoBanco);

      setState(() {
        usuarios = usuariosDoBanco;
      });
    } catch (e) {
      print('Erro ao carregar usuários: $e');
      // TODO: Adicionar lógica de tratamento de erro
    }
  }

  Future<void> _editUser(int index) async {
    TextEditingController usuarioController = TextEditingController();
    TextEditingController nomeController = TextEditingController();
    TextEditingController senhaController = TextEditingController();

    String? cargoSelecionado = usuarios[index]['role'];

    usuarioController.text = usuarios[index]['user'];
    nomeController.text = usuarios[index]['name'];
    senhaController.text = usuarios[index]['password'];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Usuário'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: usuarioController,
                  decoration: const InputDecoration(labelText: 'Usuário'),
                ),
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                DropdownButtonFormField<String>(
                  value: cargoSelecionado,
                  onChanged: (value) {
                    setState(() {
                      cargoSelecionado = value;
                    });
                  },
                  items: ['Administrador', 'Vendedor']
                      .map((cargo) => DropdownMenuItem(
                            value: cargo,
                            child: Text(cargo),
                          ))
                      .toList(),
                  decoration: const InputDecoration(labelText: 'Cargo'),
                ),
                TextFormField(
                  controller: senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha'),
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
                _editarUsuario(
                  index,
                  usuarioController.text,
                  nomeController.text,
                  cargoSelecionado,
                  senhaController.text,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editarUsuario(
    int index,
    String novoUsuario,
    String novoNome,
    String? novoCargo,
    String novaSenha,
  ) async {
    try {
      DBConnection dbConnection = DBConnection.getInstance();
      mongo_dart.Db db = await dbConnection.getConnection();

      var collection = db.collection('users');

      await collection.update(
        mongo_dart.where.eq('_id', usuarios[index]['_id']),
        {
          r'$set': {
            'user': novoUsuario,
            'name': novoNome,
            'role': novoCargo,
            'password': novaSenha,
          },
        },
      );

      Fluttertoast.showToast(
        msg: "Usuário editado com sucesso.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      _carregarUsuarios();
    } catch (e) {
      print('Erro ao editar usuário: $e');
      // TODO: Adicionar lógica de tratamento de erro
    }
  }

  Future<void> _deleteUser(int index) async {
    bool confirmarExclusao = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Deseja realmente excluir este usuário?'),
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
      await _excluirUsuario(index);
    }
  }

  Future<void> _excluirUsuario(int index) async {
    try {
      DBConnection dbConnection = DBConnection.getInstance();
      mongo_dart.Db db = await dbConnection.getConnection();

      var collection = db.collection('users');

      await collection
          .remove(mongo_dart.where.eq('_id', usuarios[index]['_id']));

      Fluttertoast.showToast(
        msg: "Usuário excluído com sucesso.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      _carregarUsuarios();
    } catch (e) {
      print('Erro ao excluir usuário: $e');
      // TODO: Adicionar lógica de tratamento de erro
    }
  }
}
