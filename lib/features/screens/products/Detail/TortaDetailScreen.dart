import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/General_models.dart';
import '../../../services/cart_services.dart';
import '../../../models/cart_models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TortaDetailScreen extends StatefulWidget {
  final ProductModel product;

  const TortaDetailScreen({super.key, required this.product});

  @override
  State<TortaDetailScreen> createState() => _TortaDetailScreenState();
}

class _TortaDetailScreenState extends State<TortaDetailScreen> {
  int quantity = 1;
  List<TortaConfiguration> tortaConfigurations = [];
  List<String> rellenos = [];
  List<String> sabores = [];
  bool isLoadingData = true;

  final formatoCOP = NumberFormat.currency(locale: 'es_CO', symbol: '\$ ', decimalDigits: 0, customPattern: '¤#,##0');

  // ✅ MAPEO MEJORADO: Incluye más variaciones de nombres
  final Map<String, double> preciosPorPorcion = {
    'Chocolate': 3500,
    'Vainilla': 3000,
    'Fresa': 3200,
    'Red Velvet': 4000,
    'Red velvet': 4000,
    'Zanahoria': 3800,
    'Tres Leches': 4200,
    'Moka': 4000,
    'Limón': 3200,
    'Maracuyá': 4500,
    'Postre Maracuyá': 4500,
    'Postre de Maracuyá': 4500,
  };

  final Map<String, double> preciosPorLibra = {
    'Chocolate': 15000,
    'Vainilla': 12000,
    'Fresa': 13000,
    'Red Velvet': 18000,
    'Red velvet': 18000,
    'Zanahoria': 16000,
    'Tres Leches': 20000,
    'Moka': 18000,
    'Limón': 13000,
    'Maracuyá': 20000,
    'Postre Maracuyá': 20000,
    'Postre de Maracuyá': 20000,
  };

