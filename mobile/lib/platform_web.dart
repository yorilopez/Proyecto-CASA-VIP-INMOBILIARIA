import 'dart:async';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'picked_image.dart';

Future<PickedImage?> pickImage() {
  final result = Completer<PickedImage?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/png,image/jpeg';
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
