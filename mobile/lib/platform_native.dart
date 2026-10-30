import 'package:flutter/services.dart';
import 'picked_image.dart';

const _channel = MethodChannel('pe.casavip/files');
Future<PickedImage?> pickImage() async {
  final result = await _channel.invokeMapMethod<String, dynamic>('pickImage');
  return result == null
      ? null
      : PickedImage(result['bytes'] as Uint8List, result['name'] as String);
}

Future<PickedImage?> pickCatalog() async {
  final result = await _channel.invokeMapMethod<String, dynamic>('pickFile');
  return result == null
      ? null
      : PickedImage(result['bytes'] as Uint8List, result['name'] as String);
}

Future<void> shareBundle(String text, List<Map<String, dynamic>> files) async {
  await _channel.invokeMethod<void>('shareBundle', {
    'text': text,
    'files': files,
  });
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

Future<String?> readSetting(String key) async {
  try {
    return await _channel.invokeMethod<String>('readSetting', {'key': key});
  } on MissingPluginException {
    return null;
  }
}

Future<void> writeSetting(String key, String value) async {
  try {
    await _channel.invokeMethod<void>('writeSetting', {
      'key': key,
      'value': value,
    });
  } on MissingPluginException {
    return;
  }
}

Future<void> deleteSetting(String key) async {
  try {
    await _channel.invokeMethod<void>('deleteSetting', {'key': key});
  } on MissingPluginException {
    return;
  }
}

Future<void> saveReport(Uint8List bytes, String name, String mime) =>
    _channel.invokeMethod<void>('saveReport', {
      'bytes': bytes,
      'name': name,
      'mime': mime,
    });
