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

  ApiService({
    String? baseUrl,
    this.useMockData = true,
    http.Client? client,
  })  : baseUrl = baseUrl ??
            (kIsWeb
                ? 'http://localhost:3000/api'
                : 'http://10.0.2.2:3000/api'),
        _client = client ?? http.Client();

  // 1. ENVIAR REPORTE CIUDADANO

  Future<bool> enviarReporte(
    String descripcion,
    String ubicacion,
  ) async {
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/reportes'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'descripcion': descripcion,
              'ubicacion': ubicacion,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if ([200, 201, 202, 204].contains(response.statusCode)) {
        return true;
      }

      debugPrint(
        'Error al enviar reporte: HTTP ${response.statusCode}',
      );

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
      await Future.delayed(const Duration(seconds: 2));

      return [
        Reporte(
          id: 1,
          descripcion: 'Fuga en la esquina',
          ubicacion: 'Calle 5',
          fecha: '2026-11-07',
        ),
        Reporte(
          id: 2,
          descripcion: 'Toma clandestina',
          ubicacion: 'Av. Juárez',
          fecha: '2026-11-06',
        ),
      ];
    }

    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/reportes'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);

        return body.map((item) {
          return Reporte.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
        }).toList();
      }

      throw Exception(
        'Error del servidor: HTTP ${response.statusCode}',
      );
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado al consultar reportes');
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión: $e');
    } catch (e) {
      throw Exception('No se pudieron consultar los reportes: $e');
    }
  }

  // ==========================================
  // 3. OBTENER AVISOS DE SUMINISTRO
  // ==========================================

  Future<List<AvisoSuministro>> obtenerAvisosSuministro() async {
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 1));

      return [
        AvisoSuministro(
          id: 1,
          titulo: 'Corte programado',
          detalle: 'Mantenimiento de tuberías',
          coloniaAfectada: 'Centro',
        ),
        AvisoSuministro(
          id: 2,
          titulo: 'Baja presión',
          detalle: 'Reparación de tubería',
          coloniaAfectada: 'Las Flores',
        ),
      ];
    }

    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/avisos'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);

        return body.map((item) {
          return AvisoSuministro.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
        }).toList();
      }

      throw Exception(
        'Error al cargar avisos: HTTP ${response.statusCode}',
      );
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado al consultar avisos');
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión: $e');
    } catch (e) {
      throw Exception('No se pudieron consultar los avisos: $e');
    }
  }

  // Cerrar el cliente HTTP cuando ya no se necesite.
  void dispose() {
    _client.close();
  }
}