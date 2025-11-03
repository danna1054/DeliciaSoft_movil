// lib/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../models/cliente.dart';
import '../models/api_response.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  Usuario? _currentUser;
  Cliente? _currentClient;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  String? _userType;
  String? _token;
  String? _tempUserType;
  String? get tempUserType => _tempUserType;

  bool _isSendingCode = false;
  bool _isVerifyingCode = false;

  // Getters
  Usuario? get currentUser => _currentUser;
  Cliente? get currentClient => _currentClient;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String? get userType => _userType;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearVerificationState() {
    _isSendingCode = false;
    _isVerifyingCode = false;
  }

 Future<String?> checkUserType(String email) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    // 1) Consultamos si existe como admin
    final isAdmin = await AuthService.checkIfAdmin(email);
    if (isAdmin) {
      return Constants.adminType;
    }

    // 2) Consultamos si existe como cliente
    final isClient = await AuthService.checkIfClient(email);
    if (isClient) {
      return Constants.clientType;
    }

    // 3) No existe en ninguno
    return null;
  } catch (e) {
    _error = e.toString().contains('Exception:')
        ? e.toString().replaceFirst('Exception:', '').trim()
        : 'Error verificando usuario';
    return null;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<String?> validateCredentials(String email, String password, String userType) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final response = await AuthService.validateCredentials(email, password, userType);
    return response; // null si es válido, mensaje de error si no
  } catch (e) {
    _error = e.toString().contains('Exception:')
        ? e.toString().replaceFirst('Exception:', '').trim()
        : 'Error validando credenciales';
    return _error;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<Map<String, dynamic>?> sendVerificationCode(String email, String password, String userType) async {
  if (_isSendingCode) {
    return {'error': 'Ya se está enviando un código, por favor espera...'};
  }

  _isSendingCode = true;

  try {
  final response = await AuthService.sendVerificationCode(email, password, userType);
    if (response) {
      return {'success': true, 'userType': userType};
    } else {
      return {'error': 'Error enviando código de verificación'};
    }
  } catch (e) {
    String errorMessage = e.toString();
    if (errorMessage.contains('Exception:')) {
      errorMessage = errorMessage.replaceFirst('Exception:', '').trim();
    }
    return {'error': errorMessage.isNotEmpty ? errorMessage : 'Error enviando código de verificación'};
  } finally {
    _isSendingCode = false;
  }
}

Future<String?> verifyCodeAndLogin(
  String email,
  String password,
  String userType,
  String code,
) async {
  if (_isVerifyingCode) {
    return 'Ya se está verificando un código, por favor espera...';
  }

  _isVerifyingCode = true;
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final response = await AuthService.verifyCodeAndLogin(email, password, userType, code);
    if (response.success) {
      _isAuthenticated = true;
      _userType = response.userType;
      _token = response.token;

      if (_token != null && _userType != null) {
        await StorageService.saveToken(_token!);
        await StorageService.saveUserType(_userType!);

        final userDataMap = response.user as Map<String, dynamic>?;
        if (userDataMap != null) {
          if (_userType == Constants.adminType) {
            final completeUserData = {
              'idUsuario': userDataMap['idUsuario'] ?? userDataMap['idusuario'] ?? 0,
              'nombre': userDataMap['nombre'] ?? '',
              'apellido': userDataMap['apellido'] ?? '',
              'correo': userDataMap['correo'] ?? '',
              'tipoDocumento': userDataMap['tipoDocumento'] ?? userDataMap['tipodocumento'] ?? '',
              'documento': userDataMap['documento'] ?? 0,
              'estado': userDataMap['estado'] ?? true,
              'hashContrasena': userDataMap['hashContrasena'] ?? userDataMap['hashcontrasena'] ?? '',
              'idRol': userDataMap['idRol'] ?? userDataMap['idrol'] ?? 2,
            };

            if (completeUserData['idUsuario'] == 0) {
              _error = 'No se pudo obtener idUsuario del servidor.';
              _isAuthenticated = false;
              return _error;
            }

            _currentUser = Usuario.fromJson(completeUserData);
            _currentClient = null;
            await StorageService.saveUserData(_currentUser!.toJson());

          } else if (_userType == Constants.clientType) {
            // ✅ SOLUCIÓN: Normalizar campos de cliente
            final completeClientData = {
              // Normalizar idCliente (puede venir como idcliente o idCliente)
              'idCliente': userDataMap['idCliente'] ?? 
                          userDataMap['idcliente'] ?? 
                          0,
              'tipoDocumento': userDataMap['tipoDocumento'] ?? 
                              userDataMap['tipodocumento'] ?? 
                              '',
              'numeroDocumento': userDataMap['numeroDocumento'] ?? 
                                userDataMap['numerodocumento'] ?? 
                                '',
              'nombre': userDataMap['nombre'] ?? '',
              'apellido': userDataMap['apellido'] ?? '',
              'correo': userDataMap['correo'] ?? '',
              'direccion': userDataMap['direccion'] ?? '',
              'barrio': userDataMap['barrio'] ?? '',
              'ciudad': userDataMap['ciudad'] ?? '',
              'fechaNacimiento': userDataMap['fechaNacimiento'] ?? 
                                userDataMap['fechanacimiento'],
              'celular': userDataMap['celular'] ?? '',
              'estado': userDataMap['estado'] ?? true,
              // NO incluir contrasena/hashContrasena aquí
            };

            print('=== DATOS CLIENTE NORMALIZADOS ===');
            print('ID Cliente: ${completeClientData['idCliente']}');
            print('Nombre: ${completeClientData['nombre']}');
            print('Correo: ${completeClientData['correo']}');
            print('================================');

            // Si aún no tenemos idCliente válido, intentar obtenerlo
            if (completeClientData['idCliente'] == 0) {
              print('⚠️ idCliente es 0, intentando obtener por correo...');
              try {
                final clientProfile = await ApiService.getClientByEmail(
                  _token!, 
                  completeClientData['correo'] as String
                );
                if (clientProfile.success && clientProfile.data != null) {
                  completeClientData['idCliente'] = clientProfile.data!.idCliente;
                  print('✅ idCliente obtenido: ${completeClientData['idCliente']}');
                }
              } catch (e) {
                print('❌ No se pudo obtener idCliente por correo: $e');
              }
            }

            _currentClient = Cliente.fromJson(completeClientData);
            _currentUser = null;
            await StorageService.saveUserData(_currentClient!.toJson());
            
            print('✅ Cliente guardado con ID: ${_currentClient!.idCliente}');
          }
        } else {
          _error = 'Datos de usuario incompletos recibidos. Intente de nuevo.';
          _isAuthenticated = false;
        }
      } else {
        _error = 'Error en la respuesta de autenticación: token o tipo de usuario faltante.';
        _isAuthenticated = false;
      }

      notifyListeners();
      _isLoading = false;
      return _error;
    } else {
      _error = response.message.isNotEmpty ? response.message : 'Error en la verificación';
      notifyListeners();
      return _error;
    }
  } catch (e) {
    _error = e.toString().contains('Exception:')
        ? e.toString().replaceFirst('Exception:', '').trim()
        : 'Error en la verificación';
    notifyListeners();
    return _error;
  } finally {
    _isVerifyingCode = false;
    _isLoading = false;
    notifyListeners();
  }
}

