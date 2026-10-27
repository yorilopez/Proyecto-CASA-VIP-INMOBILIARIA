package pe.casavip.casa_vip

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.UUID

// Selección, captura y compartición mediante URI temporales del sistema.
class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null
    private var capture: File? = null
    private val requestImage = 4101
    private val maximumBytes = 5 * 1024 * 1024

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "pe.casavip/files")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickImage" -> {
                        if (pending != null) {
                            result.error("BUSY", "Hay una selección pendiente.", null)
                        } else {
                            pending = result
                            try {
                                val picker = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                                    type = "image/" + "*"
                                    addCategory(Intent.CATEGORY_OPENABLE)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                val chooser = Intent.createChooser(picker, "Seleccionar fotografía")
                                val camera = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
                                if (camera.resolveActivity(packageManager) != null) {
                                    val folder = File(cacheDir, "shared").apply { mkdirs() }
                                    val file = File(folder, "capture_${UUID.randomUUID()}.jpg")
                                    capture = file
                                    val uri = FileProvider.getUriForFile(this, "$packageName.files", file)
                                    camera.putExtra(MediaStore.EXTRA_OUTPUT, uri)
                                    camera.clipData = ClipData.newRawUri("Fotografía", uri)
                                    camera.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                                    chooser.putExtra(Intent.EXTRA_INITIAL_INTENTS, arrayOf(camera))
                                }
                                startActivityForResult(chooser, requestImage)
                            } catch (_: Exception) {
                                capture?.delete()
                                capture = null
                                pending = null
                                result.error("PICK_FAILED", "No se pudo abrir el selector de fotos.", null)
                            }
                        }
                    }
                    "shareFile", "shareWhatsApp" -> {
                        try {
                            val bytes = call.argument<ByteArray>("bytes")
                                ?: throw IllegalArgumentException("Falta imagen")
                            val name = File(call.argument<String>("name") ?: "imagen.png").name
                            val folder = File(cacheDir, "shared").apply { mkdirs() }
                            // Conserva el archivo durante el acceso de la app receptora.
                            folder.listFiles()?.filter { System.currentTimeMillis() - it.lastModified() > 24 * 60 * 60 * 1000L }?.forEach { it.delete() }
                            val file = File(folder, "${UUID.randomUUID()}_$name")
                            file.writeBytes(bytes)
                            val uri = FileProvider.getUriForFile(this, "$packageName.files", file)
                            val share = Intent(Intent.ACTION_SEND).apply {
                                type = call.argument<String>("mime") ?: "image/png"
                                putExtra(Intent.EXTRA_STREAM, uri)
                                clipData = ClipData.newRawUri("CASA VIP", uri)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            if (call.method == "shareWhatsApp") {
                                val target = listOf("com.whatsapp", "com.whatsapp.w4b").firstOrNull {
                                    try { packageManager.getPackageInfo(it, 0); true } catch (_: Exception) { false }
                                }
                                if (target != null) share.setPackage(target)
                            }
                            if (share.`package` != null) startActivity(share)
                            else startActivity(Intent.createChooser(share, "Compartir imagen"))
                            result.success(null)
                        } catch (_: Exception) {
                            result.error("SHARE_FAILED", "No se pudo compartir la imagen.", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Compatible con el canal de selección de Flutter")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != requestImage) return
        val reply = pending ?: return
        pending = null
        try {
            if (resultCode != Activity.RESULT_OK) {
                reply.success(null)
                return
            }
            val selected = data?.data
            val photo = capture
            val mime = selected?.let { contentResolver.getType(it) } ?: "image/jpeg"
            val input = selected?.let { contentResolver.openInputStream(it) }
                ?: photo?.takeIf { it.exists() && it.length() > 0 }?.inputStream()
                ?: throw IllegalArgumentException("No se recibió una foto")
            val bytes = input.use { stream ->
                val output = ByteArrayOutputStream()
                val buffer = ByteArray(8192)
                while (true) {
                    val count = stream.read(buffer)
                    if (count < 0) break
                    if (output.size() + count > maximumBytes) throw IllegalArgumentException("Imagen demasiado grande")
                    output.write(buffer, 0, count)
                }
                output.toByteArray()
            }
            val extension = if (mime == "image/jpeg") "jpg" else "png"
            reply.success(mapOf("bytes" to bytes, "name" to "fotografia.$extension"))
        } catch (_: Exception) {
            reply.error("READ_FAILED", "Selecciona una imagen PNG o JPEG de hasta 5 MB.", null)
        } finally {
            capture?.delete()
            capture = null
        }
    }
}