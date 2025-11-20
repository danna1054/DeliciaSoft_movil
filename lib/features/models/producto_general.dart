// lib/models/General_models.dart
class ProductModel {
  final int idProductoGeneral;
  final String nombreProducto;
  final String? descripcion;
  final double precioProducto;
  final int cantidadProducto;
  final bool estado;
  final int idCategoriaProducto;
  final int? idImagen;
  final int? idReceta;
  final String? urlImg;
  final String? nombreCategoria;
  final String? nombreReceta;
  final String? especificacionesReceta;

  ProductModel({
    required this.idProductoGeneral,
    required this.nombreProducto,
    this.descripcion,
    required this.precioProducto,
    required this.cantidadProducto,
    required this.estado,
    required this.idCategoriaProducto,
    this.idImagen,
    this.idReceta,
    this.urlImg,
    this.nombreCategoria,
    this.nombreReceta,
    this.especificacionesReceta,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
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

    String _toString(dynamic v) {
      if (v == null) return '';
      return v.toString();
    }

    // Obtener URL de imagen de forma segura
    String urlImagen = '';
    if (json['urlimagen'] != null && json['urlimagen'].toString().isNotEmpty) {
      urlImagen = _toString(json['urlimagen']);
    } else if (json['imagenes'] != null && json['imagenes']['urlimg'] != null) {
      urlImagen = _toString(json['imagenes']['urlimg']);
    }

    return ProductModel(
      idProductoGeneral: _toInt(json['idproductogeneral']),
      nombreProducto: _toString(json['nombreproducto']),
      precioProducto: _toDouble(json['precioproducto']),
      cantidadProducto: _toInt(json['cantidadproducto']),
      estado: _toBool(json['estado']),
      idCategoriaProducto: _toInt(json['idcategoriaproducto']),
      idImagen: _toInt(json['idimagen']),
      idReceta: _toInt(json['idreceta']),
      urlImg: urlImagen.isEmpty ? null : urlImagen,
      nombreCategoria: _toString(json['categoria'] ?? json['categoriaproducto']?['nombrecategoria']),
      nombreReceta: _toString(json['nombrereceta'] ?? json['receta']?['nombre']),
      especificacionesReceta: _toString(json['especificacionesreceta'] ?? json['receta']?['especificaciones']),
      descripcion: _toString(json['descripcion'] ?? json['especificacionesreceta'] ?? json['receta']?['especificaciones']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idproductogeneral': idProductoGeneral,
      'nombreproducto': nombreProducto,
      'precioproducto': precioProducto.toString(),
      'cantidadproducto': cantidadProducto.toString(),
      'estado': estado,
      'idcategoriaproducto': idCategoriaProducto,
      'idimagen': idImagen,
      'idreceta': idReceta,
      'urlimagen': urlImg,
      'categoria': nombreCategoria,
      'nombrereceta': nombreReceta,
      'especificacionesreceta': especificacionesReceta,
    };
  }

  ProductModel copyWith({
    int? idProductoGeneral,
    String? nombreProducto,
    String? descripcion,
    double? precioProducto,
    int? cantidadProducto,
    bool? estado,
    int? idCategoriaProducto,
    int? idImagen,
    int? idReceta,
    String? urlImg,
    String? nombreCategoria,
    String? nombreReceta,
    String? especificacionesReceta,
  }) {
    return ProductModel(
      idProductoGeneral: idProductoGeneral ?? this.idProductoGeneral,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      descripcion: descripcion ?? this.descripcion,
      precioProducto: precioProducto ?? this.precioProducto,
      cantidadProducto: cantidadProducto ?? this.cantidadProducto,
      estado: estado ?? this.estado,
      idCategoriaProducto: idCategoriaProducto ?? this.idCategoriaProducto,
      idImagen: idImagen ?? this.idImagen,
      idReceta: idReceta ?? this.idReceta,
      urlImg: urlImg ?? this.urlImg,
      nombreCategoria: nombreCategoria ?? this.nombreCategoria,
      nombreReceta: nombreReceta ?? this.nombreReceta,
      especificacionesReceta: especificacionesReceta ?? this.especificacionesReceta,
    );
  }

  @override
  String toString() {
    return 'ProductModel(id: $idProductoGeneral, nombre: $nombreProducto, precio: $precioProducto)';
  }

  bool get tieneImagen => urlImg != null && urlImg!.isNotEmpty;
  String get precioFormateado => '\$${precioProducto.toStringAsFixed(0)}';
  bool get estaDisponible => estado && cantidadProducto > 0;
}