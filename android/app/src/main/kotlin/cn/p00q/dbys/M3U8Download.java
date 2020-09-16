package cn.p00q.dbys;

import android.os.Environment;
import net.m3u8.download.M3u8DownloadFactory;
import net.m3u8.listener.DownloadListener;
import net.m3u8.utils.Constant;

import org.eclipse.jetty.util.ajax.JSON;
import org.json.JSONException;
import org.json.JSONObject;
import java.io.File;
import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;
import java.util.Vector;

public class M3U8Download {
    private static String SaveFilePath = Environment.getExternalStorageDirectory().getPath() + File.separator;
    public static List<Download> downloadList = new Vector<>();
    //1.创建服务器端DatagramSocket，指定端口
    public static DatagramSocket socket;
    public static void init() {
        try {
            if (socket != null) {
                socket.close();
            }
            socket = new DatagramSocket(2252);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void sendData(String msg) {
        byte[] buf = msg.getBytes();
        try {
            //目标主机地址，这里发送到本机所以是127.0.0.1
            InetAddress address = InetAddress.getByName("127.0.0.1");
            int port = 2256;  //目标主机的端口号
            //创建发送方的数据报信息
            DatagramPacket dataGramPacket = new DatagramPacket(buf, buf.length, address, port);
            socket.send(dataGramPacket);  //通过套接字发送数据
        }  catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void setPath(String path) {
        SaveFilePath = path;
    }

    public synchronized static void Add(Object data) {
        JSONObject jObject = null;
        try {
            jObject = new JSONObject(data.toString());
            String id = jObject.getString("pm") + "-" + jObject.getString("jiName");
            Download d = new Download(id, jObject.getString("pm"), jObject.getString("url"), jObject.getString("jiName"));
            if (M3u8DownloadFactory.isRun()){
                System.out.println("添加");
                downloadList.add(d);
            }else {
                M3u8DownloadFactory.run=true;
                System.out.println("下载："+d.getJiName());
                Runnable networkTask = () -> Download(d);
                new Thread(networkTask).start();
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public static void cancel() {
        M3u8DownloadFactory.cancel();
    }

    public static void Download(Download d) {

        M3u8DownloadFactory.M3u8Download m3u8Download = M3u8DownloadFactory.getInstance(d.getUrl());
        //设置生成目录
        m3u8Download.setDir(SaveFilePath + "/下载/" + d.getPm());
        //设置视频名称
        m3u8Download.setFileName(d.getJiName());
        //设置线程数
        m3u8Download.setThreadCount(24);
        //设置重试次数
        m3u8Download.setRetryCount(3);
        //设置连接超时时间（单位：毫秒）
        m3u8Download.setTimeoutMillisecond(10000L);
        //设置日志级别
        //可选值：NONE INFO DEBUG ERROR
        m3u8Download.setLogLevel(Constant.NONE);
        //设置监听器间隔（单位：毫秒）
        m3u8Download.setInterval(500L);
        //添加监听器
        m3u8Download.addListener(new DownloadListener() {
            @Override
            public void start() {
                System.out.println("开始下载！");
            }

            @Override
            public void process(String downloadUrl, int finished, int sum, float percent) {
                Map rs=new HashMap();
                rs.put("type","onDownloading");
                rs.put("taskId",d.getId());
                rs.put("schedule",percent);
                rs.put("pm",d.getPm());
                rs.put("JiName",d.getJiName());
                Runnable networkTask = () -> M3U8Download.sendData(JSON.toString(rs));
                new Thread(networkTask).start();
            }

            @Override
            public void speed(String speedPerSecond) {
                Map rs=new HashMap();
                rs.put("type","onProgress");
                rs.put("taskId",d.getId());
                rs.put("speed",speedPerSecond);
                Runnable networkTask = () -> M3U8Download.sendData(JSON.toString(rs));
                new Thread(networkTask).start();
            }

            @Override
            public void end() {
                new Timer("timer - onSuccess").schedule(new TimerTask() {
                    @Override
                    public void run() {
                        Map rs=new HashMap();
                        rs.put("type","onSuccess");
                        Runnable networkTask = () -> M3U8Download.sendData(JSON.toString(rs));
                        new Thread(networkTask).start();
                        next();
                    }
                }, 2000);
                M3u8DownloadFactory.destroied();
                M3u8DownloadFactory.run=false;
            }
        });
//开始下载
        m3u8Download.start();
    }
    synchronized private static void  next(){
        System.out.println(downloadList.size());
        if(downloadList.size()>0&& !M3u8DownloadFactory.isRun()){
            Runnable networkTask = () -> Download(downloadList.remove(0));
            new Thread(networkTask).start();
        }
    }
}
