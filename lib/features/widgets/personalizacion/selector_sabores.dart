import 'package:flutter/material.dart';
import 'selector_base.dart';

class SelectorSabores extends StatelessWidget {
  final List<String> opciones;
  final List<String> seleccionados;
  final int limite;
  final Function(List<String>) onChanged;

  const SelectorSabores({
    super.key,
    required this.opciones,
    required this.seleccionados,
    required this.limite,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SelectorBase(
      titulo: 'Sabores',
      icono: Icons.cake,
      opciones: opciones,
      seleccionados: seleccionados,
      limite: limite,
      onChanged: onChanged,
    );
  }
}
