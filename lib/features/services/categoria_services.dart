// lib/services/categoria_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/categorias.dart';

class CategoriaApiService {
  // ✅ URL CORREGIDA - sin duplicación
  static const String baseUrl = 'https://deliciasoft-backend-i6g9.onrender.com/api';

  /// Obtener todas las categorías
  Future<List<Category>> obtenerCategorias() async {
    try {
      // ✅ URL CORREGIDA - usa el endpoint correcto
      final url = '$baseUrl/categorias-productos';
      print('📋 Obteniendo categorías');
      print('URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        print('Total categorías: ${jsonData.length}');

        // ✅ CORREGIDO - Filtra categorías activas
        List<Category> categorias = jsonData
            .map((json) => Category.fromJson(json))
            .where((cat) => cat.estado) // ✅ Ahora funciona porque 'estado' existe en tu modelo
            .toList();

        print('✅ ${categorias.length} categorías activas');
        return categorias;
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        throw HttpException('Error al obtener categorías: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }
}