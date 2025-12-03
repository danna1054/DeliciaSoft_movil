// lib/screens/ventas/pedidos/pedido_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/venta_api_service.dart';
import './abono_list_modal.dart';

class PedidoListScreen extends StatefulWidget {
  const PedidoListScreen({super.key});

  @override
  State<PedidoListScreen> createState() => _PedidoListScreenState();
}

class _PedidoListScreenState extends State<PedidoListScreen> {
  late Future<List<Map<String, dynamic>>> _pedidosWithClientFuture;
  List<Map<String, dynamic>> _pedidosWithClientCache = [];
  int? _expandedPedidoId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<int> _canceledPedidoIds = {};
  String _selectedEstado = 'Todos';

  // Estados disponibles
  final List<String> _estados = [
    'Todos',
    'En espera',
    'En producción',
    'Por entregar',
    'Finalizado',
    'Anulada'
  ];

  // Paleta de colores
  static const Color _primaryRose = Color.fromRGBO(228, 48, 84, 1);
  static const Color _darkGrey = Color(0xFF333333);
  static const Color _lightGrey = Color(0xFFF0F2F5);
  static const Color _mediumGrey = Color(0xFFD3DCE5);
  static const Color _textGrey = Color(0xFF6B7A8C);
  static const Color _accentGreen = Color(0xFF6EC67F);
  static const Color _accentRed = Color(0xFFE57373);
  static const Color _accentBlue = Color(0xFF64B5F6);
  static const Color _accentOrange = Color(0xFFFFB74D);

