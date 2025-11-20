// lib/services/catalogo_relleno_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CatalogoRellenoService {
  static const String baseUrl = 'https://deliciasoft-backend-i6g9.onrender.com/api';

  Future<List<String>> obtenerRellenos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/catalogo-relleno'));
      
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        List<String> rellenos = jsonData.map((item) => item['nombre'].toString()).toList();
        return rellenos;
      } else {
        throw Exception('Error al cargar rellenos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}