import 'package:flutter/services.dart';
import 'picked_image.dart';

const _channel = MethodChannel('pe.casavip/files');
Future<PickedImage?> pickImage() async {
  final result = await _channel.invokeMapMethod<String, dynamic>('pickImage');
  return result == null
      ? null
      : PickedImage(result['bytes'] as Uint8List, result['name'] as String);
}

Future<void> shareFile(Uint8List bytes, String name, String mime) async {
  await _channel.invokeMethod<void>('shareFile', {
    'bytes': bytes,
    'name': name,
    'mime': mime,
  });
}

Future<void> shareWhatsApp(Uint8List bytes, String name, String mime) async {
  await _channel.invokeMethod<void>('shareWhatsApp', {
    'bytes': bytes,
    'name': name,
    'mime': mime,
  });
}
