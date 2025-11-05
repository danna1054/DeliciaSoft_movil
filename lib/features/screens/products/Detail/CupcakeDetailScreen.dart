import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/General_models.dart' as GeneralModels;
import '../../../services/cart_services.dart';
import '../../../models/cart_models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CupcakeDetailScreen extends StatefulWidget {
  final GeneralModels.ProductModel product;

  const CupcakeDetailScreen({super.key, required this.product});

  @override
  State<CupcakeDetailScreen> createState() => _CupcakeDetailScreenState();
}

class _CupcakeDetailScreenState extends State<CupcakeDetailScreen> {
  String relleno = '';
  String topping = '';
  String cobertura = '';
  int cantidad = 1;

  List<String> rellenosDisponibles = [];
  List<String> toppingsDisponibles = [];

  final List<String> coberturasDisponibles = [
    'Crema de leche',
    'Crema chantilly',
    'Cobertura de chocolate',
  ];

  bool cargandoRellenos = false;
  bool cargandoToppings = false;

  double _precioTotal() => cantidad * widget.product.precioProducto;

  void _resetFormulario() {
    setState(() {
      relleno = '';
      topping = '';
      cobertura = '';
      cantidad = 1;
    });
  }

  @override
  void initState() {
    super.initState();
    _cargarDatosDesdeAPI();
  }

  Future<void> _cargarDatosDesdeAPI() async {
    setState(() {
      cargandoRellenos = true;
      cargandoToppings = true;
    });

    try {
      // Cargar rellenos
      final rellenoResponse = await http.get(
          Uri.parse('https://deliciasoft-backend-i6g9.onrender.com/api/catalogo-relleno'));
      
      if (rellenoResponse.statusCode == 200) {
        final List<dynamic> rellenoData = json.decode(rellenoResponse.body);
        setState(() {
          rellenosDisponibles = rellenoData
              .where((e) => e['estado'] == true)
              .map<String>((e) => e['nombre']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
          cargandoRellenos = false;
        });
      } else {
        debugPrint('Error al cargar rellenos: ${rellenoResponse.statusCode}');
        setState(() => cargandoRellenos = false);
      }
    } catch (e) {
      debugPrint('Error al cargar rellenos: $e');
      setState(() => cargandoRellenos = false);
    }

    try {
      // Cargar toppings
      final toppingResponse = await http.get(
          Uri.parse('https://deliciasoft-backend-i6g9.onrender.com/api/catalogo-toppings'));

      if (toppingResponse.statusCode == 200) {
        final List<dynamic> toppingData = json.decode(toppingResponse.body);
        setState(() {
          toppingsDisponibles = toppingData
              .where((e) => e['estado'] == true)
              .map<String>((e) => e['nombre']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
          cargandoToppings = false;
        });
      } else {
        debugPrint('Error al cargar toppings: ${toppingResponse.statusCode}');
        setState(() => cargandoToppings = false);
      }
    } catch (e) {
      debugPrint('Error al cargar toppings: $e');
      setState(() => cargandoToppings = false);
    }
  }

  void _agregarAlCarrito() {
    final cartService = Provider.of<CartService>(context, listen: false);
    
    List<String> errores = [];

    if (relleno.isEmpty) errores.add('Selecciona un relleno');
    if (topping.isEmpty) errores.add('Selecciona un topping');
    if (cobertura.isEmpty) errores.add('Selecciona una cobertura');

    if (errores.isNotEmpty) {
      _mostrarAlertaValidacion(errores);
      return;
    }

    final config = ObleaConfiguration()
      ..tipoOblea = 'Cupcake Personalizado'
      ..precio = widget.product.precioProducto
      ..ingredientesPersonalizados = {
        'Relleno': relleno,
        'Topping': topping,
        'Cobertura': cobertura,
        'Cantidad': '$cantidad ${cantidad == 1 ? 'cupcake' : 'cupcakes'}',
      };

    cartService.addToCart(
      producto: widget.product,
      cantidad: cantidad,
      configuraciones: [config],
    );

    _showSuccessAlert();
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImagenProducto(),
                    const SizedBox(height: 12),
                    Text(
                      widget.product.descripcion ?? 'Personaliza tu cupcake',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    _buildCantidadSelector(),
                    const SizedBox(height: 20),
                    _buildDropdown('Relleno', rellenosDisponibles, relleno,
                        (val) => setState(() => relleno = val!), cargandoRellenos),
                    const SizedBox(height: 20),
                    _buildDropdown('Topping', toppingsDisponibles, topping,
                        (val) => setState(() => topping = val!), cargandoToppings),
                    const SizedBox(height: 20),
                    _buildDropdown('Cobertura', coberturasDisponibles, cobertura,
                        (val) => setState(() => cobertura = val!), false),
                    const SizedBox(height: 20),
                    _buildResumenTotal(),
                    const SizedBox(height: 20),
                    _buildAddToCartBar(),
                  ],
                ),
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

  Widget _buildImagenProducto() {
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

  Widget _buildCantidadSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            if (cantidad > 1) {
              setState(() => cantidad--);
            }
          },
          icon: const Icon(Icons.remove_circle_outline, size: 32),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.pink[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$cantidad ${cantidad == 1 ? 'Cupcake' : 'Cupcakes'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: () => setState(() => cantidad++),
          icon: const Icon(Icons.add_circle_outline, size: 32),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String selectedValue,
    ValueChanged<String?> onChanged,
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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cargando opciones de $label...',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty && !isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No se pudieron cargar las opciones de $label',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final uniqueItems = items.where((item) => item.isNotEmpty).toSet().toList();
    final validSelectedValue = uniqueItems.contains(selectedValue) ? selectedValue : null;

    return DropdownButtonFormField<String>(
      value: validSelectedValue,
      decoration: _dropdownDecoration(label),
      items: uniqueItems
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildResumenTotal() {
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
        'Total: \$${_precioTotal().toStringAsFixed(0)}',
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
            'Total: \$${_precioTotal().toStringAsFixed(0)}',
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
              child: const Icon(
                Icons.add_shopping_cart_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarAlertaValidacion(List<String> errors) {
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
                'Se ${cantidad == 1 ? 'ha' : 'han'} añadido $cantidad ${cantidad == 1 ? 'cupcake' : 'cupcakes'} al carrito',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: \$${_precioTotal().toStringAsFixed(0)}',
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
                      _resetFormulario();
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
}