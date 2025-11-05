import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/General_models.dart';
import '../../../services/cart_services.dart';
import '../../../models/cart_models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PostreDetailScreen extends StatefulWidget {
  final ProductModel product;

  const PostreDetailScreen({super.key, required this.product});

  @override
  State<PostreDetailScreen> createState() => _PostreDetailScreenState();
}

class _PostreDetailScreenState extends State<PostreDetailScreen> {
  int quantity = 1;
  
  List<PostreConfiguration> postreConfigurations = [];
  List<dynamic> saboresDisponibles = [];
  bool isLoadingSabores = true;
  String errorMessage = '';

  final formatoCOP = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  // Precios de cada tipo de postre
  final Map<String, PostreDefaults> postreDefaults = {
    'Gelatina (\$2000)': PostreDefaults(
      precio: 2000,
      descripcion: 'Gelatina refrescante y deliciosa',
    ),
    'Flan (\$3000)': PostreDefaults(
      precio: 3000,
      descripcion: 'Flan cremoso con textura suave',
    ),
    'Mousse (\$4000)': PostreDefaults(
      precio: 4000,
      descripcion: 'Mousse ligero y esponjoso',
    ),
    'Tiramisú (\$5000)': PostreDefaults(
      precio: 5000,
      descripcion: 'Tiramisú italiano auténtico',
    ),
    'Cheesecake (\$6000)': PostreDefaults(
      precio: 6000,
      descripcion: 'Cheesecake cremoso con base de galleta',
    ),
  };

  final List<String> tiposPostre = [
    'Gelatina (\$2000)',
    'Flan (\$3000)',
    'Mousse (\$4000)',
    'Tiramisú (\$5000)',
    'Cheesecake (\$6000)',
  ];

  @override
  void initState() {
    super.initState();
    _initializeConfigurations();
    _loadSabores();
  }

  void _initializeConfigurations() {
    postreConfigurations = List.generate(
      quantity, 
      (index) => PostreConfiguration()
    );
  }

  Future<void> _loadSabores() async {
    try {
      setState(() {
        isLoadingSabores = true;
        errorMessage = '';
      });

      final response = await http.get(Uri.parse('https://deliciasoft-backend-i6g9.onrender.com/api/catalogo-sabor'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          saboresDisponibles = jsonData;
          isLoadingSabores = false;
        });
      } else {
        setState(() {
          isLoadingSabores = false;
          errorMessage = 'Error al cargar sabores: Código ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoadingSabores = false;
        errorMessage = 'Error al cargar sabores: ${e.toString()}';
      });
    }
  }

  double _getUnitPrice(PostreConfiguration config) {
    if (config.tipoPostre.isEmpty) return 0;

    final defaults = postreDefaults[config.tipoPostre];
    double basePrice = defaults?.precio ?? 0;

    if (config.idSabor != null) {
      final sabor = saboresDisponibles.firstWhere(
        (s) => s["idSabor"] == config.idSabor,
        orElse: () => {
          "idSabor": 0,
          "nombre": "",
          "precioAdicion": 0,
          "idInsumos": 0,
          "estado": true,
        },
      );
      basePrice += (sabor["precioAdicion"] ?? 0).toDouble();
    }

    return basePrice;
  }

