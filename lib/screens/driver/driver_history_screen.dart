import 'package:flutter/material.dart';
import '../../widgets/common/app_bar_widget.dart';

class DriverHistoryScreen extends StatelessWidget {
  const DriverHistoryScreen({super.key});

  final List<Map<String, dynamic>> mockHistorico = const [
    {
      'id': 101,
      'origem': 'Rua das Palmeiras, 45',
      'destino': 'Av. Central, 789',
      'descricao': 'Pacote médio',
      'preco': 30.00,
      'destinatario': 'Ana',
      'data': '10/05/2025',
      'status': 'Entregue',
    },
    {
      'id': 102,
      'origem': 'Rua Azul, 123',
      'destino': 'Rua Verde, 456',
      'descricao': 'Documento importante',
      'preco': 20.00,
      'destinatario': 'Pedro',
      'data': '08/05/2025',
      'status': 'Pendente',
    },
  ];

  Widget buildHistoryCard(BuildContext context, Map<String, dynamic> entrega) {
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
            // Título do Card
            Text(
              'Entrega Número: ${entrega['id']}',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            // Status da entrega
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
                  'Origem: ${entrega['origem']}',
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
                  'Valor recebido: R\$ ${entrega['preco']}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ],
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
