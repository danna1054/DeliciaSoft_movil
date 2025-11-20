// lib/widgets/personalizacion/selector_rellenos.dart
import 'package:flutter/material.dart';
import 'selector_base.dart';

class SelectorRellenos extends StatelessWidget {
  final List<String> rellenosDisponibles;
  final List<String> rellenosSeleccionados;
  final int limite;
  final Function(List<String>) onRellenosCambiados;

  const SelectorRellenos({
    super.key,
    required this.rellenosDisponibles,
    required this.rellenosSeleccionados,
    required this.limite,
    required this.onRellenosCambiados,
  });

  @override
  Widget build(BuildContext context) {
    return SelectorBase(
      titulo: 'Rellenos',
      icono: Icons.layers,
      opciones: rellenosDisponibles,
      seleccionados: rellenosSeleccionados,
      limite: limite,
      onChanged: onRellenosCambiados,
    );
  }
}