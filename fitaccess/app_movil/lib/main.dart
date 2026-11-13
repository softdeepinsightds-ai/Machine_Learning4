import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';
import 'app_theme.dart';
import 'auto_recognition_screen.dart';
import 'camera_screen.dart';
import 'premium_widgets.dart';
import 'sound_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitAccessApp());
}

class FitAccessApp extends StatelessWidget {
  const FitAccessApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FitAccess',
    debugShowCheckedModeBanner: false,
    theme: buildGymTheme(),
    home: const ConnectionPage(),
  );
}

Future<XFile?> tomarFoto(BuildContext context, String titulo) async {
  GymSounds.tap();
  return Navigator.of(context).push<XFile>(
    MaterialPageRoute(builder: (_) => CameraScreen(titulo: titulo)),
  );
}

String _fechaAmigable(Object? fecha) {
  final valor = DateTime.tryParse('$fecha')?.toLocal();
  if (valor == null) return fecha?.toString() ?? '—';
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(valor.day)}/${dos(valor.month)}/${valor.year}  ${dos(valor.hour)}:${dos(valor.minute)}';
}

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});
  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final url = TextEditingController(text: 'http://10.0.2.2:8000');
  final clave = TextEditingController();
  bool conectando = false;
  bool mostrarClave = false;
  String? error;

  @override
  void dispose() {
    url.dispose();
    clave.dispose();
    super.dispose();
  }

  Future<void> conectar() async {
    FocusScope.of(context).unfocus();
    if (url.text.trim().isEmpty || clave.text.trim().isEmpty) {
      setState(() => error = 'Indica la URL de FastAPI y la clave de operador.');
      GymSounds.notice();
      return;
    }
    GymSounds.tap();
    setState(() { conectando = true; error = null; });
    final api = ApiService(baseUrl: url.text.trim(), apiKey: clave.text.trim());
    try {
      await api.usuarios();
      if (!mounted) return;
      GymSounds.success();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(api: api)),
      );
    } catch (e) {
      if (mounted) {
        GymSounds.notice();
        setState(() => error = '$e');
      }
    } finally {
      if (mounted) setState(() => conectando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
            children: [
              const GymEnter(child: Center(child: GymLogo(size: 190, withName: true))),
              const SizedBox(height: 6),
              const GymEnter(delay: Duration(milliseconds: 100), child: Column(children: [
                Text('FITACCESS', style: TextStyle(color: GymColors.gold, fontSize: 12, letterSpacing: 3.3, fontWeight: FontWeight.w900)),
                SizedBox(height: 10),
                Text('Acceso inteligente', textAlign: TextAlign.center, style: TextStyle(color: GymColors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                SizedBox(height: 5),
                Text('Conecta tu dispositivo al sistema del gimnasio.', textAlign: TextAlign.center, style: TextStyle(color: GymColors.muted)),
              ])),
              const SizedBox(height: 30),
              GymEnter(delay: const Duration(milliseconds: 160), child: GymCard(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.router_outlined, color: GymColors.gold, size: 20), SizedBox(width: 9), Text('CONEXIÓN A RED LOCAL', style: TextStyle(fontSize: 11, color: GymColors.gold, fontWeight: FontWeight.w900, letterSpacing: .8))]),
                  const SizedBox(height: 20),
                  TextField(
                    controller: url,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Dirección de FastAPI', prefixIcon: Icon(Icons.link), hintText: 'http://192.168.100.3:8000'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: clave,
                    obscureText: !mostrarClave,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Clave de operador', prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: mostrarClave ? 'Ocultar clave' : 'Mostrar clave',
                        onPressed: () => setState(() => mostrarClave = !mostrarClave),
                        icon: Icon(mostrarClave ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 14),
                    Text(error!, style: const TextStyle(color: GymColors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: conectando ? null : conectar,
                    icon: conectando
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: GymColors.background))
                        : const Icon(Icons.arrow_forward_rounded),
                    label: Text(conectando ? 'Conectando...' : 'Ingresar al sistema'),
                  ),
                ],
              ))),
              const SizedBox(height: 24),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shield_outlined, color: GymColors.muted, size: 16), SizedBox(width: 8), Flexible(child: Text('Uso en red privada de pruebas. No publiques FastAPI en Internet.', textAlign: TextAlign.center, style: TextStyle(color: GymColors.muted, fontSize: 11)))]),
            ],
          ),
        ),
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  final ApiService api;
  const HomePage({super.key, required this.api});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pestana = 1;

  void _seleccionar(int i) {
    if (pestana == i) return;
    GymSounds.tap();
    setState(() => pestana = i);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      titleSpacing: 18,
      title: const Row(children: [
        GymLogo(size: 44),
        SizedBox(width: 8),
        Expanded(child: Text('FitAccess', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 17))),
      ]),
      actions: const [Padding(padding: EdgeInsets.only(right: 18), child: Icon(Icons.verified_user_outlined, color: GymColors.gold, size: 20))],
    ),
    // IndexedStack solo pinta la pestaña visible y conserva el estado de las otras.
    // Corrige el solapamiento causado por Stack + AnimatedOpacity en Premium v3.
    body: SizedBox.expand(
      child: IndexedStack(
        index: pestana,
        children: [
          RegistrationTab(api: widget.api),
          RecognitionTab(api: widget.api),
          HistoryTab(api: widget.api),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(color: GymColors.surface, border: Border(top: BorderSide(color: Color(0xFF39312A)))),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Row(children: [
          _navItem(0, Icons.person_add_alt_1_rounded, 'Registrar'),
          _navItem(1, Icons.face_retouching_natural_rounded, 'Reconocer'),
          _navItem(2, Icons.history_rounded, 'Asistencias'),
        ]),
      ),
    ),
  );

  Widget _navItem(int index, IconData icon, String label) {
    final selected = index == pestana;
    return Expanded(child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _seleccionar(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? GymColors.gold.withValues(alpha: .13) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? GymColors.gold.withValues(alpha: .3) : Colors.transparent),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: selected ? GymColors.gold : GymColors.muted, size: 24),
          const SizedBox(height: 5),
          Text(label, maxLines: 1, style: TextStyle(color: selected ? GymColors.gold : GymColors.muted, fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
        ]),
      ),
    ));
  }
}

