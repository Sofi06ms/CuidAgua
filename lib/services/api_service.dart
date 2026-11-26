import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';

class ApiService {
  final String baseUrl;
  final String keycloakUrl;
  final bool useMockData;
  final http.Client _client;

  ApiService({
    String? baseUrl,
    String? keycloakUrl,
    this.useMockData = false,
    http.Client? client,
  })  : baseUrl = baseUrl ??
            (kIsWeb
                ? 'http://localhost:8080/api'
                : 'http://10.0.2.2:8080/api'),
        keycloakUrl = keycloakUrl ??
            (kIsWeb
                ? 'http://localhost:8180'
                : 'http://10.0.2.2:8180'),
        _client = client ?? http.Client();

  // Pide un token a Keycloak con el usuario de prueba (credenciales escolares)
  Future<String> _obtenerToken() async {
    final response = await _client.post(
      Uri.parse('$keycloakUrl/realms/cuidagua/protocol/openid-connect/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': 'cuidagua-app',
        'username': 'ciudadano1',
        'password': 'ciudadano123',
        'grant_type': 'password',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Keycloak ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['access_token'] as String;
  }

  // 1. ENVIAR REPORTE (POST con token Bearer). Lanza excepción con el detalle si falla.
  Future<bool> enviarReporte(
    String descripcion,
    String categoria,
    int zonaId, {
    double? latitud,
    double? longitud,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }

    try {
      final token = await _obtenerToken();

      final Map<String, dynamic> cuerpo = {
        'descripcion': descripcion,
        'categoria': categoria,
        'zonaId': zonaId,
      };
      if (latitud != null && longitud != null) {
        cuerpo['latitud'] = latitud;
        cuerpo['longitud'] = longitud;
      }

      final response = await _client
          .post(
            Uri.parse('$baseUrl/reportes'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(cuerpo),
          )
          .timeout(const Duration(seconds: 10));

      if ([200, 201, 202, 204].contains(response.statusCode)) {
        return true;
      }
      throw Exception('POST ${response.statusCode}: ${response.body}');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado');
    }
  }

  // 2. CONSULTAR REPORTES (GET)
  Future<List<Reporte>> consultarReportes() async {
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 2));
      return [
        Reporte(id: 1, descripcion: 'Fuga en la esquina (Mock)', categoria: 'fuga', estado: 'pendiente'),
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
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> listaDatos = body['datos'] ?? [];
        return listaDatos
            .map((item) => Reporte.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      throw Exception('Error del servidor: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // 3. OBTENER AVISOS DE SUMINISTRO (GET)
  Future<List<AvisoSuministro>> obtenerAvisosSuministro() async {
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return [
        AvisoSuministro(id: 1, titulo: 'Corte programado (Mock)', mensaje: 'Mantenimiento', zonaId: 1),
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
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> listaDatos = body['datos'] ?? [];
        return listaDatos
            .map((item) => AvisoSuministro.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      throw Exception('Error al cargar avisos: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // 4. OBTENER ZONAS (GET). Si la ruta no responde, usa las zonas por defecto.
  Future<List<Zona>> obtenerZonas() async {
    final porDefecto = [
      Zona(id: 1, nombre: 'Zona Norte'),
      Zona(id: 2, nombre: 'Zona Centro'),
      Zona(id: 3, nombre: 'Zona Sur'),
    ];
    if (useMockData) return porDefecto;

    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/zonas'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final lista = decoded is Map ? (decoded['datos'] ?? []) : decoded;
        final zonas = (lista as List)
            .map((e) => Zona.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (zonas.isNotEmpty) return zonas;
      }
    } catch (_) {
      // Si falla, se usan las zonas por defecto
    }
    return porDefecto;
  }

  void dispose() {
    _client.close();
  }
}