import 'package:flutter/material.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.onDelete,
  });

  String _obtenerUrlImagen(String ruta) {
    if (ruta.isEmpty) return '';
    if (ruta.startsWith('http')) return ruta;
    return 'http://127.0.0.1:8000$ruta';
  }

  @override
  Widget build(BuildContext context) {
    final urlImagen = _obtenerUrlImagen(post.imagen);

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (urlImagen.isNotEmpty)
              Image.network(
                urlImagen,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 110,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.tags.isNotEmpty) ...[
                    Text(
                      post.tags,
                      style: const TextStyle(
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  Text(
                    post.titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF08245C),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    post.descripcion,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.article_outlined, size: 18),
                          SizedBox(width: 5),
                          Text('Leer publicación'),
                        ],
                      ),
                      if (onDelete != null)
                        IconButton(
                          tooltip: 'Eliminar publicación',
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: onDelete,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}