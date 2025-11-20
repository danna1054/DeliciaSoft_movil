import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/General_models.dart' as GeneralModels;
import '../../services/donas_api_services.dart';
import '../../services/cart_services.dart';
import '../../models/cart_models.dart';

class BebidasScreen extends StatefulWidget {
  final String categoryTitle;

  const BebidasScreen({super.key, required this.categoryTitle});

  @override
  State<BebidasScreen> createState() => _BebidasScreenState();
}

class _BebidasScreenState extends State<BebidasScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProductoApiService _apiService = ProductoApiService();

  List<GeneralModels.ProductModel> allProductos = [];
  List<GeneralModels.ProductModel> filteredProductos = [];
  bool isLoading = true;
  String? errorMessage;
  
  final formatoCOP = NumberFormat('#,###', 'es_CO');

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

      List<GeneralModels.ProductModel> productos =
          await _apiService.obtenerProductosPorCategoriaId(1);

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

  void _addToCart(GeneralModels.ProductModel producto) {
    final cartService = Provider.of<CartService>(context, listen: false);
    
    final config = ObleaConfiguration()
      ..tipoOblea = producto.nombreProducto
      ..precio = producto.precioProducto
      ..ingredientesPersonalizados = {
        'Producto': producto.nombreProducto,
        'Categoría': producto.nombreCategoria ?? 'Bebida',
      };

    cartService.addToCart(
      producto: producto,
      cantidad: 1,
      configuraciones: [config],
    );

    _showSuccessAlert(producto);
  }

 void _showSuccessAlert(GeneralModels.ProductModel producto) {
  final screenWidth = MediaQuery.of(context).size.width;
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all((screenWidth * 0.05).clamp(16.0, 24.0)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green[50]!, const Color.fromARGB(255, 230, 200, 227)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_cart,
                    color: const Color.fromARGB(255, 160, 67, 112),
                    size: (screenWidth * 0.1).clamp(30.0, 40.0),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Éxito!',
                  style: TextStyle(
                    fontSize: (screenWidth * 0.06).clamp(18.0, 24.0),
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 175, 76, 137),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Se ha añadido ${producto.nombreProducto} al carrito',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: (screenWidth * 0.04).clamp(14.0, 16.0)),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Precio: \$${formatoCOP.format(producto.precioProducto)}',
                  style: TextStyle(
                    fontSize: (screenWidth * 0.045).clamp(16.0, 18.0),
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 175, 76, 122),
                  ),
                ),
                const SizedBox(height: 20),
                screenWidth < 360
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color.fromARGB(255, 175, 76, 119),
                                side: const BorderSide(color: Color.fromARGB(255, 175, 76, 140)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Seguir comprando'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 175, 76, 130),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Volver al inicio'),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color.fromARGB(255, 175, 76, 119),
                                side: const BorderSide(color: Color.fromARGB(255, 175, 76, 140)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Seguir comprando',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 1,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 175, 76, 130),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Volver al inicio',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: _buildProductImage(imagen),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (precio > 0) ...[
                    Text(
                      '\$${formatoCOP.format(precio)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _addToCart(producto),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(0, 28),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_shopping_cart, size: 14),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Agregar',
                              style: TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                Icons.local_drink,
                size: 50,
                color: Colors.pinkAccent,
              ),
              SizedBox(height: 8),
              Text(
                'Bebidas',
                style: TextStyle(
                  color: Colors.pinkAccent,
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
            color: Colors.pinkAccent,
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
                : Icons.local_drink_outlined,
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

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F0),
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
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
                    color: Colors.pinkAccent,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar en ${widget.categoryTitle.toLowerCase()}...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, value, child) {
                          return value.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.pinkAccent, width: 2),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.pink[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_cart_checkout, color: Colors.pink[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Haz clic en "Agregar" para añadir productos',
                          style: TextStyle(
                            color: Colors.pink[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: filteredProductos.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _fetchProductos,
                            color: Colors.pinkAccent,
                            child: GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              itemCount: filteredProductos.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                              itemBuilder: (context, index) {
                                return _buildCard(filteredProductos[index]);
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}