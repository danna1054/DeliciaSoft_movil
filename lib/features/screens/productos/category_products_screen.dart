// lib/screens/productos/category_products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/producto_general.dart';
import '../../models/General_models.dart' as GeneralModels;
import '../../services/productos_services.dart';
import '../../services/cart_services.dart';
import '../../models/cart_models.dart';
import './product_detail_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  late Future<List<ProductModel>> _futureProductos;
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _filteredProductos = [];

  @override
  void initState() {
    super.initState();
    _futureProductos = ProductoApiService()
        .obtenerProductosPorCategoriaId(widget.categoryId);
    _searchController.addListener(_filterProducts);
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase().trim();
    if (_filteredProductos.isNotEmpty) {
      setState(() {
        if (query.isEmpty) {
          _filteredProductos = List.from(_filteredProductos);
        } else {
          _filteredProductos = _filteredProductos.where((producto) {
            return producto.nombreProducto.toLowerCase().contains(query);
          }).toList();
        }
      });
    }
  }

  // Determinar si la categoría necesita personalización
  bool _categoryNeedsPersonalization() {
    final category = widget.categoryName.toLowerCase();
    final noPersonalizationCategories = [
      'arroz con leche',
      'bebidas',
      'chocolate',
      'postres',
      'tortas',
      'cupcakes'
    ];
    
    return !noPersonalizationCategories.any((cat) => category.contains(cat));
  }

  // Determinar si un producto específico necesita personalización
  bool _productNeedsPersonalization(ProductModel producto) {
    return _categoryNeedsPersonalization();
  }

  void _addToCart(ProductModel producto) {
    final cartService = Provider.of<CartService>(context, listen: false);
    
    // Convertir ProductModel a GeneralModels.ProductModel
    final generalProducto = GeneralModels.ProductModel(
      idProductoGeneral: producto.idProductoGeneral,
      nombreProducto: producto.nombreProducto,
      precioProducto: producto.precioProducto,
      urlImg: producto.urlImg,
      cantidadProducto: 1,
      estado: producto.estaDisponible,
      idCategoriaProducto: producto.idCategoriaProducto,
      nombreCategoria: producto.nombreCategoria,
    );
    
    final config = ObleaConfiguration()
      ..tipoOblea = generalProducto.nombreProducto
      ..precio = generalProducto.precioProducto
      ..ingredientesPersonalizados = {
        'Producto': generalProducto.nombreProducto,
        'Categoría': generalProducto.nombreCategoria ?? '',
      };

    cartService.addToCart(
      producto: generalProducto,
      cantidad: 1,
      configuraciones: [config],
    );

    _showSuccessAlert(producto);
  }

  void _showSuccessAlert(ProductModel producto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart,
                  color: Color.fromARGB(255, 160, 67, 112),
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '¡Éxito!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 175, 76, 137),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Se ha añadido ${producto.nombreProducto} al carrito',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Precio: \$${producto.precioProducto.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 175, 76, 122),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color.fromARGB(255, 175, 76, 119),
                        side: const BorderSide(color: Color.fromARGB(255, 175, 76, 140)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Seguir', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 175, 76, 130),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Inicio', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F6),
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        // Agregar el icono del carrito con contador
        actions: [
          Consumer<CartService>(
            builder: (context, cartService, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () {
                      // Navegar a la pantalla del carrito
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => const CartScreen(),
                      //   ),
                      // );
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
        ],
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: _futureProductos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          // Inicializar la lista filtrada con todos los productos
          if (_filteredProductos.isEmpty) {
            _filteredProductos = snapshot.data!;
          }

          return _buildProductGrid(_filteredProductos);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
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
            'Cargando productos...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.pinkAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              "Error al cargar productos",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _futureProductos = ProductoApiService()
                      .obtenerProductosPorCategoriaId(widget.categoryId);
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar productos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 100,
              color: Colors.pink[200],
            ),
            const SizedBox(height: 24),
            const Text(
              "No hay productos disponibles",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "en ${widget.categoryName}",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<ProductModel> productos) {
    final needsPersonalization = _categoryNeedsPersonalization();

    return Column(
      children: [
        // Encabezado con buscador y mensaje
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Buscador FUNCIONAL
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar en ${widget.categoryName}...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) => _filterProducts(),
                ),
              ),
              const SizedBox(height: 12),
              
              // Mensaje con icono de carrito en card rosa
              Container(
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
                        needsPersonalization
                            ? 'Haz clic para personalizar tu producto'
                            : 'Haz clic en "Agregar" para añadir productos',
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
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Grid de productos
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: productos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.70,
            ),
            itemBuilder: (context, index) {
              final producto = productos[index];
              return _buildProductCard(producto);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel producto) {
    final needsPersonalization = _productNeedsPersonalization(producto);

    return InkWell(
      onTap: needsPersonalization ? () {
        // Navegar a pantalla de personalización
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(producto: producto),
          ),
        );
      } : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen del producto
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      producto.urlImg ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.pink[50],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.pink[200],
                        ),
                      ),
                    ),
                    if (!producto.estaDisponible)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Text(
                            'Agotado',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Información del producto
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nombre del producto CENTRADO
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        producto.nombreProducto,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          height: 1.2,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    
                    // Precio CENTRADO con puntos de miles
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        '\$${producto.precioProducto.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.pinkAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Botón Agregar o Personalizar
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: producto.estaDisponible
                            ? () {
                                if (needsPersonalization) {
                                  // Navegar a pantalla de personalización
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(producto: producto),
                                    ),
                                  );
                                } else {
                                  // Agregar directo al carrito - USANDO EL MISMO CART SERVICE
                                  _addToCart(producto);
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          needsPersonalization ? 'Personalizar' : 'Agregar',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}