import 'dart:io';
import 'package:delivery/database/repository/SyncableRepository.dart';
import 'package:delivery/models/order.dart';
import 'package:delivery/screens/error_popup.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';




class FinalizarEntregaScreen extends StatefulWidget {
  final Order encomenda;
  final SyncableRepository<Order> repository;

  const FinalizarEntregaScreen({
    Key? key,
    required this.encomenda,
    required this.repository,
  }) : super(key: key);

  @override
  State<FinalizarEntregaScreen> createState() => _FinalizarEntregaScreenState();
}

class _FinalizarEntregaScreenState extends State<FinalizarEntregaScreen> {
  File? _imagemCapturada;
  final _picker = ImagePicker();
  bool _salvando = false;

  Future<void> _tirarFoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imagemCapturada = File(pickedFile.path);
      });
    }
  }

  Future<void> _finalizarEntrega() async {
  if (_imagemCapturada == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Capture uma imagem antes de finalizar.')),
    );
    return;
  }

  setState(() {
    _salvando = true;
  });

  try {
    // Verifica permissão e localização atual
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      throw Exception('Permissão de localização negada');
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // Calcula a distância até o ponto de entrega
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      widget.encomenda.destinationAddress.latitude!,
      widget.encomenda.destinationAddress.latitude!,
    );

    const double distanciaMaxima = 100; // em metros

    if (distance > distanciaMaxima) {
      ErrorPopup.show(
        context: context,
        title: 'Fora do Local de Entrega',
        message: 'Você está a mais de 100 metros do destino da entrega.',
        icon: Icons.location_off,
      );

      setState(() => _salvando = false);
      return;
    }

    widget.encomenda.status = OrderStatus.DELIVERIED;
    widget.encomenda.imageUrl = _imagemCapturada!.path;

    // await widget.repository.save(widget.encomenda);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Entrega finalizada com sucesso!')),
    );
    Navigator.pop(context);

  } catch (e) {
    if (e is PermissionDeniedException || e.toString().contains('Permissão de localização negada')) {
      ErrorPopup.show(
        context: context,
        title: 'Permissão Negada',
        message: 'Permissão de localização negada. Por favor, permita o acesso à localização para finalizar a entrega.',
        icon: Icons.location_off,
      );
    } else {
      ErrorPopup.show(
        context: context,
        title: 'Erro ao finalizar entrega',
        message: e.toString(),
        icon: Icons.error_outline,
      );
    }
    setState(() => _salvando = false);
  }
}


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Finalizar Entrega'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'encomenda #${widget.encomenda.id}',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _imagemCapturada == null
                ? Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Center(
                      child: Text(
                        'Nenhuma imagem capturada',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _imagemCapturada!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _salvando ? null : _tirarFoto,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Tirar Foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvando ? null : _finalizarEntrega,
                child: _salvando
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Finalizar Entrega'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
