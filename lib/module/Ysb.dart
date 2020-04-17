class Ysb {
  int id;
  double pf;
  String pm;
  String tp;
  String zt;
  String bm;
  String dy;
  String zy;
  String lx;
  String dq;
  String yy;
  String sytime;
  String pctime;
  String gxtime;
  String js;
  String gkdz;
  String xzdz;

  Ysb(
      {this.id,
        this.pf,
        this.pm,
        this.tp,
        this.zt,
        this.bm,
        this.dy,
        this.zy,
        this.lx,
        this.dq,
        this.yy,
        this.sytime,
        this.pctime,
        this.gxtime,
        this.js,
        this.gkdz,
        this.xzdz});

  Ysb.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    pf = json['pf'];
    pm = json['pm'];
    tp = json['tp'];
    zt = json['zt'];
    bm = json['bm'];
    dy = json['dy'];
    zy = json['zy'];
    lx = json['lx'];
    dq = json['dq'];
    yy = json['yy'];
    sytime = json['sytime'];
    pctime = json['pctime'];
    gxtime = json['gxtime'];
    js = json['js'];
    gkdz = json['gkdz'];
    xzdz = json['xzdz'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['pf'] = this.pf;
    data['pm'] = this.pm;
    data['tp'] = this.tp;
    data['zt'] = this.zt;
    data['bm'] = this.bm;
    data['dy'] = this.dy;
    data['zy'] = this.zy;
    data['lx'] = this.lx;
    data['dq'] = this.dq;
    data['yy'] = this.yy;
    data['sytime'] = this.sytime;
    data['pctime'] = this.pctime;
    data['gxtime'] = this.gxtime;
    data['js'] = this.js;
    data['gkdz'] = this.gkdz;
    data['xzdz'] = this.xzdz;
    return data;
  }
}