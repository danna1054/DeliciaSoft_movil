// lib/models/configuracion.dart
class ConfiguracionProducto {
  final int idConfiguracion;
  final int idProductoGeneral;
  final String tipoPersonalizacion;
  final int limiteTopping;
  final int limiteSalsa;
  final int limiteRelleno;
  final int limiteSabor;
  final bool permiteToppings;
  final bool permiteSalsas;
  final bool permiteAdiciones;
  final bool permiteRellenos;
  final bool permiteSabores;

  ConfiguracionProducto({
    required this.idConfiguracion,
    required this.idProductoGeneral,
    required this.tipoPersonalizacion,
    required this.limiteTopping,
    required this.limiteSalsa,
    required this.limiteRelleno,
    required this.limiteSabor,
    required this.permiteToppings,
    required this.permiteSalsas,
    required this.permiteAdiciones,
    required this.permiteRellenos,
    required this.permiteSabores,
  });

  factory ConfiguracionProducto.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    bool _toBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) {
        final s = v.toLowerCase();
        return s == 'true' || s == '1' || s == 'si' || s == 'yes';
      }
      return false;
    }

    String _toString(dynamic v) {
      if (v == null) return '';
      return v.toString();
    }

    return ConfiguracionProducto(
      idConfiguracion: _toInt(json['idconfiguracion']),
      idProductoGeneral: _toInt(json['idproductogeneral']),
      tipoPersonalizacion: _toString(json['tipoPersonalizacion']),
      limiteTopping: _toInt(json['limiteTopping']),
      limiteSalsa: _toInt(json['limiteSalsa']),
      limiteRelleno: _toInt(json['limiteRelleno']),
      limiteSabor: _toInt(json['limiteSabor']),
      permiteToppings: _toBool(json['permiteToppings']),
      permiteSalsas: _toBool(json['permiteSalsas']),
      permiteAdiciones: _toBool(json['permiteAdiciones']),
      permiteRellenos: _toBool(json['permiteRellenos']),
      permiteSabores: _toBool(json['permiteSabores']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idconfiguracion': idConfiguracion,
      'idproductogeneral': idProductoGeneral,
      'tipoPersonalizacion': tipoPersonalizacion,
      'limiteTopping': limiteTopping,
      'limiteSalsa': limiteSalsa,
      'limiteRelleno': limiteRelleno,
      'limiteSabor': limiteSabor,
      'permiteToppings': permiteToppings,
      'permiteSalsas': permiteSalsas,
      'permiteAdiciones': permiteAdiciones,
      'permiteRellenos': permiteRellenos,
      'permiteSabores': permiteSabores,
    };
  }

  bool get permitePersonalizacion {
    return tipoPersonalizacion.toLowerCase() == 'personalizado' &&
        (permiteToppings || permiteSalsas || permiteAdiciones || permiteRellenos || permiteSabores);
  }

  @override
  String toString() {
    return 'ConfiguracionProducto(id: $idConfiguracion, producto: $idProductoGeneral, tipo: $tipoPersonalizacion)';
  }
}