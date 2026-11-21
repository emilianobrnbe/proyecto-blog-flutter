import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService authService = AuthService();
  final UserService userService = UserService();

  bool cargando = false;
  int tipoUsuarioSeleccionado = 2;

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  Future<void> registrarUsuario(bool esAdminLogueado) async {
    final mensaje = authService.validarRegistro(
      nombre: nombreController.text.trim(),
      correo: correoController.text.trim(),
      password: passwordController.text,
      confirmarpassword: passwordController.text,
    );

    if (mensaje != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => cargando = true);

    try {
      final nombreRegistrado = nombreController.text.trim();
      final nuevoUsuario = UserModel(
        id: 0,
        nombre: nombreRegistrado,
        correo: correoController.text.trim(),
        password: passwordController.text.trim(),
        direccion: null,
        tipoUsuario: esAdminLogueado ? tipoUsuarioSeleccionado : 2,
      );

      await userService.agregarUsuario(nuevoUsuario);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Usuario $nombreRegistrado registrado con éxito',
          ),
          backgroundColor: Colors.green,
        ),
      );

      if (esAdminLogueado) {
        nombreController.clear();
        correoController.clear();
        passwordController.clear();
        setState(() => tipoUsuarioSeleccionado = 2);
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final Map<String, dynamic>? adminActual =
        args is Map<String, dynamic> ? Map<String, dynamic>.from(args) : null;
    final bool esAdminLogueado =
        adminActual != null && (adminActual['tip_usu'] as num? ?? 2).toInt() == 1;

    return Scaffold(
      appBar: esAdminLogueado
          ? AppBar(
              title: const Text('Registrar usuario'),
              backgroundColor: const Color(0xFF08245C),
              foregroundColor: Colors.white,
            )
          : null,
      drawer: esAdminLogueado
          ? AdminDrawer(usuario: adminActual, rutaActual: '/register')
          : null,
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AuthCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_add,
                    size: 65,
                    color: Color(0xFF2196F3),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Text(
                    esAdminLogueado ? 'REGISTRAR USUARIO' : 'CREAR CUENTA',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF08245C),
                    ),
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  CustomTextField(
                    controller: nombreController,
                    label: 'Nombre completo',
                    prefixIcon: Icons.person,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  CustomTextField(
                    controller: correoController,
                    label: 'Correo electrónico',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  CustomTextField(
                    controller: passwordController,
                    label: 'Contraseña',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                  ),
                  if (esAdminLogueado) ...[
                    const SizedBox(
                      height: 15,
                    ),
                    DropdownButtonFormField<int>(
                      value: tipoUsuarioSeleccionado,
                      decoration: InputDecoration(
                        labelText: 'Tipo de usuario',
                        prefixIcon: const Icon(Icons.admin_panel_settings),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Usuario normal'),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Administrador'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          setState(() => tipoUsuarioSeleccionado = valor);
                        }
                      },
                    ),
                  ],
                  const SizedBox(
                    height: 25,
                  ),
                  PrimaryButton(
                    text: cargando
                        ? 'GUARDANDO...'
                        : (esAdminLogueado ? 'GUARDAR USUARIO' : 'REGISTRARME'),
                    onPressed: cargando
                        ? () {}
                        : () => registrarUsuario(esAdminLogueado),
                  ),
                  if (!esAdminLogueado) ...[
                    const SizedBox(
                      height: 15,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },
                      child: const Text(
                        'Ya tengo una cuenta',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}