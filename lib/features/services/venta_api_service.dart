// lib/services/venta_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/venta/venta.dart';
import '../models/venta/detalle_venta.dart';
import '../models/venta/pedido.dart';
import '../models/venta/abono.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

/// Servicio dedicado para gestionar Ventas, Pedidos y Abonos
class VentaApiService {
  static const String _baseUrl = Constants.baseUrl;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static void _handleHttpError(http.Response response) {
    if (response.statusCode >= 400) {
      String errorMessage = 'Error HTTP ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('message')) {
          errorMessage = decoded['message']?.toString() ?? errorMessage;
        }
      } catch (e) {
        errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
      }
      throw Exception(errorMessage);
    }
  }

  // ==================== GESTIÓN DE VENTAS ====================

  /// Obtener todas las ventas (listado resumido)
  static Future<List<Map<String, dynamic>>> getAllVentas() async {
    try {
      print('📋 Obteniendo listado de ventas...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/venta/listado-resumen'),
        headers: _headers,
      );
      
      if (kDebugMode) {
        print('URL: $_baseUrl/venta/listado-resumen');
        print('Status: ${response.statusCode}');
      }
      
      if (response.statusCode == 200) {
        final List<dynamic> ventasJson = jsonDecode(response.body);
        print('✅ ${ventasJson.length} ventas obtenidas');
        return ventasJson.cast<Map<String, dynamic>>();
      } else {
        _handleHttpError(response);
        return [];
      }
    } catch (e) {
      print('❌ Error al obtener ventas: $e');
      throw Exception('Error al obtener ventas: $e');
    }
  }

  /// Obtener venta por ID (con detalles básicos)
  static Future<Map<String, dynamic>> getVentaById(int idVenta) async {
    try {
      print('🔍 Obteniendo venta ID: $idVenta');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/venta/$idVenta/detalles'),
        headers: _headers,
      );
      
      if (kDebugMode) {
        print('URL: $_baseUrl/venta/$idVenta/detalles');
        print('Status: ${response.statusCode}');
      }
      
      if (response.statusCode == 200) {
        final ventaData = jsonDecode(response.body);
        print('✅ Venta obtenida');
        return ventaData;
      } else {
        _handleHttpError(response);
        throw Exception('Venta no encontrada');
      }
    } catch (e) {
      print('❌ Error al obtener venta: $e');
      throw Exception('Error al obtener venta: $e');
    }
  }

  /// Obtener venta completa con abonos
  static Future<Map<String, dynamic>> getVentaCompletaConAbonos(int idVenta) async {
    try {
      print('📦 Obteniendo venta completa con abonos...');
      print('ID Venta: $idVenta');
      
      // 1. Obtener venta con detalles
      final ventaData = await getVentaById(idVenta);
      
      // 2. Obtener abonos de esta venta
      List<Map<String, dynamic>> abonosData = [];
      double totalAbonado = 0.0;
      
      try {
        final abonos = await getAbonosByVentaId(idVenta);
        abonosData = abonos.map((a) => a.toJson()).toList();
        
        totalAbonado = abonos.fold(0.0, (sum, abono) => 
          sum + (abono.cantidadPagar ?? 0.0)
        );
        
        print('💰 Total abonado: \$${totalAbonado.toStringAsFixed(2)}');
      } catch (abonosError) {
        print('⚠️ No se pudieron obtener abonos: $abonosError');
      }
      
      // 3. Calcular saldo pendiente
      final total = (ventaData['total'] as num?)?.toDouble() ?? 0.0;
      final saldoPendiente = total - totalAbonado;
      
      // 4. Agregar información calculada
      ventaData['abonos'] = abonosData;
      ventaData['totalAbonado'] = totalAbonado;
      ventaData['saldoPendiente'] = saldoPendiente > 0 ? saldoPendiente : 0.0;
      
      print('✅ Venta completa obtenida');
      print('Total: \$${total.toStringAsFixed(2)}');
      print('Abonado: \$${totalAbonado.toStringAsFixed(2)}');
      print('Saldo: \$${saldoPendiente.toStringAsFixed(2)}');
      
      return ventaData;
    } catch (e) {
      print('❌ Error al obtener venta completa: $e');
      throw Exception('Error al obtener venta completa: $e');
    }
  }

  /// Crear nueva venta
  static Future<Map<String, dynamic>> createVenta({
    required DateTime fechaVenta,
    int? idCliente,
    required int idSede,
    required String metodoPago,
    required String tipoVenta,
    required double total,
    required List<Map<String, dynamic>> detalleVenta,
    int? estadoVentaId,
  }) async {
    try {
      print('📝 Creando nueva venta...');
      
      // Validaciones
      if (metodoPago.isEmpty || metodoPago.length > 20) {
        throw Exception('Método de pago inválido (máximo 20 caracteres)');
      }
      
      if (total <= 0) {
        throw Exception('Total debe ser mayor a 0');
      }
      
      if (detalleVenta.isEmpty) {
        throw Exception('Debe incluir al menos un producto');
      }
      
      // Normalizar tipo de venta
      final tipoVentaNormalizado = tipoVenta.toLowerCase() == 'venta directa' 
          ? 'directa' 
          : tipoVenta.toLowerCase();
      
      // Determinar estado automáticamente si no se proporciona
      final estadoFinal = estadoVentaId ?? 
          (tipoVentaNormalizado == 'directa' ? 5 : 1);
      
      // Construir body
      final ventaData = {
        'fechaventa': fechaVenta.toIso8601String(),
        'cliente': idCliente,
        'idsede': idSede,
        'metodopago': metodoPago,
        'tipoventa': tipoVentaNormalizado,
        'estadoVentaId': estadoFinal,
        'total': total,
        'detalleventa': detalleVenta,
      };
      
      if (kDebugMode) {
        print('Datos de venta:');
        print('  Cliente: ${idCliente ?? "Genérico"}');
        print('  Sede: $idSede');
        print('  Método: $metodoPago');
        print('  Tipo: $tipoVentaNormalizado');
        print('  Total: \$${total.toStringAsFixed(2)}');
        print('  Productos: ${detalleVenta.length}');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/venta'),
        headers: _headers,
        body: jsonEncode(ventaData),
      );
      
      if (kDebugMode) {
        print('Status: ${response.statusCode}');
        print('Response: ${response.body}');
      }
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final ventaCreada = jsonDecode(response.body);
        print('✅ Venta creada con ID: ${ventaCreada['idventa']}');
        
        if (ventaCreada['mensaje'] != null) {
          print('ℹ️ ${ventaCreada['mensaje']}');
        }
        
        return ventaCreada;
      } else {
        String errorMessage = 'Error al crear venta';
        
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message']?.toString() ?? errorMessage;
          
          // Mensajes específicos
          if (errorMessage.contains('inventario') || 
              errorMessage.contains('Inventario') ||
              errorMessage.contains('stock')) {
            errorMessage = '⚠️ Stock insuficiente: $errorMessage';
          }
        } catch (e) {
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error al crear venta: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createVentaConPedido({
  required DateTime fechaVenta,
  int? idCliente,
  required int idSede,
  required String metodoPago,
  required String tipoVenta,
  required double total,
  required List<Map<String, dynamic>> detalleVenta,
  int? estadoVentaId,
  DateTime? fechaEntrega, // 🔥 NUEVO
  String? observaciones, // 🔥 NUEVO
  String? mensajePersonalizado, // 🔥 NUEVO
}) async {
  try {
    print('📦 Creando nueva venta con información de pedido...');
    
    // Validaciones
    if (metodoPago.isEmpty || metodoPago.length > 20) {
      throw Exception('Método de pago inválido (máximo 20 caracteres)');
    }
    
    if (total <= 0) {
      throw Exception('Total debe ser mayor a 0');
    }
    
    if (detalleVenta.isEmpty) {
      throw Exception('Debe incluir al menos un producto');
    }
    
    // Normalizar tipo de venta
    final tipoVentaNormalizado = tipoVenta.toLowerCase() == 'venta directa' 
        ? 'directa' 
        : tipoVenta.toLowerCase();
    
    // Determinar estado automáticamente si no se proporciona
    final estadoFinal = estadoVentaId ?? 
        (tipoVentaNormalizado == 'directa' ? 5 : 1);
    
    // 🔥 VALIDAR FECHA DE ENTREGA PARA PEDIDOS
    if (tipoVentaNormalizado == 'pedido' && fechaEntrega == null) {
      throw Exception('La fecha de entrega es requerida para pedidos');
    }
    
    // Construir body
    final ventaData = {
      'fechaventa': fechaVenta.toIso8601String(),
      'cliente': idCliente,
      'idsede': idSede,
      'metodopago': metodoPago,
      'tipoventa': tipoVentaNormalizado,
      'estadoVentaId': estadoFinal,
      'total': total,
      'detalleventa': detalleVenta,
      // 🔥 NUEVOS CAMPOS PARA PEDIDOS
      if (fechaEntrega != null) 'fechaentrega': fechaEntrega.toIso8601String(),
      if (observaciones != null) 'observaciones': observaciones,
      if (mensajePersonalizado != null) 'mensajePersonalizado': mensajePersonalizado,
    };
    
    if (kDebugMode) {
      print('Datos de venta con pedido:');
      print('  Cliente: ${idCliente ?? "Genérico"}');
      print('  Sede: $idSede');
      print('  Método: $metodoPago');
      print('  Tipo: $tipoVentaNormalizado');
      print('  Total: \$${total.toStringAsFixed(2)}');
      print('  Productos: ${detalleVenta.length}');
      if (fechaEntrega != null) {
        print('  Fecha Entrega: ${fechaEntrega.toIso8601String()}');
      }
      if (observaciones != null) {
        print('  Observaciones: $observaciones');
      }
      if (mensajePersonalizado != null) {
        print('  Mensaje: $mensajePersonalizado');
      }
    }
    
    final response = await http.post(
      Uri.parse('$_baseUrl/venta'),
      headers: _headers,
      body: jsonEncode(ventaData),
    );
    
    if (kDebugMode) {
      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');
    }
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      final ventaCreada = jsonDecode(response.body);
      print('✅ Venta con pedido creada con ID: ${ventaCreada['idventa']}');
      
      if (ventaCreada['mensaje'] != null) {
        print('ℹ️ ${ventaCreada['mensaje']}');
      }
      
      return ventaCreada;
    } else {
      String errorMessage = 'Error al crear venta';
      
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message']?.toString() ?? errorMessage;
        
        // Mensajes específicos
        if (errorMessage.contains('inventario') || 
            errorMessage.contains('Inventario') ||
            errorMessage.contains('stock')) {
          errorMessage = '⚠️ Stock insuficiente: $errorMessage';
        } else if (errorMessage.contains('fecha de entrega')) {
          errorMessage = '⚠️ $errorMessage';
        }
      } catch (e) {
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }
      
      throw Exception(errorMessage);
    }
  } catch (e) {
    print('❌ Error al crear venta con pedido: $e');
    rethrow;
  }
}

  /// Actualizar estado de venta
  static Future<Map<String, dynamic>> updateEstadoVenta(
    int idVenta, 
    int nuevoEstadoId,
  ) async {
    try {
      print('🔄 Actualizando estado de venta $idVenta a estado $nuevoEstadoId');
      
      final response = await http.patch(
        Uri.parse('$_baseUrl/venta/$idVenta'),
        headers: _headers,
        body: jsonEncode({'estadoVentaId': nuevoEstadoId}),
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Estado actualizado');
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body);
        }
        return {'success': true};
      } else {
        _handleHttpError(response);
        throw Exception('Error al actualizar estado');
      }
    } catch (e) {
      print('❌ Error al actualizar estado: $e');
      throw Exception('Error al actualizar estado: $e');
    }
  }

  /// Anular venta (cambiar estado a 6)
  static Future<Map<String, dynamic>> anularVenta(int idVenta) async {
    try {
      print('❌ Anulando venta $idVenta');
      return await updateEstadoVenta(idVenta, 6);
    } catch (e) {
      print('❌ Error al anular venta: $e');
      throw Exception('Error al anular venta: $e');
    }
  }

  /// Obtener estados de venta disponibles
  static Future<List<Map<String, dynamic>>> getEstadosVenta() async {
    try {
      print('📊 Obteniendo estados de venta...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/estado-venta'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> estadosJson = jsonDecode(response.body);
        print('✅ ${estadosJson.length} estados obtenidos');
        return estadosJson.cast<Map<String, dynamic>>();
      } else {
        print('⚠️ Usando estados por defecto');
        return _getEstadosPorDefecto();
      }
    } catch (e) {
      print('⚠️ Error al obtener estados, usando valores por defecto: $e');
      return _getEstadosPorDefecto();
    }
  }

  static List<Map<String, dynamic>> _getEstadosPorDefecto() {
    return [
      {'idestadoventa': 1, 'nombre_estado': 'En espera'},
      {'idestadoventa': 2, 'nombre_estado': 'En producción'},
      {'idestadoventa': 3, 'nombre_estado': 'Por entregar'},
      {'idestadoventa': 4, 'nombre_estado': 'Finalizado'},
      {'idestadoventa': 5, 'nombre_estado': 'Activa'},
      {'idestadoventa': 6, 'nombre_estado': 'Anulada'},
    ];
  }

  // ==================== GESTIÓN DE PEDIDOS ====================

  /// Obtener todos los pedidos
  static Future<List<Map<String, dynamic>>> getAllPedidos() async {
    try {
      print('📋 Obteniendo pedidos...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/pedido'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> pedidosJson = jsonDecode(response.body);
        print('✅ ${pedidosJson.length} pedidos obtenidos');
        return pedidosJson.cast<Map<String, dynamic>>();
      } else {
        _handleHttpError(response);
        return [];
      }
    } catch (e) {
      print('❌ Error al obtener pedidos: $e');
      throw Exception('Error al obtener pedidos: $e');
    }
  }

  /// Obtener pedido por ID
  static Future<Map<String, dynamic>> getPedidoById(int idPedido) async {
    try {
      print('🔍 Obteniendo pedido ID: $idPedido');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/pedido/$idPedido'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final pedidoData = jsonDecode(response.body);
        print('✅ Pedido obtenido');
        return pedidoData;
      } else {
        _handleHttpError(response);
        throw Exception('Pedido no encontrado');
      }
    } catch (e) {
      print('❌ Error al obtener pedido: $e');
      throw Exception('Error al obtener pedido: $e');
    }
  }

  /// Obtener pedido por ID de venta
  static Future<Map<String, dynamic>?> getPedidoByVentaId(int idVenta) async {
    try {
      print('🔍 Buscando pedido para venta $idVenta');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/pedido/by-venta/$idVenta'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final pedidoData = jsonDecode(response.body);
        print('✅ Pedido encontrado: ID ${pedidoData['idpedido']}');
        return pedidoData;
      } else if (response.statusCode == 404) {
        print('ℹ️ No existe pedido para esta venta');
        return null;
      } else {
        _handleHttpError(response);
        return null;
      }
    } catch (e) {
      print('⚠️ Error al obtener pedido por venta: $e');
      return null;
    }
  }

  /// Crear pedido
  static Future<Map<String, dynamic>> createPedido({
    required int idVenta,
    String? observaciones,
    String? mensajePersonalizado,
    DateTime? fechaEntrega,
  }) async {
    try {
      print('📝 Creando pedido para venta $idVenta');
      
      final pedidoData = {
        'idventa': idVenta,
        if (observaciones != null) 'observaciones': observaciones,
        if (mensajePersonalizado != null) 'mensajePersonalizado': mensajePersonalizado,
        if (fechaEntrega != null) 'fechaentrega': fechaEntrega.toIso8601String(),
      };
      
      final response = await http.post(
        Uri.parse('$_baseUrl/pedido'),
        headers: _headers,
        body: jsonEncode(pedidoData),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final pedidoCreado = jsonDecode(response.body);
        print('✅ Pedido creado con ID: ${pedidoCreado['idpedido']}');
        return pedidoCreado;
      } else {
        _handleHttpError(response);
        throw Exception('Error al crear pedido');
      }
    } catch (e) {
      print('❌ Error al crear pedido: $e');
      throw Exception('Error al crear pedido: $e');
    }
  }

  /// Actualizar pedido
  static Future<Map<String, dynamic>> updatePedido(
    int idPedido,
    Map<String, dynamic> pedidoData,
  ) async {
    try {
      print('🔄 Actualizando pedido $idPedido');
      
      final response = await http.put(
        Uri.parse('$_baseUrl/pedido/$idPedido'),
        headers: _headers,
        body: jsonEncode(pedidoData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Pedido actualizado');
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body);
        }
        return pedidoData;
      } else {
        _handleHttpError(response);
        throw Exception('Error al actualizar pedido');
      }
    } catch (e) {
      print('❌ Error al actualizar pedido: $e');
      throw Exception('Error al actualizar pedido: $e');
    }
  }

  /// Eliminar pedido
  static Future<void> deletePedido(int idPedido) async {
    try {
      print('🗑️ Eliminando pedido $idPedido');
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/pedido/$idPedido'),
        headers: _headers,
      );
      
      if (response.statusCode != 204 && response.statusCode != 200) {
        _handleHttpError(response);
        throw Exception('Error al eliminar pedido');
      }
      
      print('✅ Pedido eliminado');
    } catch (e) {
      print('❌ Error al eliminar pedido: $e');
      throw Exception('Error al eliminar pedido: $e');
    }
  }

  // ==================== GESTIÓN DE ABONOS ====================

  /// Obtener abonos por ID de venta
  /// IMPORTANTE: A pesar del nombre del parámetro, se debe pasar el ID de la VENTA
  static Future<List<Abono>> getAbonosByVentaId(int idVenta) async {
    try {
      print('💰 Obteniendo abonos para venta $idVenta');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/abonos/pedido/$idVenta'),
        headers: _headers,
      );
      
      if (kDebugMode) {
        print('URL: $_baseUrl/abonos/pedido/$idVenta');
        print('Status: ${response.statusCode}');
      }
      
      if (response.statusCode == 200) {
        final List<dynamic> abonosJson = jsonDecode(response.body);
        final abonos = abonosJson.map((json) => Abono.fromJson(json)).toList();
        print('✅ ${abonos.length} abonos obtenidos');
        return abonos;
      } else if (response.statusCode == 404) {
        print('ℹ️ No hay abonos para esta venta');
        return [];
      } else {
        _handleHttpError(response);
        return [];
      }
    } catch (e) {
      print('❌ Error al obtener abonos: $e');
      return [];
    }
  }

  /// Crear abono con imagen
  static Future<Abono> createAbonoWithImage({
    required int idVenta,
    required String metodoPago,
    required double cantidadPagar,
    XFile? imagenComprobante,
  }) async {
    try {
      print('💰 Creando abono...');
      print('  Venta: $idVenta');
      print('  Método: $metodoPago');
      print('  Monto: \$${cantidadPagar.toStringAsFixed(2)}');
      print('  ¿Imagen?: ${imagenComprobante != null}');
      
      // Validaciones
      if (metodoPago.isEmpty || metodoPago.length > 20) {
        throw Exception('Método de pago inválido (máximo 20 caracteres)');
      }
      
      if (cantidadPagar <= 0) {
        throw Exception('La cantidad debe ser mayor a 0');
      }
      
      if (metodoPago == 'Transferencia' && imagenComprobante == null) {
        throw Exception('Comprobante requerido para transferencias');
      }
      
      // Crear FormData
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/abonos'),
      );
      
      // Campos obligatorios
      request.fields['idpedido'] = idVenta.toString();
      request.fields['metodopago'] = metodoPago;
      request.fields['cantidadpagar'] = cantidadPagar.toStringAsFixed(2);
      request.fields['TotalPagado'] = cantidadPagar.toStringAsFixed(2);
      
      if (kDebugMode) {
        print('Campos enviados:');
        request.fields.forEach((key, value) {
          print('  $key: $value');
        });
      }
      
      // Agregar imagen si existe
      if (imagenComprobante != null) {
        try {
          if (kIsWeb) {
            final bytes = await imagenComprobante.readAsBytes();
            request.files.add(
              http.MultipartFile.fromBytes(
                'comprobante',
                bytes,
                filename: imagenComprobante.name,
              ),
            );
          } else {
            request.files.add(
              await http.MultipartFile.fromPath(
                'comprobante',
                imagenComprobante.path,
                filename: imagenComprobante.name,
              ),
            );
          }
          print('✅ Imagen agregada al request');
        } catch (imageError) {
          print('❌ Error al procesar imagen: $imageError');
          throw Exception('Error al procesar imagen: $imageError');
        }
      }
      
      print('Enviando request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (kDebugMode) {
        print('Status: ${response.statusCode}');
        print('Response: ${response.body}');
      }
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final abonoCreado = Abono.fromJson(jsonDecode(response.body));
        print('✅ Abono creado con ID: ${abonoCreado.idAbono}');
        return abonoCreado;
      } else {
        String errorMessage = 'Error al crear abono';
        
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message']?.toString() ?? errorMessage;
          
          // Mensajes específicos
          if (errorMessage.contains('too long') || 
              errorMessage.contains('muy largo')) {
            errorMessage = 'Método de pago muy largo (máximo 20 caracteres)';
          } else if (errorMessage.contains('ID de pedido')) {
            errorMessage = 'Error: ID de venta requerido';
          }
        } catch (e) {
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error al crear abono: $e');
      rethrow;
    }
  }

  /// Actualizar abono
  static Future<void> updateAbono(int idAbono, Abono abono) async {
    try {
      print('🔄 Actualizando abono $idAbono');
      
      final response = await http.put(
        Uri.parse('$_baseUrl/abonos/$idAbono'),
        headers: _headers,
        body: jsonEncode(abono.toJson()),
      );
      
      if (response.statusCode != 204 && response.statusCode != 200) {
        _handleHttpError(response);
        throw Exception('Error al actualizar abono');
      }
      
      print('✅ Abono actualizado');
    } catch (e) {
      print('❌ Error al actualizar abono: $e');
      throw Exception('Error al actualizar abono: $e');
    }
  }

  /// Eliminar abono
  static Future<void> deleteAbono(int idAbono) async {
    try {
      print('🗑️ Eliminando abono $idAbono');
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/abonos/$idAbono'),
        headers: _headers,
      );
      
      if (response.statusCode != 204 && response.statusCode != 200) {
        _handleHttpError(response);
        throw Exception('Error al eliminar abono');
      }
      
      print('✅ Abono eliminado');
    } catch (e) {
      print('❌ Error al eliminar abono: $e');
      throw Exception('Error al eliminar abono: $e');
    }
  }

  /// Anular abono
  static Future<Map<String, dynamic>> anularAbono(int idAbono) async {
    try {
      print('❌ Anulando abono $idAbono');
      
      final response = await http.patch(
        Uri.parse('$_baseUrl/abonos/$idAbono/anular'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Abono anulado');
        return data;
      } else {
        _handleHttpError(response);
        throw Exception('Error al anular abono');
      }
    } catch (e) {
      print('❌ Error al anular abono: $e');
      throw Exception('Error al anular abono: $e');
    }
  }

  // ==================== DETALLES DE VENTA ====================

  /// Obtener detalles de venta por ID de venta
  static Future<List<Map<String, dynamic>>> getDetalleVentaByVentaId(int idVenta) async {
    try {
      print('📄 Obteniendo detalles de venta $idVenta');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/detalleventa/by-venta/$idVenta'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> detallesJson = jsonDecode(response.body);
        print('✅ ${detallesJson.length} detalles obtenidos');
        return detallesJson.cast<Map<String, dynamic>>();
      } else {
        _handleHttpError(response);
        return [];
      }
    } catch (e) {
      print('❌ Error al obtener detalles: $e');
      throw Exception('Error al obtener detalles: $e');
    }
  }

  // ==================== HELPERS ====================

  /// Calcular totales de una venta con sus abonos
  static Future<Map<String, double>> calcularTotalesVenta(int idVenta) async {
    try {
      final ventaData = await getVentaById(idVenta);
      final abonos = await getAbonosByVentaId(idVenta);
      
      final total = (ventaData['total'] as num?)?.toDouble() ?? 0.0;
      final totalAbonado = abonos.fold(0.0, (sum, abono) => 
        sum + (abono.cantidadPagar ?? 0.0)
      );
      final saldoPendiente = total - totalAbonado;
      
      return {
        'total': total,
        'totalAbonado': totalAbonado,
        'saldoPendiente': saldoPendiente > 0 ? saldoPendiente : 0.0,
      };
    } catch (e) {
      print('❌ Error al calcular totales: $e');
      return {
        'total': 0.0,
        'totalAbonado': 0.0,
        'saldoPendiente': 0.0,
      };
    }
  }

  /// Validar si una venta está completamente pagada
  static Future<bool> isVentaPagada(int idVenta) async {
    try {
      final totales = await calcularTotalesVenta(idVenta);
      return (totales['saldoPendiente'] ?? 0.0) < 0.01;
    } catch (e) {
      return false;
    }
  }
}