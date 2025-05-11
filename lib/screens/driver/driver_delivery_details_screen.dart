import 'package:flutter/material.dart';

class DriverDeliveryDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> entrega;

  const DriverDeliveryDetailsScreen({super.key, required this.entrega});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Encomenda'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entrega #${entrega['id']}',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            detailItem(Icons.access_time, 'Data: ${entrega['data']}'),
            detailItem(Icons.location_on, 'Origem: ${entrega['origem']}'),
            detailItem(Icons.location_on_outlined, 'Destino: ${entrega['destino']}'),
            detailItem(Icons.description, 'Descrição: ${entrega['descricao']}'),
            detailItem(Icons.account_circle, 'Destinatário: ${entrega['destinatario']}'),
            detailItem(Icons.monetization_on, 'Valor: R\$ ${entrega['preco']}'),
            detailItem(
              entrega['status'] == 'Entregue' ? Icons.check_circle : Icons.error,
              'Status: ${entrega['status']}',
              iconColor: entrega['status'] == 'Entregue' ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget detailItem(IconData icon, String text, {Color iconColor = Colors.grey}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
