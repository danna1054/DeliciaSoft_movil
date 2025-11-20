// lib/services/catalogo_salsa_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CatalogoSalsaService {
  static const String baseUrl = 'https://deliciasoft-backend-i6g9.onrender.com/api';

  Future<List<String>> obtenerSalsas() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/catalogo-salsas'));
      
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        List<String> salsas = jsonData.map((item) => item['nombre'].toString()).toList();
        return salsas;
      } else {
        throw Exception('Error al cargar salsas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}