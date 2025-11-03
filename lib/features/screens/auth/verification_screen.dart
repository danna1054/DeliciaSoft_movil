import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final String? password;
  final String? userType;
  final bool isPasswordReset;
  final bool isLogin;

  const VerificationScreen({
    super.key,
    required this.email,
    this.password,
    this.userType,
    this.isPasswordReset = false,
    this.isLogin = false,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendInitialCode();
    });
  }

  Future<void> _sendInitialCode() async {
    if (widget.userType != null && !widget.isPasswordReset) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // ✅ CAMBIO CRÍTICO: Ahora se envía también la contraseña
      if (widget.password != null) {
        final response = await authProvider.sendVerificationCode(
          widget.email,
          widget.password!, // ✅ Agregar password
          widget.userType!,
        );

        if (mounted && response != null && response['error'] != null) {
          _showErrorAlert('Error enviando código inicial: ${response['error']}');
        }
      } else {
        _showErrorAlert('Error: Falta la contraseña para enviar el código');
      }
    }
  }

  String get _verificationCode {
    return _controllers.map((controller) => controller.text).join();
  }

  void _showErrorAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 24),
            const SizedBox(width: 8),
            const Text('Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: Color(0xFFE91E63),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green[400], size: 24),
            const SizedBox(width: 8),
            const Text('Éxito', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Continuar',
              style: TextStyle(
                color: Color(0xFFE91E63),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyCode() async {
    if (_verificationCode.length != 6) {
      _showErrorAlert('Por favor ingresa el código completo de 6 dígitos');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final verificationCode = _verificationCode.trim();

    if (!mounted) return;

    String? errorMessage;

    if (widget.isLogin) {
      if (widget.password != null && widget.userType != null) {
        errorMessage = await authProvider.verifyCodeAndLogin(
          widget.email,
          widget.password!,
          widget.userType!,
          verificationCode,
        );

        if (!mounted) return;

        if (errorMessage == null && authProvider.isAuthenticated) {
          _showSuccessAlert(Constants.loginSuccess);
          await Future.delayed(const Duration(milliseconds: 1500));
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(AppRoutes.homeNavigation);
        } else {
          final displayMessage = errorMessage ?? 'Error desconocido en la verificación';
          _showErrorAlert(displayMessage);
          if (displayMessage.toLowerCase().contains('código') &&
              (displayMessage.toLowerCase().contains('inválido') ||
               displayMessage.toLowerCase().contains('expirado'))) {
            _clearCodeFields();
          }
        }
      } else {
        _showErrorAlert('Error interno: faltan datos para el inicio de sesión.');
      }
    } else if (widget.isPasswordReset) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final isChangePassword = args?['isChangePassword'] ?? false;

      if (isChangePassword) {
        _showSuccessAlert('Código validado. Ingresa tu nueva contraseña...');
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        
        Navigator.of(context).pushNamed(
          AppRoutes.resetPassword,
          arguments: {
            'email': widget.email,
            'verificationCode': verificationCode,
            'isChangePassword': true,
            'userType': widget.userType,
          },
        );
      } else {
        _showSuccessAlert('Código validado. Redirigiendo para restablecer contraseña...');
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        
        Navigator.of(context).pushNamed(
          AppRoutes.resetPassword,
          arguments: {
            'email': widget.email,
            'verificationCode': verificationCode,
            'isChangePassword': false,
            'userType': widget.userType,
          },
        );
      }
    } else {
      _showErrorAlert('Flujo de verificación no manejado para registro u otros casos.');
    }
  }

  void _clearCodeFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendCode() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!mounted) return;

    // ✅ CAMBIO CRÍTICO: Ahora también envía la contraseña al reenviar
    if (widget.userType != null && widget.password != null) {
      final response = await authProvider.sendVerificationCode(
        widget.email,
        widget.password!, // ✅ Agregar password
        widget.userType!,
      );

      if (!mounted) return;

      if (response != null && response['error'] != null) {
        _showErrorAlert(response['error']);
      } else {
        _showSuccessAlert('Código reenviado exitosamente');
        _clearCodeFields();
      }
    } else {
      _showErrorAlert('No se puede reenviar el código: faltan datos necesarios.');
    }
  }

  Future<bool> _onWillPop() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isChangePassword = args?['isChangePassword'] ?? false;
    
    if (isChangePassword) {
      return true;
    }
    
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Cancelar verificación?'),
        content: const Text('¿Estás seguro de que quieres cancelar la verificación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFFE91E63)),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

 @override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: _onWillPop,
    child: Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.isLogin
              ? 'Verificar Login'
              : widget.isPasswordReset
                  ? 'Verificar Código'
                  : 'Verificar Correo',
          style: const TextStyle(
            color: Color(0xFFE91E63),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFE91E63)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LoadingWidget(
            isLoading: authProvider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.isLogin)
                      Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        child: Row(
                          children: [
                            _buildProgressStep(1, true, 'Correo'),
                            Expanded(
                              child: Container(
                                height: 2,
                                color: const Color(0xFFE91E63),
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                            _buildProgressStep(2, true, 'Código'),
                            Expanded(
                              child: Container(
                                height: 2,
                                color: Colors.grey[300],
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                            _buildProgressStep(3, false, 'Nueva Contraseña'),
                          ],
                        ),
                      ),

                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFCE4EC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          size: 40,
                          color: Color(0xFFE91E63),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Verificar Código',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C2C2C),
                          ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Ingresa el código de 6 dígitos que enviamos a\n${widget.email}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 50,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _controllers[index].text.isNotEmpty
                                  ? const Color(0xFFE91E63)
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: _controllers[index].text.isNotEmpty
                                ? const Color(0xFFFCE4EC)
                                : Colors.white,
                          ),
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2C2C),
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              setState(() {});
                              if (value.isNotEmpty && index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }

                              if (value.isNotEmpty && index == 5) {
                                if (_verificationCode.length == 6) {
                                  _verifyCode();
                                }
                              }
                            },
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 40),

                    CustomButton(
                      text: widget.isLogin
                          ? 'Verificar y Entrar'
                          : widget.isPasswordReset
                              ? 'Verificar Código'
                              : 'Verificar',
                      onPressed: _verifyCode,
                    ),

                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE91E63)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Correo incorrecto',
                          style: TextStyle(
                            color: Color(0xFFE91E63),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No recibiste el código? ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: _resendCode,
                          child: const Text(
                            'Reenviar',
                            style: TextStyle(
                              color: Color(0xFFE91E63),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

  Widget _buildProgressStep(int step, bool isActive, String label) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFFE91E63) : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? const Color(0xFFE91E63) : Colors.grey[500],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}