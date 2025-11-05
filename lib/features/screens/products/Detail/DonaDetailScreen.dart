import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/General_models.dart' as GeneralModels;
import '../../../services/cart_services.dart';
import '../../../models/cart_models.dart';

class DonasDetailScreen extends StatefulWidget {
  final GeneralModels.ProductModel product;

  const DonasDetailScreen({super.key, required this.product});

  @override
  State<DonasDetailScreen> createState() => _DonasDetailScreenState();
}

class _DonasDetailScreenState extends State<DonasDetailScreen> {
  int cantidadCombos = 1;
  final List<DonaComboConfiguration> donasConfig = [];

  final List<String> tiposCombo = [
    'Combo 5 mini donas (\$7000)',
    'Combo 10 mini donas (\$12000)',
    'Combo 20 mini donas (\$22000)',
  ];

  final Map<String, DonaComboDefaults> comboDefaults = {
    'Combo 5 mini donas (\$7000)': DonaComboDefaults(precio: 7000, maxToppings: 3),
    'Combo 10 mini donas (\$12000)': DonaComboDefaults(precio: 12000, maxToppings: 5),
    'Combo 20 mini donas (\$22000)': DonaComboDefaults(precio: 22000, maxToppings: 7),
  };

  List<String> toppingsDisponibles = [];
  List<String> salsasDisponibles = [];
  
  bool cargandoToppings = false;
  bool cargandoSalsas = false;

