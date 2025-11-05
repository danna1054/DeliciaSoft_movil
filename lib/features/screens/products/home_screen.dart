import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../widgets/category_card.dart';
import '../../services/categoria_api_service.dart';
import 'package:provider/provider.dart'; 
import '../../services/cart_services.dart'; 
import '../cart_screen.dart'; 
import 'fresa_screen.dart';
import 'oblea_screen.dart';
import 'tortas_screen.dart';
import 'cupcake_screen.dart';
import 'minidona_screen.dart';
import 'postre_screen.dart';
import 'arrozConLeche.dart';
import 'Sandwiche_screen.dart';
import 'bebidas_screen.dart';
import 'chocolate_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Category>> _futureCategorias;

  @override
  void initState() {
    super.initState();
    _futureCategorias = CategoriaApiService().obtenerCategorias();
  }

  // Mapeo de categorías a sus pantallas correspondientes
  Widget? _getCategoryScreen(String title) {
    final normalizedTitle = title.trim().toLowerCase();
    
    debugPrint('🔍 Categoría seleccionada: "$title"');
    debugPrint('🔍 Título normalizado: "$normalizedTitle"');
    
    final Map<String, Widget Function()> screenMap = {
      'fresas con crema': () => FresaScreen(categoryTitle: title),
      'obleas': () => ObleaScreen(categoryTitle: title),
      'tortas': () => TortasScreen(categoryTitle: title),
      'cupcakes': () => CupcakeScreen(categoryTitle: title),
      'postres': () => PostreScreen(categoryTitle: title),
      'mini donas': () => MinidonaScreen(categoryTitle: title),
      'arroz con leche': () => ArrozConLecheScreen(categoryTitle: title),
      // 'sandwiches': () => SandwichesScreen(categoryTitle: title),
      // 'sandwich': () => SandwichesScreen(categoryTitle: title),
      'sandwches': () => SandwichesScreen(categoryTitle: title), 
      'bebidas': () => BebidasScreen(categoryTitle: title),
      'bebida': () => BebidasScreen(categoryTitle: title),
      'chocolate': () => ChocolateScreen(categoryTitle: title),
      'chocolates': () => ChocolateScreen(categoryTitle: title),
    };

    // Buscar coincidencia exacta
    if (screenMap.containsKey(normalizedTitle)) {
      debugPrint('✅ Pantalla encontrada (exacta): "$normalizedTitle"');
      return screenMap[normalizedTitle]!();
    }

    // Buscar coincidencia parcial (contiene)
    for (var entry in screenMap.entries) {
      if (normalizedTitle.contains(entry.key)) {
        debugPrint('✅ Pantalla encontrada (contiene "$normalizedTitle"): "${entry.key}"');
        return entry.value();
      }
    }
    
    // Buscar si alguna key contiene el título normalizado
    for (var entry in screenMap.entries) {
      if (entry.key.contains(normalizedTitle)) {
        debugPrint('✅ Pantalla encontrada (key contiene): "${entry.key}"');
        return entry.value();
      }
    }

    debugPrint('❌ No hay pantalla para: "$normalizedTitle"');
    debugPrint('📋 Opciones disponibles: ${screenMap.keys.join(", ")}');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F6),
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 2,
        title: const Text(
          'Categorías de Productos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<CartService>(
            builder: (context, cartService, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  if (cartService.totalQuantity > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cartService.totalQuantity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: FutureBuilder<List<Category>>(
        future: _futureCategorias,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.pinkAccent,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando categorías...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _futureCategorias = CategoriaApiService().obtenerCategorias();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No hay categorías disponibles",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _futureCategorias = CategoriaApiService().obtenerCategorias();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final categories = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];

                return CategoryCard(
                  title: category.nombreCategoria,
                  imageUrl: category.urlImg ?? '', // Usar imagen de la API
                  onTap: () {
                    debugPrint('👆 Click en: "${category.nombreCategoria}"');
                    
                    final screen = _getCategoryScreen(category.nombreCategoria);
                    
                    if (screen != null) {
                      debugPrint('✅ Navegando...');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => screen),
                      );
                    } else {
                      debugPrint('❌ Pantalla no disponible');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Pantalla no disponible para "${category.nombreCategoria}"',
                          ),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: 'OK',
                            textColor: Colors.white,
                            onPressed: () {},
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}