  double get totalPrice {
    double total = 0;
    for (var config in postreConfigurations) {
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
            if (isLoadingSabores)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Cargando sabores...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.pinkAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (errorMessage.isNotEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.pink[400],
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.pink[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSabores,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
            else
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
          widget.product.descripcion ?? 'Delicioso postre personalizado',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        _buildMainQuantitySelector(),
        const SizedBox(height: 16),
        
        ...List.generate(quantity, (index) => _buildPostreConfiguration(index)),
        
        const SizedBox(height: 16),
        _buildPriceSummary(),
        const SizedBox(height: 16),
        _buildAddToCartBar(),
      ],
    );
  }

  Widget _buildPostreConfiguration(int index) {
    if (index >= postreConfigurations.length) return Container();

    final config = postreConfigurations[index];
    final defaults = config.tipoPostre.isNotEmpty ? postreDefaults[config.tipoPostre] : null;

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
              'Postre ${index + 1}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(height: 12),

            _buildDropdown(
              'Tipo de Postre',
              config.tipoPostre,
              tiposPostre,
              (val) {
                setState(() {
                  config.tipoPostre = val;
                  config.idSabor = null;
                });
              },
            ),

            if (defaults != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descripción:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      defaults.descripcion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (config.tipoPostre.isNotEmpty && saboresDisponibles.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSaborDropdown(config),
            ],

            const SizedBox(height: 12),

            if (config.tipoPostre.isNotEmpty && saboresDisponibles.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.pink[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sabores disponibles:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: saboresDisponibles.map((sabor) {
                        final selected = config.idSabor == sabor['idSabor'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              config.idSabor = sabor['idSabor'];
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: selected ? Colors.pink[200] : Colors.pink[100],
                              borderRadius: BorderRadius.circular(12),
                              border: selected ? Border.all(color: Colors.pink[400]!, width: 2) : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  sabor['nombre'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                    color: Colors.pink,
                                  ),
                                ),
                                if ((sabor['precioAdicion'] ?? 0) > 0)
                                  Text(
                                    '+\$${(sabor['precioAdicion']).toString()}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.pink[700],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            if (config.tipoPostre.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Precio Base: ${formatoCOP.format(defaults?.precio ?? 0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                        if (config.idSabor != null)
                          Text(
                            'Adición Sabor: +${formatoCOP.format(_getSaborPrecioAdicion(config.idSabor!))}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.pink,
                              fontSize: 12,
                            ),
                          ),
                        Text(
                          'Total: ${formatoCOP.format(_getUnitPrice(config))}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.pink[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Precio Variable',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
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

  Widget _buildSaborDropdown(PostreConfiguration config) {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: 'Sabor',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      value: config.idSabor,
      items: saboresDisponibles.map<DropdownMenuItem<int>>((sabor) {
        return DropdownMenuItem<int>(
          value: sabor['idSabor'],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sabor['nombre'],
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if ((sabor['precioAdicion'] ?? 0) > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.pink[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+\$${(sabor['precioAdicion']).toString()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          config.idSabor = val;
        });
      },
    );
  }

  double _getSaborPrecioAdicion(int idSabor) {
    final sabor = saboresDisponibles.firstWhere(
      (s) => s["idSabor"] == idSabor,
      orElse: () => {"precioAdicion": 0},
    );
    return (sabor["precioAdicion"] ?? 0).toDouble();
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
          'Cantidad de Postres:',
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
                    postreConfigurations.removeLast();
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
                '$quantity ${quantity == 1 ? 'Postre' : 'Postres'}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                setState(() {
                  quantity++;
                  postreConfigurations.add(PostreConfiguration());
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
          value: currentValue.isEmpty ? null : currentValue,
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
          items: options
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (val) => val != null ? onChanged(val) : null,
        ),
      ),
    );
  }

  void _handleAddToCart() {
    List<String> errors = [];
    
    for (int i = 0; i < postreConfigurations.length; i++) {
      final config = postreConfigurations[i];
      
      if (config.tipoPostre.isEmpty) {
        errors.add('Postre ${i + 1}: Selecciona un tipo de postre');
      }
      
      if (config.idSabor == null) {
        errors.add('Postre ${i + 1}: Selecciona un sabor');
      }
    }
    
    if (errors.isNotEmpty) {
      _showValidationAlert(errors);
      return;
    }

    final cartService = Provider.of<CartService>(context, listen: false);
    final configuraciones = <ObleaConfiguration>[];

    for (int i = 0; i < postreConfigurations.length; i++) {
      final config = postreConfigurations[i];
      final unitPrice = _getUnitPrice(config);
      
      final sabor = saboresDisponibles.firstWhere(
        (s) => s["idSabor"] == config.idSabor,
        orElse: () => {"nombre": "Desconocido"},
      );
      
      final postreConfig = ObleaConfiguration()
        ..tipoOblea = '${config.tipoPostre} - ${sabor["nombre"]}'
        ..precio = unitPrice
        ..ingredientesPersonalizados = {
          'Tipo de Postre': config.tipoPostre,
          'Sabor': sabor["nombre"],
          'Precio Base': (postreDefaults[config.tipoPostre]?.precio ?? 0).toString(),
          'Adición Sabor': _getSaborPrecioAdicion(config.idSabor!).toString(),
        };

      configuraciones.add(postreConfig);
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

  void _showSuccessAlert() {
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
                child: const Icon(
                  Icons.shopping_cart,
                  color: Color.fromARGB(255, 160, 67, 112),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Éxito!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 175, 76, 137),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Se ${quantity == 1 ? 'ha' : 'han'} añadido $quantity ${quantity == 1 ? 'postre' : 'postres'} al carrito',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${formatoCOP.format(totalPrice)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 175, 76, 122),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color.fromARGB(255, 175, 76, 119),
                      side: const BorderSide(color: Color.fromARGB(255, 175, 76, 140)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Seguir comprando'),
                  ),
                  ElevatedButton(
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Volver al inicio'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      quantity = 1;
      postreConfigurations = [PostreConfiguration()];
    });
  }
}

class PostreConfiguration {
  String tipoPostre = '';
  int? idSabor;
  
  PostreConfiguration();
}

class PostreDefaults {
  final double precio;
  final String descripcion;
  
  PostreDefaults({
    required this.precio,
    required this.descripcion,
  });
}