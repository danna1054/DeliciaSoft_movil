// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/cliente.dart';
import '../models/usuario.dart';
import '../utils/constants.dart';
import '../models/rol.dart';
import '../models/venta/abono.dart';
import '../models/venta/catalogo_adicione.dart';
import '../models/venta/catalogo_relleno.dart';
import '../models/venta/catalogo_sabor.dart';
import '../models/venta/detalle_adicione.dart';
import '../models/venta/detalle_venta.dart';
import '../models/venta/pedido.dart';
import '../models/venta/producto_general.dart';
import '../models/venta/sede.dart';
import '../models/venta/venta.dart';
import '../models/venta/imagene.dart';
import 'package:image_picker/image_picker.dart'; 
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart'; 

class ApiService {
  static const String __baseUrl = Constants.baseUrl;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> _headersWithToken(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  static void _handleHttpError(http.Response response) {
    if (response.statusCode >= 400) {
      String errorMessage = 'Error HTTP ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('message')) {
          errorMessage = decoded['message']?.toString() ?? errorMessage;
        } else if (decoded is Map && decoded.containsKey('errors') && decoded['errors'] is Map) {
          final Map<String, dynamic> errorsMap = decoded['errors'];
          errorMessage = errorsMap.values.expand((e) => (e as List).map((i) => i.toString())).join(', ');
        } else if (decoded is String) {
          errorMessage = decoded;
        } else {
          errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
        }
      } catch (e) {
        errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
      }
      throw Exception(errorMessage);
    }
  }

  // ==================== MÉTODOS DE AUTENTICACIÓN ====================

  // LOGIN DIRECTO (para métodos que no requieren verificación)
  static Future<AuthResponse> login(String email, String password, String userType) async {
    try {
      String endpoint;
      if (userType == Constants.clientType) {
        endpoint = '${Constants.loginClientEndpoint}/login';
      } else {
        endpoint = '${Constants.loginUserEndpoint}/login';
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: _headers,
        body: jsonEncode({
          'correo': email,
          'contrasena': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        final token = data['token']?.toString() ?? '';

        return AuthResponse(
          success: true,
          message: 'Login exitoso',
          token: token,
          refreshToken: null,
          user: data,
          userType: userType,
          expiresIn: null,
        );
      } else {
        final errorData = jsonDecode(response.body);
        return AuthResponse(
          success: false,
          message: errorData['message']?.toString() ?? 'Error en el login',
          token: '',
          refreshToken: null,
          user: null,
          userType: userType,
          expiresIn: null,
        );
      }
    } catch (e) {
      throw Exception('Error en el login: $e');
    }
  }

static Future<ApiResponse<dynamic>> sendVerificationCode(String email, String password, String userType) async {
  try {
    // Primero verificar en qué tabla existe el usuario
    final userTypeCheck = await checkUserExists(email);
    String actualUserType = userType;
    
    if (userTypeCheck.success && userTypeCheck.data != null) {
      actualUserType = userTypeCheck.data!;
    } else {
      return ApiResponse<dynamic>(
        success: false,
        message: 'Usuario no encontrado en el sistema',
        data: null,
      );
    }

    final response = await http.post(
      Uri.parse(Constants.sendVerificationCodeEndpoint),
      headers: _headers,
      body: jsonEncode({
        'correo': email,
        'password': password,
        'userType': actualUserType,
      }),
    );
    
    print('=== ENVIANDO CÓDIGO DE VERIFICACIÓN ===');
    print('URL: ${Constants.sendVerificationCodeEndpoint}');
    print('Email: $email');
    print('UserType Original: $userType');
    print('UserType Verificado: $actualUserType');
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('====================================');

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final data = jsonDecode(response.body);
        return ApiResponse<dynamic>(
          success: true,
          message: data['message']?.toString() ?? 'Código enviado exitosamente',
          data: {'userType': actualUserType}, // Devolver el tipo correcto
        );
      } catch (e) {
        return ApiResponse<dynamic>(
          success: true,
          message: 'Código enviado exitosamente',
          data: {'userType': actualUserType},
        );
      }
    } else {
      String errorMessage = 'Error enviando código';
      
      try {
        if (response.body.isNotEmpty) {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message']?.toString() ?? errorMessage;
        }
      } catch (e) {
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }
      
      return ApiResponse<dynamic>(
        success: false,
        message: errorMessage,
        data: null,
      );
    }
  } catch (e) {
    print('Error enviando código de verificación: $e');
    return ApiResponse<dynamic>(
      success: false,
      message: e.toString(),
      data: null,
    );
  }
}

static Future<ApiResponse<Map<String, dynamic>>> validateCredentials(String email, String password, String userType) async {
  try {
    String endpoint;
    if (userType == Constants.clientType) {
      endpoint = Constants.loginClientEndpoint;
    } else {
      endpoint = Constants.loginUserEndpoint;
    }

    final response = await http.post(
      Uri.parse('$endpoint/validate'), // Endpoint para solo validar
      headers: _headers,
      body: jsonEncode({
        'correo': email,
        'contrasena': password,
      }),
    );

    print('=== VALIDANDO CREDENCIALES ===');
    print('URL: $endpoint/validate');
    print('Email: $email');
    print('UserType: $userType');
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('=============================');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ApiResponse<Map<String, dynamic>>(
        success: true,
        message: 'Credenciales válidas',
        data: data,
      );
    } else if (response.statusCode == 401) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Contraseña incorrecta',
        data: null,
      );
    } else if (response.statusCode == 404) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Usuario no encontrado',
        data: null,
      );
    } else {
      String errorMessage = 'Error validando credenciales';
      try {
        if (response.body.isNotEmpty) {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message']?.toString() ?? errorMessage;
        }
      } catch (e) {
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }
      
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: errorMessage,
        data: null,
      );
    }
  } catch (e) {
    print('Error validando credenciales: $e');
    return ApiResponse<Map<String, dynamic>>(
      success: false,
      message: 'Error de conexión',
      data: null,
    );
  }
}