  @override
  void initState() {
    super.initState();
    _pedidosWithClientFuture = _fetchPedidosWithClientNames();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _expandedPedidoId = null;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchPedidosWithClientNames() async {
    try {
      print('📋 Obteniendo pedidos (carga inicial rápida)...');

      final pedidos = await VentaApiService.getAllPedidos();

      // Crear lista inicial rápidamente sin esperar a las ventas
      _pedidosWithClientCache = pedidos.map((pedidoData) {
        return {
          'pedido': pedidoData,
          'clientName': 'Cargando...',
          'venta': null,
        };
      }).toList();

      // Notificar UI inmediatamente con la lista base
      // (la función devuelve esta lista y la UI la mostrará mientras se obtienen los detalles)
      // Luego cargamos las ventas en paralelo y actualizamos la lista a medida que llegan.
      for (int i = 0; i < _pedidosWithClientCache.length; i++) {
        final pedidoData = _pedidosWithClientCache[i]['pedido'];
        final int? idVenta = pedidoData['idventa'];

        if (idVenta != null) {
          VentaApiService.getVentaById(idVenta).then((ventaData) {
            try {
              String clientName = 'N/A';
              if (ventaData != null) {
                if (ventaData['clienteData'] != null) {
                  final nombre = ventaData['clienteData']['nombre'] ?? '';
                  final apellido = ventaData['clienteData']['apellido'] ?? '';
                  clientName = '$nombre $apellido'.trim();
                  if (clientName.isEmpty) clientName = 'Cliente Genérico';
                } else if (ventaData['cliente'] != null) {
                  clientName = ventaData['cliente'].toString();
                }
              }

              _pedidosWithClientCache[i]['clientName'] = clientName;
              _pedidosWithClientCache[i]['venta'] = ventaData;

              if (mounted) setState(() {});
            } catch (e) {
              print('⚠️ Error procesando venta para pedido ${pedidoData['idpedido']}: $e');
            }
          }).catchError((e) {
            print('⚠️ Error obteniendo venta ID $idVenta: $e');
          });
        }
      }

      print('✅ ${_pedidosWithClientCache.length} pedidos cargados (detalles en segundo plano)');
      return _pedidosWithClientCache;
    } catch (e) {
      print('❌ Error en _fetchPedidosWithClientNames: $e');
      if (mounted) {
        _showErrorDialog('Error al cargar pedidos: $e');
      }
      return [];
    }
  }

  Future<Map<String, dynamic>> _fetchFullPedidoDetails(
    int idVenta,
    int idPedido,
  ) async {
    try {
      print('📦 Obteniendo detalles completos...');
      print('ID Venta: $idVenta, ID Pedido: $idPedido');
      
      // Obtener venta completa con abonos
      final ventaCompleta = await VentaApiService.getVentaCompletaConAbonos(idVenta);
      
      print('✅ Detalles obtenidos');
      
      return {
        'venta': ventaCompleta,
        'detallesVenta': ventaCompleta['detalleventa'] ?? [],
        'cliente': ventaCompleta['clienteData'],
        'sede': ventaCompleta['sede'],
        'abonos': ventaCompleta['abonos'] ?? [],
        'totalAbonado': ventaCompleta['totalAbonado'] ?? 0.0,
        'saldoPendiente': ventaCompleta['saldoPendiente'] ?? 0.0,
      };
    } catch (e) {
      print('❌ Error en _fetchFullPedidoDetails: $e');
      throw Exception('Error al cargar detalles: $e');
    }
  }

  void _reloadPedidos() {
    setState(() {
      _pedidosWithClientFuture = _fetchPedidosWithClientNames();
      _expandedPedidoId = null;
      _searchController.clear();
      _searchQuery = '';
      _canceledPedidoIds.clear();
      _selectedEstado = 'Todos';
    });
  }

  Color _getEstadoColor(String? estado) {
    if (estado == null) return _textGrey;
    final estadoLower = estado.toLowerCase();
    if (estadoLower.contains('espera')) return _accentOrange;
    if (estadoLower.contains('producción') || estadoLower.contains('produccion')) return _accentBlue;
    if (estadoLower.contains('entregar')) return Colors.purple;
    if (estadoLower.contains('finalizado') || estadoLower.contains('activa')) return _accentGreen;
    if (estadoLower.contains('anulada') || estadoLower.contains('anulado')) return _accentRed;
    return _textGrey;
  }

  void _cancelPedido(int pedidoId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirmar Anulación',
            style: TextStyle(color: _darkGrey),
          ),
          content: Text(
            '¿Está seguro que desea anular el pedido Nro $pedidoId?',
            style: const TextStyle(color: _textGrey),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: _primaryRose),
              child: const Text('No', style: TextStyle(color: _textGrey)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _canceledPedidoIds.add(pedidoId);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pedido Nro $pedidoId anulado.',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: _accentRed,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: _accentRed),
              child: const Text('Sí', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAbonosModal(int idVenta, double totalPedido) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AbonoListModal(
          idPedido: idVenta,
          totalPedido: totalPedido,
        );
      },
    ).then((changed) async {
      // Only refresh the affected venta if the modal reported changes
      if (changed == true) {
        try {
          print('🔄 Abonos cambiados para venta $idVenta — actualizando solo ese registro');
          final ventaData = await VentaApiService.getVentaById(idVenta);

          // Encontrar en cache y actualizar
          final index = _pedidosWithClientCache.indexWhere((e) => e['pedido'] != null && e['pedido']['idventa'] == idVenta);
          if (index != -1) {
            String clientName = 'N/A';
            if (ventaData != null) {
              if (ventaData['clienteData'] != null) {
                final nombre = ventaData['clienteData']['nombre'] ?? '';
                final apellido = ventaData['clienteData']['apellido'] ?? '';
                clientName = '$nombre $apellido'.trim();
                if (clientName.isEmpty) clientName = 'Cliente Genérico';
              } else if (ventaData['cliente'] != null) {
                clientName = ventaData['cliente'].toString();
              }
            }

            setState(() {
              _pedidosWithClientCache[index]['venta'] = ventaData;
              _pedidosWithClientCache[index]['clientName'] = clientName;
            });
          } else {
            // Si no está en cache (raro), recargar la lista completa
            _reloadPedidos();
          }
        } catch (e) {
          print('⚠️ Error actualizando venta $idVenta después de cambios en abonos: $e');
          // fallback: recargar todo
          _reloadPedidos();
        }
      }
    });
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

  Widget _buildExpandableDetails(Map<String, dynamic> pedidoData) {
    final Map<String, dynamic> pedido = pedidoData['pedido'];
    final int? idVenta = pedido['idventa'];
    final int? idPedido = pedido['idpedido'];
    
    if (idVenta == null || idPedido == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Este pedido no tiene información completa.',
          style: TextStyle(color: _textGrey),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchFullPedidoDetails(idVenta, idPedido),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(color: _primaryRose),
            ),
          );
        } else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: _accentRed),
            ),
          );
        } else if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No se encontraron detalles.',
              style: TextStyle(color: _textGrey),
            ),
          );
        }

        final data = snapshot.data!;
        final Map<String, dynamic> venta = data['venta'];
        final List<dynamic> detallesVenta = data['detallesVenta'];
        final Map<String, dynamic>? cliente = data['cliente'];
        final Map<String, dynamic>? sede = data['sede'];
        final double totalAbonado = data['totalAbonado'];
        final double saldoPendiente = data['saldoPendiente'];

        // Calcular total
        final double total = (venta['total'] as num?)?.toDouble() ?? 0.0;

        // Formatear fechas
        String fechaVentaStr = 'N/A';
        if (venta['fechaventa'] != null) {
          try {
            final fechaVenta = DateTime.parse(venta['fechaventa'].toString());
            fechaVentaStr = DateFormat('dd/MM/yyyy HH:mm').format(fechaVenta);
          } catch (e) {
            fechaVentaStr = venta['fechaventa'].toString();
          }
        }

        String fechaEntregaStr = 'N/A';
        if (pedido['fechaentrega'] != null) {
          try {
            final fechaEntrega = DateTime.parse(pedido['fechaentrega'].toString());
            fechaEntregaStr = DateFormat('dd/MM/yyyy HH:mm').format(fechaEntrega);
          } catch (e) {
            fechaEntregaStr = pedido['fechaentrega'].toString();
          }
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del cliente y venta
              _buildInfoRow(
                'Cliente',
                cliente != null
                    ? '${cliente['nombre'] ?? ''} ${cliente['apellido'] ?? ''}'.trim()
                    : 'Cliente Genérico',
              ),
              _buildInfoRow('Fecha de Venta', fechaVentaStr),
              _buildInfoRow('Sede', sede?['nombre'] ?? 'N/A'),
              _buildInfoRow('Método de Pago', venta['metodopago'] ?? 'N/A'),
              _buildInfoRow('Tipo de Venta', venta['tipoventa'] ?? 'N/A'),
              _buildInfoRow(
                'Estado',
                venta['estadoVenta']?['nombre_estado'] ??
                    venta['nombreEstado'] ??
                    'N/A',
              ),
              
              const Divider(height: 30, thickness: 1, color: _mediumGrey),
              
              // Detalles de venta
              const Text(
                'Detalles de Venta:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryRose,
                ),
              ),
              const SizedBox(height: 10),
              
              if (detallesVenta.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text(
                    'No hay detalles de venta.',
                    style: TextStyle(color: _textGrey),
                  ),
                )
              else
                ...detallesVenta.map((detalle) => _buildDetalleVentaCard(detalle)),
              
              const Divider(height: 30, thickness: 1, color: _mediumGrey),
              
              // Observaciones del pedido
              _buildInfoRow(
                'Observaciones',
                pedido['observaciones']?.toString().isEmpty ?? true
                    ? 'N/A'
                    : pedido['observaciones'].toString(),
              ),
              _buildInfoRow(
                'Mensaje Personalizado',
                pedido['mensajePersonalizado']?.toString().isEmpty ?? true
                    ? 'N/A'
                    : pedido['mensajePersonalizado'].toString(),
              ),
              _buildInfoRow('Fecha de Entrega', fechaEntregaStr),
              
              const SizedBox(height: 10),
              
              // Resumen financiero
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total: \$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _primaryRose,
                      ),
                    ),
                    Text(
                      'Pagado: \$${totalAbonado.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _accentGreen,
                      ),
                    ),
                    Text(
                      'Saldo: \$${saldoPendiente.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: saldoPendiente > 0 ? _accentRed : _accentGreen,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _showAbonosModal(idVenta, total),
                      icon: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Abonos',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent.shade400,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  if (!_canceledPedidoIds.contains(idPedido))
                    ElevatedButton.icon(
                      onPressed: () => _cancelPedido(idPedido),
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: const Text(
                        'Anular Pedido',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentRed,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
              
              if (_canceledPedidoIds.contains(idPedido))
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text(
                      'Pedido Anulado',
                      style: TextStyle(
                        color: _accentRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetalleVentaCard(Map<String, dynamic> detalle) {
    final nombreProducto = detalle['nombreProducto'] ??
        detalle['productogeneral']?['nombreproducto'] ??
        'Producto N/A';
    
    final cantidad = detalle['cantidad'] ?? 0;
    final subtotal = (detalle['subtotal'] as num?)?.toDouble() ?? 0.0;
    final iva = (detalle['iva'] as num?)?.toDouble() ?? 0.0;
    final total = subtotal + iva;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Producto: $nombreProducto',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Cantidad', cantidad.toString()),
            _buildInfoRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
            _buildInfoRow('IVA', '\$${iva.toStringAsFixed(2)}'),
            _buildInfoRow('Total', '\$${total.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: _darkGrey,
              fontSize: 15,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _textGrey,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240.0,
            floating: false,
            pinned: true,
            backgroundColor: _primaryRose,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 110),
              title: const Text(
                'Pedidos',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryRose, _primaryRose.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Buscar pedidos...',
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                            hintText: 'Nro. Pedido, Cliente o Fecha',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: const BorderSide(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged();
                                    },
                                  )
                                : null,
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),

                        const SizedBox(height: 10),

                        // Filtro de estado
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedEstado,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                              dropdownColor: _primaryRose,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              items: _estados.map((String estado) {
                                return DropdownMenuItem<String>(
                                  value: estado,
                                  child: Text(estado, style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedEstado = newValue ?? 'Todos';
                                  _expandedPedidoId = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _reloadPedidos,
                tooltip: 'Recargar',
              ),
            ],
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _pedidosWithClientFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: _primaryRose),
                  ),
                );
              } else if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
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
                        ),
                      ],
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No hay pedidos disponibles.',
                      style: TextStyle(color: _textGrey),
                    ),
                  ),
                );
              }

              final filteredPedidos = snapshot.data!.where((pedidoData) {
                final Map<String, dynamic> pedido = pedidoData['pedido'];
                final String clientName = pedidoData['clientName'].toLowerCase();
                final String query = _searchQuery.toLowerCase();
                final Map<String, dynamic>? venta = pedidoData['venta'];

                // Filtro por estado si aplica
                if (_selectedEstado != 'Todos') {
                  final estadoVenta = venta?['estadoVenta']?['nombre_estado'] ?? venta?['nombreEstado'] ?? '';
                  if (!estadoVenta.toString().toLowerCase().contains(_selectedEstado.toLowerCase())) {
                    return false;
                  }
                }

                if (pedido['idpedido'] != null &&
                    pedido['idpedido'].toString().contains(query)) {
                  return true;
                }
                
                if (clientName.contains(query)) {
                  return true;
                }
                
                // Nota: ya no filtramos por fecha de entrega aquí para la UI admin
                if (pedido['fechaentrega'] != null) {
                  try {
                    final fecha = DateTime.parse(pedido['fechaentrega'].toString());
                    final formattedDate = DateFormat('dd/MM/yyyy').format(fecha);
                    if (formattedDate.contains(query)) {
                      return true;
                    }
                  } catch (e) {
                    // Ignorar error de parseo
                  }
                }

                return false;
              }).toList();

              if (filteredPedidos.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No se encontraron pedidos.',
                      style: TextStyle(color: _textGrey),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pedidoData = filteredPedidos[index];
                    final Map<String, dynamic> pedido = pedidoData['pedido'];
                    final String clientName = pedidoData['clientName'];
                    final int? idPedido = pedido['idpedido'];
                    final bool isExpanded = _expandedPedidoId == idPedido;
                    final double opacity =
                        _canceledPedidoIds.contains(idPedido) ? 0.6 : 1.0;

                    String fechaEntregaStr = 'N/A';
                    if (pedido['fechaentrega'] != null) {
                      try {
                        final fechaEntrega = DateTime.parse(
                          pedido['fechaentrega'].toString(),
                        );
                        fechaEntregaStr = DateFormat('dd/MM/yyyy HH:mm').format(fechaEntrega);
                      } catch (e) {
                        fechaEntregaStr = pedido['fechaentrega'].toString();
                      }
                    }

                    return Opacity(
                      opacity: opacity,
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 15,
                        ),
                        color: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 12.0,
                              ),
                              title: Text(
                                'Pedido Nro: $idPedido',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: _darkGrey,
                                ),
                              ),
                                      subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 6),
                                            Text(
                                              'Cliente: $clientName',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: _textGrey,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Builder(builder: (context) {
                                              final venta = pedidoData['venta'] as Map<String, dynamic>?;

                                              String estadoVenta;
                                              if (venta == null) {
                                                estadoVenta = 'N/A';
                                              } else {
                                                final dynamic estadoField = venta['estadoVenta'];
                                                final dynamic nombreEstadoField = venta['nombreEstado'];

                                                if (estadoField is Map) {
                                                  estadoVenta = (estadoField['nombre_estado'] ?? nombreEstadoField ?? 'N/A').toString();
                                                } else if (estadoField != null) {
                                                  estadoVenta = estadoField.toString();
                                                } else if (nombreEstadoField != null) {
                                                  estadoVenta = nombreEstadoField.toString();
                                                } else {
                                                  estadoVenta = 'N/A';
                                                }
                                              }

                                              final estadoColor = _getEstadoColor(estadoVenta);

                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: estadoColor.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  estadoVenta,
                                                  style: TextStyle(
                                                    color: estadoColor,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                              trailing: Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: _primaryRose,
                                size: 28,
                              ),
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedPedidoId = null;
                                  } else {
                                    _expandedPedidoId = idPedido;
                                  }
                                });
                              },
                            ),
                            if (isExpanded) _buildExpandableDetails(pedidoData),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: filteredPedidos.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}