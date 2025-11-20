// lib/widgets/personalizacion/limite_selector.dart
import 'package:flutter/material.dart';

class LimiteSelector extends StatelessWidget {
  final int limite;
  final String texto;

  const LimiteSelector({
    super.key,
    required this.limite,
    this.texto = 'Máx',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber, width: 1.5),
      ),
      child: Text(
        '$texto: $limite',
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}