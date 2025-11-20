import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/General_models.dart';
import '../../../models/Productconfiguration.dart';
import '../../../services/cart_services.dart';
import '../../../models/cart_models.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  List<ProductConfiguration> productConfigurations = [];

  List<String> adiciones = [];
  List<String> toppings = [];
  List<String> salsas = [];

  bool cargandoAdiciones = false;
  bool cargandoToppings = false;
  bool cargandoSalsas = false;

  final Map<String, int> toppingLimits = {
    '9 oz': 1,
    '12 oz': 3,
    '16 oz': 5,
    '24 oz': 7,
  };

  final Map<String, int> salsaLimits = {
    '9 oz': 1,
    '12 oz': 2,
    '16 oz': 3,
    '24 oz': 3,
  };

  final Map<String, double> sizePrices = {
    '9 oz': 7000,
    '12 oz': 12000,
    '16 oz': 16000,
    '24 oz': 20000,
  };

  final formatoCOP = NumberFormat.currency(locale: 'es_CO', symbol: '\$ ', decimalDigits: 0, customPattern: '¤#,##0');

  @override
  void initState() {
    super.initState();
    _initializeConfigurations();
    _cargarAdicionesDesdeApi();
    _cargarToppingsDesdeApi();
    _cargarSalsasDesdeApi();
  }

  void _initializeConfigurations() {
    productConfigurations = List.generate(
      quantity,
      (index) => ProductConfiguration(),
    );
  }

  Future<void> _cargarAdicionesDesdeApi() async {
    if (!mounted) return;
    setState(() => cargandoAdiciones = true);
    try {
      final response = await http.get(
        Uri.parse('https://deliciasoft-backend-i6g9.onrender.com/api/catalogo-adiciones'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          adiciones = data
              .where((item) => item['estado'] == true)
              .map<String>((item) => item['nombre'].toString())
              .toList();
        });
      } else {
        debugPrint('Error al cargar adiciones: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al cargar adiciones: $e');
    } finally {
      if (!mounted) return;
      setState(() => cargandoAdiciones = false);
    }
  }

  Future<void> _cargarToppingsDesdeApi() async {
    if (!mounted) return;
    setState(() => cargandoToppings = true);
    try {
      final response = await http.get(
        Uri.parse('https://deliciasoft-backend-i6g9.onrender.com/api/catalogo-toppings'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          toppings = data
              .where((item) => item['estado'] == true)
              .map<String>((item) => item['nombre'].toString())
              .toList();
        });
      } else {
        debugPrint('Error al cargar toppings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al cargar toppings: $e');
    } finally {
      if (!mounted) return;
      setState(() => cargandoToppings = false);
    }
  }

  Future<void> _cargarSalsasDesdeApi() async {
    if (!mounted) return;
    setState(() => cargandoSalsas = true);
    try {
      final response = await http.get(
        Uri.parse('https://deliciasoft-backend-i6g9.onrender.com/api/catalogo-salsas'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          salsas = data
              .where((item) => item['estado'] == true)
              .map<String>((item) => item['nombre'].toString())
              .toList();
        });
      } else {
        debugPrint('Error al cargar salsas: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al cargar salsas: $e');
    } finally {
      if (!mounted) return;
      setState(() => cargandoSalsas = false);
    }
  }

  void _agregarAlCarrito() {
    final cartService = Provider.of<CartService>(context, listen: false);

    List<String> errors = [];

    for (int i = 0; i < productConfigurations.length; i++) {
      final config = productConfigurations[i];

      if (config.selectedSize.isEmpty) {
        errors.add('Producto ${i + 1}: Selecciona un tamaño');
      }
      if (config.selectedToppings.isEmpty) {
        errors.add('Producto ${i + 1}: Selecciona al menos 1 topping');
      }
      if (config.selectedSalsas.isEmpty) {
        errors.add('Producto ${i + 1}: Selecciona al menos 1 salsa');
      }
    }

    if (errors.isNotEmpty) {
      _showValidationAlert(errors);
      return;
    }

    // Crear configuraciones para cada producto
    final configuraciones = <ObleaConfiguration>[];

    for (int i = 0; i < productConfigurations.length; i++) {
      final config = productConfigurations[i];
      final precioBase = sizePrices[config.selectedSize] ?? 0;
      final precioAdicionales = (config.selectedAdiciones.length) * 1000.0;
      final precioTotal = precioBase + precioAdicionales;

      final obleaConfig = ObleaConfiguration()
        ..tipoOblea = config.selectedSize
        ..precio = precioTotal
        ..ingredientesPersonalizados = {
          'Producto': 'Producto ${i + 1}',
          'Tamaño': config.selectedSize,
          'Toppings': config.selectedToppings.join(', '),
          'Salsas': config.selectedSalsas.join(', '),
          'Adiciones': config.selectedAdiciones.isEmpty 
              ? 'Sin adiciones' 
              : config.selectedAdiciones.join(', '),
        };

      configuraciones.add(obleaConfig);
    }

    // Agregar al carrito
    cartService.addToCart(
      producto: widget.product,
      cantidad: quantity,
      configuraciones: configuraciones,
    );

    // Mostrar mensaje de éxito
    _showSuccessAlert();
  }

  void _showSuccessAlert() {
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
                    'Se ${quantity == 1 ? 'ha' : 'han'} añadido $quantity ${quantity == 1 ? 'producto' : 'productos'} al carrito',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: (screenWidth * 0.04).clamp(14.0, 16.0)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: ${formatoCOP.format(totalPrice)}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            if (cargandoAdiciones || cargandoToppings || cargandoSalsas)
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: Colors.pinkAccent),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildFormContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: Colors.pinkAccent,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.product.nombreProducto,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProductImage(),
        const SizedBox(height: 12),
        Text(
          widget.product.descripcion ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        _buildQuantitySelector(),
        const SizedBox(height: 16),
        ...List.generate(quantity, (index) => _buildProductConfiguration(index)),
        const SizedBox(height: 16),
        _buildPriceSummary(),
        const SizedBox(height: 16),
        _buildAddToCartBar(),
      ],
    );
  }

  Widget _buildProductImage() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          widget.product.urlImg ?? '',
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.icecream, size: 100, color: Colors.pinkAccent),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 32),
          onPressed: () {
            if (quantity > 1) {
              setState(() {
                quantity--;
                productConfigurations.removeLast();
              });
            }
          },
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.pink[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$quantity ${quantity == 1 ? 'Producto' : 'Productos'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 32),
          onPressed: () {
            setState(() {
              quantity++;
              productConfigurations.add(ProductConfiguration());
            });
          },
        ),
      ],
    );
  }

  Widget _buildProductConfiguration(int index) {
    final config = productConfigurations[index];
    final sizeOptions = ['9 oz', '12 oz', '16 oz', '24 oz'];

    int maxToppings = toppingLimits[config.selectedSize] ?? 0;
    int maxSalsas = salsaLimits[config.selectedSize] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Producto #${index + 1}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.pinkAccent)),
            const SizedBox(height: 10),
            _buildDropdown(
              'Tamaño',
              config.selectedSize,
              sizeOptions,
              (val) {
                setState(() {
                  config.selectedSize = val;
                  config.selectedToppings.clear();
                  config.selectedSalsas.clear();
                  config.selectedAdiciones.clear();
                });
              },
              false,
            ),
            if (config.selectedSize.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Puedes escoger hasta $maxToppings topping${maxToppings != 1 ? 's' : ''}:',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              _buildMultiDropdown(
                label: 'Toppings',
                options: toppings,
                selectedValues: config.selectedToppings,
                max: maxToppings,
                config: config,
                isLoading: cargandoToppings,
              ),
              const SizedBox(height: 10),
              Text('Puedes escoger hasta $maxSalsas salsa${maxSalsas != 1 ? 's' : ''}:',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              _buildMultiDropdown(
                label: 'Salsas',
                options: salsas,
                selectedValues: config.selectedSalsas,
                max: maxSalsas,
                config: config,
                isLoading: cargandoSalsas,
              ),
              const SizedBox(height: 10),
              const Text('Puedes añadir hasta 10 adiciones (+\$1.000 c/u):',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              _buildMultiDropdown(
                label: 'Adiciones (+\$1.000 c/u)',
                options: adiciones,
                selectedValues: config.selectedAdiciones,
                max: 10,
                config: config,
                isLoading: cargandoAdiciones,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
    bool isLoading,
  ) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cargando opciones de $label...',
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: currentValue.isEmpty ? null : currentValue,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        items: options.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: (val) => val != null ? onChanged(val) : null,
      ),
    );
  }

  Widget _buildMultiDropdown({
    required String label,
    required List<String> options,
    required List<String> selectedValues,
    required int max,
    required ProductConfiguration config,
    required bool isLoading,
  }) {
    if (isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cargando $label...',
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () => _showMultiSelectModal(
          label: label,
          options: options,
          selectedValues: selectedValues,
          max: max,
          config: config,
        ),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          child: Text(
            selectedValues.isEmpty ? 'Selecciona opciones' : selectedValues.join(', '),
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ),
    );
  }

  void _showMultiSelectModal({
    required String label,
    required List<String> options,
    required List<String> selectedValues,
    required int max,
    required ProductConfiguration config,
  }) {
    List<String> tempSelected = List.from(selectedValues);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${tempSelected.length}/$max',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tempSelected.length >= max ? Colors.red : Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((option) {
                      final isSelected = tempSelected.contains(option);
                      final isLimited = tempSelected.length >= max && !isSelected;
                      return FilterChip(
                        label: Text(option, style: const TextStyle(fontSize: 13)),
                        selected: isSelected,
                        onSelected: isLimited
                            ? null
                            : (selected) {
                                setModalState(() {
                                  if (selected) {
                                    tempSelected.add(option);
                                  } else {
                                    tempSelected.remove(option);
                                  }
                                });
                              },
                        selectedColor: Colors.pinkAccent.withOpacity(0.2),
                        backgroundColor: Colors.grey[100],
                        checkmarkColor: Colors.pinkAccent,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedValues
                          ..clear()
                          ..addAll(tempSelected);
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Confirmar selección'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  double _getUnitPrice(ProductConfiguration config) {
    double basePrice = sizePrices[config.selectedSize] ?? 0;
    double adicionalesPrice = config.selectedAdiciones.length * 1000.0;
    return basePrice + adicionalesPrice;
  }

  double get totalPrice {
    return productConfigurations.fold(
      0,
      (sum, config) => sum + _getUnitPrice(config),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(20, 0, 0, 0),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        'Total: ${formatoCOP.format(totalPrice)}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAddToCartBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.pink[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${formatoCOP.format(totalPrice)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          GestureDetector(
            onTap: _agregarAlCarrito,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.pinkAccent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  void _showValidationAlert(List<String> errors) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red[50]!, Colors.red[100]!],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.pink[600],
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Campos Requeridos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: errors
                        .map((error) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  Expanded(child: Text(error)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}