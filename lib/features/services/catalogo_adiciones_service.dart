// lib/services/catalogo_adiciones_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CatalogoAdicionesService {
  static const String baseUrl = 'https://deliciasoft-backend-i6g9.onrender.com/api';

  Future<List<String>> obtenerAdiciones() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/catalogo-adiciones'));
      
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        List<String> adiciones = jsonData.map((item) => item['nombre'].toString()).toList();
        return adiciones;
      } else {
        throw Exception('Error al cargar adiciones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}