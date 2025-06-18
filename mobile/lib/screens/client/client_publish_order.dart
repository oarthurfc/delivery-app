import 'package:delivery/services/api/repos/OrderRepository2.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/address.dart';
import '../../models/order.dart';
import '../../widgets/common/app_bar_widget.dart';

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
  
  final OrderRepository2 _orderRepository = OrderRepository2();
  
  bool _isLoading = false;
  String? _errorMessage;

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

  Future<void> _publishOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obter ID do usuário atual
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');
      
      if (userId == null) {
        throw Exception('Usuário não encontrado');
      }

      // Obter coordenadas dos endereços
      final originCoords = await _getCoordinatesFromAddress(_originController.text);
      final destCoords = await _getCoordinatesFromAddress(_destinationController.text);
      
      if (originCoords == null || destCoords == null) {
        throw Exception('Não foi possível localizar um dos endereços');
      }

      // Criar endereços
      final originParts = _originController.text.split(',');
      final originAddress = Address(
        id: 0, // ID será definido pelo backend
        street: originParts.isNotEmpty ? originParts[0].trim() : _originController.text,
        number: originParts.length > 1 ? originParts[1].trim() : '',
        neighborhood: originParts.length > 2 ? originParts[2].trim() : '',
        city: originParts.length > 3 ? originParts[3].trim() : '',
        latitude: originCoords['latitude']!,
        longitude: originCoords['longitude']!,
      );

      final destParts = _destinationController.text.split(',');
      final destinationAddress = Address(
        id: 0, // ID será definido pelo backend
        street: destParts.isNotEmpty ? destParts[0].trim() : _destinationController.text,
        number: destParts.length > 1 ? destParts[1].trim() : '',
        neighborhood: destParts.length > 2 ? destParts[2].trim() : '',
        city: destParts.length > 3 ? destParts[3].trim() : '',
        latitude: destCoords['latitude']!,
        longitude: destCoords['longitude']!,
      );

      // Criar novo pedido
      final order = Order(
        id: 0, // ID será definido pelo backend
        customerId: userId,
        status: OrderStatus.PENDING,
        originAddress: originAddress,
        destinationAddress: destinationAddress,
        description: _descriptionController.text,
        imageUrl: '',
      );
      
      // Enviar para o backend via API
      final createdOrder = await _orderRepository.save(order);
      
      print('Pedido criado com sucesso: ID ${createdOrder.id}');

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
      });
      print('Erro ao publicar pedido: $e');
      
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

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
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
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Publicando pedido...'),
                ],
              ),
            )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
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
                        ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _destinationController,
                        decoration: const InputDecoration(
                          labelText: 'Endereço do destinatário',
                          hintText: 'Rua das Alvoradas, 244, Centro - Belo Horizonte',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, informe o endereço do destinatário';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _originController,
                        decoration: const InputDecoration(
                          labelText: 'Endereço do remetente',
                          hintText: 'Rua das Alvoradas, 244, Centro - Belo Horizonte',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.my_location),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, informe o endereço do remetente';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descrição da encomenda',
                          border: OutlineInputBorder(),
                          hintText: 'Chave do carro',
                          hintStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, descreva a encomenda';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _publishOrder,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 18),
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
                              : const Text('Publicar encomenda'),
                        ),
                      ),
                    ],
                  ),
                ),
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