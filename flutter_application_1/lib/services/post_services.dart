import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

class PostService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<PostModel> agregarPost({
    required String titulo,
    required String descripcion,
    String? imagen,
    String? tags,
  }) async {
    final respuesta = await http.post(
      Uri.parse('$baseUrl/blog'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'titulo': titulo.trim(),
        'descripcion': descripcion.trim(),
        'img': (imagen ?? '').trim().isEmpty ? null : imagen!.trim(),
        'tags': (tags ?? '').trim().isEmpty ? null : tags!.trim(),
      }),
    ).timeout(const Duration(seconds: 10));

    final dynamic resultado = respuesta.body.isNotEmpty
        ? jsonDecode(respuesta.body)
        : null;

    if ((respuesta.statusCode == 200 || respuesta.statusCode == 201) &&
        resultado is Map<String, dynamic>) {
      return PostModel.fromJson(resultado);
    }

    if (resultado is Map && resultado['detail'] != null) {
      throw Exception(resultado['detail'].toString());
    }

    throw Exception(
      'No se pudo guardar la publicación (HTTP ${respuesta.statusCode})',
    );
  }

  Future<List<PostModel>> obtenerPosts() async {
    final respuesta = await http.get(Uri.parse('$baseUrl/blog'));

    if (respuesta.statusCode != 200) {
      throw Exception('Error al consultar publicaciones');
    }

    final List<dynamic> datos = jsonDecode(respuesta.body);
    return datos
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PostModel> editarPost({
    required int blogId,
    required String titulo,
    required String descripcion,
    String? tags,
    int? adminId,
    Uint8List? imagenBytes,
    String? nombreArchivo,
  }) async {
    final uri = Uri.parse('$baseUrl/blog/$blogId');
    final request = http.MultipartRequest('PUT', uri)
      ..fields['titulo'] = titulo.trim()
      ..fields['descripcion'] = descripcion.trim()
      ..fields['tags'] = (tags ?? '').trim();

    if (adminId != null) {
      request.fields['usr_id'] = adminId.toString();
    }

    if (imagenBytes != null && nombreArchivo != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'imagen',
          imagenBytes,
          filename: nombreArchivo,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final datos = jsonDecode(response.body) as Map<String, dynamic>;
      return PostModel.fromJson(datos);
    }

    throw Exception('No se pudo actualizar (${response.statusCode}): ${response.body}');
  }

  Future<void> eliminarPost(int blogId, {int? adminId}) async {
    final query = adminId != null ? '?usr_id=$adminId' : '';
    final respuesta = await http.delete(
      Uri.parse('$baseUrl/blog/$blogId$query'),
    );

    if (respuesta.statusCode != 200 && respuesta.statusCode != 204) {
      throw Exception('No se pudo eliminar la publicación');
    }
  }

  Future<dynamic> obtenerValoracion(int blogId, int usrId) async {
    final respuesta = await http.get(
      Uri.parse('$baseUrl/valoraciones/$blogId?usr_id=$usrId'),
    );

    if (respuesta.statusCode != 200) {
      return {'promedio': 0.0, 'total': 0, 'mi_voto': 0};
    }

    return jsonDecode(respuesta.body) as Map<String, dynamic>;
  }

  Future<void> calificarPost({
    required int blogId,
    required int usrId,
    required int estrellas,
  }) async {
    final respuesta = await http.post(
      Uri.parse('$baseUrl/valoraciones'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'blog_id': blogId,
        'usr_id': usrId,
        'estrellas': estrellas,
      }),
    );

    if (respuesta.statusCode != 200 && respuesta.statusCode != 201) {
      throw Exception('No se pudo guardar la calificación');
    }
  }
}