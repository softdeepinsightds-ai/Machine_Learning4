import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  final String baseUrl;
  final String apiKey;
  const ApiService({required this.baseUrl, required this.apiKey});

  Uri _uri(String path) => Uri.parse('${baseUrl.replaceAll(RegExp(r"/+$"), "")}$path');
  Map<String, String> get _headers => {'X-API-Key': apiKey};

  dynamic _check(int status, String body) {
    dynamic obj;
    try {
      obj = jsonDecode(body);
    } catch (_) {
      throw ApiException('Respuesta inválida del servidor (HTTP $status).');
    }
    if (status >= 400) {
      final detail = obj is Map ? obj['detail'] : obj;
      throw ApiException('HTTP $status: $detail');
    }
    return obj;
  }

  Future<List<dynamic>> usuarios() async {
    final response = await http.get(_uri('/usuarios'), headers: _headers)
        .timeout(const Duration(seconds: 60));
    return _check(response.statusCode, response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> crearUsuario(String nombre, String codigo, String cedula) async {
    final response = await http.post(
      _uri('/usuarios'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre, 'codigo': codigo, 'cedula': cedula}),
    ).timeout(const Duration(seconds: 60));
    return Map<String, dynamic>.from(_check(response.statusCode, response.body) as Map);
  }

  Future<Map<String, dynamic>> matricular(int id, List<XFile> fotos) async {
    return _subirImagenes('/usuarios/$id/matricular', 'fotos', fotos);
  }

  Future<Map<String, dynamic>> verificar(XFile foto) async {
    return _subirImagenes('/accesos/verificar', 'foto', [foto]);
  }

  Future<Map<String, dynamic>> _subirImagenes(
      String path, String nombreCampo, List<XFile> archivos) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(_headers);
    for (final archivo in archivos) {
      request.files.add(await http.MultipartFile.fromPath(nombreCampo, archivo.path));
    }
    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final response = await http.Response.fromStream(streamed);
    return Map<String, dynamic>.from(_check(response.statusCode, response.body) as Map);
  }

  Future<List<dynamic>> asistencias() async {
    final response = await http.get(_uri('/asistencias?limit=100'), headers: _headers)
        .timeout(const Duration(seconds: 60));
    return _check(response.statusCode, response.body) as List<dynamic>;
  }
}
