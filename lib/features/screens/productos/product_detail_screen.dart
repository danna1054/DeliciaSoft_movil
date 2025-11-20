// lib/screens/productos/product_detail_screen.dart
import 'package:flutter/material.dart';
import '../../models/producto_general.dart';
import '../../models/configuracion.dart';
import '../../services/configuracion_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel producto;

  const ProductDetailScreen({
    super.key,
    required this.producto,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<ConfiguracionProducto?> _futureConfig;
  
  // Variables para personalización
  int cantidad = 1;
  String? saborSeleccionado;
  String? rellenoSeleccionado;
  String? toppingSeleccionado;
  String? salsaSeleccionada;
  String? tipoVentaSeleccionado;

  @override
  void initState() {
    super.initState();
    _futureConfig = ConfiguracionService()
        .obtenerConfiguracionProducto(widget.producto.idProductoGeneral);
  }

  void _incrementarCantidad() {
    setState(() {
      cantidad++;
    });
  }

  void _decrementarCantidad() {
    if (cantidad > 1) {
      setState(() {
        cantidad--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.producto.nombreProducto,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<ConfiguracionProducto?>(
        future: _futureConfig,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.pinkAccent),
              ),
            );
          }

          final configuracion = snapshot.data;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Imagen del producto en tarjeta
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        widget.producto.urlImg ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[100],
                          child: Icon(
                            Icons.image_not_supported,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Contenedor principal centrado
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Nombre del producto - centrado
                      Text(
                        widget.producto.nombreProducto,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Precio - centrado
                      Text(
                        widget.producto.precioFormateado,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.pinkAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (widget.producto.especificacionesReceta != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.producto.especificacionesReceta!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],

                      const SizedBox(height: 30),

                      // Selector de cantidad - centrado
                      const Text(
                        "Cantidad",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCantidadButton(
                            icon: Icons.remove,
                            onTap: _decrementarCantidad,
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4EC),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '$cantidad',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildCantidadButton(
                            icon: Icons.add,
                            onTap: _incrementarCantidad,
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Sección de personalización
                      if (configuracion != null && configuracion.permitePersonalizacion) ...[
                        const Text(
                          "Personalización",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (configuracion.permiteSabores)
                          _buildDropdownField(
                            label: "Sabor",
                            hint: "Selecciona un sabor",
                            value: saborSeleccionado,
                            icon: Icons.cake_outlined,
                            items: ['Chocolate', 'Vainilla', 'Fresa', 'Arequipe'],
                            onChanged: (value) {
                              setState(() {
                                saborSeleccionado = value;
                              });
                            },
                          ),

                        if (configuracion.permiteRellenos)
                          _buildDropdownField(
                            label: "Relleno",
                            hint: "Selecciona un relleno",
                            value: rellenoSeleccionado,
                            icon: Icons.layers_outlined,
                            items: ['Arequipe', 'Chocolate', 'Frutas', 'Crema'],
                            onChanged: (value) {
                              setState(() {
                                rellenoSeleccionado = value;
                              });
                            },
                          ),

                        if (configuracion.permiteToppings)
                          _buildDropdownField(
                            label: "Topping",
                            hint: "Selecciona un topping",
                            value: toppingSeleccionado,
                            icon: Icons.stars_outlined,
                            items: ['Chispas', 'Nueces', 'Frutas', 'Caramelo'],
                            onChanged: (value) {
                              setState(() {
                                toppingSeleccionado = value;
                              });
                            },
                          ),

                        if (configuracion.permiteSalsas)
                          _buildDropdownField(
                            label: "Salsa",
                            hint: "Selecciona una salsa",
                            value: salsaSeleccionada,
                            icon: Icons.water_drop_outlined,
                            items: ['Chocolate', 'Caramelo', 'Fresa', 'Mora'],
                            onChanged: (value) {
                              setState(() {
                                salsaSeleccionada = value;
                              });
                            },
                          ),

                        if (configuracion.permiteAdiciones)
                          _buildDropdownField(
                            label: "Tipo de Venta",
                            hint: "Selecciona tipo",
                            value: tipoVentaSeleccionado,
                            icon: Icons.shopping_bag_outlined,
                            items: ['Por Porciones', 'Torta Completa'],
                            onChanged: (value) {
                              setState(() {
                                tipoVentaSeleccionado = value;
                              });
                            },
                          ),
                      ],

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // Botón flotante
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "${widget.producto.nombreProducto} añadido al carrito",
                  ),
                  backgroundColor: Colors.pinkAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Añadir al carrito",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCantidadButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[300]!, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 26, color: Colors.black87),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[300]!, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                hint: Row(
                  children: [
                    Icon(icon, color: Colors.grey[400], size: 22),
                    const SizedBox(width: 12),
                    Text(
                      hint,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.pinkAccent,
                  size: 28,
                ),
                dropdownColor: Colors.white,
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Row(
                      children: [
                        Icon(icon, color: Colors.pinkAccent, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          item,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}