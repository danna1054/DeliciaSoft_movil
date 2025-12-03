// lib/screens/ventas/abonos/abono_list_modal.dart
import 'package:flutter/material.dart';
import '../../../models/venta/abono.dart';
import '../../../services/venta_api_service.dart';
import 'abono_form_screen.dart';

class AbonoListModal extends StatefulWidget {
  final int idPedido; // En realidad es el ID de la venta
  final double totalPedido;

  const AbonoListModal({
    super.key,
    required this.idPedido,
    required this.totalPedido,
  });

  @override
  State<AbonoListModal> createState() => _AbonoListModalState();
}

class _AbonoListModalState extends State<AbonoListModal> {
  late Future<List<Abono>> _abonosFuture;
  late Future<double> _totalAbonadoFuture;
  bool _hasChanges = false;

  // Paleta de colores
  static const Color _primaryRose = Color.fromRGBO(228, 48, 84, 1);
  static const Color _darkGrey = Color(0xFF333333);
  static const Color _lightGrey = Color(0xFFF0F2F5);
  static const Color _textGrey = Color(0xFF6B7A8C);
  static const Color _accentGreen = Color(0xFF6EC67F);
  static const Color _accentRed = Color(0xFFE57373);

  @override
  void initState() {
    super.initState();
    _abonosFuture = _fetchAbonos();
    _totalAbonadoFuture = _calculateTotalAbonado();
  }

  Future<List<Abono>> _fetchAbonos() async {
    try {
      print('💰 Obteniendo abonos para venta ${widget.idPedido}');
      final abonos = await VentaApiService.getAbonosByVentaId(widget.idPedido);
      print('✅ ${abonos.length} abonos obtenidos');
      return abonos;
    } catch (e) {
      print('❌ Error al cargar abonos: $e');
      if (mounted) {
        _showErrorDialog('Error al cargar abonos: $e');
      }
      return [];
    }
  }

  Future<double> _calculateTotalAbonado() async {
    try {
      final abonos = await VentaApiService.getAbonosByVentaId(widget.idPedido);
      double sum = 0.0;
      
      for (var abono in abonos) {
        sum += abono.cantidadPagar ?? 0.0;
      }
      
      print('💰 Total abonado: \$${sum.toStringAsFixed(2)}');
      return sum;
    } catch (e) {
      print('❌ Error calculando total: $e');
      return 0.0;
    }
  }

  void _reloadAbonos() {
    if (mounted) {
      setState(() {
        _abonosFuture = _fetchAbonos();
        _totalAbonadoFuture = _calculateTotalAbonado();
      });
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error', style: TextStyle(color: _darkGrey)),
          content: Text(message, style: const TextStyle(color: _textGrey)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: _primaryRose)),
            ),
          ],
        );
      },
    );
  }

  void _addAbono() {
    print('➕ Abriendo formulario para crear abono');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AbonoFormScreen(
          idPedido: widget.idPedido,
          totalPedido: widget.totalPedido,
        );
      },
    ).then((result) {
      if (result == true) {
        print('✅ Abono creado, recargando lista');
        _hasChanges = true;
        _reloadAbonos();
      }
    });
  }

  void _editAbono(Abono abono) {
    print('✏️ Editando abono ID: ${abono.idAbono}');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AbonoFormScreen(
          idPedido: widget.idPedido,
          abono: abono,
          totalPedido: widget.totalPedido,
        );
      },
    ).then((result) {
      if (result == true) {
        print('✅ Abono actualizado, recargando lista');
        _hasChanges = true;
        _reloadAbonos();
      }
    });
  }

  void _deleteAbono(int idAbono) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirmar Eliminación',
            style: TextStyle(color: _darkGrey),
          ),
          content: const Text(
            '¿Está seguro que desea eliminar este abono?',
            style: TextStyle(color: _textGrey),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: _primaryRose),
              child: const Text('No', style: TextStyle(color: _textGrey)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  print('🗑️ Eliminando abono $idAbono');
                  await VentaApiService.deleteAbono(idAbono);
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    _hasChanges = true;
                    _reloadAbonos();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Abono eliminado correctamente',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _accentGreen,
                      ),
                    );
                  }
                } catch (e) {
                  print('❌ Error al eliminar: $e');
                  if (mounted) {
                    Navigator.of(context).pop();
                    _showErrorDialog('Error al eliminar abono: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _accentRed),
              child: const Text('Sí', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges);
        return false;
      },
      child: Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: _lightGrey,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Column(
            children: [
              // Header
              AppBar(
                title: Text(
                  'Abonos de Venta ${widget.idPedido}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                backgroundColor: _primaryRose,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(_hasChanges),
                  ),
                ],
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                elevation: 0,
              ),
              
              // Resumen financiero
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: \$${widget.totalPedido.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: _darkGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    FutureBuilder<double>(
                      future: _totalAbonadoFuture,
                      builder: (context, snapshot) {
                        double totalAbonado = snapshot.data ?? 0.0;
                        double saldoPendiente = widget.totalPedido - totalAbonado;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Abonado: \$${totalAbonado.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: _accentGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Saldo: \$${saldoPendiente.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: saldoPendiente > 0.01
                                    ? _accentRed
                                    : _accentGreen,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Lista de abonos
              Expanded(
                child: FutureBuilder<List<Abono>>(
                  future: _abonosFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: _primaryRose),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: _accentRed,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: _accentRed),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              color: _textGrey.withOpacity(0.5),
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay abonos registrados',
                              style: TextStyle(
                                color: _textGrey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      final abonos = snapshot.data!;
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(12.0),
                        itemCount: abonos.length,
                        itemBuilder: (context, index) {
                          final abono = abonos[index];
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Monto: \$${(abono.cantidadPagar ?? 0.0).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                            color: _darkGrey,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Método: ${abono.metodoPago ?? 'N/A'}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: _textGrey,
                                          ),
                                        ),
                                        if (abono.urlImagen != null &&
                                            abono.urlImagen!.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              abono.urlImagen!,
                                              height: 80,
                                              width: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(
                                                Icons.broken_image,
                                                size: 80,
                                                color: _textGrey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blueAccent,
                                        ),
                                        onPressed: () => _editAbono(abono),
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: _accentRed,
                                        ),
                                        onPressed: () => _deleteAbono(abono.idAbono!),
                                        tooltip: 'Eliminar',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
              
              // Botón para agregar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                child: ElevatedButton.icon(
                  onPressed: _addAbono,
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                  label: const Text(
                    'Agregar Nuevo Abono',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryRose,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),)
    );
  }
}