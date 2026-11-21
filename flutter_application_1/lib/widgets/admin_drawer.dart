import 'package:flutter/material.dart';

class AdminDrawer extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final String rutaActual;

  const AdminDrawer({
    super.key,
    required this.usuario,
    required this.rutaActual,
  });

  String get nombre => usuario['nom_usr']?.toString() ?? 'Usuario';
  String get correo => usuario['mail']?.toString() ?? '';
  bool get esAdmin => (usuario['tip_usu'] as num? ?? 2).toInt() == 1;

  void _navegar(BuildContext context, String ruta) {
    Navigator.pop(context);
    if (ruta == rutaActual) return;
    Navigator.pushReplacementNamed(
      context,
      ruta,
      arguments: usuario,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF08245C)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  esAdmin ? Icons.admin_panel_settings : Icons.person,
                  color: const Color(0xFF08245C),
                  size: 34,
                ),
              ),
              accountName: Text(nombre),
              accountEmail: Text(correo),
            ),
            _opcion(
              context,
              Icons.article_outlined,
              'Publicaciones / Blog',
              '/blog',
            ),
            if (esAdmin) ...[
              _opcion(
                context,
                Icons.people_alt_outlined,
                'Gestión de usuarios',
                '/users',
              ),
              _opcion(
                context,
                Icons.person_add_alt_1,
                'Registrar usuario',
                '/register',
              ),
              _opcion(
                context,
                Icons.post_add,
                'Agregar blog',
                '/add-blog',
              ),
            ],
            _opcion(
              context,
              Icons.account_circle_outlined,
              'Mi perfil',
              '/profile',
            ),
            _opcion(
              context,
              Icons.map_outlined,
              'Ver Mapa',
              '/mapa',
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _opcion(
    BuildContext context,
    IconData icono,
    String titulo,
    String ruta,
  ) {
    final seleccionado = ruta == rutaActual;
    return ListTile(
      leading: Icon(
        icono,
        color: seleccionado ? const Color(0xFF08245C) : null,
      ),
      title: Text(titulo),
      selected: seleccionado,
      onTap: () => _navegar(context, ruta),
    );
  }
}