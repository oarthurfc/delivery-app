import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/common/app_bar_widget.dart';
import 'driver_delivery_details_screen.dart';

class GetOrderScreen extends StatelessWidget {
  const GetOrderScreen({super.key});

  final List<Map<String, dynamic>> entregas = const [
    {
      'id': 1,
      'status': 'ON_COURSE',
      'data': '2025-05-10',
      'description': 'Caixa com documentos',
      'imageUrl': 'https://picsum.photos/200/300',
      'destinatario': 'João Silva',
      'preco': 45.90,
      'originAddress': {
        'street': 'Rua Alpha',
        'number': '123',
        'neighborhood': 'Centro',
        'city': 'Belo Horizonte',
        'latitude': -19.9245,
        'longitude': -43.9352,
      },
      'destinationAddress': {
        'street': 'Av. Beta',
        'number': '456',
        'neighborhood': 'Savassi',
        'city': 'Belo Horizonte',
        'latitude': -19.9380,
        'longitude': -43.9270,
      },
    },
    {
      'id': 2,
      'status': 'PENDING',
      'data': '2025-04-28',
      'description': 'Entrega de eletrônicos',
      'imageUrl': 'https://picsum.photos/200/300',
      'destinatario': 'Maria Oliveira',
      'preco': 78.50,
      'originAddress': {
        'street': 'Rua das Flores',
        'number': '10',
        'neighborhood': 'Jardins',
        'city': 'São Paulo',
        'latitude': -23.5610,
        'longitude': -46.6560,
      },
      'destinationAddress': {
        'street': 'Av. Paulista',
        'number': '1578',
        'neighborhood': 'Bela Vista',
        'city': 'São Paulo',
        'latitude': -23.5640,
        'longitude': -46.6525,
      },
    },
    {
      'id': 3,
      'status': 'DELIVERIED',
      'data': '2025-04-15',
      'description': 'Livros escolares',
      'imageUrl': 'https://exemplo.com/imagem3.jpg',
      'destinatario': 'Carlos Mendes',
      'preco': 32.00,
      'originAddress': {
        'street': 'Rua do Sol',
        'number': '85',
        'neighborhood': 'Boa Viagem',
        'city': 'Recife',
        'latitude': -8.1117,
        'longitude': -34.9156,
      },
      'destinationAddress': {
        'street': 'Rua da Aurora',
        'number': '102',
        'neighborhood': 'Santo Amaro',
        'city': 'Recife',
        'latitude': -8.0631,
        'longitude': -34.8711,
      },
    },
  ];

  String getFormattedAddress(Map<String, dynamic> address) {
    return '${address['street']}, ${address['number']} - ${address['neighborhood']}, ${address['city']}';
  }

  String getFormattedDate(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}'; // DD/MM/YYYY
    }
    return isoDate;
  }

  Widget buildOrderCard(BuildContext context, Map<String, dynamic> encomenda) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Encomenda Nº: ${encomenda['id']}',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Origem: ${getFormattedAddress(encomenda['originAddress'])}',
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flag, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Destino: ${getFormattedAddress(encomenda['destinationAddress'])}',
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.description, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Descrição: ${encomenda['description']}',
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.account_circle, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  'Destinatário: ${encomenda['destinatario']}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.monetization_on, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  'Valor: R\$ ${encomenda['preco'].toStringAsFixed(2)}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showConfirmationModal(context, encomenda),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Aceitar encomenda'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encomendas disponíveis'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: entregas
              .map((encomenda) => buildOrderCard(context, encomenda))
              .toList(),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // lógica de navegação
        },
      ),
    );
  }
}

void _showConfirmationModal(BuildContext context, Map<String, dynamic> encomenda) {
  final LatLng origem = LatLng(
    encomenda['originAddress']['latitude'],
    encomenda['originAddress']['longitude'],
  );
  final LatLng destino = LatLng(
    encomenda['destinationAddress']['latitude'],
    encomenda['destinationAddress']['longitude'],
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Aceitar encomenda",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: FlutterMap(
                  options: MapOptions(
                    center: origem,
                    zoom: 13.0,
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
                          child: const Icon(Icons.location_on, color: Colors.blue, size: 30),
                        ),
                        Marker(
                          point: destino,
                          width: 60,
                          height: 60,
                          child: const Icon(Icons.flag, color: Colors.red, size: 30),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text("Cancelar", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Fecha o modal
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DriverDeliveryDetailsScreen(encomenda: encomenda),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text("Confirmar", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    },
  );
}