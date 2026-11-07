class Reporte {
  final int id;
  final String descripcion;
  final String ubicacion;
  final String fecha;

  Reporte({
    required this.id,
    required this.descripcion,
    required this.ubicacion,
    required this.fecha,
  });

  factory Reporte.fromJson(Map<String, dynamic> json) {
    return Reporte(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      descripcion: json['descripcion']?.toString() ?? 'Sin descripción',
      ubicacion: json['ubicacion']?.toString() ?? 'Desconocida',
      fecha: json['fecha']?.toString() ?? 'Sin fecha',
    );
  }
}

class AvisoSuministro {
  final int id;
  final String titulo;
  final String detalle;
  final String coloniaAfectada;

  AvisoSuministro({
    required this.id,
    required this.titulo,
    required this.detalle,
    required this.coloniaAfectada,
  });

  factory AvisoSuministro.fromJson(Map<String, dynamic> json) {
    return AvisoSuministro(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      titulo: json['titulo']?.toString() ?? 'Sin título',
      detalle: json['detalle']?.toString() ?? 'Sin detalle',
      coloniaAfectada:
          json['coloniaAfectada']?.toString() ?? 'General',
    );
  }
}