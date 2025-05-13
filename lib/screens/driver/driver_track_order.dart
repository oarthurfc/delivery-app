import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

class TrackOrderScreen extends StatelessWidget {
  final Map<String, dynamic> encomenda;

  const TrackOrderScreen({super.key, required this.encomenda});

  @override
  Widget build(BuildContext context) {
    final LatLng origem = LatLng(encomenda['origemLat'], encomenda['origemLng']);
    final LatLng destino = LatLng(encomenda['destinoLat'], encomenda['destinoLng']);

    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Encomenda n°${encomenda['id']}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard(context, Icons.location_on, 'Origem: ${encomenda['origem']}'),
            _buildDetailCard(context, Icons.flag, 'Destino: ${encomenda['destino']}'),
            _buildDetailCard(context, Icons.description, 'Descrição: ${encomenda['descricao']}'),
            _buildDetailCard(context, Icons.account_circle, 'Destinatário: ${encomenda['destinatario']}'),
            _buildDetailCard(context, Icons.monetization_on, 'Valor: ${currencyFormat.format(encomenda['preco'])}'),
            const SizedBox(height: 12),

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
                    minZoom: 10.0,
                    maxZoom: 18.0,
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
          ],
        ),
      ),
    );
  }

  // Função para criar os cartões de informação
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
