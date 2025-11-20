// lib/screens/productos/product_customization_screen.dart
import 'package:flutter/material.dart';
import '../../models/producto_general.dart';
import '../../models/configuracion.dart';
import '../../services/catalogo_adiciones_service.dart';
import '../../services/catalogo_relleno_service.dart';
import '../../services/catalogo_sabor_service.dart';
import '../../services/catalogo_salsa_service.dart';
import '../../services/catalogo_topping_service.dart';

class ProductCustomizationScreen extends StatefulWidget {
  final ProductModel producto;
  final ConfiguracionProducto configuracion;

  const ProductCustomizationScreen({
    super.key,
    required this.producto,
    required this.configuracion,
  });

  @override
  State<ProductCustomizationScreen> createState() => _ProductCustomizationScreenState();
}

class _ProductCustomizationScreenState extends State<ProductCustomizationScreen> {
  List<String> saboresSeleccionados = [];
  List<String> rellenosSeleccionados = [];
  List<String> toppingsSeleccionados = [];
  List<String> salsasSeleccionadas = [];
  List<String> adicionesSeleccionadas = [];

  // LISTAS DINÁMICAS DESDE API
  List<String> saboresDisponibles = [];
  List<String> rellenosDisponibles = [];
  List<String> toppingsDisponibles = [];
  List<String> salsasDisponibles = [];
  List<String> adicionesDisponibles = [];

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarOpcionesDisponibles();
  }

  Future<void> _cargarOpcionesDisponibles() async {
    try {
      final saborService = CatalogoSaborService();
      final rellenoService = CatalogoRellenoService();
      final toppingService = CatalogoToppingService();
      final salsaService = CatalogoSalsaService();
      final adicionService = CatalogoAdicionesService();

      final resultados = await Future.wait([
        saborService.obtenerSabores(),
        rellenoService.obtenerRellenos(),
        toppingService.obtenerToppings(),
        salsaService.obtenerSalsas(),
        adicionService.obtenerAdiciones(),
      ]);

      setState(() {
        saboresDisponibles = resultados[0];
        rellenosDisponibles = resultados[1];
        toppingsDisponibles = resultados[2];
        salsasDisponibles = resultados[3];
        adicionesDisponibles = resultados[4];
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      // Opcional: Mostrar error o usar valores por defecto
      print('Error cargando opciones: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.amber,
      ),
    );
  }

  String _crearResumenPersonalizacion() {
    List<String> partes = [];
    if (saboresSeleccionados.isNotEmpty) partes.add('Sabores: ${saboresSeleccionados.join(", ")}');
    if (rellenosSeleccionados.isNotEmpty) partes.add('Rellenos: ${rellenosSeleccionados.join(", ")}');
    if (toppingsSeleccionados.isNotEmpty) partes.add('Toppings: ${toppingsSeleccionados.join(", ")}');
    if (salsasSeleccionadas.isNotEmpty) partes.add('Salsas: ${salsasSeleccionadas.join(", ")}');
    if (adicionesSeleccionadas.isNotEmpty) partes.add('Adiciones: ${adicionesSeleccionadas.join(", ")}');
    return partes.join(' | ');
  }

  void _validarYAgregarAlCarrito() {
    if (widget.configuracion.permiteSabores && 
        saboresSeleccionados.isEmpty && 
        widget.configuracion.limiteSabor > 0) {
      _mostrarError('Debes seleccionar al menos un sabor');
      return;
    }

    if (widget.configuracion.permiteRellenos && 
        rellenosSeleccionados.isEmpty && 
        widget.configuracion.limiteRelleno > 0) {
      _mostrarError('Debes seleccionar al menos un relleno');
      return;
    }

    String resumen = _crearResumenPersonalizacion();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.producto.nombreProducto} añadido',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (resumen.isNotEmpty)
              Text(resumen, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.pop(context);
  }

 @override
Widget build(BuildContext context) {
  // AGREGAR ESTA VALIDACIÓN DE CARGA
  if (_cargando) {
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
          'Personaliza tu ${widget.producto.nombreProducto}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.pinkAccent),
            SizedBox(height: 16),
            Text(
              'Cargando opciones...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TU CÓDIGO ORIGINAL (cuando ya cargó)
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
        'Personaliza tu ${widget.producto.nombreProducto}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    body: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductHeader(),
                const SizedBox(height: 24),

                if (widget.configuracion.permiteSabores)
                  _buildSelectorSection(
                    titulo: 'Sabores',
                    icono: Icons.cake,
                    opciones: saboresDisponibles,
                    seleccionados: saboresSeleccionados,
                    limite: widget.configuracion.limiteSabor,
                    onChanged: (seleccion) {
                      setState(() => saboresSeleccionados = seleccion);
                    },
                  ),

                if (widget.configuracion.permiteRellenos)
                  _buildSelectorSection(
                    titulo: 'Rellenos',
                    icono: Icons.layers,
                    opciones: rellenosDisponibles,
                    seleccionados: rellenosSeleccionados,
                    limite: widget.configuracion.limiteRelleno,
                    onChanged: (seleccion) {
                      setState(() => rellenosSeleccionados = seleccion);
                    },
                  ),

                if (widget.configuracion.permiteToppings)
                  _buildSelectorSection(
                    titulo: 'Toppings',
                    icono: Icons.stars,
                    opciones: toppingsDisponibles,
                    seleccionados: toppingsSeleccionados,
                    limite: widget.configuracion.limiteTopping,
                    onChanged: (seleccion) {
                      setState(() => toppingsSeleccionados = seleccion);
                    },
                  ),

                if (widget.configuracion.permiteSalsas)
                  _buildSelectorSection(
                    titulo: 'Salsas',
                    icono: Icons.water_drop,
                    opciones: salsasDisponibles,
                    seleccionados: salsasSeleccionadas,
                    limite: widget.configuracion.limiteSalsa,
                    onChanged: (seleccion) {
                      setState(() => salsasSeleccionadas = seleccion);
                    },
                  ),

                if (widget.configuracion.permiteAdiciones)
                  _buildSelectorSection(
                    titulo: 'Adiciones Extra',
                    icono: Icons.add_circle_outline,
                    opciones: adicionesDisponibles,
                    seleccionados: adicionesSeleccionadas,
                    limite: 3,
                    onChanged: (seleccion) {
                      setState(() => adicionesSeleccionadas = seleccion);
                    },
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        _buildBottomButton(),
      ],
    ),
  );
}

  Widget _buildProductHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.producto.urlImg ?? '',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: Colors.pink[50],
                child: Icon(Icons.image_not_supported, size: 40, color: Colors.pink[200]),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.producto.nombreProducto,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.producto.precioFormateado,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorSection({
    required String titulo,
    required IconData icono,
    required List<String> opciones,
    required List<String> seleccionados,
    required int limite,
    required Function(List<String>) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink[100]!, width: 1),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: Colors.pinkAccent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber, width: 1.5),
                ),
                child: Text(
                  'Máx: $limite',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: opciones.map((opcion) {
              final estaSeleccionado = seleccionados.contains(opcion);
              final puedeSeleccionar = seleccionados.length < limite || estaSeleccionado;
              
              return GestureDetector(
                onTap: () {
                  if (estaSeleccionado) {
                    onChanged(seleccionados.where((s) => s != opcion).toList());
                  } else if (puedeSeleccionar) {
                    onChanged([...seleccionados, opcion]);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Solo puedes elegir $limite $titulo'),
                        backgroundColor: Colors.amber,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: estaSeleccionado ? Colors.pinkAccent : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: estaSeleccionado ? Colors.pinkAccent : Colors.pink[200]!,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    opcion,
                    style: TextStyle(
                      color: estaSeleccionado ? Colors.white : Colors.black87,
                      fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -3),
          )
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _validarYAgregarAlCarrito,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Añadir al carrito",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}