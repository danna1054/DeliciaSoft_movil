import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cart_services.dart';
import '../services/venta_api_service.dart';
import '../providers/auth_provider.dart';
import '../models/cart_models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

class CheckoutScreen extends StatefulWidget {
  final int clientId;

  const CheckoutScreen({super.key, required this.clientId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observacionesController = TextEditingController();
  final _abonoController = TextEditingController();
  
  List<dynamic> _sedes = [];
  int? _sedeSeleccionada;
  DateTime? _fechaEntrega;
  String _metodoPago = 'Efectivo';
  XFile? _comprobanteImagen;
  bool _isLoading = false;
  bool _isLoadingSedes = true;
  double _totalPedido = 0;

  String _formatPrice(double price) {
    final priceStr = price.toStringAsFixed(0);
    return priceStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatNumberForDisplay(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  void initState() {
    super.initState();
    _cargarSedes();
    _calcularTotal();
  }

  void _calcularTotal() {
    final cartService = Provider.of<CartService>(context, listen: false);
    setState(() {
      _totalPedido = cartService.total;
      _abonoController.text = _formatNumberForDisplay(_totalPedido * 0.5);
    });
  }

  // ✅ MÉTODO CORREGIDO PARA CARGAR SEDES REALES
  Future<void> _cargarSedes() async {
    setState(() => _isLoadingSedes = true);
    try {
      print('📍 Cargando sedes desde API...');
      
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/sede'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('Status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> sedesData = jsonDecode(response.body);
        
        // Filtrar solo sedes activas
        final sedesActivas = sedesData.where((sede) => sede['estado'] == true).toList();
        
        print('✅ ${sedesActivas.length} sedes activas cargadas');
        
        if (mounted) {
          setState(() {
            _sedes = sedesActivas;
            _isLoadingSedes = false;
            
            // Seleccionar primera sede por defecto
            if (_sedes.isNotEmpty) {
              _sedeSeleccionada = _sedes[0]['idsede'];
              print('Sede seleccionada por defecto: $_sedeSeleccionada');
            }
          });
        }
      } else {
        throw Exception('Error al cargar sedes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al cargar sedes: $e');
      if (mounted) {
        setState(() => _isLoadingSedes = false);
        _mostrarMensaje('Error al cargar sedes: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime ahora = DateTime.now();
    final DateTime minFecha = ahora.add(const Duration(days: 15));
    final DateTime maxFecha = ahora.add(const Duration(days: 30));
    
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _fechaEntrega ?? minFecha,
        firstDate: minFecha,
        lastDate: maxFecha,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.pink[400]!,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
        helpText: 'Seleccionar fecha de entrega',
        cancelText: 'Cancelar',
        confirmText: 'Aceptar',
      );
      
      if (picked != null) {
        setState(() => _fechaEntrega = picked);
      }
    } catch (e) {
      _mostrarMensaje('Error al abrir calendario', Colors.red);
    }
  }

  Future<void> _seleccionarComprobante() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _comprobanteImagen = image);
      }
    } catch (e) {
      _mostrarMensaje('Error al seleccionar imagen: $e', Colors.red);
    }
  }

  // ✅ FUNCIÓN CORREGIDA - SIN MENSAJE PERSONALIZADO
  Future<void> _procesarPedido() async {
    if (!_formKey.currentState!.validate()) return;
    
    final cartService = Provider.of<CartService>(context, listen: false);
    
    // Validaciones
    int totalProductos = cartService.items.fold(0, (sum, item) => sum + item.cantidad);
    if (totalProductos < 10) {
      _mostrarMensaje(
        'Debes tener mínimo 10 productos en tu carrito. Actualmente tienes $totalProductos.',
        Colors.orange,
      );
      return;
    }
    
    if (_sedeSeleccionada == null) {
      _mostrarMensaje('Selecciona una sede para recoger', Colors.orange);
      return;
    }
    
    if (_fechaEntrega == null) {
      _mostrarMensaje('Selecciona una fecha de entrega', Colors.orange);
      return;
    }
    
    String abonoText = _abonoController.text.replaceAll('.', '').replaceAll(',', '');
    final double abonoIngresado = double.tryParse(abonoText) ?? 0;
    final double minimoAbono = _totalPedido * 0.5;
    
    if (abonoIngresado < minimoAbono) {
      _mostrarMensaje('El abono mínimo es del 50%: \$${_formatPrice(minimoAbono)}', Colors.orange);
      return;
    }
    
    if (_metodoPago == 'Transferencia' && _comprobanteImagen == null) {
      _mostrarMensaje('Debes subir el comprobante de transferencia', Colors.orange);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      print('🚀 ======================================');
      print('🚀 INICIANDO PROCESO DE CREACIÓN DE VENTA/PEDIDO');
      print('🚀 ======================================');

      // 1️⃣ PREPARAR DETALLES DE VENTA - SIN IVA
      final List<Map<String, dynamic>> detalleVenta = cartService.items.map((CartItem item) {
        return {
          'idproductogeneral': item.producto.idProductoGeneral,
          'cantidad': item.cantidad,
          'preciounitario': item.precioUnitario,
          'subtotal': item.subtotal,
          'iva': 0.0, // ✅ IVA en 0
        };
      }).toList();

      print('📦 Productos a enviar: ${detalleVenta.length}');
      detalleVenta.forEach((detalle) {
        print('   - ID: ${detalle['idproductogeneral']}, Cant: ${detalle['cantidad']}, Subtotal: ${detalle['subtotal']}');
      });

      // 2️⃣ CREAR VENTA CON TIPO "PEDIDO" - SOLO CON OBSERVACIONES
      print('\n📝 Creando venta tipo PEDIDO...');
      print('   - Sede: $_sedeSeleccionada');
      print('   - Fecha de entrega: ${_fechaEntrega!.toIso8601String()}');
      print('   - Observaciones: ${_observacionesController.text}');
      
      final ventaResponse = await VentaApiService.createVentaConPedido(
        fechaVenta: DateTime.now(),
        idCliente: widget.clientId,
        idSede: _sedeSeleccionada!, // ✅ Ahora tiene la sede real
        metodoPago: _metodoPago,
        tipoVenta: 'pedido',
        total: _totalPedido,
        detalleVenta: detalleVenta,
        estadoVentaId: 1,
        fechaEntrega: _fechaEntrega!,
        observaciones: _observacionesController.text.isNotEmpty 
            ? _observacionesController.text.trim() 
            : null,
        // ✅ ELIMINADO: mensajePersonalizado
      );

      print('✅ Venta creada correctamente');
      print('   - ID Venta: ${ventaResponse['idventa']}');
      
      final int idVenta = ventaResponse['idventa'] is int 
          ? ventaResponse['idventa'] 
          : int.parse(ventaResponse['idventa'].toString());

      print('   - ID confirmado: $idVenta');

      // 3️⃣ CREAR ABONO
      print('\n💰 Creando abono...');
      print('   - Método: $_metodoPago');
      print('   - Monto: \$${abonoIngresado.toStringAsFixed(2)}');

      bool abonoExitoso = false;
      String mensajeErrorAbono = '';

      try {
        await VentaApiService.createAbonoWithImage(
          idVenta: idVenta,
          metodoPago: _metodoPago,
          cantidadPagar: abonoIngresado,
          imagenComprobante: _comprobanteImagen,
        );
        
        abonoExitoso = true;
        print('✅ Abono creado exitosamente');
        
      } catch (abonoError) {
        print('❌ Error al crear abono: $abonoError');
        mensajeErrorAbono = abonoError.toString();
      }

      // 4️⃣ RESULTADO FINAL
      print('\n📊 ======================================');
      print('📊 RESUMEN FINAL');
      print('📊 ======================================');
      print('📊 Venta creada: ✅');
      print('📊 Venta ID: $idVenta');
      print('📊 Sede: $_sedeSeleccionada');
      print('📊 Abono exitoso: ${abonoExitoso ? "✅" : "❌"}');
      print('📊 ======================================');

      setState(() => _isLoading = false);
      cartService.clearCart();
      
      if (abonoExitoso) {
        _mostrarDialogoExito(idVenta);
      } else {
        _mostrarDialogoExitoConAdvertencia(idVenta, mensajeErrorAbono);
      }

    } catch (e, stackTrace) {
      print('❌ ======================================');
      print('❌ ERROR CRÍTICO EN PROCESO COMPLETO');
      print('❌ Error: $e');
      print('❌ StackTrace: $stackTrace');
      print('❌ ======================================');
      
      setState(() => _isLoading = false);
      
      String errorMessage = 'Error al procesar pedido';
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        errorMessage = 'Error de conexión. Verifica tu internet.';
      } else if (e.toString().contains('Timeout') || e.toString().contains('agotado')) {
        errorMessage = 'Tiempo de espera agotado. Intenta nuevamente.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Error al procesar la respuesta del servidor.';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      _mostrarMensaje(errorMessage, Colors.red);
    }
  }

  void _mostrarDialogoExito(int idVenta) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Pedido Exitoso!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tu pedido #$idVenta ha sido registrado correctamente.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Recibirás una confirmación pronto.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[400],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Aceptar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoExitoConAdvertencia(int idVenta, String errorAbono) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 60),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Pedido Creado!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tu pedido #$idVenta ha sido registrado correctamente.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '⚠️ Hubo un problema al registrar el abono:\n$errorAbono\n\nContacta al administrador.',
              style: TextStyle(fontSize: 13, color: Colors.orange[700], fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[400],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Aceptar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarMensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _abonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Finalizar Compra', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink[400],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.pink[400]),
                  const SizedBox(height: 16),
                  const Text('Procesando pedido...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text(
                    'Por favor espera...',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildResumenPedido(),
                    const SizedBox(height: 20),
                    _buildSedeSelector(),
                    const SizedBox(height: 20),
                    _buildFechaSelector(),
                    const SizedBox(height: 20),
                    _buildMetodoPagoSelector(),
                    const SizedBox(height: 20),
                    _buildAbonoInput(),
                    if (_metodoPago == 'Transferencia') ...[
                      const SizedBox(height: 20),
                      _buildComprobanteUpload(),
                    ],
                    const SizedBox(height: 20),
                    _buildObservacionesInput(),
                    const SizedBox(height: 30),
                    _buildConfirmButton(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildResumenPedido() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, color: Colors.pink, size: 24),
              SizedBox(width: 8),
              Text(
                'Resumen del Pedido',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${_formatPrice(_totalPedido)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[400],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Información importante:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  '• Mínimo 10 productos por pedido\n• Entrega en 15-30 días\n• Abono mínimo 50%',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ SELECTOR DE SEDE CORREGIDO - USA SEDES REALES
  Widget _buildSedeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store, color: Colors.pink[400], size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sede para recoger',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_isLoadingSedes)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.pink),
              ),
            )
          else if (_sedes.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No hay sedes disponibles',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<int>(
              value: _sedeSeleccionada,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.pink[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _sedes.map((sede) {
                return DropdownMenuItem<int>(
                  value: sede['idsede'],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sede['nombre'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (sede['direccion'] != null)
                        Text(
                          sede['direccion'],
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _sedeSeleccionada = value);
                print('Sede seleccionada: $value');
              },
              validator: (value) => value == null ? 'Selecciona una sede' : null,
            ),
        ],
      ),
    );
  }

  Widget _buildFechaSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.pink[400], size: 24),
              const SizedBox(width: 8),
              const Text('Fecha de entrega', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _seleccionarFecha,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink[50]!, Colors.pink[100]!.withOpacity(0.3)],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.pink[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.pink[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _fechaEntrega == null
                          ? 'Seleccionar fecha'
                          : '${_fechaEntrega!.day}/${_fechaEntrega!.month}/${_fechaEntrega!.year}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _fechaEntrega == null ? Colors.grey[600] : Colors.black,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 18, color: Colors.pink[400]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodoPagoSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.pink[400], size: 24),
              const SizedBox(width: 8),
              const Text('Método de pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetodoPagoOption('Efectivo', Icons.money),
          const SizedBox(height: 10),
          _buildMetodoPagoOption('Transferencia', Icons.account_balance),
        ],
      ),
    );
  }

  Widget _buildMetodoPagoOption(String metodo, IconData icon) {
    final bool isSelected = _metodoPago == metodo;
    return GestureDetector(
      onTap: () {
        setState(() {
          _metodoPago = metodo;
          if (metodo == 'Efectivo') {
            _comprobanteImagen = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? Colors.pink[400]! : Colors.grey[300]!, width: 2),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: metodo,
              groupValue: _metodoPago,
              onChanged: (value) {
                setState(() {
                  _metodoPago = value!;
                  if (value == 'Efectivo') {
                    _comprobanteImagen = null;
                  }
                });
              },
              activeColor: Colors.pink[400],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.pink[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? Colors.pink[700] : Colors.grey[600], size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              metodo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.pink[700] : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbonoInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: Colors.pink[400], size: 24),
              const SizedBox(width: 8),
              const Text('Abono (mínimo 50%)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _abonoController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.monetization_on, color: Colors.pink[400]),
              hintText: 'Ingresa el monto del abono',
              filled: true,
              fillColor: Colors.pink[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.pink[200]!, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.pink[400]!, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa el monto del abono';
              }
              
              String valorLimpio = value.replaceAll('.', '');
              final double? monto = double.tryParse(valorLimpio);
              
              if (monto == null) {
                return 'Ingresa un monto válido';
              }
              
              if (monto < _totalPedido * 0.5) {
                return 'El abono debe ser mínimo el 50% (\${_formatPrice(_totalPedido * 0.5)})';
              }
              
              if (monto > _totalPedido) {
                return 'El abono no puede ser mayor al total';
              }
              
              return null;
            },
            onChanged: (value) {
              if (value.isNotEmpty) {
                String cleanValue = value.replaceAll('.', '');
                if (cleanValue.isNotEmpty) {
                  double? numericValue = double.tryParse(cleanValue);
                  if (numericValue != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _abonoController.value = _abonoController.value.copyWith(
                        text: _formatNumberForDisplay(numericValue),
                        selection: TextSelection.collapsed(offset: _formatNumberForDisplay(numericValue).length),
                      );
                    });
                  }
                }
              }
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Abono mínimo: \${_formatPrice(_totalPedido * 0.5)}',
                    style: TextStyle(fontSize: 13, color: Colors.green[900], fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComprobanteUpload() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upload_file, color: Colors.pink[400], size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Comprobante de transferencia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Requerido',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_comprobanteImagen != null) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.pink[200]!, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  children: [
                    Image.file(
                      File(_comprobanteImagen!.path), 
                      height: 200, 
                      width: double.infinity, 
                      fit: BoxFit.cover
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: () {
                            setState(() {
                              _comprobanteImagen = null;
                            });
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Comprobante cargado',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          ElevatedButton.icon(
            onPressed: _seleccionarComprobante,
            icon: Icon(
              _comprobanteImagen == null ? Icons.camera_alt : Icons.change_circle, 
              size: 24
            ),
            label: Text(
              _comprobanteImagen == null ? 'Subir Comprobante' : 'Cambiar Comprobante',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink[400],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ SOLO OBSERVACIONES - SIN MENSAJE PERSONALIZADO
  Widget _buildObservacionesInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt, color: Colors.pink[400], size: 24),
              const SizedBox(width: 8),
              const Text('Observaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('(opcional)', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _observacionesController,
            maxLines: 4,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Detalles adicionales sobre el pedido...',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.pink[400]!, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.4),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _procesarPedido,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink[400],
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 28),
            SizedBox(width: 12),
            Text('Confirmar Pedido', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}