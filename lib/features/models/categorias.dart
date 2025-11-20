// lib/models/category.dart
class Category {
  final int idcategoriaproducto;
  final String nombrecategoria;
  final String? descripcion;
  final bool estado;
  final int? idimagencat;
  final String? urlImg;

  Category({
    required this.idcategoriaproducto,
    required this.nombrecategoria,
    this.descripcion,
    required this.estado,
    this.idimagencat,
    this.urlImg,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    String _toString(dynamic v) {
      if (v == null) return '';
      return v.toString();
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    bool _toBool(dynamic v) {
      if (v == null) return true;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) {
        final s = v.toLowerCase();
        return s == 'true' || s == '1' || s == 'si' || s == 'yes';
      }
      return true;
    }

    return Category(
      idcategoriaproducto: _toInt(json['idcategoriaproducto']),
      nombrecategoria: _toString(json['nombrecategoria']),
      descripcion: _toString(json['descripcion']),
      estado: _toBool(json['estado']),
      idimagencat: _toInt(json['idimagencat']),
      urlImg: _toString(json['imagenes']?['urlimg']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idcategoriaproducto': idcategoriaproducto,
      'nombrecategoria': nombrecategoria,
      'descripcion': descripcion,
      'estado': estado,
      'idimagencat': idimagencat,
      'urlImg': urlImg,
    };
  }

  @override
  String toString() {
    return 'Category(id: $idcategoriaproducto, nombre: $nombrecategoria)';
  }
}