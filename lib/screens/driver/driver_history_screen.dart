import 'package:flutter/material.dart';
import '../../widgets/common/app_bar_widget.dart';
import 'driver_delivery_details_screen.dart';

class DriverHistoryScreen extends StatelessWidget {
  const DriverHistoryScreen({super.key});

  final List<Map<String, dynamic>> entregas = const [
    {
      'id': 1,
      'status': 'PENDING',
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
      'imageUrl': 'https://picsum.photos/200/300',
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

  Widget buildHistoryCard(BuildContext context, Map<String, dynamic> entrega) {
    final textTheme = Theme.of(context).textTheme;
    final isDelivered = entrega['status'] == 'DELIVERIED';
    final statusText = isDelivered ? 'Entregue' : 'Em andamento';
    final formattedDate = entrega['data'].toString().split('-').reversed.join('/');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DriverDeliveryDetailsScreen(encomenda: entrega),
          ),
        );
      },
      child: Card(
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
                'Entrega Número: ${entrega['id']}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    isDelivered ? Icons.check_circle : Icons.error,
                    color: isDelivered ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    statusText,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDelivered ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    'Data: $formattedDate',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Origem: ${getFormattedAddress(entrega['originAddress'])}',
                      style: textTheme.bodyMedium,
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
                    'Destinatário: ${entrega['destinatario']}',
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
                    'Valor: R\$ ${entrega['preco'].toStringAsFixed(2)}',
                    style: textTheme.bodyMedium,
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
                      'Descrição: ${entrega['description']}',
                      style: textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Encomendas'),
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
              .map((entrega) => buildHistoryCard(context, entrega))
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