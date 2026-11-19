
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../models/models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService(useMockData: false);

  late Future<List<Reporte>> _futureReportes;
  late Future<List<AvisoSuministro>> _futureAvisos;

  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();

  bool _enviando = false;

  final Color primaryColor = const Color(0xFF0077B6);
  final Color accentColor = const Color(0xFF00B4D8);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // Cargar reportes y avisos.
  void _cargarDatos() {
    _futureReportes = _apiService.consultarReportes();
    _futureAvisos = _apiService.obtenerAvisosSuministro();
  }

  // ENVIAR REPORTE
  
  Future<void> _enviarReporte() async {
    final descripcion =
        _descripcionController.text.trim();

    final ubicacion =
        _ubicacionController.text.trim();

    if (descripcion.isEmpty || ubicacion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, llena todos los campos',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    if (_enviando) return;

    setState(() {
      _enviando = true;
    });

    try {
      final exito = await _apiService.enviarReporte(
        descripcion,
        ubicacion,
      );

      if (!mounted) return;

      if (exito) {
        _descripcionController.clear();
        _ubicacionController.clear();

        setState(() {
          _cargarDatos();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Reporte enviado con éxito',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error al enviar el reporte',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  // ACTUALIZAR DATOS

  Future<void> _refrescarDatos() async {
    setState(() {
      _cargarDatos();
    });

    try {
      await Future.wait([
        _futureReportes,
        _futureAvisos,
      ]);
    } catch (e) {
      debugPrint('Error al actualizar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text(
          'CuidAgua',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: _refrescarDatos,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // FORMULARIO DE REPORTES

              _buildSectionTitle(
                'Enviar Reporte Ciudadano',
                Icons.edit_document,
              ),

              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(16.0),

                  child: Column(
                    children: [

                      TextField(
                        controller: _descripcionController,
                        decoration: InputDecoration(
                          labelText: 'Descripción del problema',
                          prefixIcon: const Icon(
                            Icons.description,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: _ubicacionController,
                        decoration: InputDecoration(
                          labelText: 'Ubicación',
                          prefixIcon: const Icon(
                            Icons.location_on,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,

                        child: _enviando
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : ElevatedButton.icon(
                                onPressed: _enviarReporte,
                                icon: const Icon(Icons.send),
                                label: const Text(
                                  'Enviar Reporte',
                                  style: TextStyle(fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // AVISOS DE SUMINISTRO

              _buildSectionTitle(
                'Avisos de Suministro',
                Icons.campaign,
              ),

              FutureBuilder<List<AvisoSuministro>>(
                future: _futureAvisos,

                builder: (context, snapshot) {

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorWidget(
                      'Error al cargar avisos',
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return _buildEmptyWidget(
                      'No hay avisos hoy',
                    );
                  }

                  return Column(
                    children: snapshot.data!.map((aviso) {
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),

                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                            ),
                          ),

                          title: Text(
                            aviso.titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          subtitle: Text(
                            '${aviso.coloniaAfectada} - ${aviso.detalle}',
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 30),

              // REPORTES RECIENTES

              _buildSectionTitle(
                'Reportes Recientes',
                Icons.assignment,
              ),

              FutureBuilder<List<Reporte>>(
                future: _futureReportes,

                builder: (context, snapshot) {

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorWidget(
                      'Error al cargar reportes',
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return _buildEmptyWidget(
                      'No hay reportes registrados',
                    );
                  }

                  return Column(
                    children: snapshot.data!.map((reporte) {
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),

                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(
                              Icons.water_damage,
                              color: Colors.blue,
                            ),
                          ),

                          title: Text(
                            reporte.descripcion,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          subtitle: Text(
                            '${reporte.ubicacion} | ${reporte.fecha}',
                          ),

                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGETS AUXILIARES

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),

      child: Row(
        children: [
          Icon(
            icon,
            color: primaryColor,
            size: 22,
          ),

          const SizedBox(width: 8),

          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String mensaje) {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
      ),

      child: Row(
        children: [
          const Icon(
            Icons.error,
            color: Colors.red,
          ),

          const SizedBox(width: 10),

          Text(
            mensaje,
            style: const TextStyle(
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String mensaje) {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),

      child: Row(
        children: [
          const Icon(
            Icons.info,
            color: Colors.grey,
          ),

          const SizedBox(width: 10),

          Text(
            mensaje,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Liberar recursos.
  @override
  void dispose() {
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _apiService.dispose();

    super.dispose();
  }
}
