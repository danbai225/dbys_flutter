package cn.p00q.dbys

import androidx.annotation.NonNull
import com.yanbo.lib_screen.VApplication
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        VApplication.init(this)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        //投屏
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"cn.p00q.dbys/tp").setMethodCallHandler(
                MethodChannel.MethodCallHandler { call, result ->
                    run {
                        if (call.method.contentEquals("getList")) {
                            TP.ini()
                            result.success(TP.get())
                        }
                        if (call.method.contentEquals("tp")) {
                            TP.tp(call.arguments)
                    }
                    }
                }
        )
        //下载
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"cn.p00q.dbys/M3U8Download").setMethodCallHandler(
                MethodChannel.MethodCallHandler { call, result ->
                    run {
                        if (call.method.contentEquals("Add")) {
                            M3U8Download.Add(call.arguments)
                        }
                        if (call.method.contentEquals("Cancel")) {
                            M3U8Download.cancel()
                        }
                        if (call.method.contentEquals("Path")) {
                            M3U8Download.setPath(call.arguments.toString())
                        }
                        if (call.method.contentEquals("removeBind")) {
                            M3U8Download.socket.close()
                        }
                    }
                }
        )
        //初始化
        M3U8Download.init()
    }
}
