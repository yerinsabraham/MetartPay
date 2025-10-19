import 'package:flutter/material.dart';

enum NotificationType { success, warning, error, info }

class NotificationBanner extends StatelessWidget {
  final String message;
  final NotificationType type;
  final VoidCallback? onClose;

  const NotificationBanner({Key? key, required this.message, this.type = NotificationType.info, this.onClose}) : super(key: key);

  Color _bgColor(BuildContext context) {
    switch (type) {
      case NotificationType.success:
        return Colors.green.shade600;
      case NotificationType.warning:
        return Colors.orange.shade700;
      case NotificationType.error:
        return Colors.red.shade700;
      case NotificationType.info:
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _icon() {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.info:
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bgColor(context),
      elevation: 6,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(_icon(), color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onClose,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
