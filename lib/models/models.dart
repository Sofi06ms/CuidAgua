class Reporte {
  final int id;
  final String? folio;
  final String descripcion;
  final String? categoria;
  final String? estado;
  final String? zonaNombre;
  final double? latitud;
  final double? longitud;

  Reporte({
    required this.id,
    this.folio,
    required this.descripcion,
    this.categoria,
    this.estado,
    this.zonaNombre,
    this.latitud,
    this.longitud,
  });

  factory Reporte.fromJson(Map<String, dynamic> json) {
    final zona = json['zona'];
    return Reporte(
      id: json['id'] ?? 0,
      folio: json['folio'],
      descripcion: json['descripcion'] ?? 'Sin descripción',
      categoria: json['categoria'],
      estado: json['estado'],
      zonaNombre: zona is Map ? zona['nombre']?.toString() : null,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
    );
  }
}

class AvisoSuministro {
  final int id;
  final int? zonaId;
  final String titulo;
  final String mensaje;
  final String? horario;
  final String? fechaPublicacion;

  AvisoSuministro({
    required this.id,
    this.zonaId,
    required this.titulo,
    required this.mensaje,
    this.horario,
    this.fechaPublicacion,
  });

  factory AvisoSuministro.fromJson(Map<String, dynamic> json) {
    final zona = json['zona'];
    return AvisoSuministro(
      id: json['id'] ?? 0,
      zonaId: json['zonaId'] ?? json['zona_id'] ?? (zona is Map ? zona['id'] : null),
      titulo: json['titulo'] ?? 'Sin título',
      mensaje: json['mensaje'] ?? 'Sin mensaje',
      horario: json['horario']?.toString(),
      fechaPublicacion: (json['fechaPublicacion'] ?? json['fecha_publicacion'])?.toString(),
    );
  }
}

class Zona {
  final int id;
  final String nombre;

  Zona({required this.id, required this.nombre});

  factory Zona.fromJson(Map<String, dynamic> json) {
    return Zona(
      id: json['id'] ?? 0,
      nombre: (json['nombre'] ?? json['nombreZona'] ?? json['nombre_zona'] ?? 'Zona ${json['id']}').toString(),
    );
  }
}