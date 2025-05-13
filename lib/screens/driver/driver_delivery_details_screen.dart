import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DriverDeliveryDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> encomenda;

  const DriverDeliveryDetailsScreen({super.key, required this.encomenda});

  @override
  State<DriverDeliveryDetailsScreen> createState() => _DriverDeliveryDetailsScreenState();
}

class _DriverDeliveryDetailsScreenState extends State<DriverDeliveryDetailsScreen> {
  // Controla a expansão da imagem
  bool _isImageExpanded = false;

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
        widget.encomenda['originAddress']['latitude'],
        widget.encomenda['originAddress']['longitude']
    );

    final LatLng destino = LatLng(
        widget.encomenda['destinationAddress']['latitude'],
        widget.encomenda['destinationAddress']['longitude']
    );

    final isDelivered = widget.encomenda['status'] == 'DELIVERIED';
    final statusText = getStatusText(widget.encomenda['status']);
    final formattedDate = getFormattedDate(widget.encomenda['data']);

    return Scaffold(
      appBar: AppBar(
        title: Text('Entrega n°${widget.encomenda['id']}'),
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
              'Origem: ${getFormattedAddress(widget.encomenda['originAddress'])}',
            ),
            _buildDetailCard(
              context,
              Icons.location_on_outlined,
              'Destino: ${getFormattedAddress(widget.encomenda['destinationAddress'])}',
            ),
            _buildDetailCard(
              context,
              Icons.description,
              'Descrição: ${widget.encomenda['description']}',
            ),
            _buildDetailCard(
              context,
              Icons.account_circle,
              'Destinatário: ${widget.encomenda['destinatario']}',
            ),
            _buildDetailCard(
              context,
              Icons.monetization_on,
              'Valor: R\$ ${widget.encomenda['preco'].toStringAsFixed(2)}',
            ),
            if (widget.encomenda['imageUrl'] != null)
              _buildExpandableImageCard(context),
          ],
        ),
      ),
    );
  }

  // Card expandível para a imagem
  Widget _buildExpandableImageCard(BuildContext context) {
    final imageUrl = widget.encomenda['imageUrl'];
    final hasValidImageUrl = imageUrl != null && imageUrl.toString().startsWith('http');

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _isImageExpanded = !_isImageExpanded;
          });
        },
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.image, size: 30, color: Colors.grey),
              title: const Text('Imagem disponível', style: TextStyle(fontSize: 16)),
              trailing: Icon(
                _isImageExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.grey,
              ),
            ),
            if (_isImageExpanded && hasValidImageUrl)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GestureDetector(
                  onTap: () {
                    // Opcionalmente, você pode adicionar um visualizador de imagem em tela cheia aqui
                    _showFullScreenImage(context, imageUrl);
                  },
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Icon(Icons.broken_image, color: Colors.grey, size: 64),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            if (_isImageExpanded && !hasValidImageUrl)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Imagem não disponível ou formato inválido',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Método para exibir a imagem em tela cheia
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Visualização da imagem'),
            backgroundColor: Colors.black,
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(20.0),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, color: Colors.white, size: 100),
              ),
            ),
          ),
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