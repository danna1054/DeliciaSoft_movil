// lib/services/configuracion_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/configuracion.dart';

class ConfiguracionService {
  static const String baseUrl = 'https://deliciasoft-backend-i6g9.onrender.com/api';

  /// Obtener la configuración de un producto específico
  Future<ConfiguracionProducto?> obtenerConfiguracionProducto(int idProducto) async {
    try {
      final url = '$baseUrl/configuracion-producto';
      print('🔍 Buscando configuración para producto ID: $idProducto');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        print('Total configuraciones en API: ${jsonData.length}');

        // Buscar la configuración del producto específico
        try {
          final configuracionJson = jsonData.firstWhere(
            (config) {
              int? prodId = int.tryParse(config['idproductogeneral']?.toString() ?? '0');
              return prodId == idProducto;
            },
          );

          print('✅ Configuración encontrada para producto $idProducto');
          return ConfiguracionProducto.fromJson(configuracionJson);
        } catch (e) {
          print('⚠️ No hay configuración para producto $idProducto');
          return null;
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error: $e');
      return null;
    }
  }

  /// Obtener todas las configuraciones
  Future<List<ConfiguracionProducto>> obtenerTodasLasConfiguraciones() async {
    try {
      final url = '$baseUrl/configuracion-producto';
      print('📋 Obteniendo todas las configuraciones');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        
        List<ConfiguracionProducto> configuraciones = jsonData
            .map((json) => ConfiguracionProducto.fromJson(json))
            .toList();

        print('✅ ${configuraciones.length} configuraciones obtenidas');
        return configuraciones;
      } else {
        throw HttpException('Error al obtener configuraciones: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }
}