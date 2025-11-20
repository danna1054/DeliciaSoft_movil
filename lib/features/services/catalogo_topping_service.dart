// lib/services/catalogo_topping_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CatalogoToppingService {
  static const String baseUrl = 'https://deliciasoft-backend-i6g9.onrender.com/api';

  Future<List<String>> obtenerToppings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/catalogo-toppings'));
      
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        List<String> toppings = jsonData.map((item) => item['nombre'].toString()).toList();
        return toppings;
      } else {
        throw Exception('Error al cargar toppings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}