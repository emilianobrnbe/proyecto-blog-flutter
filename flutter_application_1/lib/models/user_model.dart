class UserModel {
  final int id;
  final String nombre;
  final String correo;
  final String? password;
  final String? direccion;
  final int tipoUsuario;

  UserModel({
    required this.id,
    required this.nombre,
    required this.correo,
    this.password,
    this.direccion,
    this.tipoUsuario = 2, // 1 = Usuario Estándar
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id_usr'] as int,
      nombre: json['nom_usr'] as String,
      correo: json['mail'] as String,
      direccion: json['dir_usr'] as String?,
      tipoUsuario: json['tip_usu'] as int? ?? 2,
    );
  }

  Map<String, dynamic> toJsonCrear() {
    return {
      'nom_usr': nombre,
      'mail': correo,
      'password': password,
      'dir_usr': (direccion != null && direccion!.trim().isNotEmpty) ? direccion : null,
      'tip_usu': tipoUsuario,
    };
  }
}