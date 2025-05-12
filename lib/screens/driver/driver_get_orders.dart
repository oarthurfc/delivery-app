import 'package:flutter/material.dart';
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
    },
    {
      'id': 2,
      'origem': 'Av. Paulista, 1000',
      'destino': 'Rua das Flores, 200',
      'descricao': 'Envelope com documentos',
      'preco': 15.50,
      'destinatario': 'Maria',
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
                onPressed: () {
                  // Ação para aceitar a encomenda
                },
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