import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';
import '../services/post_services.dart';

class EditPostPage extends StatefulWidget {
  final PostModel post;
  final Map<String, dynamic>? usuario;

  const EditPostPage({
    super.key,
    required this.post,
    this.usuario,
  });

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final _formKey = GlobalKey<FormState>();
  final PostService _postService = PostService();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _titulo;
  late final TextEditingController _descripcion;
  late final TextEditingController _tags;

  XFile? _fotoNueva;
  Uint8List? _imagenBytesNueva;
  bool _guardando = false;

  int? get _adminId => (widget.usuario?['id_usr'] as num?)?.toInt();

  @override
  void initState() {
    super.initState();
    _titulo = TextEditingController(text: widget.post.titulo);
    _descripcion = TextEditingController(text: widget.post.descripcion);
    _tags = TextEditingController(text: widget.post.tags);
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (imagen != null) {
      final bytes = await imagen.readAsBytes();
      setState(() {
        _fotoNueva = imagen;
        _imagenBytesNueva = bytes;
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final postActualizado = await _postService.editarPost(
        blogId: widget.post.id,
        titulo: _titulo.text.trim(),
        descripcion: _descripcion.text.trim(),
        tags: _tags.text.trim(),
        adminId: _adminId,
        imagenBytes: _imagenBytesNueva,
        nombreArchivo: _fotoNueva?.name,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicación actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, postActualizado);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _construirVistaPreviaImagen() {
    if (_imagenBytesNueva != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          _imagenBytesNueva!,
          height: 190,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    if (widget.post.imagen.isNotEmpty) {
      final urlImagen = widget.post.imagen.startsWith('http')
          ? widget.post.imagen
          : "http://127.0.0.1:8000${widget.post.imagen.startsWith('/') ? '' : '/'}${widget.post.imagen}";

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          urlImagen,
          height: 190,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
          ),
        ),
      );
    }

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
        SizedBox(height: 8),
        Text(
          'Haz clic aquí para seleccionar una imagen',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar publicación'),
      ),
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
                        'Editar publicación',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
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
                      InkWell(
                        onTap: _seleccionarFoto,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 190,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: _construirVistaPreviaImagen(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Toca la imagen si deseas reemplazarla (opcional)',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                        textAlign: TextAlign.center,
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
                        onPressed: _guardando ? null : _guardarCambios,
                        icon: _guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _guardando ? 'Guardando...' : 'Guardar cambios',
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