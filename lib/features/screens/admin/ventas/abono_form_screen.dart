// lib/screens/ventas/abonos/abono_form_screen.dart
import 'package:flutter/material.dart';
import '../../../models/venta/abono.dart';
import '../../../services/venta_api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AbonoFormScreen extends StatefulWidget {
  final int idPedido; // En realidad es el ID de la venta
  final Abono? abono;
  final double totalPedido;

  const AbonoFormScreen({
    super.key,
    required this.idPedido,
    this.abono,
    required this.totalPedido,
  });

  @override
  State<AbonoFormScreen> createState() => _AbonoFormScreenState();
}

class _AbonoFormScreenState extends State<AbonoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cantidadPagarController;
  String? _selectedMetodoPago;
  XFile? _selectedImage;
  String? _existingImageUrl;
  double _currentAbonosSum = 0.0;
  bool _isLoading = false;

  // Paleta de colores
  static const Color _primaryRose = Color.fromRGBO(228, 48, 84, 1);
  static const Color _darkGrey = Color(0xFF333333);
  static const Color _textGrey = Color(0xFF6B7A8C);
  static const Color _accentGreen = Color(0xFF6EC67F);
  static const Color _accentRed = Color(0xFFE57373);

  // ✅ MÉTODOS DE PAGO VÁLIDOS
  static const List<String> _metodosPagoValidos = [
    'Efectivo',
    'Transferencia',
  ];

  // ✅ TAMAÑO MÁXIMO DE IMAGEN (5MB)
  static const int _maxImageSizeBytes = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _cantidadPagarController = TextEditingController(
      text: widget.abono?.cantidadPagar?.toStringAsFixed(0) ?? ''
    );
    _selectedMetodoPago = widget.abono?.metodoPago;
    _existingImageUrl = widget.abono?.urlImagen;
    _fetchCurrentAbonosSum();
  }

  @override
  void dispose() {
    _cantidadPagarController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentAbonosSum() async {
    try {
      final abonos = await VentaApiService.getAbonosByVentaId(widget.idPedido);
      double sum = 0.0;
      
      for (var abono in abonos) {
        // Excluir el abono actual si estamos editando
        if (widget.abono != null && abono.idAbono == widget.abono!.idAbono) {
          continue;
        }
        sum += abono.cantidadPagar ?? 0.0;
      }
      
      if (mounted) {
        setState(() {
          _currentAbonosSum = sum;
        });
      }
      
      print('💰 Suma actual de abonos: \$${sum.toStringAsFixed(2)}');
    } catch (e) {
      print('⚠️ Error al obtener suma de abonos: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        // ✅ VALIDAR TAMAÑO DE IMAGEN
        final bytes = await image.readAsBytes();
        final sizeInBytes = bytes.length;
        final sizeInMB = sizeInBytes / (1024 * 1024);
        
        print('📸 Imagen seleccionada:');
        print('  Nombre: ${image.name}');
        print('  Tamaño: ${sizeInMB.toStringAsFixed(2)} MB');
        print('  Tipo: ${image.mimeType ?? "desconocido"}');
        
        if (sizeInBytes > _maxImageSizeBytes) {
          _showErrorSnackBar(
            'Imagen muy grande (${sizeInMB.toStringAsFixed(1)}MB). Máximo 5MB.'
          );
          return;
        }
        
        // ✅ VALIDAR TIPO DE ARCHIVO
        final fileName = image.name.toLowerCase();
        if (!fileName.endsWith('.jpg') && 
            !fileName.endsWith('.jpeg') && 
            !fileName.endsWith('.png')) {
          _showErrorSnackBar('Solo se permiten imágenes JPG, JPEG o PNG');
          return;
        }
        
        setState(() {
          _selectedImage = image;
        });
        print('✅ Imagen válida y lista para subir');
      }
    } catch (e) {
      print('❌ Error al seleccionar imagen: $e');
      _showErrorSnackBar('Error al seleccionar imagen');
    }
  }

  void _saveAbono() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMetodoPago == null || _selectedMetodoPago!.isEmpty) {
      _showErrorSnackBar('Por favor, seleccione un método de pago');
      return;
    }

    if (_selectedMetodoPago!.length > 20) {
      _showErrorSnackBar('Método de pago muy largo (máximo 20 caracteres)');
      return;
    }

    final cantidadPagar = double.tryParse(_cantidadPagarController.text);
    if (cantidadPagar == null || cantidadPagar <= 0) {
      _showErrorSnackBar('Cantidad inválida');
      return;
    }

    // ✅ VALIDAR QUE NO EXCEDA EL SALDO PENDIENTE
    final currentAbonoValue = widget.abono?.cantidadPagar ?? 0.0;
    final saldoDisponible = widget.totalPedido - _currentAbonosSum;
    
    if (cantidadPagar > saldoDisponible + currentAbonoValue + 0.01) {
      _showErrorSnackBar(
        'El monto excede el saldo pendiente. Máximo: \$${(saldoDisponible + currentAbonoValue).toStringAsFixed(2)}'
      );
      return;
    }

    // Validar comprobante para transferencias
    if (_selectedMetodoPago == 'Transferencia') {
      if (_selectedImage == null && _existingImageUrl == null) {
        _showErrorSnackBar('Comprobante requerido para transferencias');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.abono == null) {
        // CREAR NUEVO ABONO
        print('📝 Creando nuevo abono...');
        print('  ID Venta: ${widget.idPedido}');
        print('  Método: $_selectedMetodoPago');
        print('  Monto: \$${cantidadPagar.toStringAsFixed(2)}');
        
        await VentaApiService.createAbonoWithImage(
          idVenta: widget.idPedido,
          metodoPago: _selectedMetodoPago!,
          cantidadPagar: cantidadPagar,
          imagenComprobante: _selectedImage,
        );
        
        if (mounted) {
          _showSuccessSnackBar('Abono creado exitosamente');
          Navigator.of(context).pop(true);
        }
      } else {
        // ACTUALIZAR ABONO EXISTENTE
        print('🔄 Actualizando abono...');
        
        // ⚠️ Actualización de imagen no implementada en este momento
        if (_selectedImage != null) {
          _showErrorSnackBar('Actualización de imagen aún no disponible');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final updatedAbono = Abono(
          idAbono: widget.abono!.idAbono,
          idPedido: widget.abono!.idPedido,
          metodoPago: _selectedMetodoPago,
          cantidadPagar: cantidadPagar,
          TotalPagado: cantidadPagar,
          idImagen: widget.abono!.idImagen,
          urlImagen: widget.abono!.urlImagen,
        );

        await VentaApiService.updateAbono(
          updatedAbono.idAbono!,
          updatedAbono,
        );
        
        if (mounted) {
          _showSuccessSnackBar('Abono actualizado exitosamente');
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      print('❌ Error al guardar abono: $e');
      
      String errorMessage = 'Error al guardar abono';
      final errorStr = e.toString();
      
      if (errorStr.contains('Solo se permiten archivos de imagen')) {
        errorMessage = 'Error: El archivo no es una imagen válida. Use JPG, JPEG o PNG.';
      } else if (errorStr.contains('Método de pago muy largo')) {
        errorMessage = 'Método de pago muy largo (máximo 20 caracteres)';
      } else if (errorStr.contains('Comprobante requerido')) {
        errorMessage = 'Comprobante de imagen requerido para transferencias';
      } else if (errorStr.contains('Stock insuficiente')) {
        errorMessage = 'Stock insuficiente en inventario';
      } else if (errorStr.contains('excede el saldo')) {
        errorMessage = 'El monto excede el saldo pendiente';
      } else {
        errorMessage = errorStr.replaceAll('Exception: ', '');
      }
      
      if (mounted) {
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: _accentGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: _accentRed,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calcular saldo pendiente
    final double currentAbonoValue = widget.abono?.cantidadPagar ?? 0.0;
    final double saldoPendiente = widget.totalPedido - _currentAbonosSum - currentAbonoValue;
    final double saldoDisponible = widget.totalPedido - _currentAbonosSum;

    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.pink,
        ).copyWith(
          primary: _primaryRose,
          secondary: _primaryRose.withOpacity(0.7),
          onSurface: _darkGrey,
          error: _accentRed,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: _primaryRose,
          selectionHandleColor: _primaryRose,
          selectionColor: _primaryRose.withOpacity(0.2),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: _textGrey),
          floatingLabelStyle: const TextStyle(color: _primaryRose),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: _primaryRose.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: _primaryRose, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: _textGrey.withOpacity(0.4)),
          ),
        ),
      ),
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.abono == null ? 'Crear Abono' : 'Editar Abono',
              style: const TextStyle(
                color: _darkGrey,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total: \$${widget.totalPedido.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 15, color: _textGrey),
                  ),
                  Text(
                    'Saldo: \$${saldoPendiente.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: saldoPendiente < 0.01 ? _accentGreen : _accentRed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: _primaryRose),
                ),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Método de Pago
                      DropdownButtonFormField<String>(
                        value: _selectedMetodoPago,
                        decoration: const InputDecoration(
                          labelText: 'Método de Pago',
                        ),
                        items: _metodosPagoValidos
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedMetodoPago = newValue;
                            if (newValue != 'Transferencia') {
                              _selectedImage = null;
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Seleccione el método de pago';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),
                      
                      // Cantidad a Pagar
                      TextFormField(
                        controller: _cantidadPagarController,
                        decoration: InputDecoration(
                          labelText: 'Cantidad a Pagar',
                          prefixText: '\$ ',
                          helperText: 'Máximo: \$${(saldoDisponible + currentAbonoValue).toStringAsFixed(0)}',
                          helperStyle: const TextStyle(color: _textGrey, fontSize: 12),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese la cantidad';
                          }
                          
                          final amount = double.tryParse(value);
                          if (amount == null) {
                            return 'Ingrese un número válido';
                          }
                          
                          if (amount <= 0) {
                            return 'Debe ser mayor que cero';
                          }
                          
                          if (amount > saldoDisponible + currentAbonoValue + 0.01) {
                            return 'Excede el saldo (\$${(saldoDisponible + currentAbonoValue).toStringAsFixed(0)})';
                          }
                          
                          return null;
                        },
                      ),
                      
                      // Selector de Imagen para Transferencias
                      if (_selectedMetodoPago == 'Transferencia') ...[
                        const SizedBox(height: 20.0),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Seleccionar Comprobante'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent.shade400,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Formatos: JPG, JPEG, PNG (máx 5MB)',
                          style: TextStyle(fontSize: 11, color: _textGrey),
                        ),
                        
                        // Mostrar imagen seleccionada o existente
                        if (_selectedImage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Archivo: ${_selectedImage!.name}',
                            style: const TextStyle(color: _textGrey, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: _textGrey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: kIsWeb
                                  ? Image.network(
                                      _selectedImage!.path,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.broken_image, size: 60),
                                    )
                                  : Image.file(
                                      File(_selectedImage!.path),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.broken_image, size: 60),
                                    ),
                            ),
                          ),
                        ] else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text(
                            'Comprobante actual:',
                            style: TextStyle(color: _textGrey, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: _textGrey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                _existingImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 60),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        actions: _isLoading
            ? []
            : [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(foregroundColor: _textGrey),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _saveAbono,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryRose,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar'),
                ),
              ],
      ),
    );
  }
}
