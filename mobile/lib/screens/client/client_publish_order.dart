import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/repository/OrderRepository.dart';
import '../../database/repository/address_repository.dart';
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
  final _priceController = TextEditingController();
  final _receiverController = TextEditingController();
  
  final OrderRepository _orderRepository = OrderRepository();
  final AddressRepository _addressRepository = AddressRepository();
  
  File? _imageFile;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
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

      // Criar endereço de origem
      final originParts = _originController.text.split(',');
      final originAddress = Address(
        id: DateTime.now().millisecondsSinceEpoch,
        street: originParts.isNotEmpty ? originParts[0].trim() : _originController.text,
        number: originParts.length > 1 ? originParts[1].trim() : '',
        neighborhood: originParts.length > 2 ? originParts[2].trim() : '',
        city: originParts.length > 3 ? originParts[3].trim() : '',
        latitude: originCoords['latitude']!,
        longitude: originCoords['longitude']!,
      );
      
      await _addressRepository.save(originAddress);

      // Criar endereço de destino
      final destParts = _destinationController.text.split(',');
      final destinationAddress = Address(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        street: destParts.isNotEmpty ? destParts[0].trim() : _destinationController.text,
        number: destParts.length > 1 ? destParts[1].trim() : '',
        neighborhood: destParts.length > 2 ? destParts[2].trim() : '',
        city: destParts.length > 3 ? destParts[3].trim() : '',
        latitude: destCoords['latitude']!,
        longitude: destCoords['longitude']!,
      );
      
      await _addressRepository.save(destinationAddress);

      // Criar novo pedido
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch + 2,
        customerId: userId,
        status: OrderStatus.PENDING,
        originAddress: originAddress,
        destinationAddress: destinationAddress,
        description: _descriptionController.text,
        imageUrl: _imageFile?.path ?? '',
      );
      
      await _orderRepository.save(order);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido publicado com sucesso!')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao publicar pedido: $e';
      });
      print('Erro ao publicar pedido: $e');
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
    _priceController.dispose();
    _receiverController.dispose();
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
          ? const Center(child: CircularProgressIndicator())
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
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
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
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, descreva a encomenda';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Preço',
                          prefixText: 'R\$ ',
                          hintText: '20,00',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, informe o preço';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _receiverController,
                        decoration: const InputDecoration(
                          labelText: 'Quem vai receber',
                          hintText: 'Maria Joaquina',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, informe quem vai receber';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Adicionar imagem'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      if (_imageFile != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Image.file(
                            _imageFile!,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _publishOrder,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                          child: const Text('Publicar encomenda'),
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