static Future<ApiResponse<dynamic>> verifyCodeAndLogin(String email, String password, String userType, String code) async {
  try {
    final requestBody = {
        'correo': email,
        'password': password,
        'userType': userType == 'usuario' ? 'admin' : userType.toLowerCase(),
        'codigo': code,  // ✅ CAMBIO CRÍTICO: de 'code' a 'codigo'
      };

    final response = await http.post(
      Uri.parse(Constants.verifyCodeAndLoginEndpoint),
      headers: _headers,
      body: jsonEncode(requestBody),
    );
    
    print('=== VERIFICANDO CÓDIGO Y LOGIN (API Service) ===');
    print('URL: ${Constants.verifyCodeAndLoginEndpoint}');
    print('Request Body (sent): ${jsonEncode(requestBody)}');
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('================================');
    
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        
        // Verificar si la respuesta indica éxito
        bool isSuccess = data['success'] == true || 
                        data.containsKey('token') || 
                        data.containsKey('user');
        
        if (isSuccess) {
          // Procesar los datos de forma segura con valores por defecto
          final processedData = <String, dynamic>{};
          
          // Token (requerido) - usar string vacío si es null
          processedData['token'] = data['token']?.toString() ?? '';
          
          // RefreshToken (opcional) - permitir null
          processedData['refreshToken'] = data['refreshToken']?.toString();
          
          // User data (requerido para login exitoso) - usar mapa vacío si es null
          if (data.containsKey('user') && data['user'] != null) {
            processedData['user'] = Map<String, dynamic>.from(data['user'] as Map);
          } else {
            processedData['user'] = <String, dynamic>{};
          }
          
          // UserType - usar el userType pasado como parámetro si no viene en la respuesta
          processedData['userType'] = data['userType']?.toString() ?? userType;
          
          // ExpiresIn (opcional) - permitir null
          if (data.containsKey('expiresIn') && data['expiresIn'] != null) {
            processedData['expiresIn'] = data['expiresIn'];
          }
          
          // Message - usar mensaje por defecto si es null
          final message = data['message']?.toString() ?? 'Login exitoso';
          
          return ApiResponse<dynamic>(
            success: true,
            message: message,
            data: processedData,
          );
        } else {
          return ApiResponse<dynamic>(
            success: false,
            message: data['message']?.toString() ?? 'Error en la verificación',
            data: null,
          );
        }
      } catch (e) {
        print('Error parseando respuesta exitosa: $e');
        return ApiResponse<dynamic>(
          success: false,
          message: 'Error procesando respuesta del servidor',
          data: null,
        );
      }
    } else if (response.statusCode == 400) {
      // Error de validación (código incorrecto, expirado, etc.)
      try {
        final errorData = jsonDecode(response.body);
        String errorMessage = errorData['message']?.toString() ?? 'Código inválido o expirado';
        
        return ApiResponse<dynamic>(
          success: false,
          message: errorMessage,
          data: null,
        );
      } catch (e) {
        return ApiResponse<dynamic>(
          success: false,
          message: 'Código inválido o expirado',
          data: null,
        );
      }
    } else if (response.statusCode == 401) {
      return ApiResponse<dynamic>(
        success: false,
        message: 'Credenciales incorrectas',
        data: null,
      );
    } else if (response.statusCode == 404) {
      return ApiResponse<dynamic>(
        success: false,
        message: 'Usuario no encontrado',
        data: null,
      );
    } else {
      // Otros errores del servidor
      String errorMessage = 'Error del servidor';
      try {
        if (response.body.isNotEmpty) {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message']?.toString() ?? errorMessage;
        }
      } catch (e) {
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }
      
      return ApiResponse<dynamic>(
        success: false,
        message: errorMessage,
        data: null,
      );
    }
  } catch (e) {
    print('Excepción en verifyCodeAndLogin: $e');
    return ApiResponse<dynamic>(
      success: false,
      message: 'Error de conexión o inesperado. Intenta nuevamente.',
      data: null,
    );
  }
}

 static Future<ApiResponse<String>> checkUserExists(String email) async {
  try {
    print('🔍 Verificando usuario con email: $email');
    
    // Primero verificar en clientes (más común)
    final clientResponse = await http.get(
      Uri.parse('${Constants.getClientEndpoint}?correo=$email'),
      headers: _headers,
    );
    
    print('🔍 Cliente response status: ${clientResponse.statusCode}');
    print('🔍 Cliente response body: ${clientResponse.body}');
    
    if (clientResponse.statusCode == 200) {
      final clientData = jsonDecode(clientResponse.body);
      
      // Verificar si hay datos
      if (clientData != null) {
        // Si es una lista, verificar que no esté vacía
        if (clientData is List && clientData.isNotEmpty) {
          // Buscar el cliente específico por email
          final clientFound = clientData.any((client) => client['correo'] == email);
          if (clientFound) {
            print('✅ Cliente encontrado en lista');
            return ApiResponse<String>(
              success: true,
              message: 'Usuario encontrado',
              data: Constants.clientType,
            );
          }
        }
        // Si es un objeto (mapa), verificar directamente
        else if (clientData is Map && clientData['correo'] == email) {
          print('✅ Cliente encontrado como objeto');
          return ApiResponse<String>(
            success: true,
            message: 'Usuario encontrado',
            data: Constants.clientType,
          );
        }
      }
    }
    
    // Luego verificar en usuarios (admin)
    final userResponse = await http.get(
      Uri.parse('${Constants.getUserEndpoint}?correo=$email'),
      headers: _headers,
    );
    
    print('🔍 Usuario response status: ${userResponse.statusCode}');
    print('🔍 Usuario response body: ${userResponse.body}');
    
    if (userResponse.statusCode == 200) {
      final userData = jsonDecode(userResponse.body);
      
      // Verificar si hay datos
      if (userData != null) {
        // Si es una lista, verificar que no esté vacía
        if (userData is List && userData.isNotEmpty) {
          // Buscar el usuario específico por email
          final userFound = userData.any((user) => user['correo'] == email);
          if (userFound) {
            print('✅ Usuario admin encontrado en lista');
            return ApiResponse<String>(
              success: true,
              message: 'Usuario encontrado',
              data: Constants.adminType,
            );
          }
        }
        // Si es un objeto (mapa), verificar directamente
        else if (userData is Map && userData['correo'] == email) {
          print('✅ Usuario admin encontrado como objeto');
          return ApiResponse<String>(
            success: true,
            message: 'Usuario encontrado',
            data: Constants.adminType,
          );
        }
      }
    }
    
    print('❌ Usuario no encontrado en ninguna tabla');
    return ApiResponse<String>(
      success: false,
      message: 'Usuario no encontrado',
      data: null,
    );
  } catch (e) {
    print('❌ Error verificando usuario: $e');
    throw Exception('Error verificando usuario: $e');
  }
}

