package pe.casavip.casa_vip
import android.app.Activity
import android.content.Intent
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.ByteArrayOutputStream

/** Selector del sistema sin permisos de almacenamiento y compartición con URI privada. */
class MainActivity: FlutterActivity() {
 private var pending: MethodChannel.Result? = null
 override fun configureFlutterEngine(engine: FlutterEngine) {
  super.configureFlutterEngine(engine)
  MethodChannel(engine.dartExecutor.binaryMessenger,"pe.casavip/files").setMethodCallHandler { call,result ->
   when(call.method) {
    "pickImage" -> {
     if(pending!=null){result.error("BUSY","Hay una selección pendiente.",null)}
     else {pending=result;val intent=Intent(Intent.ACTION_OPEN_DOCUMENT).apply{type="image/*";addCategory(Intent.CATEGORY_OPENABLE);putExtra(Intent.EXTRA_MIME_TYPES,arrayOf("image/png","image/jpeg"))};startActivityForResult(intent,910)}
    }
    "shareFile" -> try {
     val bytes=call.argument<ByteArray>("bytes")!!
     val name=call.argument<String>("name")!!.substringAfterLast('/').substringAfterLast('\\')
     val dir=File(cacheDir,"shared").apply{mkdirs()}
     dir.listFiles()?.forEach{if(it.lastModified()<System.currentTimeMillis()-86400000)it.delete()}
     val file=File(dir,name);file.writeBytes(bytes)
     val uri=FileProvider.getUriForFile(this,"$packageName.files",file)
     val intent=Intent(Intent.ACTION_SEND).apply{type=call.argument<String>("mime");putExtra(Intent.EXTRA_STREAM,uri);addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)}
     startActivity(Intent.createChooser(intent,"Compartir archivo"));result.success(null)
    } catch(e:Exception) {result.error("SHARE","No se pudo compartir el archivo.",null)}
    else -> result.notImplemented()
   }
  }
 }
 @Deprecated("Deprecated in Android API")
 override fun onActivityResult(requestCode:Int,resultCode:Int,data:Intent?) {
  super.onActivityResult(requestCode,resultCode,data)
  if(requestCode!=910)return
  val result=pending;pending=null
  if(resultCode!=Activity.RESULT_OK||data?.data==null){result?.success(null);return}
  try {val uri=data.data!!;val bytes=contentResolver.openInputStream(uri)!!.use{input -> val out=ByteArrayOutputStream();val buffer=ByteArray(8192);while(out.size()<=5*1024*1024){val count=input.read(buffer);if(count<0)break;out.write(buffer,0,count)};out.toByteArray()};if(bytes.size>5*1024*1024){result?.error("SIZE","La imagen supera 5 MB.",null);return};result?.success(mapOf("bytes" to bytes,"name" to "documento"))}catch(e:Exception){result?.error("FILE","No se pudo leer la fotografía.",null)}
 }
}
