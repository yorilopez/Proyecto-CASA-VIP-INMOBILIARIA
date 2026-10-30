import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'picked_image.dart';

Future<PickedImage?> pickImage() => _pickFile('image/png,image/jpeg');
Future<PickedImage?> pickCatalog() => _pickFile('.csv,.xlsx,.json');
Future<PickedImage?> _pickFile(String accept) {
  final result = Completer<PickedImage?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept;
  input.style.display = 'none';
  web.document.body!.appendChild(input);
  void finish(PickedImage? image) {
    if (!result.isCompleted) result.complete(image);
    input.remove();
  }

  input.addEventListener(
    'change',
    ((web.Event e) {
      final file = input.files?.item(0);
      if (file == null) {
        finish(null);
        return;
      }
      if (file.size > 5 * 1024 * 1024) {
        result.completeError(Exception('Selecciona una imagen de hasta 5 MB.'));
        input.remove();
        return;
      }
      file
          .arrayBuffer()
          .toDart
          .then(
            (buffer) =>
                finish(PickedImage(buffer.toDart.asUint8List(), file.name)),
          )
          .catchError((Object e) {
            result.completeError(e);
            input.remove();
          });
    }).toJS,
  );
  input.addEventListener('cancel', ((web.Event e) => finish(null)).toJS);
  input.click();
  return result.future;
}

Future<void> shareBundle(String text, List<Map<String, dynamic>> files) async {
  final selected = files
      .map(
        (f) => web.File(
          [(f['bytes'] as Uint8List).toJS].toJS,
          f['name'] as String,
          web.FilePropertyBag(type: f['mime'] as String),
        ),
      )
      .toList();
  final data = web.ShareData(
    text: text,
    title: 'CASA VIP',
    files: selected.toJS,
  );
  try {
    if (web.window.isSecureContext && web.window.navigator.canShare(data)) {
      try {
        await web.window.navigator.share(data).toDart;
        return;
      } catch (e) {
        if (e.toString().contains('AbortError')) return;
      }
    }
  } catch (_) {}
  final downloads = <Map<String, dynamic>>[
    {
      'bytes': Uint8List.fromList(utf8.encode(text)),
      'name': 'operacion_CASA_VIP.txt',
      'mime': 'text/plain',
    },
    ...files,
  ];
  for (final f in downloads) {
    final blob = web.Blob(
      [(f['bytes'] as Uint8List).toJS].toJS,
      web.BlobPropertyBag(type: f['mime'] as String),
    );
    final url = web.URL.createObjectURL(blob);
    final link = web.HTMLAnchorElement()
      ..href = url
      ..download = f['name'] as String;
    web.document.body!.appendChild(link);
    link.click();
    link.remove();
    Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
  }
}

Future<void> shareWhatsApp(Uint8List bytes, String name, String mime) =>
    shareFile(bytes, name, mime);

Future<void> shareFile(Uint8List bytes, String name, String mime) async {
  try {
    final file = web.File(
      [bytes.toJS].toJS,
      name,
      web.FilePropertyBag(type: mime),
    );
    final data = web.ShareData(files: [file].toJS, title: "CASA VIP");
    if (web.window.isSecureContext && web.window.navigator.canShare(data)) {
      try {
        await web.window.navigator.share(data).toDart;
        return;
      } catch (e) {
        if (e.toString().contains("AbortError")) return;
      }
    }
  } catch (_) {}
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime));
  final url = web.URL.createObjectURL(blob);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  web.document.body!.appendChild(link);
  link.click();
  link.remove();
  Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
}

Future<String?> readSetting(String key) async =>
    web.window.localStorage.getItem('casavip.$key');
Future<void> writeSetting(String key, String value) async =>
    web.window.localStorage.setItem('casavip.$key', value);
Future<void> deleteSetting(String key) async =>
    web.window.localStorage.removeItem('casavip.$key');
Future<void> saveReport(Uint8List bytes, String name, String mime) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime));
  final url = web.URL.createObjectURL(blob);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  web.document.body!.appendChild(link);
  link.click();
  link.remove();
  Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
}