class RegistrationTab extends StatefulWidget {
  final ApiService api;
  const RegistrationTab({super.key, required this.api});
  @override
  State<RegistrationTab> createState() => _RegistrationTabState();
}

class _RegistrationTabState extends State<RegistrationTab> {
  final nombre = TextEditingController();
  final codigo = TextEditingController();
  final cedula = TextEditingController();
  final List<XFile> fotos = [];
  int? idPendiente;
  String? codigoPendiente;
  bool trabajando = false;
  String mensaje = '';
  bool exito = false;

  @override
  void dispose() {
    nombre.dispose();
    codigo.dispose();
    cedula.dispose();
    super.dispose();
  }

  Future<void> nuevaFoto() async {
    if (fotos.length >= 10 || trabajando) return;
    final foto = await tomarFoto(context, 'Matrícula · Foto ${fotos.length + 1}');
    if (foto != null && mounted) {
      GymSounds.tap();
      setState(() => fotos.add(foto));
    }
  }

  Future<void> guardar() async {
    FocusScope.of(context).unfocus();
    if (nombre.text.trim().length < 2 || codigo.text.trim().isEmpty ||
        !RegExp(r'^\d{10}$').hasMatch(cedula.text.trim()) || fotos.length < 3) {
      GymSounds.notice();
      setState(() {
        exito = false;
        mensaje = 'Revisa nombre, código, cédula de 10 dígitos y al menos 3 fotos.';
      });
      return;
    }
    if (idPendiente != null && codigo.text.trim().toLowerCase() != codigoPendiente) {
      GymSounds.notice();
      setState(() => mensaje = 'Termina la matrícula pendiente del código $codigoPendiente.');
      return;
    }
    setState(() { trabajando = true; mensaje = ''; exito = false; });
    try {
      if (idPendiente == null) {
        final nuevo = await widget.api.crearUsuario(
          nombre.text.trim(), codigo.text.trim(), cedula.text.trim());
        idPendiente = nuevo['id'] as int;
        codigoPendiente = codigo.text.trim().toLowerCase();
      }
      final resultado = await widget.api.matricular(idPendiente!, List<XFile>.from(fotos));
      if (!mounted) return;
      GymSounds.success();
      setState(() {
        exito = true;
        mensaje = 'Matrícula completada: ${resultado['nombre']} · ${resultado['nuevos_embeddings']} embeddings generados.';
        fotos.clear();
        nombre.clear();
        codigo.clear();
        cedula.clear();
        idPendiente = null;
        codigoPendiente = null;
      });
    } catch (e) {
      if (!mounted) return;
      GymSounds.notice();
      setState(() {
        exito = false;
        mensaje = 'No se completó: $e';
      });
    } finally {
      if (mounted) setState(() => trabajando = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
    children: [
      const GymSectionTitle(
        overline: 'Registro de socios', title: 'Registrar socio',
        subtitle: 'El personal del gimnasio registra a cada nuevo socio.'),
      const SizedBox(height: 22),
      GymCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.badge_outlined, color: GymColors.gold, size: 20), SizedBox(width: 9), Text('01 · IDENTIDAD DEL SOCIO', style: TextStyle(fontWeight: FontWeight.w900, color: GymColors.gold, letterSpacing: .7, fontSize: 12))]),
        const SizedBox(height: 20),
        TextField(controller: nombre, enabled: !trabajando && idPendiente == null,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 12),
        TextField(controller: codigo, enabled: !trabajando && idPendiente == null,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'Código único de socio', hintText: 'ej. socio_008', prefixIcon: Icon(Icons.tag))),
        const SizedBox(height: 12),
        TextField(controller: cedula, enabled: !trabajando && idPendiente == null,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          decoration: const InputDecoration(labelText: 'Cédula (10 dígitos)', hintText: 'Verificar documento original', prefixIcon: Icon(Icons.credit_card_outlined))),
        const SizedBox(height: 12),
        const Text('Comprueba la cédula del socio antes de completar el registro.', style: TextStyle(color: GymColors.muted, fontSize: 12)),
        if (idPendiente != null) ...[
          const SizedBox(height: 12),
          const GymStatus(text: 'REGISTRO PENDIENTE: REPETIR FOTOS', color: GymColors.orange, icon: Icons.info_outline),
        ],
      ])),
      const SizedBox(height: 18),
      GymCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.photo_camera_outlined, color: GymColors.gold, size: 20), SizedBox(width: 9), Text('02 · BIOMETRÍA FACIAL', style: TextStyle(fontWeight: FontWeight.w900, color: GymColors.gold, letterSpacing: .7, fontSize: 12))]),
        const SizedBox(height: 12),
        const Text('Toma entre 3 y 10 fotos presenciales. Varía ligeramente el ángulo, la expresión y la iluminación.', style: TextStyle(color: GymColors.muted, fontSize: 13)),
        const SizedBox(height: 17),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: trabajando || fotos.length >= 10 ? null : nuevaFoto,
            icon: const Icon(Icons.add_a_photo_outlined, size: 20),
            label: const Text('Tomar foto'),
          )),
          if (fotos.isNotEmpty) ...[
            const SizedBox(width: 9),
            IconButton(
              tooltip: 'Eliminar última foto',
              onPressed: trabajando ? null : () { GymSounds.tap(); setState(() => fotos.removeLast()); },
              icon: const Icon(Icons.undo_rounded, color: GymColors.orange),
            ),
          ],
        ]),
        const SizedBox(height: 14),
        Row(children: [
          const Icon(Icons.photo_library_outlined, size: 17, color: GymColors.gold),
          const SizedBox(width: 8),
          Text('${fotos.length} / 10 fotografías', style: const TextStyle(color: GymColors.white, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(12), child: LinearProgressIndicator(
          value: fotos.length / 10,
          minHeight: 7,
          backgroundColor: GymColors.surfaceHigh,
          valueColor: const AlwaysStoppedAnimation<Color>(GymColors.gold),
        )),
        if (fotos.isNotEmpty) ...[
          const SizedBox(height: 13),
          SizedBox(height: 66, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: fotos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(fotos[i].path), width: 66, height: 66, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported))),
          )),
        ],
      ])),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: trabajando ? null : guardar,
        icon: trabajando ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: GymColors.background)) : const Icon(Icons.how_to_reg_outlined),
        label: Text(trabajando ? 'Generando embeddings...' : 'Crear socio y matricular'),
      ),
      if (mensaje.isNotEmpty) ...[
        const SizedBox(height: 15),
        GymCard(color: exito ? const Color(0xFF153124) : const Color(0xFF382125), child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(exito ? Icons.check_circle_outline : Icons.error_outline, color: exito ? GymColors.green : GymColors.red),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje, style: TextStyle(color: exito ? GymColors.green : GymColors.red))),
          ],
        )),
      ],
      const SizedBox(height: 20),
      const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.privacy_tip_outlined, color: GymColors.muted, size: 17), SizedBox(width: 8),
        Expanded(child: Text('Solicita consentimiento informado antes de procesar datos biométricos y aplica las políticas de privacidad correspondientes.', style: TextStyle(fontSize: 11, color: GymColors.muted))),
      ]),
    ],
  );
}