Future<void> initialize() async {
  _isLoading = true;
  notifyListeners();

  try {
    final authResponse = await AuthService.autoLogin();
    if (authResponse != null && authResponse.success) {
      _isAuthenticated = true;
      _userType = authResponse.userType;
      _token = authResponse.token;

      if (authResponse.user != null && _userType != null && _token != null) {
        final userDataMap = authResponse.user as Map<String, dynamic>;
        
        if (_userType == Constants.adminType) {
          final completeUserData = {
            'idUsuario': userDataMap['idUsuario'] ?? userDataMap['idusuario'] ?? 0,
            'nombre': userDataMap['nombre'] ?? '',
            'apellido': userDataMap['apellido'] ?? '',
            'correo': userDataMap['correo'] ?? '',
            'tipoDocumento': userDataMap['tipoDocumento'] ?? userDataMap['tipodocumento'] ?? '',
            'documento': userDataMap['documento'] ?? 0,
            'estado': userDataMap['estado'] ?? true,
            'hashContrasena': userDataMap['hashContrasena'] ?? userDataMap['hashcontrasena'] ?? '',
            'idRol': userDataMap['idRol'] ?? userDataMap['idrol'] ?? 2,
          };
          _currentUser = Usuario.fromJson(completeUserData);
          
        } else if (_userType == Constants.clientType) {
          // ✅ SOLUCIÓN: Normalizar campos de cliente
          final completeClientData = {
            'idCliente': userDataMap['idCliente'] ?? 
                        userDataMap['idcliente'] ?? 
                        0,
            'tipoDocumento': userDataMap['tipoDocumento'] ?? 
                            userDataMap['tipodocumento'] ?? 
                            '',
            'numeroDocumento': userDataMap['numeroDocumento'] ?? 
                              userDataMap['numerodocumento'] ?? 
                              '',
            'nombre': userDataMap['nombre'] ?? '',
            'apellido': userDataMap['apellido'] ?? '',
            'correo': userDataMap['correo'] ?? '',
            'direccion': userDataMap['direccion'] ?? '',
            'barrio': userDataMap['barrio'] ?? '',
            'ciudad': userDataMap['ciudad'] ?? '',
            'fechaNacimiento': userDataMap['fechaNacimiento'] ?? 
                              userDataMap['fechanacimiento'],
            'celular': userDataMap['celular'] ?? '',
            'estado': userDataMap['estado'] ?? true,
          };

          print('=== DATOS CLIENTE INITIALIZE NORMALIZADOS ===');
          print('ID Cliente: ${completeClientData['idCliente']}');
          print('==========================================');

          _currentClient = Cliente.fromJson(completeClientData);
          
          print('✅ Cliente inicializado con ID: ${_currentClient!.idCliente}');
        }
      } else {
        _error = 'Datos incompletos en autoLogin.';
        _isAuthenticated = false;
        await AuthService.logout();
        await StorageService.clearAuthData();
      }
    }
  } catch (e) {
    _error = e.toString().contains('Exception:')
        ? e.toString().replaceFirst('Exception:', '').trim()
        : 'Error en inicialización de autenticación';
    _isAuthenticated = false;
    await AuthService.logout();
    await StorageService.clearAuthData();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<String?> login(String email, String password, String userType) async {
  _isLoading = true;
  _error = null;
  notifyListeners();
  try {
    final response = await AuthService.login(email, password, userType);
    if (response.success) {
      _isAuthenticated = true;
      _userType = response.userType;
      _token = response.token;

      if (_token != null && _userType != null) {
        await StorageService.saveToken(_token!);
        await StorageService.saveUserType(_userType!);

        if (response.user != null) {
          final userDataMap = response.user as Map<String, dynamic>;
          if (_userType == Constants.adminType) {
            // ✅ SOLO PARA ADMIN: normalizar campos
            final completeUserData = {
              'idUsuario': userDataMap['idUsuario'] ?? userDataMap['idusuario'] ?? 0,
              'nombre': userDataMap['nombre'] ?? '',
              'apellido': userDataMap['apellido'] ?? '',
              'correo': userDataMap['correo'] ?? '',
              'tipoDocumento': userDataMap['tipoDocumento'] ?? userDataMap['tipodocumento'] ?? '',
              'documento': userDataMap['documento'] ?? 0,
              'estado': userDataMap['estado'] ?? true,
              'hashContrasena': userDataMap['hashContrasena'] ?? userDataMap['hashcontrasena'] ?? '',
              'idRol': userDataMap['idRol'] ?? userDataMap['idrol'] ?? 2,
            };

            if (completeUserData['idUsuario'] == 0) {
              _error = 'No se pudo obtener idUsuario del servidor.';
              _isAuthenticated = false;
              return _error;
            }

            _currentUser = Usuario.fromJson(completeUserData);
            _currentClient = null;
            await StorageService.saveUserData(_currentUser!.toJson());

          } else if (_userType == Constants.clientType) {
            // ✅ PARA CLIENTE: DEJAR EXACTAMENTE COMO ESTABA
            final completeClientData = Map<String, dynamic>.from(userDataMap);

            if (completeClientData['idCliente'] == null) {
              try {
                final clientProfile = await ApiService.getClientByEmail(_token!, completeClientData['correo'] as String);
                if (clientProfile.success && clientProfile.data != null) {
                  completeClientData['idCliente'] = clientProfile.data!.idCliente;
                }
              } catch (e) {
                debugPrint('No se pudo obtener idCliente por correo: $e');
              }
            }

            _currentClient = Cliente.fromJson(completeClientData);
            _currentUser = null;
            await StorageService.saveUserData(_currentClient!.toJson());
          }
        } else {
          _error = 'Datos de usuario incompletos recibidos. Intente de nuevo.';
          _isAuthenticated = false;
        }
      } else {
        _error = 'Error en la respuesta de autenticación: token o tipo de usuario faltante.';
        _isAuthenticated = false;
      }

      notifyListeners();
      return _error;
    } else {
      _error = response.message.isNotEmpty ? response.message : 'Error en login';
      notifyListeners();
      return _error;
    }
  } catch (e) {
    _error = e.toString().contains('Exception:')
        ? e.toString().replaceFirst('Exception:', '').trim()
        : 'Error en login';
    notifyListeners();
    return _error;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  Future<String?> registerClient(Cliente cliente) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final success = await AuthService.registerClient(cliente);
      if (success) {
        return null;
      } else {
        _error = Constants.registerError;
        return _error;
      }
    } catch (e) {
      _error = e.toString().contains('Exception:')
          ? e.toString().replaceFirst('Exception:', '').trim()
          : Constants.registerError;
      if (kDebugMode) {
        print('Error en AuthProvider registerClient: $_error');
      }
      return _error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> registerUser(Usuario usuario) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final success = await AuthService.registerUser(usuario);
      if (success) {
        return null;
      } else {
        _error = Constants.registerError;
        return _error;
      }
    } catch (e) {
      _error = e.toString().contains('Exception:')
          ? e.toString().replaceFirst('Exception:', '').trim()
          : Constants.registerError;
      if (kDebugMode) {
        print('Error en AuthProvider registerUser: $_error');
      }
      return _error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await AuthService.logout();

   await StorageService.clearAuthData(); 

    _isAuthenticated = false;
    _currentUser = null;
    _currentClient = null;
    _userType = null;
    _token = null; // LIMPIAMOS LA PROPIEDAD _token
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

 Future<String?> forgotPassword(String email) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    print('🔄 Iniciando proceso de forgot password para: $email');
    
    // Si hay un usuario autenticado, usar su userType
    String? userTypeToUse = _userType;
    
    // Si no hay usuario autenticado, buscar el tipo de usuario
    if (userTypeToUse == null) {
      userTypeToUse = await checkUserType(email);
      if (userTypeToUse == null) {
        _error = 'Usuario no encontrado';
        return _error;
      }
    }
    
    print('🔄 Usando userType: $userTypeToUse');

    final response = await ApiService.requestPasswordReset(email);
    print('🔄 forgotPassword response: ${response.userType}'); // DEBUG

    if (response.success) {
      // ✅ IMPORTANTE: Guardamos el tipo de usuario que devuelve el backend
      // O usamos el que ya tenemos si el usuario está autenticado
      _tempUserType = response.userType ?? userTypeToUse;
      print('✅ Código enviado exitosamente. UserType guardado: $_tempUserType');
      return null; // Sin error
    } else {
      print('❌ Error en forgot password: ${response.message}');
      _error = response.message.isNotEmpty ? response.message : 'Error solicitando restablecimiento de contraseña';
      return _error;
    }
  } catch (e) {
    String errorMessage = e.toString();
    if (errorMessage.contains('Exception:')) {
      errorMessage = errorMessage.replaceFirst('Exception:', '').trim();
    }

    _error = errorMessage.isNotEmpty
        ? errorMessage
        : 'Error solicitando restablecimiento de contraseña';
    print('❌ Excepción en forgotPassword: $_error');
    return _error;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  Future<String?> resetPassword(String email, String code, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Iniciando proceso de reset password para: $email');
      print('🔄 Código: $code');
      print('🔄 UserType temporal disponible: $_tempUserType');

      // ✅ VALIDACIÓN: Asegurarnos de que tenemos el userType
      if (_tempUserType == null) {
        print('❌ ERROR: UserType temporal es null, usando "cliente" por defecto');
        _tempUserType = 'cliente'; // Fallback por seguridad
      }

      final response = await ApiService.resetPassword(
        email,
        code,
        newPassword,
        _tempUserType!, // Usar el tipo correcto
      );

      if (response.success) {
        print('✅ Contraseña reseteada exitosamente');
        _tempUserType = null; // Limpiar después del uso
        return null; // Sin error
      } else {
        print('❌ Error en reset password: ${response.message}');
        _error = response.message.isNotEmpty ? response.message : 'Error al restablecer contraseña';
        return _error;
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceFirst('Exception:', '').trim();
      }

      _error = errorMessage.isNotEmpty
          ? errorMessage
          : 'Error al restablecer contraseña';
      print('❌ Excepción en resetPassword: $_error');
      return _error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

Future<void> fetchCurrentClientProfile() async {
  if (_userType != Constants.clientType || _currentClient == null) return;

  _isLoading = true;
  notifyListeners();

  try {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('Token no encontrado');

    // ===== AQUÍ USAMOS EL NUEVO MÉTODO DE ApiService =====
    final apiResponse = await ApiService.getClientById(token, _currentClient!.idCliente);

    if (apiResponse.success && apiResponse.data != null) {
      _currentClient = apiResponse.data; // El dato ya es un objeto Cliente
      await StorageService.saveUserData(_currentClient!.toJson()); // Actualiza el storage
    } else {
      // Si la respuesta no fue exitosa, usa el mensaje del API
      throw Exception(apiResponse.message ?? 'Error al cargar el perfil del cliente');
    }
  } catch (e) {
    print('Error en fetchCurrentClientProfile: $e');
    // Puedes decidir si mostrar un error al usuario aquí
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<String?> updateUserProfile(Map<String, dynamic> userData) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    if (_userType == null) {
      _error = 'Tipo de usuario no definido para actualizar perfil.';
      return _error;
    }

    if (_userType == Constants.adminType) {
      // Para usuarios admin
      final usuario = Usuario.fromJson(userData);
      final response = await AuthService.updateAdminProfile(usuario);
      
      if (response.success) {
        if (response.data != null) {
          _currentUser = response.data as Usuario;
          await StorageService.saveUserData(_currentUser!.toJson());
        }
        return null;
      } else {
        _error = response.message.isNotEmpty ? response.message : 'Error al actualizar perfil';
        return _error;
      }
    } else if (_userType == Constants.clientType) {
      // Para clientes
      final cliente = Cliente.fromJson(userData);
      final response = await AuthService.updateClientProfile(cliente);
      
      if (response.success) {
        if (response.data != null) {
          _currentClient = response.data as Cliente;
          await StorageService.saveUserData(_currentClient!.toJson());
        }
        return null;
      } else {
        _error = response.message.isNotEmpty ? response.message : 'Error al actualizar perfil';
        return _error;
      }
    }

    _error = 'Tipo de usuario desconocido al actualizar perfil';
    return _error;
  } catch (e) {
    _error = e.toString().contains('Exception:')
        ? e.toString().replaceFirst('Exception:', '').trim()
        : 'Error al actualizar perfil';
    if (kDebugMode) {
      print('Error al actualizar perfil: $_error');
    }
    return _error;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  Future<String?> updateProfile(dynamic userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_userType == null) {
        _error = 'Tipo de usuario no definido para actualizar perfil.';
        return _error;
      }

      if (_userType == Constants.adminType) {
        if (userData is! Usuario) {
          _error = 'Datos de usuario inválidos para actualización de administrador';
          return _error;
        }
        
        final apiResponse = await AuthService.updateUserProfileAdmin(_token!, userData);

        if (apiResponse.success && apiResponse.data != null) {
          _currentUser = apiResponse.data as Usuario;
          await StorageService.saveUserData(_currentUser!.toJson());
          return null;
        } else {
          _error = apiResponse.message.isNotEmpty
              ? apiResponse.message
              : 'Error al actualizar perfil de administrador';
          return _error;
        }
      } else if (_userType == Constants.clientType) {
        if (userData is! Cliente) {
          _error = 'Datos de cliente inválidos para actualización';
          return _error;
        }
        
        final apiResponse = await AuthService.updateClientProfile(userData);

        if (apiResponse.success && apiResponse.data != null) {
          _currentClient = apiResponse.data as Cliente;
          await StorageService.saveUserData(_currentClient!.toJson());
          return null;
        } else {
          _error = apiResponse.message.isNotEmpty
              ? apiResponse.message
              : 'Error al actualizar perfil de cliente';
          return _error;
        }
      }

      _error = 'Tipo de usuario desconocido al actualizar perfil';
      return _error;
    } catch (e) {
      _error = e.toString().contains('Exception:')
          ? e.toString().replaceFirst('Exception:', '').trim()
          : 'Error al actualizar perfil';
      if (kDebugMode) {
        print('Error al actualizar perfil: $_error');
      }
      return _error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  

 // REEMPLAZA el método loadProfileFromApi en tu auth_provider.dart

Future<void> loadProfileFromApi() async {
  print('=== INICIANDO loadProfileFromApi ===');
  print('Token: ${_token != null ? "Existe" : "NULL"}');
  print('UserType: $_userType');
  print('CurrentUser ID: ${_currentUser?.idUsuario}');
  print('CurrentClient ID: ${_currentClient?.idCliente}');
  
  if (_token == null || _userType == null) {
    print('ERROR: Token o UserType son null');
    _error = 'No hay sesión activa para cargar perfil';
    notifyListeners();
    return;
  }

  _isLoading = true;
  notifyListeners();

  try {
    if (_userType == Constants.adminType && _currentUser != null) {
      print('Cargando perfil de ADMIN con correo: ${_currentUser!.correo}');
      
      // Para admin, intentar usar el método existente o crear uno similar
      try {
        // Verificar si existe getCurrentAdminProfile, si no, usar una alternativa
        final response = await AuthService.getCurrentAdminProfile(_currentUser!.correo);
        
        print('Respuesta API Admin - Success: ${response.success}');
        print('Respuesta API Admin - Message: ${response.message}');
        
        if (response.success && response.data != null) {
          _currentUser = response.data as Usuario;
          await StorageService.saveUserData(_currentUser!.toJson());
          print('Perfil de admin actualizado exitosamente');
        } else {
          // Si el método falla, mantener los datos actuales
          print('ADVERTENCIA: No se pudo actualizar perfil admin, manteniendo datos actuales');
        }
      } catch (e) {
        // Si el método no existe, simplemente mantener los datos actuales
        print('ADVERTENCIA: Método getCurrentAdminProfile no disponible: $e');
        print('Manteniendo datos de admin actuales del login');
      }
      
    } else if (_userType == Constants.clientType && _currentClient != null) {
      print('Cargando perfil de CLIENTE con ID: ${_currentClient!.idCliente}');
      
      final response = await ApiService.getClientProfile(_token!, _currentClient!.idCliente);
      
      print('Respuesta API Cliente - Success: ${response.success}');
      print('Respuesta API Cliente - Message: ${response.message}');
      
      if (response.success && response.data != null) {
        _currentClient = response.data;
        await StorageService.saveUserData(_currentClient!.toJson());
        print('Perfil de cliente actualizado exitosamente');
      } else {
        _error = response.message.isNotEmpty ? response.message : 'Error al obtener perfil de cliente';
        print('ERROR obteniendo perfil cliente: $_error');
      }
    } else {
      _error = 'Usuario no disponible para cargar perfil';
      print('ERROR: $_error');
      print('UserType: $_userType');
      print('CurrentUser disponible: ${_currentUser != null}');
      print('CurrentClient disponible: ${_currentClient != null}');
    }
  } catch (e) {
    _error = 'Error cargando perfil desde API: $e';
    print('EXCEPCIÓN en loadProfileFromApi: $e');
    print('Stack trace: ${StackTrace.current}');
  } finally {
    _isLoading = false;
    print('=== FINALIZANDO loadProfileFromApi - isLoading: $_isLoading ===');
    notifyListeners();
  }
}

Future<void> loadAdminProfileSafe() async {
  if (_userType == Constants.adminType && _currentUser != null) {
    print('Admin profile ya cargado desde login, no necesita actualización adicional');
    return;
  }
}

Future<String?> refreshCurrentClientProfile() async {
  if (_userType != Constants.clientType || _currentClient == null) {
    return 'Solo disponible para clientes autenticados';
  }
  
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final response = await AuthService.getCurrentClientProfile(_currentClient!.correo);
    
    if (response.success && response.data != null) {
      _currentClient = response.data as Cliente;
      await StorageService.saveUserData(_currentClient!.toJson());
      return null;
    } else {
      _error = response.message.isNotEmpty ? response.message : 'Error al obtener perfil del cliente';
      return _error;
    }
  } catch (e) {
    _error = e.toString().contains('Exception:')
        ? e.toString().replaceFirst('Exception:', '').trim()
        : 'Error al obtener perfil del cliente';
    return _error;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}


}