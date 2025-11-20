// lib/services/catalogo_sabor_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CatalogoSaborService {
  static const String baseUrl = 'https://deliciasoft-backend-i6g9.onrender.com/api';

  Future<List<String>> obtenerSabores() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/catalogo-sabor'));
      
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        List<String> sabores = jsonData.map((item) => item['nombre'].toString()).toList();
        return sabores;
      } else {
        throw Exception('Error al cargar sabores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}