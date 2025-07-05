import 'package:delivery/services/api/repos/OrderRepository2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../models/address.dart';
import '../../models/order.dart';
import '../../widgets/common/app_bar_widget.dart';

enum PublishOrderStep {
  selectAddresses,
  confirmAddresses,
  addDescription,
  publishing
}

class PublishOrderScreen extends StatefulWidget {
  const PublishOrderScreen({super.key});

  @override
  State<PublishOrderScreen> createState() => _PublishOrderScreenState();
}

class _PublishOrderScreenState extends State<PublishOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final MapController _mapController = MapController();
  
  final OrderRepository2 _orderRepository = OrderRepository2();
  
  // Controle de etapas
  PublishOrderStep _currentStep = PublishOrderStep.selectAddresses;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Variáveis para o mapa
  LatLng? _originLatLng;
  LatLng? _destinationLatLng;
  List<LatLng> _routePoints = [];
  
  // Variáveis para autocomplete
  List<String> _originSuggestions = [];
  List<String> _destinationSuggestions = [];
  bool _showOriginSuggestions = false;
  bool _showDestinationSuggestions = false;
  
  // Foco dos campos
  final FocusNode _originFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    _originFocusNode.addListener(() {
      if (!_originFocusNode.hasFocus) {
        setState(() {
          _showOriginSuggestions = false;
        });
      }
    });
    
    _destinationFocusNode.addListener(() {
      if (!_destinationFocusNode.hasFocus) {
        setState(() {
          _showDestinationSuggestions = false;
        });
      }
    });
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case PublishOrderStep.selectAddresses:
        return 'Selecione os endereços';
      case PublishOrderStep.confirmAddresses:
        return 'Confirme os endereços';
      case PublishOrderStep.addDescription:
        return 'Descreva a encomenda';
      case PublishOrderStep.publishing:
        return 'Publicando encomenda';
    }
  }

  bool _canEditAddresses() {
    return _currentStep == PublishOrderStep.selectAddresses;
  }

  bool _canEditDescription() {
    return _currentStep == PublishOrderStep.addDescription;
  }

  Future<List<String>> _getAddressSuggestions(String query) async {
    if (query.length < 3) return [];
    
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=5&countrycodes=br'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item['display_name'].toString()).toList();
      }
    } catch (e) {
      print('Erro ao buscar sugestões: $e');
    }
    return [];
  }

  Future<void> _onOriginChanged(String value) async {
    if (!_canEditAddresses()) return;
    
    if (value.length >= 3) {
      final suggestions = await _getAddressSuggestions(value);
      setState(() {
        _originSuggestions = suggestions;
        _showOriginSuggestions = true;
      });
    } else {
      setState(() {
        _showOriginSuggestions = false;
      });
    }
  }

  Future<void> _onDestinationChanged(String value) async {
    if (!_canEditAddresses()) return;
    
    if (value.length >= 3) {
      final suggestions = await _getAddressSuggestions(value);
      setState(() {
        _destinationSuggestions = suggestions;
        _showDestinationSuggestions = true;
      });
    } else {
      setState(() {
        _showDestinationSuggestions = false;
      });
    }
  }

  Future<Map<String, double>?> _getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
      }
      return null;
    } catch (e) {
      print('Erro ao obter coordenadas: $e');
      return null;
    }
  }

  Future<void> _updateMapWithAddress(String address, bool isOrigin) async {
    final coords = await _getCoordinatesFromAddress(address);
    if (coords != null) {
      final latLng = LatLng(coords['latitude']!, coords['longitude']!);
      
      setState(() {
        if (isOrigin) {
          _originLatLng = latLng;
        } else {
          _destinationLatLng = latLng;
        }
      });
    }
  }

  Future<void> _updateRoute() async {
    if (_originLatLng != null && _destinationLatLng != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.get(
          Uri.parse('https://router.project-osrm.org/route/v1/driving/'
              '${_originLatLng!.longitude},${_originLatLng!.latitude};'
              '${_destinationLatLng!.longitude},${_destinationLatLng!.latitude}'
              '?overview=full&geometries=geojson'),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['routes'].isNotEmpty) {
            final route = data['routes'][0];
            final geometry = route['geometry']['coordinates'] as List;
            
            setState(() {
              _routePoints = geometry
                  .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
                  .toList();
            });
            
            _centerMapOnPoints();
          }
        }
      } catch (e) {
        print('Erro ao calcular rota: $e');
        setState(() {
          _errorMessage = 'Erro ao calcular rota. Tente novamente.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _centerMapOnPoints() {
    if (_originLatLng != null && _destinationLatLng != null) {
      final bounds = LatLngBounds.fromPoints([_originLatLng!, _destinationLatLng!]);
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
    } else if (_originLatLng != null) {
      _mapController.move(_originLatLng!, 15);
    } else if (_destinationLatLng != null) {
      _mapController.move(_destinationLatLng!, 15);
    }
  }

  Future<void> _nextStep() async {
    setState(() {
      _errorMessage = null;
    });

    switch (_currentStep) {
      case PublishOrderStep.selectAddresses:
        if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
          setState(() {
            _errorMessage = 'Por favor, preencha ambos os endereços';
          });
          return;
        }
        
        // Obter coordenadas e calcular rota
        await _updateMapWithAddress(_originController.text, true);
        await _updateMapWithAddress(_destinationController.text, false);
        await _updateRoute();
        
        setState(() {
          _currentStep = PublishOrderStep.confirmAddresses;
        });
        break;
        
      case PublishOrderStep.confirmAddresses:
        setState(() {
          _currentStep = PublishOrderStep.addDescription;
        });
        // Focar no campo de descrição
        Future.delayed(const Duration(milliseconds: 100), () {
          _descriptionFocusNode.requestFocus();
        });
        break;
        
      case PublishOrderStep.addDescription:
        if (_descriptionController.text.isEmpty) {
          setState(() {
            _errorMessage = 'Por favor, descreva a encomenda';
          });
          return;
        }
        await _publishOrder();
        break;
        
      case PublishOrderStep.publishing:
        break;
    }
  }

  void _previousStep() {
    setState(() {
      _errorMessage = null;
    });

    switch (_currentStep) {
      case PublishOrderStep.confirmAddresses:
        setState(() {
          _currentStep = PublishOrderStep.selectAddresses;
          // Limpar rota e pontos do mapa
          _routePoints.clear();
          _originLatLng = null;
          _destinationLatLng = null;
        });
        break;
        
      case PublishOrderStep.addDescription:
        setState(() {
          _currentStep = PublishOrderStep.confirmAddresses;
        });
        break;
        
      default:
        break;
    }
  }

  Future<void> _publishOrder() async {
    setState(() {
      _currentStep = PublishOrderStep.publishing;
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');
      
      if (userId == null) {
        throw Exception('Usuário não encontrado');
      }

      final originCoords = await _getCoordinatesFromAddress(_originController.text);
      final destCoords = await _getCoordinatesFromAddress(_destinationController.text);
      
      if (originCoords == null || destCoords == null) {
        throw Exception('Não foi possível localizar um dos endereços');
      }

      final originParts = _originController.text.split(',');
      final originAddress = Address(
        id: 0,
        street: originParts.isNotEmpty ? originParts[0].trim() : _originController.text,
        number: originParts.length > 1 ? originParts[1].trim() : '',
        neighborhood: originParts.length > 2 ? originParts[2].trim() : '',
        city: originParts.length > 3 ? originParts[3].trim() : '',
        latitude: originCoords['latitude']!,
        longitude: originCoords['longitude']!,
      );

      final destParts = _destinationController.text.split(',');
      final destinationAddress = Address(
        id: 0,
        street: destParts.isNotEmpty ? destParts[0].trim() : _destinationController.text,
        number: destParts.length > 1 ? destParts[1].trim() : '',
        neighborhood: destParts.length > 2 ? destParts[2].trim() : '',
        city: destParts.length > 3 ? destParts[3].trim() : '',
        latitude: destCoords['latitude']!,
        longitude: destCoords['longitude']!,
      );

      final order = Order(
        id: 0,
        customerId: userId,
        status: OrderStatus.PENDING,
        originAddress: originAddress,
        destinationAddress: destinationAddress,
        description: _descriptionController.text,
        imageUrl: '',
      );
      
      final createdOrder = await _orderRepository.save(order);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido publicado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao publicar pedido: $e';
        _currentStep = PublishOrderStep.addDescription;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao publicar pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildAddressField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required String hintText,
    required IconData icon,
    required Function(String) onChanged,
    required List<String> suggestions,
    required bool showSuggestions,
    required bool isOrigin,
  }) {
    final bool isEnabled = _canEditAddresses();
    
    return Column(
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: isEnabled,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            border: const OutlineInputBorder(),
            prefixIcon: Icon(icon),
            suffixIcon: controller.text.isNotEmpty && isEnabled
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      setState(() {
                        if (isOrigin) {
                          _originLatLng = null;
                          _showOriginSuggestions = false;
                        } else {
                          _destinationLatLng = null;
                          _showDestinationSuggestions = false;
                        }
                        _routePoints.clear();
                      });
                    },
                  )
                : null,
          ),
          onChanged: isEnabled ? onChanged : null,
        ),
        if (showSuggestions && suggestions.isNotEmpty && isEnabled)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on, size: 16),
                  title: Text(
                    suggestions[index],
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () {
                    controller.text = suggestions[index];
                    setState(() {
                      if (isOrigin) {
                        _showOriginSuggestions = false;
                      } else {
                        _showDestinationSuggestions = false;
                      }
                    });
                    focusNode.unfocus();
                    _updateMapWithAddress(suggestions[index], isOrigin);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Indicador de progresso
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              _buildStepIndicator(1, _currentStep.index >= 0),
              Expanded(child: _buildStepConnector(_currentStep.index >= 1)),
              _buildStepIndicator(2, _currentStep.index >= 1),
              Expanded(child: _buildStepConnector(_currentStep.index >= 2)),
              _buildStepIndicator(3, _currentStep.index >= 2),
            ],
          ),
        ),
        
        // Título da etapa
        Text(
          _getStepTitle(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        // Mensagem de erro
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
          ),
        
        // Campos de endereço (sempre visíveis)
        _buildAddressField(
          controller: _originController,
          focusNode: _originFocusNode,
          labelText: 'Endereço do remetente',
          hintText: 'Rua das Alvoradas, 244, Centro - Belo Horizonte',
          icon: Icons.my_location,
          onChanged: _onOriginChanged,
          suggestions: _originSuggestions,
          showSuggestions: _showOriginSuggestions,
          isOrigin: true,
        ),
        const SizedBox(height: 16),
        
        _buildAddressField(
          controller: _destinationController,
          focusNode: _destinationFocusNode,
          labelText: 'Endereço do destinatário',
          hintText: 'Rua das Alvoradas, 244, Centro - Belo Horizonte',
          icon: Icons.location_on,
          onChanged: _onDestinationChanged,
          suggestions: _destinationSuggestions,
          showSuggestions: _showDestinationSuggestions,
          isOrigin: false,
        ),
        
        // Campo de descrição (só aparece na etapa de descrição)
        if (_currentStep.index >= 2) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            focusNode: _descriptionFocusNode,
            enabled: _canEditDescription(),
            decoration: const InputDecoration(
              labelText: 'Descrição da encomenda',
              border: OutlineInputBorder(),
              hintText: 'Chave do carro',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
          ),
        ],
        
        const SizedBox(height: 24),
        
        // Botões de navegação
        Row(
          children: [
            if (_currentStep != PublishOrderStep.selectAddresses)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Voltar'),
                ),
              ),
            if (_currentStep != PublishOrderStep.selectAddresses)
              const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_getNextButtonText()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int step, bool isCompleted) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? Colors.blue : Colors.grey.shade300,
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: TextStyle(
            color: isCompleted ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStepConnector(bool isCompleted) {
    return Container(
      height: 2,
      color: isCompleted ? Colors.blue : Colors.grey.shade300,
    );
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case PublishOrderStep.selectAddresses:
        return 'Próxima etapa';
      case PublishOrderStep.confirmAddresses:
        return 'Confirmar endereços';
      case PublishOrderStep.addDescription:
        return 'Publicar encomenda';
      case PublishOrderStep.publishing:
        return 'Publicando...';
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    _originFocusNode.dispose();
    _destinationFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publique uma encomenda'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Mapa (sempre visível, parte superior)
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(-19.9167, -43.9345), // Belo Horizonte
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.delivery',
                  ),
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 4.0,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (_originLatLng != null)
                        Marker(
                          point: _originLatLng!,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      if (_destinationLatLng != null)
                        Marker(
                          point: _destinationLatLng!,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Formulário das etapas (parte inferior, scrollável)
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildStepContent(),
            ),
          ),
        ],
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