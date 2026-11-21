import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../widgets/admin_drawer.dart';

class AddBlogPage extends StatefulWidget {
  const AddBlogPage({super.key});

  @override
  State<AddBlogPage> createState() => _AddBlogPageState();
}

class _AddBlogPageState extends State<AddBlogPage> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  final _tags = TextEditingController();

  // Controladores e instancias para la imagen
  final ImagePicker _picker = ImagePicker();
  XFile? _foto;
  Uint8List? _imagenBytes;

  bool _guardando = false;
  Map<String, dynamic> _usuario = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) _usuario = Map<String, dynamic>.from(args);
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _tags.dispose();
    super.dispose();
  }

  // Función para seleccionar la foto desde Galería/Cámara
  Future<void> _tomarFoto() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (imagen != null) {
      final bytes = await imagen.readAsBytes();
      setState(() {
        _foto = imagen;
        _imagenBytes = bytes;
      });
    }
  }

  // Función para enviar los campos y la imagen a FastAPI vía MultipartRequest
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_foto == null || _imagenBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una imagen para la publicación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final uri = Uri.parse('http://127.0.0.1:8000/blog');
      final request = http.MultipartRequest('POST', uri)
        ..fields['titulo'] = _titulo.text.trim()
        ..fields['descripcion'] = _descripcion.text.trim()
        ..fields['tags'] = _tags.text.trim()
        ..files.add(http.MultipartFile.fromBytes(
          'imagen',
          _imagenBytes!,
          filename: _foto!.name,
        ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publicación agregada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        _titulo.clear();
        _descripcion.clear();
        _tags.clear();
        setState(() {
          _foto = null;
          _imagenBytes = null;
        });
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _usuario['nom_usr']?.toString() ?? 'Administrador';

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar blog')),
      drawer: AdminDrawer(usuario: _usuario, rutaActual: '/add-blog'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Nueva publicación',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text('Administrador: $nombre'),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titulo,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ingresa el título'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descripcion,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ingresa la descripción'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // VISTA PREVIA Y SELECTOR DE IMAGEN (Reemplaza al TextField de URL)
                      InkWell(
                        onTap: _tomarFoto,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: _imagenBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _imagenBytes!,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo,
                                        size: 40, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                      'Haz clic aquí para seleccionar una imagen',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _tags,
                        decoration: const InputDecoration(
                          labelText: 'Etiquetas (opcional)',
                          hintText: 'flutter, tecnología, móvil',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _guardando ? 'Guardando...' : 'Guardar publicación',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}