class RecognitionTab extends StatefulWidget {
  final ApiService api;
  const RecognitionTab({super.key, required this.api});
  @override
  State<RecognitionTab> createState() => _RecognitionTabState();
}

class _RecognitionTabState extends State<RecognitionTab> {
  bool trabajando = false;
  Map<String, dynamic>? resultado;
  String? error;

  Future<void> reconocer() async {
    GymSounds.tap();
    final foto = await Navigator.of(context).push<XFile>(
      MaterialPageRoute(builder: (_) => const AutoRecognitionScreen()),
    );
    if (foto == null || !mounted) return;
    setState(() { trabajando = true; resultado = null; error = null; });
    try {
      final res = await widget.api.verificar(foto);
      if (mounted) {
        if (res['estado'] == 'ACCEPTED') {
          GymSounds.success();
        } else {
          GymSounds.notice();
        }
        setState(() => resultado = res);
      }
    } catch (e) {
      if (mounted) {
        GymSounds.notice();
        setState(() => error = '$e');
      }
    } finally {
      if (mounted) setState(() => trabajando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = resultado;
    final estado = r?['estado'];
    final ok = estado == 'ACCEPTED';
    final duplicada = estado == 'DUPLICATE';
    final color = ok ? GymColors.green : duplicada ? GymColors.orange : GymColors.red;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 32),
      children: [
        const GymSectionTitle(
          overline: 'Control inteligente', title: 'Acceso facial',
          subtitle: 'La cámara detecta tu rostro y registra tu acceso de forma automática.'),
        const SizedBox(height: 26),
        GymCard(child: Column(children: [
          const GymLogo(size: 150),
          const SizedBox(height: 7),
          const Text('IDENTIFICACIÓN BIOMÉTRICA', style: TextStyle(color: GymColors.gold, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.6)),
          const SizedBox(height: 12),
          const Text('Colócate frente a la cámara y sigue las indicaciones. La foto se tomará automáticamente.', textAlign: TextAlign.center, style: TextStyle(color: GymColors.muted, fontSize: 13, height: 1.55)),
          const SizedBox(height: 19),
          FilledButton.icon(
            onPressed: trabajando ? null : reconocer,
            icon: trabajando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: GymColors.background)) : const Icon(Icons.center_focus_strong),
            label: Text(trabajando ? 'Verificando identidad...' : 'Abrir cámara y reconocer'),
          ),
        ])),
        if (error != null) ...[
          const SizedBox(height: 14),
          GymCard(color: const Color(0xFF382125), child: Text(error!, style: const TextStyle(color: GymColors.red))),
        ],
        if (r != null) ...[
          const SizedBox(height: 22),
          GymEnter(child: GymCard(child: Column(children: [
            Icon(ok ? Icons.verified_rounded : duplicada ? Icons.access_time_filled_rounded : Icons.gpp_bad_rounded, size: 60, color: color),
            const SizedBox(height: 10),
            GymStatus(
              text: '$estado', color: color,
              icon: ok ? Icons.check_circle_outline : duplicada ? Icons.info_outline : Icons.cancel_outlined,
            ),
            const SizedBox(height: 14),
            Text((r['usuario'] as Map?)?['nombre']?.toString() ?? 'Persona no identificada', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 9),
            _dato('DISTANCIA COSENO', r['distancia'] is num ? (r['distancia'] as num).toStringAsFixed(6) : 'No disponible'),
            const SizedBox(height: 8),
            _dato('MOTIVO', '${r['motivo'] ?? '—'}'),
            const SizedBox(height: 8),
            _dato('FECHA Y HORA', _fechaAmigable(r['fecha_hora'])),
          ]))),
        ],
      ],
    );
  }

  Widget _dato(String nombre, String valor) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 135, child: Text(nombre, style: const TextStyle(color: GymColors.muted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .5))),
    const SizedBox(width: 8),
    Expanded(child: Text(valor, style: const TextStyle(color: GymColors.white, fontSize: 12, fontWeight: FontWeight.w700))),
  ]);
}

