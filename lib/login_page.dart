// login_page.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo_dart;
import 'home_page.dart';
import 'mongo_db_service.dart';
import 'user_data.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Faça login'),
          ),
          body: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _usuarioController,
                    decoration: const InputDecoration(labelText: 'Usuário'),
                  ),
                  TextField(
                    controller: _senhaController,
                    decoration: const InputDecoration(labelText: 'Senha'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      String usuario = _usuarioController.text;
                      String senha = _senhaController.text;

                      DBConnection dbConnection = DBConnection.getInstance();
                      mongo_dart.Db db;

                      try {
                        await dbConnection.initialize();
                        db = await dbConnection.getConnection();
                      } catch (e) {
                        print("Erro ao obter conexão: $e");
                        return;
                      }

                      var collection = db.collection('users');

                      var result = await collection.findOne({
                        'user': usuario,
                        'password': senha,
                      });

                      if (result != null) {
                        // Usuário encontrado, criar instância de UserData
                        UserData userData = UserData(
                          id: result['_id'],
                          usuario: usuario,
                          nome: result['name'],
                          cargo: result['role'],
                        );

                        // Navegar para a página inicial (home_page.dart) com UserData
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(userData: userData),
                          ),
                        );
                      } else {
                        // Usuário não encontrado
                        Fluttertoast.showToast(
                          msg: "Usuário não encontrado",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      }
                    },
                    child: const Text('Entrar'),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }
}
