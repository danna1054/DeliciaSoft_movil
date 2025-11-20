// lib/widgets/personalizacion/selector_adiciones.dart
import 'package:flutter/material.dart';
import 'selector_base.dart';

class SelectorAdiciones extends StatelessWidget {
  final List<String> adicionesDisponibles;
  final List<String> adicionesSeleccionadas;
  final int limite;
  final Function(List<String>) onAdicionesCambiadas;

  const SelectorAdiciones({
    super.key,
    required this.adicionesDisponibles,
    required this.adicionesSeleccionadas,
    required this.limite,
    required this.onAdicionesCambiadas,
  });

  @override
  Widget build(BuildContext context) {
    return SelectorBase(
      titulo: 'Adiciones Extra',
      icono: Icons.add_circle_outline,
      opciones: adicionesDisponibles,
      seleccionados: adicionesSeleccionadas,
      limite: limite,
      onChanged: onAdicionesCambiadas,
    );
  }
}