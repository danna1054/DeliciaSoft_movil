import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'products/home_screen.dart';
import 'auth/login_screen.dart';
import 'client/client_dashboard.dart';
import 'client/client_pedido_history_screen.dart';
import 'admin/admin_dashboard.dart';
import 'admin/ventas/pedido_list_screen.dart'; // Add this line

class HomeNavigation extends StatefulWidget {
  const HomeNavigation({super.key});

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _selectedIndex = 0;

  List<Widget> _buildScreens(AuthProvider auth) {
    if (!auth.isAuthenticated) {
      return [
        HomeScreen(),
        const Center(child: Text('Mis pedidos (requiere login)')),
        const LoginScreen(),
      ];
    }

    if (auth.userType == 'admin') {
      return [
        HomeScreen(), // Categorías (inicio)
        const AdminDashboard(), // Dashboard/Perfil del admin
        const PedidoListScreen(), // This will now be the "Ventas" screen
        const SizedBox(), // Placeholder para logout
      ];
    }

    // Cliente
    return [
      HomeScreen(),
      const ClientDashboard(), 
      const ClientPedidoHistoryScreen(),
      const SizedBox(),
    ];
  }

  List<BottomNavigationBarItem> _buildItems(AuthProvider auth) {
    if (!auth.isAuthenticated) {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Mis pedidos'),
        BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Iniciar'),
      ];
    }

    if (auth.userType == 'admin') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Categorías'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Ventas'),
        BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Cerrar'),
      ];
    }

    return const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Mis pedidos'),
      BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Cerrar'),
    ];
  }

  void _onItemTapped(int index, AuthProvider auth) {
    final isLogout = auth.isAuthenticated && index == _buildItems(auth).length - 1;

    if (!auth.isAuthenticated && index == 1) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else if (!auth.isAuthenticated && index == 2) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else if (isLogout) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cerrar sesión'),
          content: Text(auth.userType == 'admin' 
            ? '¿Estás seguro de que deseas cerrar sesión como administrador?' 
            : '¿Estás segura de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Cierra el diálogo
                await auth.logout();
                if (mounted) setState(() => _selectedIndex = 0);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sesión cerrada correctamente')),
                );
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final screens = _buildScreens(auth);
    final items = _buildItems(auth);

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => _onItemTapped(i, auth),
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: items,
      ),
    );
  }
}