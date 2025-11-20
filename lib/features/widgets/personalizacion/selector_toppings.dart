// lib/widgets/personalizacion/selector_toppings.dart
import 'package:flutter/material.dart';
import 'selector_base.dart';

class SelectorToppings extends StatelessWidget {
  final List<String> toppingsDisponibles;
  final List<String> toppingsSeleccionados;
  final int limite;
  final Function(List<String>) onToppingsCambiados;

  const SelectorToppings({
    super.key,
    required this.toppingsDisponibles,
    required this.toppingsSeleccionados,
    required this.limite,
    required this.onToppingsCambiados,
  });

  @override
  Widget build(BuildContext context) {
    return SelectorBase(
      titulo: 'Toppings',
      icono: Icons.stars,
      opciones: toppingsDisponibles,
      seleccionados: toppingsSeleccionados,
      limite: limite,
      onChanged: onToppingsCambiados,
    );
  }
}