// lib/services/donas_api_services.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/producto_general.dart'; // Cambié a producto_general.dart

class ProductoApiService {
  static const String baseUrl = 'https://deliciasoft-backend-i6g9.onrender.com/api';

  /// Obtener productos por categoría usando ID - CORREGIDO
  Future<List<ProductModel>> obtenerProductosPorCategoriaId(int idCategoria) async {
    try {
      final url = '$baseUrl/productoGeneral';
      print('🔍 Obteniendo productos de categoría ID: $idCategoria');
      print('URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        print('Total productos en API: ${jsonData.length}');

        // DEBUG: Mostrar estructura del primer producto para ver los campos
        if (jsonData.isNotEmpty) {
          print('🔍 Estructura del primer producto:');
          print(jsonData.first);
        }

        // Filtrar productos por categoría - POSIBLES CAMPOS A VERIFICAR
        List<dynamic> productosFiltrados = jsonData.where((producto) {
          // Prueba con diferentes nombres de campo que podría tener la categoría
          int? categoriaId;
          
          // Intenta con diferentes nombres de campo
          if (producto['idcategoriaproducto'] != null) {
            categoriaId = int.tryParse(producto['idcategoriaproducto'].toString());
          } else if (producto['categoriaId'] != null) {
            categoriaId = int.tryParse(producto['categoriaId'].toString());
          } else if (producto['idCategoria'] != null) {
            categoriaId = int.tryParse(producto['idCategoria'].toString());
          } else if (producto['categoriaID'] != null) {
            categoriaId = int.tryParse(producto['categoriaID'].toString());
          } else if (producto['idCategoriaProducto'] != null) {
            categoriaId = int.tryParse(producto['idCategoriaProducto'].toString());
          }
          
          print('Producto: ${producto['nombreProducto']} - Categoría ID encontrado: $categoriaId');
          return categoriaId == idCategoria;
        }).toList();

        print('✅ Productos encontrados para categoría $idCategoria: ${productosFiltrados.length}');

        // Convertir a ProductModel
        List<ProductModel> productos = productosFiltrados.map((json) {
          return ProductModel.fromJson(json);
        }).toList();

        return productos;
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        throw HttpException('Error al obtener productos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error de conexión: $e');
      rethrow;
    }
  }

  /// Obtener todos los productos
  Future<List<ProductModel>> obtenerTodosLosProductos() async {
    try {
      final url = '$baseUrl/productoGeneral';
      print('📋 Obteniendo todos los productos');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        
        List<ProductModel> productos = jsonData
            .map((json) => ProductModel.fromJson(json))
            .toList();

        print('✅ ${productos.length} productos obtenidos');
        return productos;
      } else {
        throw HttpException('Error al obtener productos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }
}