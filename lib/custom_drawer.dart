import 'package:flutter/material.dart';
import 'package:tbcontrol/login_page.dart';
import 'package:tbcontrol/products_page.dart';
import 'package:tbcontrol/sellers_page.dart';
import 'package:tbcontrol/user_data.dart';
import 'home_page.dart';
import 'users_page.dart';
import 'seller_page.dart';

class CustomDrawer extends StatelessWidget {
  final UserData userData;
  final VoidCallback onMenuTap;

  const CustomDrawer({
    Key? key,
    required this.userData,
    required this.onMenuTap,
    required String nomeUsuario,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: _buildMenuItems(context), // Passa o contexto para o método
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    List<Widget> menuItems = [
      _buildDrawerHeader(),
      ListTile(
        title: const Text('Inicial'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(userData: userData),
            ),
          );
        },
      ),
    ];

    // Adiciona os itens do menu com base nas permissões do usuário
    menuItems.addAll(_buildMenuItemsBasedOnRole(context));

    return menuItems;
  }

  List<Widget> _buildMenuItemsBasedOnRole(BuildContext context) {
    List<Widget> roleBasedMenuItems = [];

    // Verifica a role do usuário e adiciona os itens apropriados
    if (userData.cargo == 'Administrador') {
      roleBasedMenuItems.add(
        ListTile(
          title: const Text('Usuários'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UsersPage(userData: userData),
              ),
            );
          },
        ),
      );

      roleBasedMenuItems.add(
        ListTile(
          title: const Text('Produtos'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductsPage(userData: userData),
              ),
            );
          },
        ),
      );

      roleBasedMenuItems.add(
        ListTile(
          title: const Text('Vendedores'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SellersPage(userData: userData),
              ),
            );
          },
        ),
      );
      // Adicione outros itens específicos para 'Administrador' aqui, se necessário
    }

    if (userData.cargo == 'Vendedor') {
      roleBasedMenuItems.add(
        ListTile(
          title: const Text('Vender'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SellerPage(userData: userData),
              ),
            );
          },
        ),
      );
    }

    roleBasedMenuItems.add(
      ListTile(
        title: const Text('Sair'),
        onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
            (route) => false,
          );
        },
      ),
    );

    return roleBasedMenuItems;
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
        color: Colors.blue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bem-vindo,',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
          Text(
            userData.nome,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
