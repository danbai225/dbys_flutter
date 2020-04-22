package cn.p00q.dbys

import android.util.Log
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
    }
}
