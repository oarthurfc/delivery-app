import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/order.dart';

class CustomerDeliveryDetailsScreen extends StatefulWidget {
  final Order order;

  const CustomerDeliveryDetailsScreen({super.key, required this.order});

  @override
  State<CustomerDeliveryDetailsScreen> createState() => _CustomerDeliveryDetailsScreenState();
}

class _CustomerDeliveryDetailsScreenState extends State<CustomerDeliveryDetailsScreen> {
  bool _isImageExpanded = false;

  String getFormattedAddress(address) {
    return '${address.street}, ${address.number} - ${address.neighborhood}, ${address.city}';
  }

  String getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.DELIVERIED:
        return 'Entregue';
      case OrderStatus.PENDING:
        return 'Pendente';
      case OrderStatus.ACCEPTED:
        return 'Aceito';
      case OrderStatus.ON_COURSE:
        return 'Em transporte';
    }
  }

  Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.DELIVERIED:
        return Colors.green;
      case OrderStatus.PENDING:
        return Colors.amber;
      case OrderStatus.ACCEPTED:
        return Colors.blue;
      case OrderStatus.ON_COURSE:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final textTheme = Theme.of(context).textTheme;
    final statusText = getStatusText(order.status);
    final statusColor = getStatusColor(order.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Entrega'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mapa mostrando a rota
            SizedBox(
              height: 250,
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(
                    (order.originAddress.latitude + order.destinationAddress.latitude) / 2,
                    (order.originAddress.longitude + order.destinationAddress.longitude) / 2,
                  ),
                  zoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                  ),                  MarkerLayer(
                    markers: [
                      // Marcador de origem
                      Marker(
                        point: LatLng(
                          order.originAddress.latitude,
                          order.originAddress.longitude,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                      // Marcador de destino
                      Marker(
                        point: LatLng(
                          order.destinationAddress.latitude,
                          order.destinationAddress.longitude,
                        ),
                        child: const Icon(
                          Icons.flag,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                  // Linha conectando origem e destino
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          LatLng(
                            order.originAddress.latitude,
                            order.originAddress.longitude,
                          ),
                          LatLng(
                            order.destinationAddress.latitude,
                            order.destinationAddress.longitude,
                          ),
                        ],
                        strokeWidth: 4,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Informações do pedido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status da entrega
                  Row(
                    children: [
                      Icon(
                        order.status == OrderStatus.DELIVERIED 
                            ? Icons.check_circle 
                            : Icons.delivery_dining,
                        color: statusColor,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Status: $statusText',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Descrição do pedido
                  Text(
                    'Descrição:',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.description,
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),

                  // Endereço de origem
                  Text(
                    'Endereço de Coleta:',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getFormattedAddress(order.originAddress),
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),

                  // Endereço de destino
                  Text(
                    'Endereço de Entrega:',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getFormattedAddress(order.destinationAddress),
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),

                  // Imagem da encomenda
                  if (order.imageUrl.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Imagem da Encomenda:',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isImageExpanded = !_isImageExpanded;
                            });
                          },
                          child: order.imageUrl.startsWith('http')
                              ? Image.network(
                                  order.imageUrl,
                                  width: double.infinity,
                                  height: _isImageExpanded ? null : 200,
                                  fit: _isImageExpanded ? BoxFit.contain : BoxFit.cover,
                                )
                              : Image.file(
                                  File(order.imageUrl),
                                  width: double.infinity,
                                  height: _isImageExpanded ? null : 200,
                                  fit: _isImageExpanded ? BoxFit.contain : BoxFit.cover,
                                ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}