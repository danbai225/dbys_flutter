package cn.p00q.dbys;

import android.util.Log;

import com.yanbo.lib_screen.callback.ControlCallback;
import com.yanbo.lib_screen.entity.ClingDevice;
import com.yanbo.lib_screen.entity.RemoteItem;
import com.yanbo.lib_screen.manager.ClingManager;
import com.yanbo.lib_screen.manager.ControlManager;
import com.yanbo.lib_screen.manager.DeviceManager;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class TP {
    private static List<ClingDevice> clingDevices;
    private static RemoteItem remoteItem;
    public static void ini(){
        Log.d("投屏", "初始化");
        clingDevices=new ArrayList<ClingDevice>();
        ClingManager.getInstance().startClingService();
        clingDevices = DeviceManager.getInstance().getClingDeviceList();
    }
    public static List<String> get(){
        List<String> list=new ArrayList<>();
        if(clingDevices.size()>0){
            for (int i=0;i<clingDevices.size();i++){
                list.add(getDname(clingDevices.get(i)));
            }
        }
        Log.d("投屏", "有设备："+list.size());
        return list;
    }
    public static void tp(Object data){
        try {
            JSONObject jObject=new JSONObject(data.toString());
            tou(jObject.getString("url"),jObject.getInt("index"));
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
    /**
     * 网络投屏
     */
    private static String getDname(ClingDevice device){
        return device.getDevice().getDetails().getFriendlyName()+"-"+device.getDevice().getDetails().getPresentationURI().getHost();
    }
    public static void tou(String url,int index){
        DeviceManager.getInstance().setCurrClingDevice(clingDevices.get(index));
        //设置网络投屏的信息
        RemoteItem itemurl = new RemoteItem("淡白影视", "996", "淡白影视",123123, "00:00:00", "1920x1080",url);
        //添加网络投屏的信息
        ClingManager.getInstance().setRemoteItem(itemurl);
        remoteItem = ClingManager.getInstance().getRemoteItem();
        //播放
        if (ControlManager.getInstance().getState() == ControlManager.CastState.STOPED) {
            newPlayCastRemoteContent();
        }
    }
    private static void newPlayCastRemoteContent() {

        ControlManager.getInstance().setState(ControlManager.CastState.TRANSITIONING);

        ControlManager.getInstance().newPlayCast(remoteItem, new ControlCallback() {

            @Override
            public void onSuccess() {
                ControlManager.getInstance().setState(ControlManager.CastState.PLAYING);
                ControlManager.getInstance().initScreenCastCallback();
                Log.d("投屏", "投屏成功");
            }

            @Override
            public void onError(int code, String msg) {
                ControlManager.getInstance().setState(ControlManager.CastState.STOPED);
                Log.d("投屏", "投屏失败");
            }
        });
    }
}
