import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DriverDeliveryDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> encomenda;

  const DriverDeliveryDetailsScreen({super.key, required this.encomenda});

  String getFormattedAddress(Map<String, dynamic> address) {
    return '${address['street']}, ${address['number']} - ${address['neighborhood']}, ${address['city']}';
  }

  String getFormattedDate(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}'; // DD/MM/YYYY
    }
    return isoDate; // Retorna original se não conseguir formatar
  }

  String getStatusText(String status) {
    switch (status) {
      case 'DELIVERIED':
        return 'Entregue';
      case 'PENDING':
        return 'Em andamento';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Coordenadas da entrega com a nova estrutura de dados
    final LatLng origem = LatLng(
        encomenda['originAddress']['latitude'],
        encomenda['originAddress']['longitude']
    );

    final LatLng destino = LatLng(
        encomenda['destinationAddress']['latitude'],
        encomenda['destinationAddress']['longitude']
    );

    final isDelivered = encomenda['status'] == 'DELIVERIED';
    final statusText = getStatusText(encomenda['status']);
    final formattedDate = getFormattedDate(encomenda['data']);

    return Scaffold(
      appBar: AppBar(
        title: Text('Entrega n°${encomenda['id']}'),
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
              'Status: $statusText',
              iconColor: isDelivered ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 12),

            // Data (segundo item mostrado)
            _buildDetailCard(
              context,
              Icons.access_time,
              'Data: $formattedDate',
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
            const SizedBox(height: 12),

            // Informações detalhadas (restante das informações)
            _buildDetailCard(
              context,
              Icons.location_on,
              'Origem: ${getFormattedAddress(encomenda['originAddress'])}',
            ),
            _buildDetailCard(
              context,
              Icons.location_on_outlined,
              'Destino: ${getFormattedAddress(encomenda['destinationAddress'])}',
            ),
            _buildDetailCard(
              context,
              Icons.description,
              'Descrição: ${encomenda['description']}',
            ),
            _buildDetailCard(
              context,
              Icons.account_circle,
              'Destinatário: ${encomenda['destinatario']}',
            ),
            _buildDetailCard(
              context,
              Icons.monetization_on,
              'Valor: R\$ ${encomenda['preco'].toStringAsFixed(2)}',
            ),
            if (encomenda['imageUrl'] != null)
              _buildDetailCard(
                context,
                Icons.image,
                'Imagem disponível',
                trailingWidget: encomenda['imageUrl'].toString().startsWith('http')
                    ? Image.network(
                  encomenda['imageUrl'],
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, color: Colors.grey),
                )
                    : const Icon(Icons.image_not_supported),
              ),
          ],
        ),
      ),
    );
  }

  // Função que gera o cartão de detalhes
  Widget _buildDetailCard(
      BuildContext context,
      IconData icon,
      String text, {
        Color iconColor = Colors.grey,
        Widget? trailingWidget,
      }) {
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
        trailing: trailingWidget,
      ),
    );
  }
}