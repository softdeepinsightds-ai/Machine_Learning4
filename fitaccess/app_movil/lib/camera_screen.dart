import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'premium_widgets.dart';
import 'sound_service.dart';

/// Muestra una vista previa y devuelve UNA fotografía al módulo solicitante.
class CameraScreen extends StatefulWidget {
  final String titulo;
  const CameraScreen({super.key, required this.titulo});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception('No se encontró ninguna cámara');
      final cam = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      await _activar(cam);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _activar(CameraDescription cam) async {
    final anterior = _controller;
    _controller = null;
    if (mounted) setState(() {});
    await anterior?.dispose();
    final nuevo = CameraController(cam, ResolutionPreset.high, enableAudio: false);
    try {
      await nuevo.initialize();
      if (!mounted) {
        await nuevo.dispose();
        return;
      }
      setState(() => _controller = nuevo);
    } catch (_) {
      await nuevo.dispose();
      rethrow;
    }
  }

  Future<void> _cambiarCamara() async {
    if (_busy || _controller == null || _cameras.length < 2) return;
    setState(() => _busy = true);
    try {
      final actual = _controller!.description;
      final otra = _cameras.firstWhere((c) => c.name != actual.name, orElse: () => actual);
      await _activar(otra);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _capturar() async {
    final c = _controller;
    if (_busy || c == null || !c.value.isInitialized) return;
    setState(() => _busy = true);
    try {
      final archivo = await c.takePicture();
      GymSounds.tap();
      if (mounted) Navigator.of(context).pop(archivo);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo tomar la foto: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: Column(children: [
        Expanded(
          child: Center(
            child: _error != null
                ? Padding(padding: const EdgeInsets.all(18), child: Text(_error!))
                : c == null || !c.value.isInitialized
                    ? const CircularProgressIndicator()
                    : CameraPreview(c),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: GymCard(padding: EdgeInsets.all(14), child: Row(children: [
            Icon(Icons.light_mode_outlined, color: GymColors.gold),
            SizedBox(width: 12),
            Expanded(child: Text('Un rostro por foto · buena iluminación · sin filtros.', style: TextStyle(color: GymColors.white, fontSize: 12))),
          ])),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
          child: Row(children: [
            IconButton(
              tooltip: 'Cambiar cámara',
              onPressed: _cameras.length > 1 && !_busy ? _cambiarCamara : null,
              icon: const Icon(Icons.cameraswitch_outlined, color: GymColors.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy || c == null || !c.value.isInitialized ? null : _capturar,
                icon: const Icon(Icons.camera_alt),
                label: Text(_busy ? 'Procesando...' : 'Tomar fotografía'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
