# docker安装(Linux)

## **一、准备**
### 卸载旧版本
``` shell
yum remove docker docker-common docker-selinux docker-engine 
yum remove docker-ce
```

### 卸载后将保留/var/lib/docker 的内容（镜像、容器、存储卷和网络等）。
``` shell
rm -rf /var/lib/docker
```

### 安装依赖软件包
``` shell
yum install -y yum-utils device-mapper-persistent-data lvm2 
# 安装前可查看device-mapper-persistent-data和lvm2是否已经安装
rpm -qa|grep device-mapper-persistent-data
rpm -qa|grep lvm2
```

### 设置yum源
``` shell
# docker官网 Yum源
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# 阿里云Docker Yum源
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

### 更新yum软件包索引
``` shell
yum makecache fast
```

## **二、安装**
### 安装最新版本docker-ce
``` shell
yum install docker-ce -y
#安装指定版本docker-ce可使用以下命令查看
yum list docker-ce.x86_64	--showduplicates | sort -r 
# 安装完成之后可以使用命令查看
docker version
```
### 启动docker服务
``` shell
systemctl restart docker
```

## **三、配置镜像加速**
### 1.找到/etc/docker目录下的daemon.json文件，没有则直接 vi daemon.json

### 2.加入以下配置
``` json
{
  "registry-mirrors": ["https://xxxxx.mirror.aliyuncs.com"]
}
```

### 3.通知systemd重载此配置文件
``` shell
systemctl daemon-reload
```

### 4.重启docker服务
``` shell
systemctl restart docker
```