import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkStatusChip extends StatefulWidget {
  const NetworkStatusChip({super.key});

  @override
  State<NetworkStatusChip> createState() => _NetworkStatusChipState();
}

class _NetworkStatusChipState extends State<NetworkStatusChip> {
  ConnectivityResult _status = ConnectivityResult.none;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) setState(() => _status = result);
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) setState(() => _status = result);
  }

  IconData get _icon {
    switch (_status) {
      case ConnectivityResult.wifi:
        return Icons.wifi;
      case ConnectivityResult.mobile:
        return Icons.signal_cellular_alt;
      default:
        return Icons.signal_wifi_off;
    }
  }

  String get _label {
    switch (_status) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return '4G';
      default:
        return 'Offline';
    }
  }

  Color get _color {
    switch (_status) {
      case ConnectivityResult.wifi:
        return const Color(0xFF2E7D32);
      case ConnectivityResult.mobile:
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFFD32F2F);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Chip(
        avatar: Icon(_icon, size: 14, color: Colors.white),
        label: Text(
          _label,
          style: const TextStyle(
              fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: _color,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
