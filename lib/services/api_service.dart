import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';

class ApiService {
  // Configuración de la dirección del servidor.
  final String baseUrl;

  // Activar o desactivar datos simulados.
  final bool useMockData;

  // Cliente HTTP.
  final http.Client _client;

  ApiService({String? baseUrl, this.useMockData = true, http.Client? client})
    : baseUrl =
          baseUrl ??
          (kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api'),
      _client = client ?? http.Client();

  static const _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ==========================================
  // 0. INICIAR SESIÓN
  // ==========================================

  Future<Usuario?> iniciarSesion(
    String correo,
    String contrasena,
    RolUsuario rol,
  ) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (contrasena.length < 4) return null;
      if (rol == RolUsuario.administrador) {
        if (correo != _MockDb.adminCorreo || contrasena != 'admin123') {
          return null;
        }
        return const Usuario(
          id: 100,
          nombre: 'Laura Méndez',
          correo: _MockDb.adminCorreo,
          rol: RolUsuario.administrador,
        );
      }
      return Usuario(
        id: 1,
        nombre: 'María González',
        correo: correo,
        colonia: 'Centro',
        rol: RolUsuario.ciudadano,
      );
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'correo': correo,
              'contrasena': contrasena,
              'rol': rol == RolUsuario.administrador
                  ? 'ADMINISTRADOR'
                  : 'CIUDADANO',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Usuario.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body) as Map),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error al iniciar sesión: $e');
      return null;
    }
  }

  // ==========================================
  // 1. ENVIAR REPORTE CIUDADANO
  // ==========================================

  Future<bool> enviarReporte(
    String descripcion,
    String ubicacion, {
    TipoProblema tipo = TipoProblema.otro,
    String colonia = 'Sin colonia',
    String ciudadano = 'Anónimo',
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      _MockDb.agregarReporte(
        descripcion: descripcion,
        ubicacion: ubicacion,
        tipo: tipo,
        colonia: colonia,
        ciudadano: ciudadano,
      );
      return true;
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/reportes'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'descripcion': descripcion,
              'ubicacion': ubicacion,
              'tipo': tipo.name.toUpperCase(),
              'colonia': colonia,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if ([200, 201, 202, 204].contains(response.statusCode)) {
        return true;
      }

      debugPrint('Error al enviar reporte: HTTP ${response.statusCode}');
      return false;
    } on TimeoutException {
      debugPrint('Tiempo de espera agotado al enviar reporte');
      return false;
    } on http.ClientException catch (e) {
      debugPrint('Error de conexión: $e');
      return false;
    } catch (e) {
      debugPrint('Error inesperado al enviar reporte: $e');
      return false;
    }
  }

  // ==========================================
  // 2. CONSULTAR REPORTES
  // ==========================================

  Future<List<Reporte>> consultarReportes() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 900));
      return List.of(_MockDb.reportes);
    }

    return _getLista('reportes', Reporte.fromJson, 'los reportes');
  }

  // ==========================================
  // 3. ACTUALIZAR REPORTE (ADMINISTRADOR)
  // ==========================================

  Future<bool> actualizarReporte(
    int id, {
    EstadoReporte? estado,
    Prioridad? prioridad,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _MockDb.actualizarReporte(
        id,
        estado: estado,
        prioridad: prioridad,
      );
    }

    try {
      final response = await _client
          .patch(
            Uri.parse('$baseUrl/reportes/$id'),
            headers: _jsonHeaders,
            body: jsonEncode({
              if (estado != null) 'estado': estado.valorApi,
              if (prioridad != null) 'prioridad': prioridad.name.toUpperCase(),
            }),
          )
          .timeout(const Duration(seconds: 10));
      return [200, 204].contains(response.statusCode);
    } catch (e) {
      debugPrint('Error al actualizar reporte: $e');
      return false;
    }
  }

  // ==========================================
  // 4. AVISOS DE SUMINISTRO
  // ==========================================

  Future<List<AvisoSuministro>> obtenerAvisosSuministro() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 700));
      return List.of(_MockDb.avisos);
    }

    return _getLista('avisos', AvisoSuministro.fromJson, 'los avisos');
  }

  Future<bool> crearAviso(AvisoSuministro aviso) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      _MockDb.agregarAviso(aviso);
      return true;
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/avisos'),
            headers: _jsonHeaders,
            body: jsonEncode(aviso.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      return [200, 201].contains(response.statusCode);
    } catch (e) {
      debugPrint('Error al crear aviso: $e');
      return false;
    }
  }

  Future<bool> eliminarAviso(int id) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      _MockDb.avisos.removeWhere((a) => a.id == id);
      return true;
    }

    try {
      final response = await _client
          .delete(Uri.parse('$baseUrl/avisos/$id'))
          .timeout(const Duration(seconds: 10));
      return [200, 204].contains(response.statusCode);
    } catch (e) {
      debugPrint('Error al eliminar aviso: $e');
      return false;
    }
  }

  // ==========================================
  // AUXILIARES
  // ==========================================

  Future<List<T>> _getLista<T>(
    String recurso,
    T Function(Map<String, dynamic>) fromJson,
    String nombre,
  ) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/$recurso'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body
            .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      throw Exception('Error del servidor: HTTP ${response.statusCode}');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado al consultar $nombre');
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Cerrar el cliente HTTP cuando ya no se necesite.
  void dispose() {
    _client.close();
  }
}

/// Datos simulados en memoria, compartidos por todas las instancias del
/// servicio para que los cambios del administrador se vean del lado ciudadano.
class _MockDb {
  static const adminCorreo = 'admin@cuidagua.mx';

