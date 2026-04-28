import 'package:url_launcher/url_launcher.dart';

class MapsLauncher {
  /// Buka Google Maps dengan koordinat tertentu
  static Future<void> openLocation(double lat, double lng,
      {String? label}) async {
    // geo: URI — langsung membuka Google Maps tanpa perlu canLaunchUrl
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    final mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    } else {
      // Fallback ke URL https jika geo: tidak tersedia
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    }
  }
}
