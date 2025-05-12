import 'package:flutter/material.dart';
import '../../widgets/common/app_bar_widget.dart';
import 'driver_delivery_details_screen.dart';

class DriverHistoryScreen extends StatelessWidget {
  const DriverHistoryScreen({super.key});

  final List<Map<String, dynamic>> mockHistorico = const [
    {
      'id': 101,
      'origemEndereco': 'Rua das Palmeiras, 45',
      'origemLat': -19.9245,
      'origemLng': -43.9352, // Exemplo: BH
      'destinoEndereco': 'Av. Central, 789',
      'destinoLat': -19.9156,
      'destinoLng': -43.9262, // Exemplo: BH
      'descricao': 'Pacote médio',
      'preco': 30.00,
      'destinatario': 'Ana',
      'data': '10/05/2025',
      'status': 'Entregue',
    },
    {
      'id': 102,
      'origemEndereco': 'Rua Azul, 123',
      'origemLat': -23.5505,
      'origemLng': -46.6333, // Exemplo: SP
      'destinoEndereco': 'Rua Verde, 456',
      'destinoLat': -23.5596,
      'destinoLng': -46.6252, // Exemplo: SP
      'descricao': 'Documento importante',
      'preco': 20.00,
      'destinatario': 'Pedro',
      'data': '08/05/2025',
      'status': 'Pendente',
    },
  ];


  Widget buildHistoryCard(BuildContext context, Map<String, dynamic> entrega) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DriverDeliveryDetailsScreen(entrega: entrega),
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
                    entrega['status'] == 'Entregue' ? Icons.check_circle : Icons.error,
                    color: entrega['status'] == 'Entregue' ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    entrega['status'],
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: entrega['status'] == 'Entregue' ? Colors.green : Colors.red,
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
                    'Data: ${entrega['data']}',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    'Origem: ${entrega['origemEndereco']}',
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
                    'Valor: R\$ ${entrega['preco']}',
                    style: textTheme.bodyMedium,
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
          children: mockHistorico
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