  static int _siguienteReporte = 9;
  static int _siguienteAviso = 4;

  static final List<Reporte> reportes = [
    Reporte(
      id: 8,
      descripcion: 'Fuga constante frente a la escuela primaria',
      ubicacion: 'Calle 5 de Mayo #120',
      fecha: '2026-11-17',
      tipo: TipoProblema.fuga,
      estado: EstadoReporte.pendiente,
      prioridad: Prioridad.alta,
      colonia: 'Centro',
      ciudadano: 'María González',
    ),
    Reporte(
      id: 7,
      descripcion: 'Llevamos dos días sin agua en toda la cuadra',
      ubicacion: 'Av. Juárez #45',
      fecha: '2026-11-16',
      tipo: TipoProblema.sinSuministro,
      estado: EstadoReporte.enRevision,
      prioridad: Prioridad.alta,
      colonia: 'Las Flores',
      ciudadano: 'José Ramírez',
    ),
    Reporte(
      id: 6,
      descripcion: 'El agua sale color café por las mañanas',
      ubicacion: 'Privada Olivos #8',
      fecha: '2026-11-15',
      tipo: TipoProblema.aguaTurbia,
      estado: EstadoReporte.enProceso,
      prioridad: Prioridad.media,
      colonia: 'Centro',
      ciudadano: 'María González',
    ),
    Reporte(
      id: 5,
      descripcion: 'Presión muy baja en el segundo piso',
      ubicacion: 'Calle Pino #33',
      fecha: '2026-11-14',
      tipo: TipoProblema.bajaPresion,
      estado: EstadoReporte.enProceso,
      prioridad: Prioridad.baja,
      colonia: 'San Rafael',
      ciudadano: 'Ana López',
    ),
    Reporte(
      id: 4,
      descripcion: 'Coladera tapada, se desborda al llover',
      ubicacion: 'Esq. Hidalgo y Morelos',
      fecha: '2026-11-12',
      tipo: TipoProblema.drenaje,
      estado: EstadoReporte.resuelto,
      prioridad: Prioridad.media,
      colonia: 'Las Flores',
      ciudadano: 'Carlos Pérez',
    ),
    Reporte(
      id: 3,
      descripcion: 'Tubería rota en banqueta',
      ubicacion: 'Calle Roble #210',
      fecha: '2026-11-10',
      tipo: TipoProblema.fuga,
      estado: EstadoReporte.resuelto,
      prioridad: Prioridad.alta,
      colonia: 'San Rafael',
      ciudadano: 'María González',
    ),
    Reporte(
      id: 2,
      descripcion: 'Toma clandestina en terreno baldío',
      ubicacion: 'Av. Juárez s/n',
      fecha: '2026-11-06',
      tipo: TipoProblema.otro,
      estado: EstadoReporte.pendiente,
      prioridad: Prioridad.media,
      colonia: 'Centro',
      ciudadano: 'Anónimo',
    ),
    Reporte(
      id: 1,
      descripcion: 'Fuga en la esquina del mercado',
      ubicacion: 'Calle 5 #12',
      fecha: '2026-11-05',
      tipo: TipoProblema.fuga,
      estado: EstadoReporte.resuelto,
      prioridad: Prioridad.media,
      colonia: 'Centro',
      ciudadano: 'Luis Torres',
    ),
  ];

  static final List<AvisoSuministro> avisos = [
    AvisoSuministro(
      id: 3,
      titulo: 'Corte programado',
      detalle: 'Sustitución de válvula en la red principal.',
      coloniaAfectada: 'Centro',
      tipo: TipoAviso.corte,
      horario: 'Jue 20 nov · 08:00 – 14:00',
    ),
    AvisoSuministro(
      id: 2,
      titulo: 'Baja presión',
      detalle: 'Reparación de tubería en Av. Juárez.',
      coloniaAfectada: 'Las Flores',
      tipo: TipoAviso.bajaPresion,
      horario: 'Hoy · hasta las 18:00',
    ),
    AvisoSuministro(
      id: 1,
      titulo: 'Servicio restablecido',
      detalle: 'Se concluyó el mantenimiento del tanque elevado.',
      coloniaAfectada: 'San Rafael',
      tipo: TipoAviso.restablecido,
      horario: 'Desde ayer 19:30',
    ),
  ];

  static void agregarReporte({
    required String descripcion,
    required String ubicacion,
    required TipoProblema tipo,
    required String colonia,
    required String ciudadano,
  }) {
    final hoy = DateTime.now();
    final fecha =
        '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-'
        '${hoy.day.toString().padLeft(2, '0')}';
    reportes.insert(
      0,
      Reporte(
        id: _siguienteReporte++,
        descripcion: descripcion,
        ubicacion: ubicacion,
        fecha: fecha,
        tipo: tipo,
        colonia: colonia,
        ciudadano: ciudadano,
      ),
    );
  }

  static bool actualizarReporte(
    int id, {
    EstadoReporte? estado,
    Prioridad? prioridad,
  }) {
    final i = reportes.indexWhere((r) => r.id == id);
    if (i == -1) return false;
    reportes[i] = reportes[i].copyWith(estado: estado, prioridad: prioridad);
    return true;
  }

  static void agregarAviso(AvisoSuministro aviso) {
    avisos.insert(
      0,
      AvisoSuministro(
        id: _siguienteAviso++,
        titulo: aviso.titulo,
        detalle: aviso.detalle,
        coloniaAfectada: aviso.coloniaAfectada,
        tipo: aviso.tipo,
        horario: aviso.horario,
      ),
    );
  }
}
