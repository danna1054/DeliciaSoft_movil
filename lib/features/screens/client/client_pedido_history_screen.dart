// lib/screens/client/client_pedido_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/venta_api_service.dart';
import '../../providers/auth_provider.dart';

class ClientPedidoHistoryScreen extends StatefulWidget {
  const ClientPedidoHistoryScreen({super.key});

  @override
  State<ClientPedidoHistoryScreen> createState() => _ClientPedidoHistoryScreenState();
}

class _ClientPedidoHistoryScreenState extends State<ClientPedidoHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _pedidosClienteFuture;
  int? _expandedPedidoId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedEstado = 'Todos';
  
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

  // Estados disponibles
  final List<String> _estados = [
    'Todos',
    'En espera',
    'En producción',
    'Por entregar',
    'Finalizado',
    'Anulada'
  ];

  @override
  void initState() {
    super.initState();
    _pedidosClienteFuture = _fetchPedidosCliente();
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

 Future<List<Map<String, dynamic>>> _fetchPedidosCliente() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      if (auth.currentClient == null) {
        throw Exception('Cliente no autenticado');
      }

      final idCliente = auth.currentClient!.idCliente;
      
      print('ðŸ"‹ Obteniendo pedidos del cliente...');
      print('   ID Cliente buscado: $idCliente');
      
      // Obtener todos los pedidos
      final pedidos = await VentaApiService.getAllPedidos();
      print('   Total pedidos en sistema: ${pedidos.length}');
      
      List<Map<String, dynamic>> pedidosCliente = [];

      for (var pedidoData in pedidos) {
        int? idVenta = pedidoData['idventa'];
        
        if (idVenta != null) {
          try {
            // Obtener detalles de la venta
            final ventaData = await VentaApiService.getVentaById(idVenta);
            
            print('   ðŸ" Venta $idVenta:');
            print('      - campo cliente: ${ventaData['cliente']}');
            print('      - tipo: ${ventaData['cliente'].runtimeType}');
            
            // âœ… SOLUCIÃ"N: El backend retorna 'cliente' como int directamente
            final clienteVenta = ventaData['cliente'];
            
            // Comparar convirtiendo ambos a int para evitar problemas de tipo
            int? clienteVentaId;
            if (clienteVenta != null) {
              if (clienteVenta is int) {
                clienteVentaId = clienteVenta;
              } else if (clienteVenta is String) {
                clienteVentaId = int.tryParse(clienteVenta);
              }
            }
            
            if (clienteVentaId == idCliente) {
              pedidosCliente.add({
                'pedido': pedidoData,
                'venta': ventaData,
              });
              print('      âœ… Match! Pedido agregado (Cliente: $clienteVentaId)');
            } else {
              print('      âŒ No match (Cliente venta: $clienteVentaId vs Esperado: $idCliente)');
            }
          } catch (e) {
            print('âš ï¸ Error obteniendo venta ${idVenta}: $e');
          }
        }
      }
      
      // Ordenar por fecha de entrega (más reciente primero)
      pedidosCliente.sort((a, b) {
        final fechaA = a['pedido']['fechaentrega'];
        final fechaB = b['pedido']['fechaentrega'];
        
        if (fechaA == null && fechaB == null) return 0;
        if (fechaA == null) return 1;
        if (fechaB == null) return -1;
        
        return DateTime.parse(fechaB.toString())
            .compareTo(DateTime.parse(fechaA.toString()));
      });
      
      print('✅ ${pedidosCliente.length} pedidos encontrados para el cliente');
      return pedidosCliente;
    } catch (e) {
      print('❌ Error en _fetchPedidosCliente: $e');
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
      print('📦 Obteniendo detalles completos del pedido $idPedido...');
      
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
      _pedidosClienteFuture = _fetchPedidosCliente();
      _expandedPedidoId = null;
      _searchController.clear();
      _searchQuery = '';
      _selectedEstado = 'Todos';
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
        final Map<String, dynamic>? sede = data['sede'];
        final double totalAbonado = data['totalAbonado'];
        final double saldoPendiente = data['saldoPendiente'];

        final double total = (venta['total'] as num?)?.toDouble() ?? 0.0;

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

        final estadoVenta = venta['estadoVenta']?['nombre_estado'] ??
            venta['nombreEstado'] ?? 'N/A';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información general
              _buildInfoRow('Fecha de Pedido', fechaVentaStr),
              _buildInfoRow('Fecha de Entrega', fechaEntregaStr),
              _buildInfoRow('Sede', sede?['nombre'] ?? 'N/A'),
              _buildInfoRow('Método de Pago', venta['metodopago'] ?? 'N/A'),
              
              // Estado con color
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _darkGrey,
                        fontSize: 15,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getEstadoColor(estadoVenta).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          estadoVenta,
                          style: TextStyle(
                            color: _getEstadoColor(estadoVenta),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 30, thickness: 1, color: _mediumGrey),
              
              // Detalles de productos
              const Text(
                'Productos:',
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
                    'No hay productos.',
                    style: TextStyle(color: _textGrey),
                  ),
                )
              else
                ...detallesVenta.map((detalle) => _buildDetalleVentaCard(detalle)),
              
              const Divider(height: 30, thickness: 1, color: _mediumGrey),
              
              // Observaciones
              if (pedido['observaciones']?.toString().isNotEmpty ?? false)
                _buildInfoRow(
                  'Observaciones',
                  pedido['observaciones'].toString(),
                ),
              
              if (pedido['mensajePersonalizado']?.toString().isNotEmpty ?? false)
                _buildInfoRow(
                  'Mensaje Personalizado',
                  pedido['mensajePersonalizado'].toString(),
                ),
              
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
              nombreProducto,
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
                'Mis Pedidos',
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
                        // Buscador
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Buscar pedidos...',
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                            hintText: 'Nro. Pedido o Fecha',
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
                                  child: Text(estado),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedEstado = newValue!;
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
            future: _pedidosClienteFuture,
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: _textGrey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tienes pedidos aún.',
                          style: TextStyle(
                            color: _textGrey,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Filtrar pedidos
              final filteredPedidos = snapshot.data!.where((pedidoData) {
                final Map<String, dynamic> pedido = pedidoData['pedido'];
                final Map<String, dynamic> venta = pedidoData['venta'];
                final String query = _searchQuery.toLowerCase();

                // Filtro por estado
                if (_selectedEstado != 'Todos') {
                  final estadoVenta = venta['estadoVenta']?['nombre_estado'] ??
                      venta['nombreEstado'] ?? '';
                  if (!estadoVenta.toLowerCase().contains(_selectedEstado.toLowerCase())) {
                    return false;
                  }
                }

                // Filtro por búsqueda
                if (query.isNotEmpty) {
                  // Buscar por ID de pedido
                  if (pedido['idpedido'] != null &&
                      pedido['idpedido'].toString().contains(query)) {
                    return true;
                  }
                  
                  // Buscar por fecha
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
                }

                return true;
              }).toList();

              if (filteredPedidos.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No se encontraron pedidos con los filtros seleccionados.',
                      style: TextStyle(color: _textGrey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pedidoData = filteredPedidos[index];
                    final Map<String, dynamic> pedido = pedidoData['pedido'];
                    final Map<String, dynamic> venta = pedidoData['venta'];
                    final int? idPedido = pedido['idpedido'];
                    final bool isExpanded = _expandedPedidoId == idPedido;

                    String fechaEntregaStr = 'N/A';
                    if (pedido['fechaentrega'] != null) {
                      try {
                        final fechaEntrega = DateTime.parse(
                          pedido['fechaentrega'].toString(),
                        );
                        fechaEntregaStr = DateFormat('dd/MM/yyyy').format(fechaEntrega);
                      } catch (e) {
                        fechaEntregaStr = pedido['fechaentrega'].toString();
                      }
                    }

                    final estadoVenta = venta['estadoVenta']?['nombre_estado'] ??
                        venta['nombreEstado'] ?? 'N/A';

                    return Card(
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
                                  'Entrega: $fechaEntregaStr',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: _textGrey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getEstadoColor(estadoVenta).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    estadoVenta,
                                    style: TextStyle(
                                      color: _getEstadoColor(estadoVenta),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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