class HistoryTab extends StatefulWidget {
  final ApiService api;
  const HistoryTab({super.key, required this.api});
  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List<dynamic> registros = [];
  bool cargando = false;
  String? error;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    if (mounted) setState(() { cargando = true; error = null; });
    try {
      final lista = await widget.api.asistencias();
      if (mounted) setState(() => registros = lista);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 14),
      child: Row(children: [
        const Expanded(child: GymSectionTitle(
          overline: 'Auditoría de accesos', title: 'Asistencias',
          subtitle: 'Historial de ingresos y verificaciones.')),
        IconButton(
          tooltip: 'Actualizar historial',
          onPressed: cargando ? null : () { GymSounds.tap(); cargar(); },
          icon: const Icon(Icons.refresh_rounded, color: GymColors.gold),
        ),
      ]),
    ),
    if (cargando) const LinearProgressIndicator(minHeight: 2),
    if (error != null) Padding(padding: const EdgeInsets.all(18), child: Text(error!, style: const TextStyle(color: GymColors.red))),
    if (!cargando && registros.isEmpty && error == null)
      const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.event_available_outlined, color: GymColors.gold, size: 50),
        SizedBox(height: 12),
        Text('Aún no hay asistencias', style: TextStyle(color: GymColors.white, fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        Text('Los accesos aparecerán aquí.', style: TextStyle(color: GymColors.muted)),
      ]))),
    if (registros.isNotEmpty)
      Expanded(child: RefreshIndicator(
        onRefresh: cargar,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 25),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: registros.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final r = Map<String, dynamic>.from(registros[i] as Map);
            final estado = '${r['estado']}';
            final ok = estado == 'ACCEPTED';
            final dup = estado == 'DUPLICATE';
            final color = ok ? GymColors.green : dup ? GymColors.orange : GymColors.red;
            return GymCard(padding: const EdgeInsets.all(15), child: Row(children: [
              Container(width: 46, height: 46,
                decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(15)),
                child: Icon(ok ? Icons.check_rounded : dup ? Icons.schedule_rounded : Icons.close_rounded, color: color)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r['usuario_nombre']?.toString() ?? 'Persona desconocida', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: GymColors.white)),
                const SizedBox(height: 4),
                Text(_fechaAmigable(r['fecha_hora']), style: const TextStyle(color: GymColors.muted, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${r['motivo'] ?? ''}', style: const TextStyle(color: GymColors.muted, fontSize: 10)),
              ])),
              const SizedBox(width: 5),
              GymStatus(text: estado, color: color, icon: ok ? Icons.check : dup ? Icons.info_outline : Icons.close),
            ]));
          },
        ),
      )),
  ]);
}