  Future<void> fetchRellenos() async {
    try {
      final response = await http.get(Uri.parse('https://deliciasoft-backend-i6g9.onrender.com/api/catalogo-relleno'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<String> rellenosUnicos = [];
        final Set<String> rellenosSet = <String>{};
        
        for (var item in data) {
          final String nombre = item['nombre'] as String;
          if (!rellenosSet.contains(nombre)) {
            rellenosSet.add(nombre);
            rellenosUnicos.add(nombre);
          }
        }
        
        if (mounted) {
          setState(() {
            rellenos = rellenosUnicos;
          });
        }
      }
    } catch (e) {
      print('Excepción al cargar rellenos: $e');
    }
  }

  Future<void> fetchSabores() async {
    try {
      final response = await http.get(Uri.parse('https://deliciasoft-backend-i6g9.onrender.com/api/catalogo-sabor'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<String> saboresUnicos = [];
        final Set<String> saboresSet = <String>{};
        
        for (var item in data) {
          final String nombre = item['nombre'] as String;
          if (!saboresSet.contains(nombre)) {
            saboresSet.add(nombre);
            saboresUnicos.add(nombre);
          }
        }
        
        if (mounted) {
          setState(() {
            sabores = saboresUnicos;
          });
        }
      }
    } catch (e) {
      print('Excepción al cargar sabores: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // ✅ INICIALIZACIÓN MEJORADA: Espera a que se carguen los datos de la API
  Future<void> _initializeData() async {
    await Future.wait([
      fetchRellenos(),
      fetchSabores(),
    ]);
    
    if (mounted) {
      setState(() {
        _initializeConfigurations();
        isLoadingData = false;
      });
    }
  }

  void _initializeConfigurations() {
    tortaConfigurations = List.generate(
      quantity, 
      (index) => TortaConfiguration()
    );
    
    // ✅ ASIGNAR VALORES POR DEFECTO
    for (var config in tortaConfigurations) {
      // Sabor por defecto: nombre del producto
      config.sabor = widget.product.nombreProducto;
      
      // Relleno por defecto: primero de la lista
      if (rellenos.isNotEmpty) {
        config.relleno = rellenos.first;
      }
      
      // Tipo de venta por defecto
      config.tipoVenta = 'Por Porciones';
      config.porciones = 1;
    }
  }

  // ✅ FUNCIÓN MEJORADA: Busca el precio con normalización
  double _getPrecioBase(String sabor, bool esPorPorcion) {
    final mapa = esPorPorcion ? preciosPorPorcion : preciosPorLibra;
    
    // Buscar coincidencia exacta primero
    if (mapa.containsKey(sabor)) {
      return mapa[sabor]!;
    }
    
    // Buscar coincidencia sin considerar mayúsculas/minúsculas
    for (var key in mapa.keys) {
      if (key.toLowerCase() == sabor.toLowerCase()) {
        return mapa[key]!;
      }
    }
    
    // Si no encuentra, usar precio por defecto de Vainilla
    print('⚠️ Precio no encontrado para: $sabor, usando precio de Vainilla');
    return mapa['Vainilla'] ?? (esPorPorcion ? 3000 : 12000);
  }

  double _getUnitPrice(TortaConfiguration config) {
    if (config.sabor.isEmpty || config.tipoVenta.isEmpty) return 0;

    double basePrice = 0;
    
    if (config.tipoVenta == 'Por Porciones') {
      basePrice = _getPrecioBase(config.sabor, true);
      basePrice *= config.porciones;
    } else {
      basePrice = _getPrecioBase(config.sabor, false);
      basePrice *= config.libras;
    }

    // Incremento por relleno premium
    if (config.relleno == 'Nutella' || config.relleno == 'Dulce de Leche') {
      basePrice += (config.tipoVenta == 'Por Porciones') ? 
        (config.porciones * 500) : (config.libras * 2000);
    }

    return basePrice;
  }

  double get totalPrice {
    double total = 0;
    for (var config in tortaConfigurations) {
      total += _getUnitPrice(config);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: isLoadingData
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.pinkAccent),
                          SizedBox(height: 16),
                          Text('Cargando opciones...'),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
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
          widget.product.descripcion ?? 'Deliciosa torta personalizada',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        _buildMainQuantitySelector(),
        const SizedBox(height: 16),
        
        ...List.generate(quantity, (index) => _buildTortaConfiguration(index)),
        
        const SizedBox(height: 16),
        _buildPriceSummary(),
        const SizedBox(height: 16),
        _buildAddToCartBar(),
      ],
    );
  }

  Widget _buildTortaConfiguration(int index) {
    if (index >= tortaConfigurations.length) return Container();
    
    final config = tortaConfigurations[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Torta ${index + 1}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildDropdown(
              'Sabor de la Torta',
              config.sabor,
              sabores,
              (val) {
                setState(() {
                  config.sabor = val;
                });
              },
            ),
            
            _buildDropdown(
              'Relleno',
              config.relleno,
              rellenos,
              (val) {
                setState(() {
                  config.relleno = val;
                });
              },
            ),
            
            _buildDropdown(
              'Tipo de Venta',
              config.tipoVenta,
              ['Por Porciones', 'Por Libra'],
              (val) {
                setState(() {
                  config.tipoVenta = val;
                  config.porciones = 1;
                  config.libras = 0.5;
                });
              },
            ),
            
            if (config.tipoVenta.isNotEmpty)
              _buildConfigQuantitySelector(config),
            
            const SizedBox(height: 8),
            if (config.sabor.isNotEmpty && config.tipoVenta.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Precio: ${formatoCOP.format(_getUnitPrice(config))}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                    if (config.relleno == 'Nutella' || config.relleno == 'Dulce de Leche')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Relleno Premium',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigQuantitySelector(TortaConfiguration config) {
    if (config.tipoVenta == 'Por Porciones') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Número de Porciones:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  if (config.porciones > 1) {
                    setState(() => config.porciones--);
                  }
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${config.porciones} ${config.porciones == 1 ? 'porción' : 'porciones'}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => config.porciones++),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cantidad en Libras:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  if (config.libras > 0.5) {
                    setState(() => config.libras -= 0.5);
                  }
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${config.libras} ${config.libras == 1.0 ? 'libra' : 'libras'}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => config.libras += 0.5),
              ),
            ],
          ),
        ],
      );
    }
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
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.cake, size: 100, color: Colors.pinkAccent),
        ),
      ),
    );
  }

  Widget _buildMainQuantitySelector() {
    return Column(
      children: [
        const Text(
          'Número de Tortas:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                if (quantity > 1) {
                  setState(() {
                    quantity--;
                    tortaConfigurations.removeLast();
                  });
                }
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.pink[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$quantity ${quantity == 1 ? 'Torta' : 'Tortas'}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                setState(() {
                  quantity++;
                  final newConfig = TortaConfiguration();
                  newConfig.sabor = widget.product.nombreProducto;
                  newConfig.tipoVenta = 'Por Porciones';
                  newConfig.porciones = 1;
                  if (rellenos.isNotEmpty) {
                    newConfig.relleno = rellenos.first;
                  }
                  tortaConfigurations.add(newConfig);
                });
              },
            ),
          ],
        ),
      ],
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
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            onTap: _handleAddToCart,
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

  Widget _buildDropdown(String label, String currentValue, List<String> options,
      Function(String) onChanged) {
    
    final uniqueOptions = options.toSet().toList();
    
    // ✅ Si el dropdown es de sabor, asegurar que el nombre del producto esté en las opciones
    if (label == 'Sabor de la Torta') {
      final nombreProducto = widget.product.nombreProducto;
      if (!uniqueOptions.contains(nombreProducto)) {
        uniqueOptions.insert(0, nombreProducto);
      }
    }
    
    String? dropdownValue;
    if (currentValue.isEmpty && uniqueOptions.isNotEmpty) {
      dropdownValue = uniqueOptions.first;
    } else if (currentValue.isNotEmpty) {
      dropdownValue = currentValue;
    } else {
      dropdownValue = null;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(20, 0, 0, 0),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: dropdownValue,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              color: Color.fromARGB(255, 175, 76, 130),
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.pinkAccent),
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
          items: uniqueOptions
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              onChanged(val);
            }
          },
        ),
      ),
    );
  }

  void _handleAddToCart() {
    List<String> errors = [];
    
    for (int i = 0; i < tortaConfigurations.length; i++) {
      final config = tortaConfigurations[i];
      
      if (config.sabor.isEmpty) {
        errors.add('Torta ${i + 1}: Selecciona un sabor');
      }
      
      if (config.relleno.isEmpty) {
        errors.add('Torta ${i + 1}: Selecciona un relleno');
      }
      
      if (config.tipoVenta.isEmpty) {
        errors.add('Torta ${i + 1}: Selecciona el tipo de venta');
      }
    }
    
    if (errors.isNotEmpty) {
      _showValidationAlert(errors);
      return;
    }

    final cartService = Provider.of<CartService>(context, listen: false);
    final configuraciones = <ObleaConfiguration>[];

    for (int i = 0; i < tortaConfigurations.length; i++) {
      final config = tortaConfigurations[i];
      final unitPrice = _getUnitPrice(config);
      
      final tortaConfig = ObleaConfiguration()
        ..tipoOblea = 'Torta ${config.sabor} con ${config.relleno}'
        ..precio = unitPrice
        ..ingredientesPersonalizados = {
          'Sabor': config.sabor,
          'Relleno': config.relleno,
          'Tipo de Venta': config.tipoVenta,
          if (config.tipoVenta == 'Por Porciones')
            'Porciones': config.porciones.toString(),
          if (config.tipoVenta == 'Por Libra')
            'Libras': config.libras.toString(),
        };

      configuraciones.add(tortaConfig);
    }

    cartService.addToCart(
      producto: widget.product,
      cantidad: quantity,
      configuraciones: configuraciones,
    );

    _showSuccessAlert();
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
                                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Expanded(child: Text(error)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
        ),
      ),
    );
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
                    'Se ${quantity == 1 ? 'ha' : 'han'} añadido $quantity ${quantity == 1 ? 'torta' : 'tortas'} al carrito',
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

  void _resetForm() {
    setState(() {
      quantity = 1;
      tortaConfigurations = [TortaConfiguration()];
      
      if (tortaConfigurations.isNotEmpty) {
        tortaConfigurations[0].sabor = widget.product.nombreProducto;
        tortaConfigurations[0].tipoVenta = 'Por Porciones';
        tortaConfigurations[0].porciones = 1;
        
        if (rellenos.isNotEmpty) {
          tortaConfigurations[0].relleno = rellenos.first;
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class TortaConfiguration {
  String sabor = '';
  String relleno = '';
  String tipoVenta = '';
  int porciones = 1;
  double libras = 0.5;
  
  TortaConfiguration();
}