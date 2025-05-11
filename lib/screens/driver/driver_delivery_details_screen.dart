import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DriverDeliveryDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> entrega;

  const DriverDeliveryDetailsScreen({super.key, required this.entrega});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Coordenadas da entrega (mock para compatibilidade com OpenStreetMap)
    final LatLng origem = LatLng(entrega['origemLat'], entrega['origemLng']);
    final LatLng destino = LatLng(entrega['destinoLat'], entrega['destinoLng']);

    return Scaffold(
      appBar: AppBar(
        title: Text('Entrega n°${entrega['id']}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status (primeiro item mostrado)
            _buildDetailCard(
              context,
              Icons.check_circle,
              'Status: ${entrega['status']}',
              iconColor: entrega['status'] == 'Entregue' ? Colors.green : Colors.red, // Cor dependendo do status
            ),
            const SizedBox(height: 12),

            // Data (segundo item mostrado)
            _buildDetailCard(
              context,
              Icons.access_time,
              'Data: ${entrega['data']}',
            ),
            const SizedBox(height: 12),

            // Mapa (terceiro item mostrado)
            Text(
              'Rota no Mapa:',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 250,
                child: FlutterMap(
                  options: MapOptions(
                    center: origem,
                    zoom: 13.0,
                    minZoom: 10.0, // Impede que o mapa seja zoomado muito para longe
                    maxZoom: 18.0, // Limita o zoom
                    interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.pinchZoom,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: origem,
                          width: 60,
                          height: 60,
                          child: const Icon(Icons.location_on, color: Colors.blue, size: 32),
                        ),
                        Marker(
                          point: destino,
                          width: 60,
                          height: 60,
                          child: const Icon(Icons.flag, color: Colors.red, size: 32),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Informações detalhadas (restante das informações)
            _buildDetailCard(
              context,
              Icons.location_on,
              'Origem: ${entrega['origemEndereco']}',
            ),
            _buildDetailCard(
              context,
              Icons.location_on_outlined,
              'Destino: ${entrega['destinoEndereco']}',
            ),
            _buildDetailCard(
              context,
              Icons.description,
              'Descrição: ${entrega['descricao']}',
            ),
            _buildDetailCard(
              context,
              Icons.account_circle,
              'Destinatário: ${entrega['destinatario']}',
            ),
            _buildDetailCard(
              context,
              Icons.monetization_on,
              'Valor: R\$ ${entrega['preco']}',
            ),
          ],
        ),
      ),
    );
  }

  // Função que gera o cartão de detalhes
  Widget _buildDetailCard(BuildContext context, IconData icon, String text,
      {Color iconColor = Colors.grey}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 30, color: iconColor),
        title: Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
