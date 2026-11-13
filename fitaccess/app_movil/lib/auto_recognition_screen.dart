import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'camera_screen.dart';
import 'app_theme.dart';
import 'premium_widgets.dart';

/// CAPTURA AUTOMÁTICA: controla la cámara y la calidad de la captura localmente.
/// IMPORTANTE: el parpadeo/giro es una DEMOSTRACIÓN de interacción, NO una
/// prueba de vida robusta. El servidor actual no valida este desafío.
class AutoRecognitionScreen extends StatefulWidget {
  const AutoRecognitionScreen({super.key});

  @override
  State<AutoRecognitionScreen> createState() => _AutoRecognitionScreenState();
}

class _AutoRecognitionScreenState extends State<AutoRecognitionScreen> {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.18,
    ),
  );

  static const Map<DeviceOrientation, int> _orientaciones = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  CameraController? _camera;
  List<CameraDescription> _camaras = [];
  bool _cambiandoCamara = false;
  bool _procesando = false;
  bool _capturando = false;
  bool _cerrando = false;
  bool _rostroApto = false;
  String _mensaje = 'Iniciando cámara...';
  String? _error;

  // Fases: 0 = alinear; 1 = realizar desafío; 2 = volver al frente;
  // 3 = mantenerse quieto y esperar captura.
  int _fase = 0;
  int _alineadoSeguido = 0;
  int _estableSeguido = 0;
  bool _ojoCerradoDetectado = false;
  late final bool _desafioParpadeo = Random.secure().nextBool();
  DateTime _ultimoFotograma = DateTime.fromMillisecondsSinceEpoch(0);
  Offset? _centroPrevio;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      _camaras = await availableCameras();
      if (_camaras.isEmpty) throw StateError('No hay cámaras disponibles');

      // Para reconocer, la frontal es la opción principal.
      final frontal = _camaras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _camaras.first,
      );
      try {
        await _activarCamara(frontal);
      } catch (_) {
        // Algunos teléfonos enumeran la cámara frontal aunque esté dañada.
        final trasera = _camaras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => frontal,
        );
        if (trasera.name == frontal.name) rethrow;
        await _activarCamara(trasera);
      }
    } catch (e) {
      if (mounted && !_cerrando) {
        setState(() {
          _error = 'No se pudo iniciar el análisis facial: $e';
          _mensaje = 'Comprueba los permisos de cámara.';
        });
      }
    }
  }

  /// Abre una cámara concreta y activa su análisis en tiempo real.
  Future<void> _activarCamara(CameraDescription seleccionada) async {
    final nuevo = CameraController(
      seleccionada,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    try {
      await nuevo.initialize();
      if (!mounted || _cerrando) {
        await nuevo.dispose();
        return;
      }
      _camera = nuevo;
      setState(() {
        _error = null;
        _mensaje = 'Coloca un solo rostro dentro del recuadro.';
      });
      await nuevo.startImageStream(_analizarFotograma);
    } catch (_) {
      if (identical(_camera, nuevo)) _camera = null;
      await nuevo.dispose();
      rethrow;
    }
  }

  Future<void> _cambiarCamara() async {
    final anterior = _camera;
    if (_cambiandoCamara || _capturando || _cerrando ||
        anterior == null || _camaras.length < 2) return;

    final direccionActual = anterior.description.lensDirection;
    final direccionNueva = direccionActual == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final nueva = _camaras.firstWhere(
      (c) => c.lensDirection == direccionNueva,
      orElse: () => anterior.description,
    );
    if (nueva.name == anterior.description.name) return;

    setState(() {
      _cambiandoCamara = true;
      _camera = null;
      _error = null;
      _mensaje = 'Cambiando cámara...';
      _fase = 0;
      _alineadoSeguido = 0;
      _estableSeguido = 0;
      _ojoCerradoDetectado = false;
      _rostroApto = false;
      _centroPrevio = null;
    });

    try {
      if (anterior.value.isStreamingImages) {
        await anterior.stopImageStream();
      }
      await anterior.dispose();
      await _activarCamara(nueva);
    } catch (e) {
      if (mounted && !_cerrando) {
        setState(() {
          _error = 'No se pudo cambiar de cámara: $e';
          _mensaje = 'Vuelve a abrir el escaneo para intentarlo otra vez.';
        });
      }
    } finally {
      if (mounted && !_cerrando) {
        setState(() => _cambiandoCamara = false);
      }
    }
  }

  InputImage? _convertirImagen(CameraImage fotograma, CameraController controlador) {
    if (fotograma.planes.length != 1) return null;
    final formato = InputImageFormatValue.fromRawValue(fotograma.format.raw);
    if (Platform.isAndroid && formato != InputImageFormat.nv21) return null;
    if (Platform.isIOS && formato != InputImageFormat.bgra8888) return null;

    final sensor = controlador.description.sensorOrientation;
    final rotacionDispositivo = _orientaciones[controlador.value.deviceOrientation];
    if (rotacionDispositivo == null) return null;
    final grados = Platform.isAndroid
        ? (controlador.description.lensDirection == CameraLensDirection.front
            ? (sensor + rotacionDispositivo) % 360
            : (sensor - rotacionDispositivo + 360) % 360)
        : sensor;
    final rotacion = InputImageRotationValue.fromRawValue(grados);
    if (rotacion == null) return null;
    final plano = fotograma.planes.first;
    return InputImage.fromBytes(
      bytes: plano.bytes,
      metadata: InputImageMetadata(
        size: Size(fotograma.width.toDouble(), fotograma.height.toDouble()),
        rotation: rotacion,
        format: formato!,
        bytesPerRow: plano.bytesPerRow,
      ),
    );
  }

  void _reiniciar(String mensaje) {
    if (!mounted || _capturando || _cambiandoCamara) return;
    setState(() {
      _fase = 0;
      _alineadoSeguido = 0;
      _estableSeguido = 0;
      _ojoCerradoDetectado = false;
      _rostroApto = false;
      _centroPrevio = null;
      _mensaje = mensaje;
    });
  }

  void _analizarFotograma(CameraImage fotograma) {
    if (_procesando || _capturando || _cerrando || _cambiandoCamara) return;
    final ahora = DateTime.now();
    if (ahora.difference(_ultimoFotograma).inMilliseconds < 260) return;
    _ultimoFotograma = ahora;
    _procesando = true;
    unawaited(_procesar(fotograma));
  }

  Future<void> _procesar(CameraImage fotograma) async {
    try {
      final controlador = _camera;
      if (!mounted || controlador == null || _capturando || _cambiandoCamara) return;
      final imagen = _convertirImagen(fotograma, controlador);
      if (imagen == null) {
        if (mounted && _error == null) {
          setState(() => _error = 'Formato de fotograma no compatible. '
              'Comprueba que camera_android esté instalado.');
        }
        return;
      }
      final caras = await _detector.processImage(imagen);
      if (!mounted || _capturando || _cerrando || _cambiandoCamara) return;
      if (caras.length != 1) {
        _reiniciar(caras.isEmpty
            ? 'Acerca el rostro a la cámara.'
            : 'Debe aparecer una sola persona frente a la cámara.');
        return;
      }
      final rostro = caras.first;
      final rotado = imagen.metadata!.rotation == InputImageRotation.rotation90deg ||
          imagen.metadata!.rotation == InputImageRotation.rotation270deg;
      final ancho = rotado ? fotograma.height.toDouble() : fotograma.width.toDouble();
      final alto = rotado ? fotograma.width.toDouble() : fotograma.height.toDouble();
      final centro = Offset(rostro.boundingBox.center.dx / ancho,
          rostro.boundingBox.center.dy / alto);
      final proporcionCara = rostro.boundingBox.width / ancho;
      final giro = rostro.headEulerAngleY ?? 0.0;
      final inclinacion = rostro.headEulerAngleZ ?? 0.0;
      final deFrente = giro.abs() <= 12 && inclinacion.abs() <= 12;
      final bienColocado = centro.dx >= 0.23 && centro.dx <= 0.77 &&
          centro.dy >= 0.20 && centro.dy <= 0.84 &&
          proporcionCara >= 0.22 && proporcionCara <= 0.90;

      if (!bienColocado) {
        _reiniciar('Centra el rostro y acércate ligeramente.');
        return;
      }
      if (_fase == 0) {
        if (!deFrente) {
          _reiniciar('Mira de frente a la cámara.');
          return;
        }
        _alineadoSeguido++;
        _actualizar(true, 'Mantén la cabeza centrada...');
        if (_alineadoSeguido >= 2) {
          _fase = 1;
          _actualizar(true, _desafioParpadeo
              ? 'Ahora PARPADEA: cierra y abre los ojos.'
              : 'Ahora GIRA ligeramente la cabeza a un lado.');
        }
        return;
      }

      if (_fase == 1) {
        if (_desafioParpadeo) {
          if (!deFrente) {
            _actualizar(false, 'Mira de frente y parpadea.');
            return;
          }
          final izquierdo = rostro.leftEyeOpenProbability;
          final derecho = rostro.rightEyeOpenProbability;
          if (izquierdo == null || derecho == null) {
            _actualizar(false, 'Acércate y mantén los ojos visibles.');
            return;
          }
          if (!_ojoCerradoDetectado && izquierdo < 0.38 && derecho < 0.38) {
            _ojoCerradoDetectado = true;
            _actualizar(true, 'Ahora abre los ojos.');
          } else if (_ojoCerradoDetectado && izquierdo > 0.68 && derecho > 0.68) {
            _fase = 3;
            _estableSeguido = 0;
            _centroPrevio = null;
            _actualizar(true, 'Bien. Mantente quieto unos instantes.');
          }
        } else {
          if (giro.abs() >= 18 && giro.abs() <= 42) {
            _fase = 2;
            _actualizar(true, 'Perfecto. Vuelve a mirar de frente.');
          } else {
            _actualizar(true, 'Gira ligeramente la cabeza a un lado.');
          }
        }
        return;
      }

      if (_fase == 2) {
        if (deFrente) {
          _fase = 3;
          _estableSeguido = 0;
          _centroPrevio = null;
          _actualizar(true, 'Bien. Mantente quieto unos instantes.');
        } else {
          _actualizar(true, 'Vuelve a mirar de frente.');
        }
        return;
      }

      if (!deFrente) {
        _estableSeguido = 0;
        _centroPrevio = null;
        _actualizar(false, 'Para capturar, vuelve a mirar de frente.');
        return;
      }
      final movimiento = _centroPrevio == null ? 0.0 : (centro - _centroPrevio!).distance;
      _centroPrevio = centro;
      _estableSeguido = movimiento < 0.055 ? _estableSeguido + 1 : 0;
      _actualizar(true, 'Rostro correcto. Captura automática en breve...');
      if (_estableSeguido >= 4) {
        _capturando = true;
        // Deja concluir la detección antes de cerrar el stream de la cámara.
        Future<void>.microtask(_tomarAutomaticamente);
      }
    } catch (e) {
      if (mounted && !_cerrando && !_cambiandoCamara) {
        setState(() => _error = 'Error del detector: $e');
      }
    } finally {
      _procesando = false;
    }
  }

  void _actualizar(bool valido, String mensaje) {
    if (!mounted || _cerrando || _cambiandoCamara) return;
    if (_mensaje != mensaje || _rostroApto != valido) {
      setState(() {
        _mensaje = mensaje;
        _rostroApto = valido;
      });
    }
  }

  Future<void> _tomarAutomaticamente() async {
    final controlador = _camera;
    if (controlador == null || !mounted || _cambiandoCamara) return;
    try {
      setState(() => _mensaje = 'Tomando fotografía automáticamente...');
      if (controlador.value.isStreamingImages) await controlador.stopImageStream();
      final foto = await controlador.takePicture();
      if (mounted) Navigator.of(context).pop(foto);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Falló la captura automática: $e';
          _capturando = false;
          _mensaje = 'Utiliza el modo manual de diagnóstico.';
        });
      }
    }
  }

  /// Alternativa solo para depurar incompatibilidades del detector.
  /// No debería estar disponible en un control de acceso de seguridad real.
  void _modoManual() {
    Navigator.of(context).pushReplacement<XFile, XFile>(
      MaterialPageRoute(builder: (_) => const CameraScreen(
        titulo: 'Captura manual (solo diagnóstico)',
      )),
    );
  }

  @override
  void dispose() {
    _cerrando = true;
    final cam = _camera;
    _camera = null;
    if (cam != null) unawaited(cam.dispose());
    unawaited(_detector.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cam = _camera;
    final iniciado = cam != null && cam.value.isInitialized;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaneo inteligente'),
        actions: [
          if (_camaras.length > 1)
            IconButton(
              tooltip: 'Cambiar entre cámara frontal y trasera',
              onPressed: _cambiandoCamara || _capturando || !iniciado
                  ? null
                  : _cambiarCamara,
              icon: const Icon(Icons.cameraswitch_outlined, color: GymColors.gold),
            ),
        ],
      ), 
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: !iniciado
                  ? const CircularProgressIndicator()
                  : AspectRatio(
                      aspectRatio: 1 / cam.value.aspectRatio,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(cam),
                          Center(
                            child: FractionallySizedBox(
                              widthFactor: 0.75,
                              heightFactor: 0.66,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _rostroApto ? GymColors.green : GymColors.gold,
                                    width: 4,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                          if (_capturando)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: GymCard(padding: const EdgeInsets.all(16), child: Row(
              children: [
                Icon(_rostroApto ? Icons.verified_user_outlined : Icons.center_focus_strong,
                  color: _rostroApto ? GymColors.green : GymColors.gold, size: 27),
                const SizedBox(width: 14),
                Expanded(child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(_mensaje, key: ValueKey(_mensaje),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: GymColors.white)),
                )),
              ],
            )),
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(_error!, style: const TextStyle(color: GymColors.red, fontSize: 12))),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 5, 18, 16),
            child: OutlinedButton.icon(
              onPressed: _capturando ? null : _modoManual,
              icon: const Icon(Icons.build_outlined),
              label: const Text('Modo manual · diagnóstico'),
            ),
          ),

        ],
      ),
    );
  }
}
