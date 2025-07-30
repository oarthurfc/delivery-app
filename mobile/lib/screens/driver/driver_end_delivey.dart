import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:delivery/database/repository/OrderRepository.dart';
import 'package:delivery/models/order.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:delivery/services/api/repos/OrderRepository2.dart';
import 'package:http/http.dart' as http;
import 'package:delivery/services/api/ApiService.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
  final OrderRepository2 _orderRepository = OrderRepository2();
  File? _capturedImage;
  File? _compressedImage;
  final _picker = ImagePicker();
  bool _isSaving = false;
  bool _isCompressing = false;
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

  Future<File?> _compressImage(File file) async {
    try {
      setState(() {
        _isCompressing = true;
      });

      // Obter diretório temporário
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = path.basename(file.path);
      final String targetPath = path.join(tempDir.path, 'compressed_$fileName');

      // Comprimir a imagem
      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70, // Qualidade de 0-100 (70% é um bom equilíbrio)
        minWidth: 800, // Largura máxima
        minHeight: 600, // Altura máxima
        format: CompressFormat.jpeg, // Formato JPEG é menor que PNG
      );

      if (compressedFile != null) {
        File compressed = File(compressedFile.path);
        
        // Verificar o tamanho do arquivo
        int originalSize = await file.length();
        int compressedSize = await compressed.length();
        
        print('Tamanho original: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');
        print('Tamanho comprimido: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
        print('Redução: ${((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1)}%');
        
        return compressed;
      }
      
      return null;
    } catch (e) {
      print('Erro ao comprimir imagem: $e');
      return null;
    } finally {
      setState(() {
        _isCompressing = false;
      });
    }
  }

  Future<void> _takePicture() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85, // Reduz qualidade na captura
      maxWidth: 1200,   // Limita largura
      maxHeight: 1200,  // Limita altura
    );
    
    if (pickedFile != null) {
      File originalFile = File(pickedFile.path);
      
      setState(() {
        _capturedImage = originalFile;
      });

      // Comprimir a imagem
      File? compressed = await _compressImage(originalFile);
      
      if (compressed != null) {
        setState(() {
          _compressedImage = compressed;
        });
      } else {
        // Se falhar na compressão, usar a original
        setState(() {
          _compressedImage = originalFile;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> fetchUserData(int userId) async {
    try {
      // Use o ApiService para buscar o usuário
      final apiService = ApiService();
      return await apiService.getUserById(userId);
    } catch (e) {
      print('Erro ao buscar dados do usuário $userId: $e');
      return null;
    }
  }

  Future<void> _finishDelivery() async {
    if (_compressedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture uma imagem antes de finalizar.')),
      );
      return;
    }

    // Verificar se os IDs não são nulos
    if (widget.order.customerId == null || widget.order.driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID do cliente ou motorista não encontrado.')),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final clienteData = await fetchUserData(widget.order.customerId!);
      final motoristaData = await fetchUserData(widget.order.driverId!);

      if (clienteData == null || motoristaData == null) {
        throw Exception('Não foi possível obter dados do cliente ou motorista.');
      }

      // Preparar dados
      final completeOrderData = {
        "clienteEmail": clienteData["email"],
        "motoristaEmail": motoristaData["email"],
        "fcmToken": clienteData["fcmToken"] ?? ""
      };

      print("BODY COMPLETE REQUEST: $completeOrderData");

      // Verificar tamanho do arquivo antes de enviar
      int fileSize = await _compressedImage!.length();
      print('Tamanho do arquivo a ser enviado: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      //CALL API com imagem comprimida
      final apiService = ApiService();
      final result = await apiService.completeOrderWithMultipart(
        widget.order.id, 
        completeOrderData, 
        _compressedImage! // Usar imagem comprimida
      );

      if (result == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrega finalizada com sucesso!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao finalizar entrega.')),
        );
      }
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

  String _getFileSizeText() {
    if (_compressedImage == null) return '';
    
    return FutureBuilder<int>(
      future: _compressedImage!.length(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          double sizeMB = snapshot.data! / 1024 / 1024;
          return Text('Tamanho: ${sizeMB.toStringAsFixed(2)} MB');
        }
        return const Text('Calculando tamanho...');
      },
    ).toString();
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
                      
                      if (_isCompressing)
                        const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Comprimindo imagem...'),
                          ],
                        )
                      else if (_capturedImage != null)
                        Column(
                          children: [
                            Image.file(
                              _capturedImage!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 8),
                            // Mostrar informação de tamanho
                            FutureBuilder<int>(
                              future: _compressedImage?.length(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  double sizeMB = snapshot.data! / 1024 / 1024;
                                  Color sizeColor = sizeMB > 5 ? Colors.red : Colors.green;
                                  return Text(
                                    'Tamanho: ${sizeMB.toStringAsFixed(2)} MB',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: sizeColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
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
                        onPressed: _isCompressing ? null : _takePicture,
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
                    onPressed: (_compressedImage != null && !_isCompressing) ? _finishDelivery : null,
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