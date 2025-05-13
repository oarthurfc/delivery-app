import 'package:flutter/material.dart';

class ErrorPopup {
  // Método principal genérico
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
    bool isDismissible = true,
    IconData? icon,
  }) {
    showDialog(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => _ErrorPopupContent(
        title: title,
        message: message,
        buttonText: buttonText,
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }

  // Métodos específicos para erros comuns
  static void showNetworkError(BuildContext context) {
    show(
      context: context,
      title: 'Sem conexão',
      message: 'Verifique sua conexão com a internet e tente novamente.',
      icon: Icons.wifi_off,
    );
  }

  static void showApiError(BuildContext context, {String? message}) {
    show(
      context: context,
      title: 'Erro no servidor',
      message: message ?? 'Ocorreu um erro ao comunicar com o servidor.',
      icon: Icons.cloud_off,
    );
  }

  static void showPermissionError(BuildContext context, {String? permission}) {
    show(
      context: context,
      title: 'Permissão necessária',
      message: permission != null
          ? 'Por favor, conceda acesso a $permission para continuar.'
          : 'Permissão negada. Acesse as configurações para conceder.',
      buttonText: 'Configurações',
      icon: Icons.privacy_tip,
      onPressed: () {
        Navigator.pop(context);
        // AppSettings.openAppSettings(); // Descomente se usar o pacote app_settings
      },
    );
  }
}

// Widget interno reutilizável
class _ErrorPopupContent extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;
  final IconData? icon;

  const _ErrorPopupContent({
    required this.title,
    required this.message,
    this.buttonText,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      icon: Icon(
        icon ?? Icons.error_outline,
        size: 32,
        color: theme.colorScheme.error,
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.error,
        ),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: onPressed ?? () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.onErrorContainer,
          ),
          child: Text(buttonText ?? 'Entendi'),
        ),
      ],
    );
  }
}