// AÑADE estos métodos a tu ApiService

static Future<ApiResponse<Usuario>> getUserByEmail(String token, String email) async {
  try {
    final response = await http.get(
      Uri.parse(Constants.getUserEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> users = jsonDecode(response.body);
      final userData = users.firstWhere(
        (u) => u['correo'] == email,
        orElse: () => null,
      );

      if (userData != null) {
        // Completar datos faltantes si es necesario
        final completeUserData = {
          'idUsuario': userData['idUsuario'] ?? userData['id'] ?? 0,
          'nombre': userData['nombre'] ?? '',
          'apellido': userData['apellido'] ?? '',
          'correo': userData['correo'] ?? '',
          'tipoDocumento': userData['tipoDocumento'] ?? '',
          'documento': userData['documento']?.toString() ?? '',
          'estado': userData['estado'] ?? true,
          'contrasena': '',
        };

        return ApiResponse<Usuario>(
          success: true,
          message: 'Usuario encontrado',
          data: Usuario.fromJson(completeUserData),
        );
      } else {
        return ApiResponse<Usuario>(
          success: false,
          message: 'Usuario no encontrado',
          data: null,
        );
      }
    } else {
      return ApiResponse<Usuario>(
        success: false,
        message: 'Error HTTP ${response.statusCode}',
        data: null,
      );
    }
  } catch (e) {
    return ApiResponse<Usuario>(
      success: false,
      message: 'Error: $e',
      data: null,
    );
  }
}

static Future<ApiResponse<Cliente>> getClientByEmail(String token, String email) async {
  try {
    final response = await http.get(
      Uri.parse(Constants.getClientEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      List<dynamic> clients;

      if (data is List) {
        clients = data;
      } else if (data is Map) {
        clients = [data];
      } else {
        throw Exception('Respuesta inesperada del servidor');
      }

      final clientData = clients.firstWhere(
        (c) => c['correo'] == email,
        orElse: () => null,
      );

      if (clientData != null) {
        return ApiResponse<Cliente>(
          success: true,
          message: 'Cliente encontrado',
          data: Cliente.fromJson(clientData),
        );
      } else {
        return ApiResponse<Cliente>(
          success: false,
          message: 'Cliente no encontrado',
          data: null,
        );
      }
    } else {
      return ApiResponse<Cliente>(
        success: false,
        message: 'Error HTTP ${response.statusCode}',
        data: null,
      );
    }
  } catch (e) {
    return ApiResponse<Cliente>(
      success: false,
      message: 'Error: $e',
      data: null,
    );
  }
}

  // ==================== REGISTRO ====================

 // REEMPLAZAR el método registerClient en api_service.dart
static Future<ApiResponse<Cliente>> registerClient(Cliente cliente) async {
  try {
    final clienteParaRegistro = Cliente.forRegistration(
      tipoDocumento: cliente.tipoDocumento,
      numeroDocumento: cliente.numeroDocumento,
      nombre: cliente.nombre,
      apellido: cliente.apellido,
      correo: cliente.correo,
      contrasena: cliente.contrasena,
      direccion: cliente.direccion,
      barrio: cliente.barrio,
      ciudad: cliente.ciudad,
      fechaNacimiento: cliente.fechaNacimiento,  // pasamos como DateTime
      celular: cliente.celular,
      estado: cliente.estado,
    );

    final clienteJson = clienteParaRegistro.toJson();
    // Aquí convertimos fechaNacimiento a "yyyy-MM-dd"
    clienteJson['fechaNacimiento'] = cliente.fechaNacimiento?.toIso8601String().split('T')[0];

    final body = jsonEncode(clienteJson);

    print('=== REGISTRANDO CLIENTE ===');
    print('URL: ${Constants.registerClientEndpoint}');
    print('JSON: $body');
    print('=========================');

    final response = await http.post(
      Uri.parse(Constants.registerClientEndpoint),
      headers: _headers,
      body: body,
    );

    print('=== RESPUESTA REGISTRO CLIENTE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('=================================');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return ApiResponse<Cliente>(
        success: true,
        message: 'Cliente registrado exitosamente',
        data: Cliente.fromJson(data),
      );
    } else {
      _handleHttpError(response);
      return ApiResponse<Cliente>(
        success: false,
        message: 'Error en el registro',
        data: null,
      );
    }
  } catch (e) {
    print('Error en registerClient: $e');
    throw Exception('Error registrando cliente: $e');
  }
}


  static Future<ApiResponse<dynamic>> registerUser(Usuario usuario) async {
    try {
      final response = await http.post(
        Uri.parse(Constants.registerUserEndpoint),
        headers: _headers,
        body: jsonEncode(usuario.toJson()),
      );
      _handleHttpError(response);
      final data = jsonDecode(response.body);
      return ApiResponse<Usuario>.fromJson(data, (Object? json) => Usuario.fromJson(json as Map<String, dynamic>));
    } catch (e) {
      throw Exception('Error registrando usuario: $e');
    }
  }

  // ==================== RESETEO DE CONTRASEÑA ====================

 static Future<PasswordResetResponse> requestPasswordReset(String email) async {
  try {
    // Primero verificar el tipo de usuario usando checkUserExists
    final userTypeCheck = await checkUserExists(email);
    
    if (!userTypeCheck.success || userTypeCheck.data == null) {
      throw Exception('Usuario no encontrado en el sistema');
    }

    final userType = userTypeCheck.data!; // Será Constants.adminType o Constants.clientType

    final response = await http.post(
      Uri.parse(Constants.requestPasswordResetEndpoint),
      headers: _headers,
      body: jsonEncode({
        'correo': email,        // ✅ Cambiar de 'Email' a 'correo'
        'userType': userType,   // ✅ Agregar userType (admin o cliente)
      }),
    );

    print('=== SOLICITANDO RESET DE CONTRASEÑA ===');
    print('URL: ${Constants.requestPasswordResetEndpoint}');
    print('Email: $email');
    print('UserType encontrado: $userType');
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('======================================');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return PasswordResetResponse(
        success: true,
        message: data['message']?.toString() ?? 'Código enviado exitosamente',
        userType: userType,
      );
    } else {
      _handleHttpError(response);
      return PasswordResetResponse(
        success: false,
        message: 'Error enviando código de recuperación',
        userType: userType,
      );
    }
  } catch (e) {
    print('Error en requestPasswordReset: $e');
    throw Exception('Error solicitando reseteo de contraseña: $e');
  }
}

