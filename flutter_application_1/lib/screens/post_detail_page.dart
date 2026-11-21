import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/comentario_model.dart';
import '../services/comentario_service.dart';
import '../services/post_services.dart';
import 'edit_post_page.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;
  final Map<String, dynamic>? usuario;

  const PostDetailPage({
    super.key,
    required this.post,
    this.usuario,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final ComentarioService _comentarioService = ComentarioService();
  final PostService _postService = PostService();
  final TextEditingController _comentarioController = TextEditingController();

  late PostModel _postActual;
  bool _seEdito = false;

  List<ComentarioModel> _comentarios = [];
  bool _cargandoComentarios = true;
  bool _enviandoComentario = false;

  double _promedioEstrellas = 0.0;
  int _totalVotos = 0;
  int _miVoto = 0;
  bool _guardandoVoto = false;

  int get _usuarioId => (widget.usuario?['id_usr'] as num?)?.toInt() ?? 0;
  bool get _esAdmin => (widget.usuario?['tip_usu'] as num? ?? 2).toInt() == 1;

  @override
  void initState() {
    super.initState();
    _postActual = widget.post;
    _cargarDatos();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    await Future.wait([
      _cargarComentarios(),
      _cargarValoracion(),
    ]);
  }

  Future<void> _cargarComentarios() async {
    try {
      final todos = await _comentarioService.obtenerComentarios();
      if (!mounted) return;
      setState(() {
        _comentarios = todos.where((c) => c.blogId == _postActual.id).toList();
        _cargandoComentarios = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoComentarios = false);
    }
  }

  Future<void> _cargarValoracion() async {
    try {
      final info = await _postService.obtenerValoracion(_postActual.id, _usuarioId);
      if (!mounted) return;
      setState(() {
        _promedioEstrellas = (info['promedio'] as num?)?.toDouble() ?? 0.0;
        _totalVotos = (info['total'] as num?)?.toInt() ?? 0;
        _miVoto = (info['mi_voto'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _abrirEditarPublicacion() async {
    final actualizado = await Navigator.push<PostModel>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPostPage(
          post: _postActual,
          usuario: widget.usuario,
        ),
      ),
    );

    if (actualizado != null && mounted) {
      setState(() {
        _postActual = actualizado;
        _seEdito = true;
      });
    }
  }

  Future<void> _votarEstrellas(int estrellas) async {
    if (_esAdmin) return;

    if (_usuarioId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para valorar esta publicación')),
      );
      return;
    }

    setState(() => _guardandoVoto = true);
    try {
      await _postService.calificarPost(
        blogId: _postActual.id,
        usrId: _usuarioId,
        estrellas: estrellas,
      );
      await _cargarValoracion();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calificaste con $estrellas ${estrellas == 1 ? 'estrella' : 'estrellas'}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al calificar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _guardandoVoto = false);
    }
  }

  Future<void> _enviarComentario() async {
    if (_esAdmin) return;

    final texto = _comentarioController.text.trim();
    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un comentario antes de enviar')),
      );
      return;
    }

    if (_usuarioId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para comentar')),
      );
      return;
    }

    setState(() => _enviandoComentario = true);
    try {
      final nuevo = ComentarioModel(
        id: 0,
        comentario: texto,
        fecha: '',
        estatus: 1,
        usuarioId: _usuarioId,
        blogId: _postActual.id,
      );
      await _comentarioService.agregarComentario(nuevo);
      _comentarioController.clear();
      await _cargarComentarios();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comentario publicado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo publicar el comentario: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _enviandoComentario = false);
    }
  }

  Future<void> _eliminarComentario(ComentarioModel com) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text('¿Deseas eliminar este comentario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await _comentarioService.eliminarComentario(com.id, adminId: _usuarioId);
      await _cargarComentarios();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comentario eliminado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _eliminarPublicacion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: Text('¿Deseas eliminar "${_postActual.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await _postService.eliminarPost(_postActual.id, adminId: _usuarioId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar publicación: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _seEdito);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalle de publicación'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _seEdito),
          ),
          actions: [
            if (_esAdmin) ...[
              IconButton(
                tooltip: 'Editar publicación',
                icon: const Icon(Icons.edit_outlined),
                onPressed: _abrirEditarPublicacion,
              ),
              IconButton(
                tooltip: 'Eliminar publicación',
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _eliminarPublicacion,
              ),
            ],
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_postActual.imagen.isNotEmpty)
                Image.network(
                  _postActual.imagen.startsWith('http')
                      ? _postActual.imagen
                      : "http://127.0.0.1:8000${_postActual.imagen.startsWith('/') ? '' : '/'}${_postActual.imagen}",
                  height: 230,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 150,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_postActual.tags.isNotEmpty) ...[
                      Text(
                        _postActual.tags,
                        style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    Text(
                      _postActual.titulo,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08245C),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      _postActual.descripcion.isNotEmpty
                          ? _postActual.descripcion
                          : 'Esta publicación no tiene descripción.',
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 12),

                    // ==========================================
                    // VALORACIÓN CON ESTRELLAS (1 A 5)
                    // ==========================================
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Valoración de la publicación',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF08245C),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 22),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_promedioEstrellas / 5 ($_totalVotos)',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (!_esAdmin) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Toca una estrella para calificar:',
                                style: TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: List.generate(5, (index) {
                                  final numeroEstrella = index + 1;
                                  final seleccionada = numeroEstrella <= _miVoto;
                                  return IconButton(
                                    onPressed: _guardandoVoto
                                        ? null
                                        : () => _votarEstrellas(numeroEstrella),
                                    icon: Icon(
                                      seleccionada ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 32,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==========================================
                    // SECCIÓN DE COMENTARIOS
                    // ==========================================
                    const Text(
                      'Comentarios',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08245C),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (!_esAdmin) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _comentarioController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'Escribe un comentario...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _enviandoComentario ? null : _enviarComentario,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF08245C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                            ),
                            icon: _enviandoComentario
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: const Text('Enviar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],

                    if (_cargandoComentarios)
                      const Center(child: CircularProgressIndicator())
                    else if (_comentarios.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          _esAdmin
                              ? 'Aún no hay comentarios en esta publicación.'
                              : 'Aún no hay comentarios. ¡Sé el primero en opinar!',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comentarios.length,
                        itemBuilder: (context, index) {
                          final com = _comentarios[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF08245C),
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(
                                com.nombreUsuario,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(com.comentario),
                                  if (com.fecha.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      com.fecha.replaceFirst('T', ' ').split('.').first,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: _esAdmin
                                  ? IconButton(
                                      tooltip: 'Eliminar comentario',
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _eliminarComentario(com),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}