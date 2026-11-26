import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Reporte>> _futureReportes;
  late Future<List<AvisoSuministro>> _futureAvisos;

  final _descripcionController = TextEditingController();
  bool _enviando = false;

  String _categoria = 'fuga';
  int? _zonaId;
  List<Zona> _zonas = [];

  final Color primaryColor = const Color(0xFF0077B6);

  // Categorías permitidas por la API
  static const Map<String, String> _categorias = {
    'fuga': 'Fuga',
    'tuberia_danada': 'Tubería dañada',
    'falta_suministro': 'Falta de suministro',
    'baja_presion': 'Baja presión',
    'otro': 'Otro',
  };

  static const Map<String, IconData> _iconosCategoria = {
    'fuga': Icons.water_drop,
    'tuberia_danada': Icons.plumbing,
    'falta_suministro': Icons.do_not_disturb_on,
    'baja_presion': Icons.speed,
    'otro': Icons.report,
  };

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _cargarZonas();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _cargarDatos() {
    setState(() {
      _futureReportes = _apiService.consultarReportes();
      _futureAvisos = _apiService.obtenerAvisosSuministro();
    });
  }

  Future<void> _cargarZonas() async {
    final zonas = await _apiService.obtenerZonas();
    if (!mounted) return;
    setState(() {
      _zonas = zonas;
      _zonaId = zonas.isNotEmpty ? zonas.first.id : null;
    });
  }

  void _mostrarMensaje(String texto, Color color, {int segundos = 4}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: color, duration: Duration(seconds: segundos)),
    );
  }

  void _enviarReporte() async {
    if (_descripcionController.text.trim().isEmpty) {
      _mostrarMensaje('⚠️ Escribe la descripción', Colors.orange);
      return;
    }
    if (_zonaId == null) {
      _mostrarMensaje('⚠️ Elige una zona', Colors.orange);
      return;
    }

    setState(() { _enviando = true; });
    try {
      await _apiService.enviarReporte(
        _descripcionController.text.trim(),
        _categoria,
        _zonaId!,
      );
      if (!mounted) return;
      _mostrarMensaje('✅ Reporte enviado con éxito', Colors.green);
      _descripcionController.clear();
      _cargarDatos();
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('❌ $e', Colors.red, segundos: 8);
    } finally {
      if (mounted) setState(() { _enviando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('CuidAgua', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _cargarDatos();
          await _futureReportes;
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Enviar Reporte Ciudadano', Icons.edit_document),
                  _buildFormulario(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Avisos de Suministro', Icons.campaign),
                  _buildAvisos(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Reportes Recientes', Icons.assignment),
                  _buildReportes(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _descripcionController,
              decoration: InputDecoration(
                labelText: 'Descripción del problema',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: InputDecoration(
                labelText: 'Categoría',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _categorias.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<int>(
              value: _zonaId,
              decoration: InputDecoration(
                labelText: 'Zona',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _zonas
                  .map((z) => DropdownMenuItem(value: z.id, child: Text(z.nombre)))
                  .toList(),
              onChanged: (v) => setState(() => _zonaId = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _enviando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _enviarReporte,
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar Reporte', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvisos() {
    return FutureBuilder<List<AvisoSuministro>>(
      future: _futureAvisos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) return _buildErrorWidget('Error al cargar avisos');
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyWidget('No hay avisos hoy');

        return Column(
          children: snapshot.data!.map((aviso) {
            final tieneHorario = aviso.horario != null && aviso.horario!.isNotEmpty;
            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                ),
                title: Text(aviso.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(tieneHorario ? '${aviso.mensaje}\n🕒 ${aviso.horario}' : aviso.mensaje),
                isThreeLine: tieneHorario,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildReportes() {
    return FutureBuilder<List<Reporte>>(
      future: _futureReportes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) return _buildErrorWidget('Error al cargar reportes');
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyWidget('No hay reportes registrados');

        return Column(children: snapshot.data!.map(_buildReporteCard).toList());
      },
    );
  }

  Widget _buildReporteCard(Reporte r) {
    final categoriaTxt = _categorias[r.categoria] ?? (r.categoria ?? 'Sin categoría');
    final linea = [r.folio, categoriaTxt, r.zonaNombre]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' · ');

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(_iconosCategoria[r.categoria] ?? Icons.report, color: Colors.blue),
        ),
        title: Text(r.descripcion, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(linea),
        ),
        trailing: _buildEstadoChip(r.estado ?? 'pendiente'),
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    final colores = {
      'pendiente': Colors.orange,
      'en_revision': Colors.blue,
      'resuelto': Colors.green,
      'rechazado': Colors.red,
    };
    final color = colores[estado] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.replaceAll('_', ' '),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 22),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String mensaje) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(mensaje, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String mensaje) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.grey),
          const SizedBox(width: 10),
          Text(mensaje, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}