package cn.p00q.dbys;

public class Download {
    private String id;
    private String pm;
    private String url;
    private String jiName;


    public String getUrl() {
        return url;
    }

    public Download(String id, String pm, String url, String jiName) {
        this.id = id;
        this.pm = pm;
        this.url = url;
        this.jiName = jiName;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getPm() {
        return pm;
    }

    public void setPm(String pm) {
        this.pm = pm;
    }

    public String getJiName() {
        return jiName;
    }

    public void setJiName(String jiName) {
        this.jiName = jiName;
    }

}
