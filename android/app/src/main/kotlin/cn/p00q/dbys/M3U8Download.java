package cn.p00q.dbys;

import android.os.Environment;
import android.util.Log;

import com.hdl.m3u8.M3U8DownloadTask;
import com.hdl.m3u8.M3U8Manger;
import com.hdl.m3u8.bean.M3U8;
import com.hdl.m3u8.bean.M3U8Listener;
import com.hdl.m3u8.bean.OnDownloadListener;
import com.hdl.m3u8.utils.NetSpeedUtils;

import org.eclipse.jetty.util.ajax.JSON;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.SocketException;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class M3U8Download {
    private static String SaveFilePath=Environment.getExternalStorageDirectory().getPath() + File.separator;
    public static List<Download> downloadList=new ArrayList<>();
    private static  MyM3U8DownloadTask downloadTask;
    //1.创建服务器端DatagramSocket，指定端口
    public static DatagramSocket  socket;
    public static void init(){
        try {
            if(socket!=null){
                socket.close();
            }
            socket = new DatagramSocket(2252);
        }catch (Exception e) {
                e.printStackTrace();
            }
    }
    public static void sendData(String msg){
        byte[] buf = msg.getBytes();
        try {
            //目标主机地址，这里发送到本机所以是127.0.0.1
            InetAddress address = InetAddress.getByName("127.0.0.1");
            int port = 2256;  //目标主机的端口号
            //创建发送方的数据报信息
            DatagramPacket dataGramPacket = new DatagramPacket(buf, buf.length, address, port);
            socket.send(dataGramPacket);  //通过套接字发送数据
    } catch (UnknownHostException e) {
            e.printStackTrace();
        } catch (SocketException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    public static void setPath(String path){
        SaveFilePath=path;
    }
    public static void Add(Object data){
        JSONObject jObject= null;
        try {
            jObject = new JSONObject(data.toString());
            String id=jObject.getString("pm")+"-"+jObject.getString("jiName");
            Download d=new Download(id,jObject.getString("pm"),jObject.getString("url"),jObject.getString("jiName"));
            downloadList.add(d);
            if(downloadList.size()>0&&(downloadTask==null||!downloadTask.isRunning())){
                Download(downloadList.get(0));
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
    public static void cancel(){
        if(downloadTask!=null&&downloadTask.isRunning()){
            downloadTask.stop();
            downloadList.remove(0);
            if(downloadList.size()>0){
                Download(downloadList.get(0));
            }
        }
    }
        public static void Download(Download d){
            downloadTask = new MyM3U8DownloadTask(d.getId());
            MyM3U8DownloadTask.curTs=0;
            downloadTask.setThreadCount(10);
            downloadTask.setSaveFilePath(SaveFilePath+"/下载/"+d.getPm()+"/"+d.getJiName()+".mp4");
            downloadTask.download(d.getUrl(), new OnDownloadListener() {
                private long lastLength = 0;
                @Override
                public void onDownloading(final long itemFileSize, final int totalTs, final int curTs) {
                    Log.d("TEST",totalTs+"--curTs:"+curTs);
                    Map rs=new HashMap();
                    rs.put("type","onDownloading");
                    rs.put("taskId",d.getId());
                    rs.put("schedule",((double)curTs/totalTs));
                    rs.put("pm",d.getPm());
                    rs.put("JiName",d.getJiName());
                    Runnable networkTask = () -> M3U8Download.sendData(JSON.toString(rs));
                    new Thread(networkTask).start();
                }
                /**
                 * 下载成功
                 */
                @Override
                public void onSuccess() {
                    downloadList.remove(0);
                    if(downloadList.size()>0&&!downloadTask.isRunning()){
                        Download(downloadList.get(0));
                    }
                    Log.d("M3U8Download","下载完成了:"+d.getId());
                    Map rs=new HashMap();
                    rs.put("type","onSuccess");
                    Runnable networkTask = () -> M3U8Download.sendData(JSON.toString(rs));
                    new Thread(networkTask).start();
                }
                /**
                 * 当前的进度回调
                 *
                 * @param curLenght
                 */
                @Override
                public void onProgress(final long curLenght) {
                    if (curLenght - lastLength > 0) {
                        final String speed = NetSpeedUtils.getInstance().displayFileSize(curLenght - lastLength) + "/s";
                        lastLength = curLenght;
                        Map rs=new HashMap();
                        rs.put("type","onProgress");
                        rs.put("taskId",d.getId());
                        rs.put("speed",speed);
                        Runnable networkTask = () -> M3U8Download.sendData(JSON.toString(rs));
                        new Thread(networkTask).start();
                    }
                }
                @Override
                public void onStart() {
                    Log.d("M3U8Download","开始下载了");
                }

                @Override
                public void onError(Throwable errorMsg) {
                    Log.e("M3U8Download",errorMsg.getMessage());
                }
            });
    }
}
