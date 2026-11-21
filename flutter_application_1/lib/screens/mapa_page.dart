import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/admin_drawer.dart';

class MapaPage extends StatelessWidget {
  const MapaPage({super.key});

  void _mostrarInfo(BuildContext context, String titulo, String descripcion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF08245C),
          ),
        ),
        content: Text(descripcion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final Map<String, dynamic> usuarioActual = args is Map<String, dynamic>
        ? Map<String, dynamic>.from(args)
        : {'nom_usr': 'Usuario', 'mail': '', 'tip_usu': 2};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lugares de mi comunidad'),
        backgroundColor: const Color(0xFF08245C),
        foregroundColor: Colors.white,
      ),
      drawer: AdminDrawer(usuario: usuarioActual, rutaActual: '/mapa'),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(20.6350, -100.4100),
          initialZoom: 12.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app_movil',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: const LatLng(20.6540, -100.4048),
                width: 45,
                height: 45,
                child: GestureDetector(
                  onTap: () => _mostrarInfo(
                    context,
                    'UTEQ',
                    'Universidad Tecnológica de Querétaro, ubicada en Av. Pie de la Cuesta.',
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.purple,
                    size: 40,
                  ),
                ),
              ),
              Marker(
                point: const LatLng(20.5928, -100.3897),
                width: 45,
                height: 45,
                child: GestureDetector(
                  onTap: () => _mostrarInfo(
                    context,
                    'Centro Histórico',
                    'Corazón cultural, histórico y turístico de Santiago de Querétaro.',
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ),
              Marker(
                point: const LatLng(20.5964, -100.4103),
                width: 45,
                height: 45,
                child: GestureDetector(
                  onTap: () => _mostrarInfo(
                    context,
                    'Cerro de las Campanas',
                    'Parque nacional histórico y cultural de Querétaro.',
                  ),
                  child: const Icon(
                    Icons.park,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
              ),
              Marker(
                point: const LatLng(20.6725, -100.4344),
                width: 45,
                height: 45,
                child: GestureDetector(
                  onTap: () => _mostrarInfo(
                    context,
                    'Antea',
                    'Centro comercial donde todo esta caro.',
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
    );
  }
}