  final formatoCOP = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _inicializarCombos();
    _cargarToppingsDesdeAPI();
    _cargarSalsasDesdeAPI();
  }

  void _inicializarCombos() {
    donasConfig.clear();
    for (int i = 0; i < cantidadCombos; i++) {
      donasConfig.add(DonaComboConfiguration());
    }
  }

  Future<void> _cargarToppingsDesdeAPI() async {
    setState(() => cargandoToppings = true);
    try {
      final resp = await http.get(Uri.parse('https://deliciasoft-backend-i6g9.onrender.com/api/catalogo-toppings'));
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        setState(() {
          toppingsDisponibles = data
              .where((e) => e['estado'] == true)
              .map<String>((e) => e['nombre'].toString())
              .toList();
        });
      } else {
        print('Error al cargar toppings: ${resp.statusCode}');
      }
    } catch (e) {
      print('Error al conectar toppings: $e');
    } finally {
      setState(() => cargandoToppings = false);
    }
  }

  Future<void> _cargarSalsasDesdeAPI() async {
    setState(() => cargandoSalsas = true);
    try {
      final resp = await http.get(Uri.parse('https://deliciasoft-backend-i6g9.onrender.com/api/catalogo-salsas'));
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        setState(() {
          salsasDisponibles = data
              .where((e) => e['estado'] == true)
              .map<String>((e) => e['nombre'].toString())
              .toList();
        });
      } else {
        print('Error al cargar salsas: ${resp.statusCode}');
      }
    } catch (e) {
      print('Error al conectar salsas: $e');
    } finally {
      setState(() => cargandoSalsas = false);
    }
  }

  double _precioTotal() {
    return donasConfig.fold<double>(
        0,
        (prev, cfg) =>
            prev + (comboDefaults[cfg.tipoCombo]?.precio ?? 0));
  }

  void _agregarAlCarrito() {
    final cartService = Provider.of<CartService>(context, listen: false);
    
    final errores = <String>[];
    for (int i = 0; i < donasConfig.length; i++) {
      if (donasConfig[i].tipoCombo.isEmpty) {
        errores.add('Combo ${i + 1}: Debes elegir un tipo de combo.');
      }
    }
    
    if (errores.isNotEmpty) {
      _mostrarAlertaValidacion(errores);
      return;
    }

    final configuraciones = <ObleaConfiguration>[];
    
    for (int i = 0; i < donasConfig.length; i++) {
      final config = donasConfig[i];
      final defaults = comboDefaults[config.tipoCombo]!;
      
      final obleaConfig = ObleaConfiguration()
        ..tipoOblea = config.tipoCombo
        ..precio = defaults.precio
        ..ingredientesPersonalizados = {
          'Tipo Combo': config.tipoCombo,
          'Toppings': config.toppingsSeleccionados.join(', '),
          'Salsa': config.salsaSeleccionada.isEmpty ? 'Sin salsa' : config.salsaSeleccionada,
          'Número de Combo': '${i + 1}',
        };

      configuraciones.add(obleaConfig);
    }

    cartService.addToCart(
      producto: widget.product,
      cantidad: cantidadCombos,
      configuraciones: configuraciones,
    );

    // Mostrar alerta de éxito en lugar del SnackBar
    _showSuccessAlert();
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
                'Se ${cantidadCombos == 1 ? 'ha' : 'han'} añadido $cantidadCombos ${cantidadCombos == 1 ? 'combo' : 'combos'} al carrito',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${formatoCOP.format(_precioTotal())}',
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
                      Navigator.pop(context); // Cierra solo el diálogo
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
                      Navigator.pop(context); // Cierra el diálogo
                      Navigator.pop(context); // Regresa a la pantalla anterior
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            if (cargandoToppings || cargandoSalsas)
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: Colors.pinkAccent),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProductImage(),
                    const SizedBox(height: 12),
                    Text(
                      'Personaliza tu combo de mini donas',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    _buildComboQuantitySelector(),
                    const SizedBox(height: 20),
                    ...List.generate(cantidadCombos, (i) => _buildDonaCombo(i)),
                    const SizedBox(height: 12),
                    _buildTotalResumen(),
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

  Widget _buildAppBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        color: Colors.pinkAccent,
        child: Row(
          children: [
            IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.product.nombreProducto ?? 'Producto',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
            const SizedBox(width: 48),
          ],
        ),
      );

  Widget _buildProductImage() => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(widget.product.urlImg ?? '',
              height: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
            return const Icon(Icons.donut_small,
                size: 100, color: Colors.pinkAccent);
          }),
        ),
      );

  Widget _buildDonaCombo(int index) {
    final config = donasConfig[index];
    final defaults = comboDefaults[config.tipoCombo];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Combo ${index + 1}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: _dropdownDecoration('Tipo de combo'),
            value: config.tipoCombo.isEmpty ? null : config.tipoCombo,
            items: tiposCombo
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (val) {
              setState(() {
                config.tipoCombo = val!;
                config.toppingsSeleccionados.clear();
                config.salsaSeleccionada = '';
              });
            },
          ),
          const SizedBox(height: 12),
          if (defaults != null) _buildToppingsSelector(config, defaults),
          const SizedBox(height: 16),
          _buildSalsaSelector(config),
          const SizedBox(height: 12),
          if (defaults != null)
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Precio: ${formatoCOP.format(defaults.precio)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green)),
                  Text('${defaults.maxToppings} toppings máx.',
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                          fontSize: 14)),
                ])
        ]),
      ),
    );
  }

  Widget _buildToppingsSelector(DonaComboConfiguration cfg, DonaComboDefaults df) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Selecciona tus toppings:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
            Text('${cfg.toppingsSeleccionados.length}/${df.maxToppings}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cfg.toppingsSeleccionados.length >= df.maxToppings 
                        ? Colors.red 
                        : Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(maxHeight: 180),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: toppingsDisponibles.map((t) {
                final sel = cfg.toppingsSeleccionados.contains(t);
                final lim = cfg.toppingsSeleccionados.length >= df.maxToppings && !sel;
                return FilterChip(
                  selected: sel,
                  label: Text(t, style: const TextStyle(fontSize: 13)),
                  onSelected: lim
                      ? null
                      : (v) {
                          setState(() {
                            if (v) cfg.toppingsSeleccionados.add(t);
                            else cfg.toppingsSeleccionados.remove(t);
                          });
                        },
                  selectedColor: Colors.pinkAccent.withOpacity(0.2),
                  backgroundColor: Colors.grey[100],
                  checkmarkColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ),
        ),
      ]);

  Widget _buildSalsaSelector(DonaComboConfiguration cfg) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿Deseas alguna salsa o crema?',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
          const SizedBox(height: 6),
          cargandoSalsas
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  ),
                )
              : DropdownButtonFormField<String>(
                  decoration: _dropdownDecoration('Selecciona una opción'),
                  value:
                      cfg.salsaSeleccionada.isEmpty ? null : cfg.salsaSeleccionada,
                  items: salsasDisponibles
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      cfg.salsaSeleccionada = v ?? '';
                    });
                  },
                ),
        ],
      );

  InputDecoration _dropdownDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  Widget _buildComboQuantitySelector() => Column(children: [
        const Text('¿Cuántos combos quieres?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              onPressed: () {
                if (cantidadCombos > 1) {
                  setState(() {
                    cantidadCombos--;
                    donasConfig.removeLast();
                  });
                }
              },
              icon: const Icon(Icons.remove_circle_outline)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
                color: Colors.pink[100], borderRadius: BorderRadius.circular(12)),
            child: Text('$cantidadCombos ${cantidadCombos == 1 ? 'Combo' : 'Combos'}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          IconButton(
              onPressed: () {
                setState(() {
                  cantidadCombos++;
                  donasConfig.add(DonaComboConfiguration());
                });
              },
              icon: const Icon(Icons.add_circle_outline)),
        ])
      ]);

  Widget _buildTotalResumen() => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color.fromARGB(20, 0, 0, 0),
                blurRadius: 6,
                offset: Offset(0, 3)),
          ],
        ),
        child: Text('Total: ${formatoCOP.format(_precioTotal())}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _buildAddToCartBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
            color: Colors.pink[100], borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total: ${formatoCOP.format(_precioTotal())}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          GestureDetector(
            onTap: _agregarAlCarrito,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
                  ]),
              child: const Icon(Icons.add_shopping_cart_rounded,
                  color: Colors.white, size: 26),
            ),
          )
        ]),
      );

  void _mostrarAlertaValidacion(List<String> errores) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Campos Requeridos'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            children: errores.map((e) => Text('• $e')).toList()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'))
        ],
      ),
    );
  }
}

class DonaComboDefaults {
  final double precio;
  final int maxToppings;

  DonaComboDefaults({required this.precio, required this.maxToppings});
}

class DonaComboConfiguration {
  String tipoCombo = '';
  List<String> toppingsSeleccionados = [];
  String salsaSeleccionada = '';
}