static Future<PasswordResetResponse> resetPassword(
  String email, 
  String verificationCode, 
  String newPassword, 
  String userType  // <-- agregar aquí
) async {
  try {
    final response = await http.post(
      Uri.parse(Constants.resetPasswordEndpoint),
      headers: _headers,
      body: jsonEncode({
        'correo': email,
        'userType': userType,
        'nuevaPassword': newPassword,  // ✅ Verificar nombre en backend
        'codigo': verificationCode,  // ✅ CORRECTO
      }),
    );

    print('=== RESETEANDO CONTRASEÑA ===');
    print('URL: ${Constants.resetPasswordEndpoint}');
    print('Email: $email');
    print('UserType enviado: $userType');
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('============================');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return PasswordResetResponse(
        success: true,
        message: data['message']?.toString() ?? 'Contraseña actualizada exitosamente',
        userType: userType,
      );
    } else {
      _handleHttpError(response);
      return PasswordResetResponse(
        success: false,
        message: 'Error actualizando contraseña',
        userType: userType,
      );
    }
  } catch (e) {
    print('Error en resetPassword: $e');
    throw Exception('Error reseteando contraseña: $e');
  }
}




  // ==================== REFRESH TOKEN ====================

  static Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(Constants.refreshTokenEndpoint),
        headers: _headers,
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      _handleHttpError(response);
      final data = jsonDecode(response.body);
      return AuthResponse.fromJson(data);
    } catch (e) {
      throw Exception('Error refreshing token: $e');
    }
  }

  // ==================== MÉTODOS ADMIN ====================
  // (Mantengo los nombres de clave JSON como los tenías si no hay indicaciones de lo contrario)

  static Future<ApiResponse<List<Usuario>>> getAllUsers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$__baseUrl/Usuarios'),
        headers: _headersWithToken(token),
      );
      _handleHttpError(response);
      final data = jsonDecode(response.body);
      return ApiResponse<List<Usuario>>.fromJson(data, (Object? json) => (json as List).map((i) => Usuario.fromJson(i as Map<String, dynamic>)).toList());
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  static Future<ApiResponse<Cliente>> getClientProfile(String token, int idCliente) async {
  try {
    final response = await http.get(
      Uri.parse('$__baseUrl/Clientes/$idCliente'),
      headers: _headersWithToken(token),
    );
    _handleHttpError(response);
    final data = jsonDecode(response.body);
    return ApiResponse<Cliente>.fromJson(
      data, 
      (Object? json) => Cliente.fromJson(json as Map<String, dynamic>)
    );
  } catch (e) {
    throw Exception('Error obteniendo perfil del cliente: $e');
  }
}

static Future<ApiResponse<Usuario>> getUserProfile(String token, int idUsuario) async {
  try {
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/Usuarios/$idUsuario'),
      headers: _headersWithToken(token),
    );
    
    print('=== OBTENIENDO PERFIL USUARIO ===');
    print('URL: ${Constants.baseUrl}/Usuarios/$idUsuario');
    print('ID Usuario: $idUsuario');
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('================================');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ApiResponse<Usuario>(
        success: true,
        message: 'Usuario obtenido exitosamente',
        data: Usuario.fromJson(data),
      );
    } else {
      _handleHttpError(response);
      return ApiResponse<Usuario>(
        success: false,
        message: 'Error obteniendo usuario',
        data: null,
      );
    }
  } catch (e) {
    return ApiResponse<Usuario>(
    success: false,
    message: 'Error obteniendo perfil del usuario: $e',
    data: null,
  );
  }
}

