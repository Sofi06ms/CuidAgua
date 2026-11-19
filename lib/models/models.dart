import 'package:flutter/material.dart';

// ───────────────────────────── USUARIO ─────────────────────────────

enum RolUsuario { ciudadano, administrador }

class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final String colonia;
  final RolUsuario rol;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.colonia = 'Centro',
  });

  bool get esAdmin => rol == RolUsuario.administrador;

  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    return partes
        .take(2)
        .map((p) => p.isEmpty ? '' : p[0])
        .join()
        .toUpperCase();
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      nombre: json['nombre']?.toString() ?? 'Usuario',
      correo: json['correo']?.toString() ?? '',
      colonia: json['colonia']?.toString() ?? 'Centro',
      rol: json['rol']?.toString().toUpperCase() == 'ADMINISTRADOR'
          ? RolUsuario.administrador
          : RolUsuario.ciudadano,
    );
  }
}

// ───────────────────────────── REPORTES ─────────────────────────────

enum EstadoReporte {
  pendiente('Pendiente', Icons.schedule_rounded, Color(0xFF8A6D00)),
  enRevision('En revisión', Icons.manage_search_rounded, Color(0xFF6A4BC4)),
  enProceso('En proceso', Icons.construction_rounded, Color(0xFF0077B6)),
  resuelto('Resuelto', Icons.check_circle_rounded, Color(0xFF2E7D32));

  final String etiqueta;
  final IconData icono;
  final Color color;

  const EstadoReporte(this.etiqueta, this.icono, this.color);

  static EstadoReporte desdeTexto(String? valor) {
    switch (valor?.toUpperCase()) {
      case 'EN_REVISION':
        return EstadoReporte.enRevision;
      case 'EN_PROCESO':
        return EstadoReporte.enProceso;
      case 'RESUELTO':
        return EstadoReporte.resuelto;
      default:
        return EstadoReporte.pendiente;
    }
  }

  String get valorApi => switch (this) {
    EstadoReporte.pendiente => 'PENDIENTE',
    EstadoReporte.enRevision => 'EN_REVISION',
    EstadoReporte.enProceso => 'EN_PROCESO',
    EstadoReporte.resuelto => 'RESUELTO',
  };
}

enum Prioridad {
  baja('Baja', Color(0xFF607D8B)),
  media('Media', Color(0xFFEF6C00)),
  alta('Alta', Color(0xFFC62828));

  final String etiqueta;
  final Color color;

  const Prioridad(this.etiqueta, this.color);

  static Prioridad desdeTexto(String? valor) => Prioridad.values.firstWhere(
    (p) => p.name.toUpperCase() == valor?.toUpperCase(),
    orElse: () => Prioridad.media,
  );
}

enum TipoProblema {
  fuga('Fuga de agua', Icons.water_drop_rounded),
  sinSuministro('Sin suministro', Icons.format_color_reset_rounded),
  bajaPresion('Baja presión', Icons.speed_rounded),
  aguaTurbia('Agua turbia', Icons.blur_on_rounded),
  drenaje('Drenaje', Icons.plumbing_rounded),
  otro('Otro', Icons.help_outline_rounded);

  final String etiqueta;
  final IconData icono;

  const TipoProblema(this.etiqueta, this.icono);

  static TipoProblema desdeTexto(String? valor) =>
      TipoProblema.values.firstWhere(
        (t) => t.name.toUpperCase() == valor?.toUpperCase(),
        orElse: () => TipoProblema.otro,
      );
}

class Reporte {
  final int id;
  final String descripcion;
  final String ubicacion;
  final String fecha;
  final TipoProblema tipo;
  final EstadoReporte estado;
  final Prioridad prioridad;
  final String colonia;
  final String ciudadano;

  Reporte({
    required this.id,
    required this.descripcion,
    required this.ubicacion,
    required this.fecha,
    this.tipo = TipoProblema.otro,
    this.estado = EstadoReporte.pendiente,
    this.prioridad = Prioridad.media,
    this.colonia = 'Sin colonia',
    this.ciudadano = 'Anónimo',
  });

  Reporte copyWith({EstadoReporte? estado, Prioridad? prioridad}) {
    return Reporte(
      id: id,
      descripcion: descripcion,
      ubicacion: ubicacion,
      fecha: fecha,
      tipo: tipo,
      estado: estado ?? this.estado,
      prioridad: prioridad ?? this.prioridad,
      colonia: colonia,
      ciudadano: ciudadano,
    );
  }

  factory Reporte.fromJson(Map<String, dynamic> json) {
    return Reporte(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      descripcion: json['descripcion']?.toString() ?? 'Sin descripción',
      ubicacion: json['ubicacion']?.toString() ?? 'Desconocida',
      fecha: json['fecha']?.toString() ?? 'Sin fecha',
      tipo: TipoProblema.desdeTexto(json['tipo']?.toString()),
      estado: EstadoReporte.desdeTexto(json['estado']?.toString()),
      prioridad: Prioridad.desdeTexto(json['prioridad']?.toString()),
      colonia: json['colonia']?.toString() ?? 'Sin colonia',
      ciudadano: json['ciudadano']?.toString() ?? 'Anónimo',
    );
  }
}

// ───────────────────────────── AVISOS ─────────────────────────────

enum TipoAviso {
  corte('Corte programado', Icons.block_rounded, Color(0xFFC62828)),
  bajaPresion('Baja presión', Icons.speed_rounded, Color(0xFFEF6C00)),
  mantenimiento('Mantenimiento', Icons.engineering_rounded, Color(0xFF6A4BC4)),
  restablecido('Restablecido', Icons.check_circle_rounded, Color(0xFF2E7D32));

  final String etiqueta;
  final IconData icono;
  final Color color;

  const TipoAviso(this.etiqueta, this.icono, this.color);

  static TipoAviso desdeTexto(String? valor) => TipoAviso.values.firstWhere(
    (t) => t.name.toUpperCase() == valor?.toUpperCase(),
    orElse: () => TipoAviso.mantenimiento,
  );
}

class AvisoSuministro {
  final int id;
  final String titulo;
  final String detalle;
  final String coloniaAfectada;
  final TipoAviso tipo;
  final String horario;

  AvisoSuministro({
    required this.id,
    required this.titulo,
    required this.detalle,
    required this.coloniaAfectada,
    this.tipo = TipoAviso.mantenimiento,
    this.horario = 'Por confirmar',
  });

  factory AvisoSuministro.fromJson(Map<String, dynamic> json) {
    return AvisoSuministro(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      titulo: json['titulo']?.toString() ?? 'Sin título',
      detalle: json['detalle']?.toString() ?? 'Sin detalle',
      coloniaAfectada: json['coloniaAfectada']?.toString() ?? 'General',
      tipo: TipoAviso.desdeTexto(json['tipo']?.toString()),
      horario: json['horario']?.toString() ?? 'Por confirmar',
    );
  }

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'detalle': detalle,
    'coloniaAfectada': coloniaAfectada,
    'tipo': tipo.name.toUpperCase(),
    'horario': horario,
  };
}

/// Colonias disponibles para reportes y avisos.
const coloniasDisponibles = [
  'Centro',
  'Las Flores',
  'San Rafael',
  'Del Valle',
  'Jardines',
];
