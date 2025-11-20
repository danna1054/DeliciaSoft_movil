import 'package:flutter/material.dart';

class SelectorBase extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<String> opciones;
  final List<String> seleccionados;
  final int limite;
  final Function(List<String>) onChanged;

  const SelectorBase({
    super.key,
    required this.titulo,
    required this.icono,
    required this.opciones,
    required this.seleccionados,
    required this.limite,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink[100]!, width: 1),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: Colors.pinkAccent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber, width: 1.5),
                ),
                child: Text(
                  'Máx: $limite',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: opciones.map((opcion) {
              final estaSeleccionado = seleccionados.contains(opcion);
              final puedeSeleccionar =
                  seleccionados.length < limite || estaSeleccionado;

              return GestureDetector(
                onTap: () {
                  if (estaSeleccionado) {
                    onChanged(
                        seleccionados.where((s) => s != opcion).toList());
                  } else if (puedeSeleccionar) {
                    onChanged([...seleccionados, opcion]);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Solo puedes elegir $limite $titulo'),
                        backgroundColor: Colors.amber,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        estaSeleccionado ? Colors.pinkAccent : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: estaSeleccionado
                          ? Colors.pinkAccent
                          : Colors.pink[200]!,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    opcion,
                    style: TextStyle(
                      color:
                          estaSeleccionado ? Colors.white : Colors.black87,
                      fontWeight: estaSeleccionado
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }
}