static Future<ApiResponse<Usuario>> updateUserProfileAdmin(String token, Usuario usuario) async {
  try {
    final url = '${Constants.baseUrl}/Usuarios/${usuario.idUsuario}';
    final bodyJson = jsonEncode(usuario.toJsonWithoutId());

    print('=== ACTUALIZANDO PERFIL USUARIO ===');
    print('URL: $url');
    print('Body JSON: $bodyJson');
    print('==================================');

    final response = await http.put(
      Uri.parse(url),
      headers: _headersWithToken(token),
      body: bodyJson,
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('==================================');

    if (response.statusCode == 200 || response.statusCode == 204) {
      // Si el backend no devuelve datos, retornamos el mismo usuario que enviamos
      return ApiResponse<Usuario>(
        success: true,
        message: 'Usuario actualizado exitosamente',
        data: usuario,
      );
    } else {
      _handleHttpError(response);
      return ApiResponse<Usuario>(
        success: false,
        message: 'Error actualizando usuario',
        data: null,
      );
    }
  } catch (e) {
    print('❌ Error actualizando usuario: $e');
    throw Exception('Error al actualizar perfil de usuario: $e');
  }
}

 static Future<ApiResponse<List<Cliente>>> getAllClients(String token) async {
  try {
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/Clientes'), // ✅ RUTA CORRECTA
      headers: _headersWithToken(token),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ApiResponse<List<Cliente>>(
        success: true,
        message: 'Clientes obtenidos exitosamente',
        data: (data as List).map((i) => Cliente.fromJson(i as Map<String, dynamic>)).toList(),
      );
    } else {
      _handleHttpError(response);
      return ApiResponse<List<Cliente>>(
        success: false,
        message: 'Error obteniendo clientes',
        data: null,
      );
    }
  } catch (e) {
    throw Exception('Error fetching clients: $e');
  }
}

  static Future<ApiResponse<List<Rol>>> getAllRoles(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$__baseUrl/admin/roles'),
        headers: _headersWithToken(token),
      );
      _handleHttpError(response);
      final data = jsonDecode(response.body);
      return ApiResponse<List<Rol>>.fromJson(data, (Object? json) => (json as List).map((i) => Rol.fromJson(i as Map<String, dynamic>)).toList());
    } catch (e) {
      throw Exception('Error fetching roles: $e');
    }
  }

  static Future<ApiResponse<Usuario>> updateUserProfile(String token, Usuario usuario) async {
    try {
      final response = await http.put(
        Uri.parse('$__baseUrl/Usuarios/${usuario.idUsuario}'),
        headers: _headersWithToken(token),
        body: jsonEncode(usuario.toJson()),
      );
      _handleHttpError(response);
      final data = jsonDecode(response.body);
      return ApiResponse<Usuario>.fromJson(data, (Object? json) => Usuario.fromJson(json as Map<String, dynamic>));
    } catch (e) {
      throw Exception('Error al actualizar perfil de usuario (admin): $e');
    }
  }

 static Future<ApiResponse<Cliente>> updateClientProfileApi(String token, Cliente cliente) async {
  try {
    final response = await http.put(
      Uri.parse('${Constants.baseUrl}/Clientes/${cliente.idCliente}'),
      headers: _headersWithToken(token),
      body: jsonEncode(cliente.toJsonForUpdate()),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ApiResponse<Cliente>(
        success: true,
        message: 'Cliente actualizado exitosamente',
        data: Cliente.fromJson(data),
      );
    } else if (response.statusCode == 204) {
      // No devuelve datos, pero consideramos éxito y devolvemos el mismo cliente
      return ApiResponse<Cliente>(
        success: true,
        message: 'Cliente actualizado exitosamente (sin contenido)',
        data: cliente,
      );
    } else {
      _handleHttpError(response);
      return ApiResponse<Cliente>(
        success: false,
        message: 'Error actualizando cliente',
        data: null,
      );
    }
  } catch (e) {
    throw Exception('Error al actualizar cliente: $e');
  }
}

  static Future<ApiResponse<Usuario>> updateUsuarioStatus(String token, int idUsuario, bool newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$__baseUrl/Usuarios/$idUsuario'),
        headers: _headersWithToken(token),
        body: jsonEncode({'estado': newStatus}), // Mantener camelCase si es lo que funciona
      );
      _handleHttpError(response);
      final data = jsonDecode(response.body);
      return ApiResponse<Usuario>.fromJson(data, (Object? json) => Usuario.fromJson(json as Map<String, dynamic>));
    } catch (e) {
      throw Exception('Error actualizando estado de usuario: $e');
    }
  }

  static Future<ApiResponse<Cliente>> updateClientStatus(String token, int idCliente, bool newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$__baseUrl/Clientes/$idCliente'),
        headers: _headersWithToken(token),
      );
      _handleHttpError(response);
      final data = jsonDecode(response.body);
      return ApiResponse<Cliente>.fromJson(data, (Object? json) => Cliente.fromJson(json as Map<String, dynamic>));
    } catch (e) {
      throw Exception('Error actualizando estado de cliente: $e');
    }
  }

  static Future<ApiResponse<Cliente>> getClientById(String token, int idCliente) async {
  try {
    final response = await http.get(
      Uri.parse('$__baseUrl/Clientes/$idCliente'), 
      headers: _headersWithToken(token),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ApiResponse<Cliente>(
        success: true,
        message: 'Cliente obtenido exitosamente',
        data: Cliente.fromJson(data),
      );
    } else {
      _handleHttpError(response);
      return ApiResponse<Cliente>(
        success: false,
        message: 'Error obteniendo cliente',
        data: null,
      );
    }
  } catch (e) {
    throw Exception('Error al obtener el cliente por ID: $e');
  }
}

