import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/models.dart';
import '../../widgets/metartpay_branding.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  MerchantNotificationSettings? _settings;
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notificationProvider = context.read<NotificationProvider>();
    await notificationProvider.loadNotificationSettings();
    if (!mounted) return;

    setState(() {
      _settings = notificationProvider.settings;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_settings == null || !_hasChanges) return;

    final notificationProvider = context.read<NotificationProvider>();

    try {
      await notificationProvider.updateNotificationSettings(_settings!);
      if (!mounted) return;

      setState(() {
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateSetting(
    MerchantNotificationSettings Function(MerchantNotificationSettings) update,
  ) {
    if (_settings == null) return;

    setState(() {
      _settings = update(_settings!);
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: MetartPayColors.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: MetartPayColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveSettings,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: MetartPayColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settings == null
          ? _buildErrorState()
          : _buildSettingsContent(),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Failed to load settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // General Settings
          _buildSection('General Settings', [
            _buildSwitchTile(
              'Push Notifications',
              'Receive notifications on this device',
              _settings!.enablePushNotifications,
              (value) => _updateSetting(
                (s) => s.copyWith(enablePushNotifications: value),
              ),
              icon: Icons.notifications,
            ),
            _buildSwitchTile(
              'Email Notifications',
              'Receive notifications via email',
              _settings!.enableEmailNotifications,
              (value) => _updateSetting(
                (s) => s.copyWith(enableEmailNotifications: value),
              ),
              icon: Icons.email,
            ),
            _buildSwitchTile(
              'SMS Notifications',
              'Receive notifications via SMS',
              _settings!.enableSMSNotifications,
              (value) => _updateSetting(
                (s) => s.copyWith(enableSMSNotifications: value),
              ),
              icon: Icons.sms,
            ),
          ]),

          const SizedBox(height: 24),

          // Notification Types
          _buildSection('Notification Types', [
            _buildSwitchTile(
              'Payment Received',
              'When a payment is received',
              _settings!.notifyOnPaymentReceived,
              (value) => _updateSetting(
                (s) => s.copyWith(notifyOnPaymentReceived: value),
              ),
              icon: Icons.payment,
              enabled: _settings!.enablePushNotifications,
            ),
            _buildSwitchTile(
              'Payment Confirmed',
              'When a payment is confirmed on blockchain',
              _settings!.notifyOnPaymentConfirmed,
              (value) => _updateSetting(
                (s) => s.copyWith(notifyOnPaymentConfirmed: value),
              ),
              icon: Icons.check_circle,
              enabled: _settings!.enablePushNotifications,
            ),
            _buildSwitchTile(
              'KYC Updates',
              'Updates on your verification status',
              _settings!.notifyOnKYCUpdate,
              (value) =>
                  _updateSetting((s) => s.copyWith(notifyOnKYCUpdate: value)),
              icon: Icons.verified_user,
              enabled: _settings!.enablePushNotifications,
            ),
            _buildSwitchTile(
              'Security Events',
              'Important security alerts',
              _settings!.notifyOnSecurityEvents,
              (value) => _updateSetting(
                (s) => s.copyWith(notifyOnSecurityEvents: value),
              ),
              icon: Icons.security,
              enabled: _settings!.enablePushNotifications,
            ),
            _buildSwitchTile(
              'System Updates',
              'App updates and maintenance',
              _settings!.notifyOnSystemUpdates,
              (value) => _updateSetting(
                (s) => s.copyWith(notifyOnSystemUpdates: value),
              ),
              icon: Icons.system_update,
              enabled: _settings!.enablePushNotifications,
            ),
            _buildSwitchTile(
              'Low Balance Alerts',
              'When your balance is running low',
              _settings!.notifyOnLowBalance,
              (value) =>
                  _updateSetting((s) => s.copyWith(notifyOnLowBalance: value)),
              icon: Icons.account_balance_wallet,
              enabled: _settings!.enablePushNotifications,
            ),
          ]),

          const SizedBox(height: 24),

          // Quiet Hours
          _buildSection('Quiet Hours', [
            _buildSwitchTile(
              'Enable Quiet Hours',
              'Disable notifications during specified hours',
              _settings!.enableQuietHours,
              (value) =>
                  _updateSetting((s) => s.copyWith(enableQuietHours: value)),
              icon: Icons.bedtime,
            ),
            if (_settings!.enableQuietHours) ...[
              _buildTimeTile(
                'Start Time',
                _settings!.quietHoursStart,
                (time) =>
                    _updateSetting((s) => s.copyWith(quietHoursStart: time)),
              ),
              _buildTimeTile(
                'End Time',
                _settings!.quietHoursEnd,
                (time) =>
                    _updateSetting((s) => s.copyWith(quietHoursEnd: time)),
              ),
            ],
          ]),

          const SizedBox(height: 24),

          // Test Section
          _buildSection('Test', [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.send, color: Colors.blue),
              ),
              title: const Text('Send Test Notification'),
              subtitle: const Text('Test your notification settings'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _sendTestNotification,
            ),
          ]),

          const SizedBox(height: 24),

          // Device Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Device Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Some notification settings may be controlled by your device. If notifications aren\'t working as expected, check your device notification settings.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _openDeviceSettings,
                      child: const Text('Open Device Settings'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MetartPayColors.primary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged, {
    IconData? icon,
    bool enabled = true,
  }) {
    return ListTile(
      leading: icon != null
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: enabled
                    ? MetartPayColors.primary.withAlpha((0.1 * 255).round())
                    : Colors.grey.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: enabled ? MetartPayColors.primary : Colors.grey,
                size: 20,
              ),
            )
          : null,
      title: Text(title, style: TextStyle(color: enabled ? null : Colors.grey)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        // activeThumbColor expects a Color? (not a MaterialStateProperty)
        activeThumbColor: MetartPayColors.primary,
      ),
      enabled: enabled,
    );
  }

  Widget _buildTimeTile(String title, String time, Function(String) onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: MetartPayColors.primary.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.access_time,
          color: MetartPayColors.primary,
          size: 20,
        ),
      ),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
      onTap: () => _selectTime(title, time, onChanged),
    );
  }

  Future<void> _selectTime(
    String title,
    String currentTime,
    Function(String) onChanged,
  ) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onChanged(formattedTime);
    }
  }

  void _sendTestNotification() {
    final notificationProvider = context.read<NotificationProvider>();
    notificationProvider.sendTestNotification(
      title: 'Test Notification',
      body:
          'This is a test notification to verify your settings are working correctly.',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _openDeviceSettings() async {
    final notificationProvider = context.read<NotificationProvider>();
    await notificationProvider.openNotificationSettings();
  }
}
