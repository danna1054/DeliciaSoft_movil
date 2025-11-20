// lib/widgets/personalizacion/selector_salsas.dart
import 'package:flutter/material.dart';
import 'selector_base.dart';

class SelectorSalsas extends StatelessWidget {
  final List<String> salsasDisponibles;
  final List<String> salsasSeleccionadas;
  final int limite;
  final Function(List<String>) onSalsasCambiadas;

  const SelectorSalsas({
    super.key,
    required this.salsasDisponibles,
    required this.salsasSeleccionadas,
    required this.limite,
    required this.onSalsasCambiadas,
  });

  @override
  Widget build(BuildContext context) {
    return SelectorBase(
      titulo: 'Salsas',
      icono: Icons.water_drop,
      opciones: salsasDisponibles,
      seleccionados: salsasSeleccionadas,
      limite: limite,
      onChanged: onSalsasCambiadas,
    );
  }
}