static Future<ApiResponse<Cliente>> getCurrentClientProfile(String token, String email) async {
  try {
    final response = await http.get(
      Uri.parse('${Constants.getClientEndpoint}?correo=$email'),
      headers: _headersWithToken(token),
    );
    _handleHttpError(response);
    final data = jsonDecode(response.body);
    return ApiResponse<Cliente>.fromJson(data, (Object? json) => Cliente.fromJson(json as Map<String, dynamic>));
  } catch (e) {
    throw Exception('Error al obtener cliente por email: $e');
  }
}

static Future<ApiResponse<Usuario>> getCurrentAdminProfile(String token, String email) async {
  try {
    final response = await http.get(
      Uri.parse('${Constants.getAdminEndpoint}?correo=$email'),
      headers: _headersWithToken(token),
    );

    print('=== OBTENIENDO PERFIL ADMIN POR CORREO ===');
    print('Status Code: ${response.statusCode}');
    print('Body: ${response.body}');
    print('=========================================');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final firstItem = (data as List).firstWhere(
        (u) => u['correo'] == email,
        orElse: () => null,
      );

      if (firstItem == null) {
        return ApiResponse<Usuario>(
          success: false,
          message: 'No se encontró admin con ese correo',
          data: null,
        );
      }

      return ApiResponse<Usuario>(
        success: true,
        message: 'Usuario obtenido exitosamente',
        data: Usuario.fromJson(firstItem as Map<String, dynamic>),
      );
    } else {
      _handleHttpError(response);
      return ApiResponse<Usuario>(
        success: false,
        message: 'Error obteniendo admin',
        data: null,
      );
    }
  } catch (e) {
    return ApiResponse<Usuario>(
      success: false,
      message: 'Error al obtener admin por email: $e',
      data: null,
    );
  }
}

  static Future<List<Pedido>> getPedidos() async {
    final response = await http.get(Uri.parse('$__baseUrl/pedido'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((pedido) => Pedido.fromJson(pedido)).toList();
    } else {
      throw Exception('Failed to load pedidos: ${response.statusCode}');
    }
  }

  static Future<Pedido> getPedidoById(int id) async {
    final response = await http.get(Uri.parse('$__baseUrl/pedido/$id'));

    if (response.statusCode == 200) {
      return Pedido.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load pedido with ID $id: ${response.statusCode}');
    }
  }

  static Future<ProductoGeneral> getProductoGeneralById(int id) async {
    final response = await http.get(Uri.parse('$__baseUrl/ProductoGenerals/$id'));

    if (response.statusCode == 200) {
      return ProductoGeneral.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load ProductoGeneral with ID $id: ${response.statusCode}');
    }
  }

  static Future<Venta> getVentaById(int id) async {
    final response = await http.get(Uri.parse('$__baseUrl/venta/$id'));

    if (response.statusCode == 200) {
      return Venta.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load Venta with ID $id: ${response.statusCode}');
    }
  }
  

  // Nuevo método para obtener DetalleVenta por IdVenta
  static Future<List<DetalleVenta>> getDetalleVentaByVentaId(int idVenta) async {
    final response = await http.get(Uri.parse('$__baseUrl/detalleventa/by-venta/$idVenta'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((detalle) => DetalleVenta.fromJson(detalle)).toList();
    } else {
      throw Exception('Failed to load DetalleVenta for Venta ID $idVenta: ${response.statusCode} - ${response.body}');
    }
  }

  // Nuevo método para obtener DetalleAdiciones por IdDetalleVenta
  static Future<List<DetalleAdicione>> getDetalleAdicionesByDetalleVentaId(int idDetalleVenta) async {
    final response = await http.get(Uri.parse('$__baseUrl/DetalleAdiciones'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse
          .map((adicione) => DetalleAdicione.fromJson(adicione))
          .where((adicione) => adicione.idDetalleVenta == idDetalleVenta)
          .toList();
    } else {
      throw Exception('Failed to load DetalleAdiciones for DetalleVenta ID $idDetalleVenta: ${response.statusCode} - ${response.body}');
    }
  }

  // NEW: Method to get CatalogoAdicione by ID
  static Future<CatalogoAdicione> getCatalogoAdicionesById(int id) async {
    final response = await http.get(Uri.parse('$__baseUrl/CatalogoAdiciones/$id'));
    if (response.statusCode == 200) {
      return CatalogoAdicione.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load CatalogoAdicione with ID $id: ${response.statusCode}');
    }
  }

  // NEW: Method to get CatalogoSabor by ID
  static Future<CatalogoSabor> getCatalogoSaborById(int id) async {
    final response = await http.get(Uri.parse('$__baseUrl/CatalogoSabors/$id'));
    if (response.statusCode == 200) {
      return CatalogoSabor.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load CatalogoSabor with ID $id: ${response.statusCode}');
    }
  }

  // NEW: Method to get CatalogoRelleno by ID
  static Future<CatalogoRelleno> getCatalogoRellenoById(int id) async {
    final response = await http.get(Uri.parse('$__baseUrl/CatalogoRellenoes/$id'));
    if (response.statusCode == 200) {
      return CatalogoRelleno.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load CatalogoRelleno with ID $id: ${response.statusCode}');
    }
  }

  static Future<Cliente> getClienteById(int id) async {
    final response = await http.get(Uri.parse('$__baseUrl/Clientes/$id'));

    if (response.statusCode == 200) {
      return Cliente.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load Cliente with ID $id: ${response.statusCode}');
    }
  }
  

  static Future<Sede> getSedeById(int id) async {
    final response = await http.get(Uri.parse('$__baseUrl/Sedes/$id'));

    if (response.statusCode == 200) {
      return Sede.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load Sede with ID $id: ${response.statusCode}');
    }
  }

  static Future<Pedido> createPedido(Pedido pedido) async {
    final response = await http.post(
      Uri.parse('$__baseUrl/pedido'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(pedido.toCreateJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Pedido.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create pedido: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<Pedido> updatePedido(int id, Pedido pedido) async {
    final response = await http.put(
      Uri.parse('$__baseUrl/pedido/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(pedido.toJson()),
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      return pedido;
    } else {
      throw Exception('Failed to update pedido: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllPedidos() async {
  try {
    print('=== OBTENIENDO PEDIDOS ===');
    
    final response = await http.get(
      Uri.parse('$__baseUrl/pedido'), // ✅ Endpoint correcto (singular)
      headers: _headers,
    );
    
    print('URL: $__baseUrl/pedido');
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('=========================');
    
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

  static Future<void> deletePedido(int id) async {
    final response = await http.delete(Uri.parse('$__baseUrl/pedido/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete pedido: ${response.statusCode} - ${response.body}');
    }
  }

 static Future<Imagene> uploadImage(XFile imageFile) async {
  final uri = Uri.parse('$__baseUrl/Imagenes/subir');
  var request = http.MultipartRequest('POST', uri);

  if (kIsWeb) {
    // En web, leemos los bytes y los mandamos como MultipartFile.fromBytes
    Uint8List bytes = await imageFile.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'archivo', // debe coincidir con el nombre del parámetro en tu API
        bytes,
        filename: imageFile.name,
      ),
    );
  } else {
    // En móvil o escritorio, usamos fromPath
    request.files.add(
      await http.MultipartFile.fromPath(
        'archivo',
        imageFile.path,
        filename: imageFile.name,
      ),
    );

  }

  var response = await request.send();

  if (response.statusCode == 201) {
    final responseBody = await response.stream.bytesToString();
    final Map<String, dynamic> jsonResponse = json.decode(responseBody);
    return Imagene.fromJson(jsonResponse);
  } else {
    final errorBody = await response.stream.bytesToString();
    throw Exception('Failed to upload image: ${response.statusCode} - $errorBody');
 
  }
}

static Future<List<Abono>> getAbonosByPedidoId(int idVenta) async {
  try {

    final response = await http.get(
      Uri.parse('$__baseUrl/abonos/pedido/$idVenta'),
      headers: _headers,
    );
    
    print('=== OBTENIENDO ABONOS ===');
    print('URL: $__baseUrl/abonos/pedido/$idVenta');
    print('ID Venta: $idVenta');
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('========================');
    
    if (response.statusCode == 200) {
      final List<dynamic> abonosJson = jsonDecode(response.body);
      final abonos = abonosJson.map((abono) => Abono.fromJson(abono)).toList();
      print('✅ ${abonos.length} abonos obtenidos');
      return abonos;
    } else if (response.statusCode == 404) {
      // Si no existe pedido para esta venta, devolver lista vacía
      print('ℹ️ No hay pedido/abonos para esta venta');
      return [];
    } else {
      _handleHttpError(response);
      return [];
    }
  } catch (e) {
    print('❌ Error al obtener abonos: $e');
    // No lanzar excepción, devolver lista vacía
    return [];
  }
}

static Future<Abono> createAbonoWithImage({
  required int idVenta,  // ✅ CAMBIO IMPORTANTE: Ahora recibe idVenta, no idPedido
  required String metodoPago,
  required double cantidadPagar,
  XFile? imagenComprobante,
}) async {
  try {
    print('=== CREANDO ABONO ===');
    print('ID Venta: $idVenta');
    print('Método Pago: $metodoPago');
    print('Cantidad: $cantidadPagar');
    print('¿Tiene imagen?: ${imagenComprobante != null}');
    
    // Validaciones
    if (metodoPago.isEmpty) {
      throw Exception('Método de pago es requerido');
    }
    
    if (metodoPago.length > 20) {
      throw Exception('Método de pago muy largo (máximo 20 caracteres)');
    }
    
    if (cantidadPagar <= 0) {
      throw Exception('La cantidad a pagar debe ser mayor a 0');
    }
    
    // Crear FormData para enviar archivo
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$__baseUrl/abonos'), // ✅ CORREGIDO: /abonos (minúscula)
    );
    
    // ✅ IMPORTANTE: El backend espera estos nombres de campos exactos
    request.fields['idpedido'] = idVenta.toString(); // Backend lo llama idpedido pero recibe ID de venta
    request.fields['metodopago'] = metodoPago;
    request.fields['cantidadpagar'] = cantidadPagar.toStringAsFixed(2);
    request.fields['TotalPagado'] = cantidadPagar.toStringAsFixed(2);
    
    print('Campos enviados:');
    request.fields.forEach((key, value) {
      print('  $key: $value');
    });
    
    // Si hay imagen, agregarla
    if (imagenComprobante != null) {
      try {
        if (kIsWeb) {
          Uint8List bytes = await imagenComprobante.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'comprobante', // ✅ Nombre correcto del campo
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
    
    print('Enviando request a: ${request.url}');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('====================');
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      final abonoCreado = Abono.fromJson(jsonDecode(response.body));
      print('✅ Abono creado exitosamente con ID: ${abonoCreado.idAbono}');
      return abonoCreado;
    } else {
      String errorMessage = 'Error al crear abono';
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message']?.toString() ?? errorMessage;
        
        // Mensajes específicos
        if (errorMessage.contains('too long for the column') || 
            errorMessage.contains('MÃ©todo de pago muy largo')) {
          errorMessage = 'Método de pago muy largo (máximo 20 caracteres)';
        } else if (errorMessage.contains('ID de pedido es requerido')) {
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
    print('❌ Error en createAbonoWithImage: $e');
    throw Exception('Error al crear abono: $e');
  }
}

 @Deprecated('Usar createAbonoWithImage en su lugar')
static Future<Abono> createAbono(Abono abono) async {
  try {
    print('⚠️ ADVERTENCIA: Usando método legacy createAbono');
    print('Abono data: ${jsonEncode(abono.toCreateJson())}');
    
    final response = await http.post(
      Uri.parse('$__baseUrl/abonos'), // ✅ CORREGIDO: /abonos (minúscula)
      headers: _headers,
      body: jsonEncode(abono.toCreateJson()),
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Abono.fromJson(jsonDecode(response.body));
    } else {
      _handleHttpError(response);
      throw Exception('Failed to create abono');
    }
  } catch (e) {
    print('❌ Error en createAbono legacy: $e');
    throw Exception('Error al crear abono: $e');
  }
}

   static Future<void> updateAbono(int id, Abono abono) async {
  try {
    print('=== ACTUALIZANDO ABONO ===');
    print('ID: $id');
    print('Datos: ${jsonEncode(abono.toJson())}');
    
    final response = await http.put(
      Uri.parse('$__baseUrl/abonos/$id'), // ✅ CORREGIDO: /abonos (minúscula)
      headers: _headers,
      body: jsonEncode(abono.toJson()),
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('=========================');

    if (response.statusCode != 204 && response.statusCode != 200) {
      _handleHttpError(response);
      throw Exception('Failed to update abono');
    }
    
    print('✅ Abono actualizado exitosamente');
  } catch (e) {
    print('❌ Error al actualizar abono: $e');
    throw Exception('Error al actualizar abono: $e');
  }
}

  static Future<void> deleteAbono(int id) async {
  try {
    print('=== ELIMINANDO ABONO ===');
    print('ID: $id');
    
    final response = await http.delete(
      Uri.parse('$__baseUrl/abonos/$id'), // ✅ CORREGIDO: /abonos (minúscula)
      headers: _headers,
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('=======================');

    if (response.statusCode != 204 && response.statusCode != 200) {
      _handleHttpError(response);
      throw Exception('Failed to delete abono');
    }
    
    print('✅ Abono eliminado exitosamente');
  } catch (e) {
    print('❌ Error al eliminar abono: $e');
    throw Exception('Error al eliminar abono: $e');
  }
}

// 6. ANULAR ABONO (NUEVO MÉTODO)
static Future<Map<String, dynamic>> anularAbono(int idAbono) async {
  try {
    print('=== ANULANDO ABONO ===');
    print('ID: $idAbono');
    
    final response = await http.patch(
      Uri.parse('$__baseUrl/abonos/$idAbono/anular'), // ✅ Ruta correcta
      headers: _headers,
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('=====================');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Abono anulado exitosamente');
      return data;
    } else {
      _handleHttpError(response);
      throw Exception('Failed to anular abono');
    }
  } catch (e) {
    print('❌ Error al anular abono: $e');
    throw Exception('Error al anular abono: $e');
  }
}

 static Future<Venta> createVenta(Venta venta) async {
  final fechaFormateada = DateFormat('yyyy-MM-dd').format(venta.fechaVenta);
  final requestBody = {
  "fechaVenta": fechaFormateada,
  "idCliente": venta.idCliente,
  "idSede": venta.idSede,
  "MetodoPago": venta.metodoPago,
  "TipoVenta": venta.tipoVenta,
  "estadoVenta": venta.estadoVenta,
};

  final response = await http.post(
    Uri.parse('$__baseUrl/venta'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(requestBody),
  );

  if (kDebugMode) {
    print('Request body: ${jsonEncode(requestBody)}');
  }

  if (response.statusCode == 201 || response.statusCode == 200) {
    return Venta.fromJson(json.decode(response.body));
  } else {
    if (kDebugMode) {
      print('Error response: ${response.body}');
    }
    throw Exception('Failed to create venta: ${response.statusCode} - ${response.body}');
  }
}

// Crear DetalleVenta - CORREGIDO
static Future<DetalleVenta> createDetalleVenta(DetalleVenta detalleVenta) async {
  final requestBody = {
    "idVenta": detalleVenta.idVenta,
    "idProductoGeneral": detalleVenta.idProductoGeneral,
    "cantidad": detalleVenta.cantidad,
    "precioUnitario": detalleVenta.precioUnitario,
    "subtotal": detalleVenta.subtotal,
    "iva": detalleVenta.iva,
    "total": detalleVenta.total,
  };

  final response = await http.post(
    Uri.parse('$__baseUrl/detalleventa'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(requestBody),
  );

  // Solo mostrar logs en modo debug
  if (kDebugMode) {
    print('DetalleVenta request body: ${jsonEncode(requestBody)}');
  }

  if (response.statusCode == 201 || response.statusCode == 200) {
    return DetalleVenta.fromJson(json.decode(response.body));
  } else {
    if (kDebugMode) {
      print('Error response DetalleVenta: ${response.body}');
    }
    throw Exception('Failed to create detalleVenta: ${response.statusCode} - ${response.body}');
  }
}

  
}

