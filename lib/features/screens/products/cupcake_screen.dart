import 'package:flutter/material.dart';
import '../../models/General_models.dart' as GeneralModels;
import '../../services/donas_api_services.dart';
import 'Detail/CupcakeDetailScreen.dart';
import 'package:intl/intl.dart';

class CupcakeScreen extends StatefulWidget {
  final String categoryTitle;

  const CupcakeScreen({super.key, required this.categoryTitle});

  @override
  State<CupcakeScreen> createState() => _CupcakeScreenState();
}

class _CupcakeScreenState extends State<CupcakeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProductoApiService _apiService = ProductoApiService();

  List<GeneralModels.ProductModel> allProductos = [];
  List<GeneralModels.ProductModel> filteredProductos = [];
  bool isLoading = true;
  String? errorMessage;

  final formatoCOP = NumberFormat('#,##0', 'es_CO');

  @override
  void initState() {
    super.initState();
    _fetchProductos();
    _searchController.addListener(_filterProducts);
  }

  Future<void> _fetchProductos() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Obtener productos por categoría ID 5 (Cupcakes)
      List<GeneralModels.ProductModel> productos =
          await _apiService.obtenerProductosPorCategoriaId(5);

      if (mounted) {
        setState(() {
          allProductos = productos;
          filteredProductos = List.from(allProductos);
        });
      }
    } catch (e) {
      errorMessage = 'Error de conexión: ${e.toString()}';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage!),
            backgroundColor: Colors.pinkAccent,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _fetchProductos,
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase().trim();
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          filteredProductos = List.from(allProductos);
        } else {
          filteredProductos = allProductos.where((producto) {
            final nombre = producto.nombreProducto.toLowerCase();
            final categoria = producto.nombreCategoria?.toLowerCase() ?? '';
            return nombre.contains(query) || categoria.contains(query);
          }).toList();
        }
      });
    }
  }

  void _navigateToDetail(GeneralModels.ProductModel producto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CupcakeDetailScreen(product: producto),
      ),
    );
  }

  Widget _buildCard(GeneralModels.ProductModel producto) {
    final nombre = producto.nombreProducto;
    final imagen = producto.urlImg ?? '';
    final precio = producto.precioProducto;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(producto),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: _buildProductImage(imagen),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (precio > 0) ...[
                      Text(
                        '\$ ${formatoCOP.format(precio)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        'Personalizable',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.pinkAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cake,
                size: 50,
                color: Colors.pink,
              ),
              SizedBox(height: 8),
              Text(
                'Cupcakes',
                style: TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            color: Colors.pink,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[100],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 40, color: Colors.grey),
              SizedBox(height: 4),
              Text(
                'Sin imagen',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isNotEmpty
                ? Icons.search_off
                : Icons.cake_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No se encontraron resultados'
                : 'No hay productos disponibles',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Intenta con otro término de búsqueda'
                : 'Verifica tu conexión a internet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchProductos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.pink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Seleccionaste: ${widget.categoryTitle}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchProductos,
              tooltip: 'Actualizar productos',
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.pink,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando productos...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar cupcakes...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.pink[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.pink[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Toca cualquier producto para personalizarlo',
                          style: TextStyle(
                            color: Colors.pink[900],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredProductos.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchProductos,
                          color: Colors.pink,
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: filteredProductos.length,
                            itemBuilder: (context, index) {
                              final producto = filteredProductos[index];
                              return _buildCard(producto);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}