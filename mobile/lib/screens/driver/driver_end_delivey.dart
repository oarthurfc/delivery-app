import 'dart:io';
import 'package:delivery/database/repository/OrderRepository.dart';
import 'package:delivery/models/order.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class DriverEndDeliveryScreen extends StatefulWidget {
  final Order order;

  const DriverEndDeliveryScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<DriverEndDeliveryScreen> createState() => _DriverEndDeliveryScreenState();
}

class _DriverEndDeliveryScreenState extends State<DriverEndDeliveryScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  File? _capturedImage;
  final _picker = ImagePicker();
  bool _isSaving = false;
  String? _currentAddress;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      setState(() {
        _currentPosition = position;
      });
      
      // Obter o endereço atual baseado nas coordenadas
      _getAddressFromLatLng(position);
    } catch (e) {
      print('Erro ao obter localização: $e');
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = 
              '${place.street}, ${place.subThoroughfare}, ${place.subLocality}, '
              '${place.locality}, ${place.postalCode}, ${place.country}';
        });
      }
    } catch (e) {
      print('Erro ao obter endereço: $e');
    }
  }

  Future<void> _takePicture() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _capturedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _finishDelivery() async {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture uma imagem antes de finalizar.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Atualizar o status do pedido para entregue
      final order = widget.order;
      order.status = OrderStatus.DELIVERIED;
      
      // Armazenar a imagem de confirmação
      // Nota: Em um aplicativo real, você provavelmente faria upload da imagem para um servidor
      // e armazenaria a URL da imagem no pedido
      
      await _orderRepository.update(order);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrega finalizada com sucesso!')),
      );
      
      // Retornar true para a tela anterior indicando sucesso
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao finalizar entrega: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Entrega'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _isSaving 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Finalizando entrega...'),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirme a entrega',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Informações da localização atual
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sua localização atual:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _currentPosition != null
                          ? Text(
                              'Coordenadas: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
                              style: const TextStyle(fontSize: 14),
                            )
                          : const Text('Obtendo localização...'),
                      const SizedBox(height: 4),
                      if (_currentAddress != null)
                        Text(
                          'Endereço: $_currentAddress',
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Captura de imagem para confirmação
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Capture uma foto da entrega',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_capturedImage != null)
                        Image.file(
                          _capturedImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.camera_alt,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _takePicture,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tirar Foto'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Botão de finalização
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _capturedImage != null ? _finishDelivery : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: const Text(
                      'CONFIRMAR ENTREGA',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
