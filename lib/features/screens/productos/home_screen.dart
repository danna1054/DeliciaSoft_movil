// lib/screens/products/home_screen.dart
import 'package:flutter/material.dart';
import '../../services/categoria_services.dart'; 
import '../../models/categorias.dart'; 
import 'category_products_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Category>> futureCategorias;

  @override
  void initState() {
    super.initState();
    futureCategorias = CategoriaApiService().obtenerCategorias();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F6), // Fondo rosado claro
      appBar: AppBar(
        title: const Text(
          'Categorías de Productos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.pinkAccent,
        elevation: 2,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              // Acción del carrito de compras
            },
          ),
        ],
      ),
      body: _buildHomeContent(),
    );
  }

  Widget _buildHomeContent() {
    return FutureBuilder<List<Category>>(
      future: futureCategorias,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.pinkAccent),
                SizedBox(height: 16),
                Text(
                  "Cargando categorías...",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.pinkAccent),
                const SizedBox(height: 16),
                const Text(
                  "Error al cargar categorías",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      futureCategorias = CategoriaApiService().obtenerCategorias();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No hay categorías disponibles",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final categorias = snapshot.data!;
        return _buildCategoriesGrid(categorias);
      },
    );
  }

  Widget _buildCategoriesGrid(List<Category> categorias) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.95, // Más alto que ancho
        ),
        itemCount: categorias.length,
        itemBuilder: (context, index) {
          final categoria = categorias[index];
          return _buildCategoryCard(categoria);
        },
      ),
    );
  }

  Widget _buildCategoryCard(Category categoria) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryProductsScreen(
                categoryId: categoria.idcategoriaproducto,
                categoryName: categoria.nombrecategoria,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Imagen redondeada más grande
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: categoria.urlImg != null && categoria.urlImg!.isNotEmpty
                        ? Image.network(
                            categoria.urlImg!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                          )
                        : _buildPlaceholderIcon(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Texto del nombre de categoría
              Text(
                categoria.nombrecategoria,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.category,
        size: 40,
        color: Colors.pink[300],
      ),
    );
  }
}