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

  Widget buildOrderCard(Map<String, dynamic> encomenda) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Origem: ${encomenda['origem']}'),
            Text('Destino: ${encomenda['destino']}'),
            Text('Descrição: ${encomenda['descricao']}'),
            Text('Destinatário: ${encomenda['destinatario']}'),
            Text('Preço: R\$ ${encomenda['preco']}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Ação para aceitar a encomenda
              },
              child: const Text('Aceitar encomenda'),
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
        title: const Text('Encomendas disponíveis'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: mockOrders.map(buildOrderCard).toList(),
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

