import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/common/app_bar_widget.dart';

class GetOrderScreen extends StatelessWidget {
  const GetOrderScreen({super.key});

  final List<Map<String, dynamic>> mockOrders = const [
    {
      'id': 1,
      'origem': 'Rua A, 123',
      'destino': 'Rua B, 456',
      'descricao': 'Caixa pequena',
      'preco': 25.00,
      'destinatario': 'Carlos',
      'origemLat': -23.550520,
      'origemLng': -46.633308,
      'destinoLat': -23.558702,
      'destinoLng': -46.625218,
    },
    {
      'id': 2,
      'origem': 'Av. Paulista, 1000',
      'destino': 'Rua das Flores, 200',
      'descricao': 'Envelope com documentos',
      'preco': 15.50,
      'destinatario': 'Maria',
      'origemLat': -23.564924,
      'origemLng': -46.652888,
      'destinoLat': -23.564924,
      'destinoLng': -46.652888,
    },
  ];

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
                Text(
                  'Origem: ${encomenda['origem']}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flag, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  'Destino: ${encomenda['destino']}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.description, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  'Descrição: ${encomenda['descricao']}',
                  style: textTheme.bodyMedium,
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
                  'Valor: R\$ ${encomenda['preco']}',
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
          children: mockOrders
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
  final LatLng origem = LatLng(encomenda['origemLat'], encomenda['origemLng']);
  final LatLng destino = LatLng(encomenda['destinoLat'], encomenda['destinoLng']);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Entrega aceita!")),
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
