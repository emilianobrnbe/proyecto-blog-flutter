import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_services.dart';
import '../widgets/post_card.dart';
import 'post_detail_page.dart';
import '../widgets/admin_drawer.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final PostService postService = PostService();
  late Future<List<PostModel>> futurePosts;
  String nombreUsuario = 'Usuario';
  Map<String, dynamic> usuarioActual = {
    'nom_usr': 'Usuario',
    'mail': '',
    'tip_usu': 2,
  };
  bool argumentoLeido = false;

  bool get esAdmin => (usuarioActual['tip_usu'] as num? ?? 2).toInt() == 1;

  @override
  void initState() {
    super.initState();
    futurePosts = postService.obtenerPosts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!argumentoLeido) {
      final argumento = ModalRoute.of(context)?.settings.arguments;

      if (argumento is Map<String, dynamic>) {
        usuarioActual = Map<String, dynamic>.from(argumento);
        nombreUsuario = usuarioActual['nom_usr']?.toString() ?? 'Usuario';
      } else if (argumento is String && argumento.isNotEmpty) {
        nombreUsuario = argumento;
        usuarioActual = {
          'nom_usr': nombreUsuario,
          'mail': '',
          'tip_usu': 2,
        };
      }

      argumentoLeido = true;
    }
  }

  void recargarPosts() {
    setState(() {
      futurePosts = postService.obtenerPosts();
    });
  }

  Future<void> _confirmarEliminarBlog(PostModel post) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: Text('¿Deseas eliminar "${post.titulo}"?'),
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
      final adminId = (usuarioActual['id_usr'] as num?)?.toInt();
      await postService.eliminarPost(post.id, adminId: adminId);
      if (!mounted) return;
      recargarPosts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicación eliminada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Publicaciones'),
            Text(
              'Bienvenido, $nombreUsuario',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: recargarPosts,
          ),
        ],
      ),
      drawer: AdminDrawer(usuario: usuarioActual, rutaActual: '/blog'),
      body: FutureBuilder<List<PostModel>>(
        future: futurePosts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return const Center(child: Text('No hay publicaciones'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                post: post,
                onDelete: esAdmin ? () => _confirmarEliminarBlog(post) : null,
                onTap: () async {
                  final eliminado = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailPage(
                        post: post,
                        usuario: usuarioActual,
                      ),
                    ),
                  );
                  if (eliminado == true && mounted) {
                    recargarPosts();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}