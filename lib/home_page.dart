import 'package:flutter/material.dart';
import 'package:tbcontrol/user_data.dart';
import 'custom_drawer.dart';

class HomePage extends StatelessWidget {
  final UserData userData;

  const HomePage({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TBControl'),
      ),
      drawer: CustomDrawer(
        userData: userData,
        onMenuTap: () {
          Navigator.pop(context);
        },
        nomeUsuario: '',
      ),
      body: const Center(
        child: Text(
          'Seja bem-vindo ao TBControl',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
