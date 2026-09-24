import 'package:flutter/services.dart';

/// Detects whether the app was installed from the Play Store or sideloaded
/// (e.g. a GitHub Release APK) — used to decide whether to prompt for a
/// Play Store rating or a GitHub star.
class InstallSourceService {
  InstallSourceService._();
  static final InstallSourceService instance = InstallSourceService._();

  static const _channel = MethodChannel('topsheet/install_source');

  bool? _isPlayStoreCache;

  Future<bool> isFromPlayStore() async {
    if (_isPlayStoreCache != null) return _isPlayStoreCache!;
    try {
      final installer = await _channel.invokeMethod<String>('getInstaller');
      _isPlayStoreCache = installer == 'com.android.vending';
    } catch (_) {
      _isPlayStoreCache = false;
    }
    return _isPlayStoreCache!;
  }
}
