class ComentarioModel {
  final int id;
  final String comentario;
  final String fecha;
  final int estatus;
  final int usuarioId;
  final int blogId;
  final String nombreUsuario;

  ComentarioModel({
    required this.id,
    required this.comentario,
    required this.fecha,
    required this.estatus,
    required this.usuarioId,
    required this.blogId,
    this.nombreUsuario = '',
  });

  factory ComentarioModel.fromJson(Map<String, dynamic> json) {
    return ComentarioModel(
      id: (json['id_com'] as num).toInt(),
      comentario: json['comentario']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      estatus: (json['estatus'] as num?)?.toInt() ?? 1,
      usuarioId: (json['usr_id'] as num).toInt(),
      blogId: (json['blog_id'] as num).toInt(),
      nombreUsuario: json['nom_usr']?.toString() ?? 'Usuario #${json['usr_id']}',
    );
  }

  Map<String, dynamic> toJsonCrear() {
    return {
      'comentario': comentario,
      'usr_id': usuarioId,
      'blog_id': blogId,
    };
  }
}