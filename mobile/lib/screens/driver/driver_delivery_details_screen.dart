import 'package:delivery/database/repository/OrderRepository.dart';
import 'package:delivery/models/address.dart';
import 'package:delivery/models/order.dart';
import 'package:delivery/screens/driver/driver_end_delivey.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // Adicionado o pacote geolocator
import 'package:flutter/services.dart';

class DriverDeliveryDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> encomenda;

  const DriverDeliveryDetailsScreen({super.key, required this.encomenda});

  @override
  State<DriverDeliveryDetailsScreen> createState() =>
      _DriverDeliveryDetailsScreenState();
}

class _DriverDeliveryDetailsScreenState
    extends State<DriverDeliveryDetailsScreen> {
  bool _isImageExpanded = false;
  LatLng? _currentPosition; // Para armazenar a posição atual
  bool _isLoadingLocation = true; // Indicador de carregamento da posição
  final MapController _mapController = MapController(); // Controlador do mapa

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Obter a localização atual ao iniciar a tela
  }

  // Função para solicitar e verificar permissões de localização
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se o serviço de localização está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Os serviços de localização estão desativados. Por favor, ative-os.')));
      return false;
    }

    // Verifica as permissões de localização
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissões de localização negadas')));
        return false;
      }
    }

    // Se a permissão for permanentemente negada
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Permissões de localização permanentemente negadas. Por favor, habilite-as nas configurações.')));
      return false;
    }

    return true;
  }

  // Função para obter a localização atual
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      setState(() {
        _isLoadingLocation = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Centralize o mapa na posição atual, se disponível
      if (_currentPosition != null) {
        _mapController.move(_currentPosition!, 15.0);
      }
    } on PlatformException catch (e) {
      debugPrint('Erro ao obter localização: ${e.message}');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  // Botão para centralizar o mapa na localização atual
  Widget _buildLocationButton() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton(
        heroTag: 'locationButton',
        backgroundColor: Colors.white,
        mini: true,
        onPressed: () {
          if (_currentPosition != null) {
            _mapController.move(_currentPosition!, 15.0);
          } else {
            _getCurrentLocation();
          }
        },
        child: Icon(
          Icons.my_location,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

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

  String getStatusText(String status) {
    switch (status) {
      case 'DELIVERIED':
        return 'Entregue';
      case 'PENDING':
        return 'Pendente';
      case 'ON_COURSE':
        return 'Em Rota';
      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'DELIVERIED':
        return Colors.green;
      case 'PENDING':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final isDelivered = widget.encomenda['status'] == 'DELIVERIED';
    final statusText = getStatusText(widget.encomenda['status']);
    final statusColor = getStatusColor(widget.encomenda['status']);
    final formattedDate = getFormattedDate(widget.encomenda['data']);

    // Coordenadas da entrega
    final LatLng origem = LatLng(
      widget.encomenda['originAddress']['latitude'],
      widget.encomenda['originAddress']['longitude'],
    );

    final LatLng destino = LatLng(
      widget.encomenda['destinationAddress']['latitude'],
      widget.encomenda['destinationAddress']['longitude'],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Encomenda'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Parte superior fixa (status e data)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            color: colorScheme.primary.withOpacity(0.05),
            child: Row(
              children: [
                // Status badge
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDelivered
                              ? Icons.check_circle
                              : Icons.pending_actions,
                          color: statusColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Data
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data:',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Conteúdo com rolagem
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3. Mapa (área central, destaque visual)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rota no Mapa',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 220,
                              width: double.infinity,
                              child: Stack(
                                children: [
                                  FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      center: _currentPosition ?? origem,
                                      zoom: 13.0,
                                      minZoom: 10.0,
                                      maxZoom: 18.0,
                                      interactiveFlags: InteractiveFlag.all,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        subdomains: ['a', 'b', 'c'],
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: origem,
                                            width: 60,
                                            height: 60,
                                            child: const Icon(
                                              Icons.location_on,
                                              color: Colors.blue,
                                              size: 32,
                                            ),
                                          ),
                                          Marker(
                                            point: destino,
                                            width: 60,
                                            height: 60,
                                            child: const Icon(
                                              Icons.flag,
                                              color: Colors.red,
                                              size: 32,
                                            ),
                                          ),
                                          // Marcador da posição atual
                                          if (_currentPosition != null)
                                            Marker(
                                              point: _currentPosition!,
                                              width: 60,
                                              height: 60,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.7),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.person_pin_circle,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // Indicador de carregamento
                                  if (_isLoadingLocation)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black12,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                  // Botão de localização
                                  _buildLocationButton(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. Informações da entrega
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informações da Entrega',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Origem
                            _buildInfoRow(
                              context,
                              Icons.location_on,
                              'Origem',
                              getFormattedAddress(
                                widget.encomenda['originAddress'],
                              ),
                              Colors.blue,
                            ),
                            const SizedBox(height: 16),

                            // Destino
                            _buildInfoRow(
                              context,
                              Icons.flag,
                              'Destino',
                              getFormattedAddress(
                                widget.encomenda['destinationAddress'],
                              ),
                              Colors.red,
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Divider(height: 1),
                            ),

                            // Descrição
                            _buildInfoRow(
                              context,
                              Icons.description,
                              'Descrição',
                              widget.encomenda['description'],
                              Colors.grey,
                            ),
                            const SizedBox(height: 16),

                            // Destinatário
                            _buildInfoRow(
                              context,
                              Icons.person,
                              'Destinatário',
                              widget.encomenda['destinatario'],
                              Colors.grey,
                            ),
                            const SizedBox(height: 16),

                            // Valor
                            _buildInfoRow(
                              context,
                              Icons.monetization_on,
                              'Valor',
                              'R\$ ${widget.encomenda['preco'].toStringAsFixed(2)}',
                              Colors.green,
                              isValueField: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 5. Imagem do Produto (somente se entregue e imagem presente)
                  if (widget.encomenda['imageUrl'] != null &&
                      widget.encomenda['imageUrl'].toString().isNotEmpty &&
                      widget.encomenda['status'] == 'DELIVERIED')
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildExpandableImageSection(context),
                    ),

                  // Botão de Finalizar Entrega (visível apenas se status for ON_COURSE)
                  if (widget.encomenda['status'] == 'ON_COURSE')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            // Conferir se está funcionando aqui depois de criar a tela
                            MaterialPageRoute(
                              builder:
                                  (_) => FinalizarEntregaScreen(
                                //A encomenda está sendo mockada no momento
                                encomenda: Order(
                                  id: 1,
                                  description: "Entrega de livros",

                                  status: OrderStatus.ON_COURSE,

                                  originAddress: Address(
                                    street: "Rua das Flores",
                                    number: "123",
                                    neighborhood: "Centro",
                                    city: "Cidade Exemplo",
                                    latitude: -23.55052,
                                    longitude: -46.633308,
                                    id: 1,
                                  ),
                                  destinationAddress: Address(
                                    street: "Avenida Brasil",
                                    number: "456",
                                    neighborhood: "Jardim América",
                                    city: "Cidade Exemplo",
                                    latitude: -23.559616,
                                    longitude: -46.658917,
                                    id: 1,
                                  ),
                                  imageUrl:
                                  "https://via.placeholder.com/300x200.png?text=Produto",
                                  customerId: 1,
                                ),
                                repository: OrderRepository(),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Finalizar Entrega'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      Color iconColor, {
        bool isValueField = false,
      }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style:
                isValueField
                    ? textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                )
                    : textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableImageSection(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final imageUrl = widget.encomenda['imageUrl'];
    final hasValidImageUrl =
        imageUrl != null && imageUrl.toString().startsWith('http');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          setState(() {
            _isImageExpanded = !_isImageExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.image,
                      color: Colors.purple,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ver Imagem do Produto',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _isImageExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
            if (_isImageExpanded && hasValidImageUrl)
              GestureDetector(
                onTap: () => _showFullScreenImage(context, imageUrl),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 350),
                  padding: const EdgeInsets.only(
                    bottom: 16.0,
                    left: 16.0,
                    right: 16.0,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Não foi possível carregar a imagem',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32.0),
                            child: CircularProgressIndicator(
                              value:
                              loadingProgress.expectedTotalBytes != null
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Imagem não disponível ou formato inválido',
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
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
                errorBuilder:
                    (context, error, stackTrace) => Icon(
                  Icons.broken_image,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 100,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}