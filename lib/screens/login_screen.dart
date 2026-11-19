import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/comunes.dart';
import '../widgets/ilustraciones.dart';
import 'admin/admin_shell.dart';
import 'ciudadano/ciudadano_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController(text: 'maria@correo.mx');
  final _contrasenaController = TextEditingController(text: '1234');
  final _apiService = ApiService();

  RolUsuario _rol = RolUsuario.ciudadano;
  bool _ocultarContrasena = true;
  bool _cargando = false;

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _cambiarRol(RolUsuario rol) {
    setState(() {
      _rol = rol;
      // Credenciales de demostración para cada rol.
      if (rol == RolUsuario.administrador) {
        _correoController.text = 'admin@cuidagua.mx';
        _contrasenaController.text = 'admin123';
      } else {
        _correoController.text = 'maria@correo.mx';
        _contrasenaController.text = '1234';
      }
    });
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate() || _cargando) return;
    setState(() => _cargando = true);

    final usuario = await _apiService.iniciarSesion(
      _correoController.text.trim(),
      _contrasenaController.text,
      _rol,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo o contraseña incorrectos')),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => usuario.esAdmin
            ? AdminShell(usuario: usuario)
            : CiudadanoShell(usuario: usuario),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final ancho = c.maxWidth >= 900;
          if (ancho) {
            return Row(
              children: [
                const Expanded(child: _PanelMarca()),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _formulario(context),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(
                  width: double.infinity,
                  height: 320,
                  child: _PanelMarca(compacto: true),
                ),
                Transform.translate(
                  offset: const Offset(0, -36),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 8,
                      shadowColor: const Color(0x330B2350),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _formulario(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _formulario(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final esAdmin = _rol == RolUsuario.administrador;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¡Hola de nuevo!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Elige cómo quieres entrar',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _OpcionRol(
                  icono: Icons.person_rounded,
                  titulo: 'Ciudadano',
                  detalle: 'Reporta y consulta',
                  seleccionado: !esAdmin,
                  onTap: () => _cambiarRol(RolUsuario.ciudadano),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OpcionRol(
                  icono: Icons.admin_panel_settings_rounded,
                  titulo: 'Administrador',
                  detalle: 'Gestiona incidencias',
                  seleccionado: esAdmin,
                  onTap: () => _cambiarRol(RolUsuario.administrador),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _correoController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Escribe un correo válido'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _contrasenaController,
            obscureText: _ocultarContrasena,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _entrar(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _ocultarContrasena ? 'Mostrar' : 'Ocultar',
                onPressed: () =>
                    setState(() => _ocultarContrasena = !_ocultarContrasena),
                icon: Icon(
                  _ocultarContrasena
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (v) =>
                (v == null || v.length < 4) ? 'Mínimo 4 caracteres' : null,
          ),
          const SizedBox(height: 22),
          FilledButton(
            style: FilledButton.styleFrom(shape: const StadiumBorder()),
            onPressed: _cargando ? null : _entrar,
            child: _cargando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          esAdmin ? 'Entrar al panel' : 'Entrar',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    esAdmin ? 'Demo: admin@cuidagua.mx / admin123' : 'Demo: cualquier correo y contraseña de 4+ caracteres',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionRol extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionRol({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: seleccionado
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: seleccionado ? scheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconoCirculo(
                      icono: icono,
                      color: seleccionado ? scheme.primary : scheme.outline,
                      tamano: 40,
                    ),
                    const Spacer(),
                    Icon(
                      seleccionado
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 18,
                      color: seleccionado ? scheme.primary : scheme.outline,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  detalle,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelMarca extends StatelessWidget {
  final bool compacto;

  const _PanelMarca({this.compacto = false});

  @override
  Widget build(BuildContext context) {
    final isDark = context.esOscuro;
    final tinta = isDark ? Colors.white : AppTheme.tinta;
    return Stack(
      children: [
        const Positioned.fill(child: CieloFondo()),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AspectRatio(
            aspectRatio: 2.1,
            child: PaisajeFondo(conCielo: false),
          ),
        ),
        Positioned(
          right: compacto ? 12 : 60,
          bottom: compacto ? 50 : 70,
          child: GotaMascota(alto: compacto ? 120 : 230),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(compacto ? 22 : 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: compacto
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                LogoCuidAgua(tamano: compacto ? 24 : 32, claro: isDark),
                SizedBox(height: compacto ? 18 : 40),
                Text(
                  'Cada gota\ncuenta.',
                  style: TextStyle(
                    color: tinta,
                    fontSize: compacto ? 30 : 56,
                    height: 1.02,
                    letterSpacing: -1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compacto ? 210 : 420),
                  child: Text(
                    'Reporta fugas, consulta cortes de suministro y da '
                    'seguimiento a los problemas de agua en tu colonia.',
                    style: TextStyle(
                      color: tinta.withValues(alpha: 0.8),
                      fontSize: compacto ? 13.5 : 17,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (!compacto) ...[
                  const SizedBox(height: 32),
                  const _Beneficio(
                    icono: Icons.bolt_rounded,
                    texto: 'Reporta un problema en menos de un minuto',
                  ),
                  const _Beneficio(
                    icono: Icons.notifications_active_rounded,
                    texto: 'Recibe avisos de cortes en tu zona',
                  ),
                  const _Beneficio(
                    icono: Icons.timeline_rounded,
                    texto: 'Sigue el avance de cada reporte',
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Beneficio extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Beneficio({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    final isDark = context.esOscuro;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 18, color: AppTheme.azul),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              texto,
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.tinta,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
