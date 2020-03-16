# **Docker Compose**

## **简介**
Compose的作用是“定义和运行多个Docker容器的应用”。使用Compose，你可以在一个配置文件（yaml格式）中配 置你应用的服务，然后使用一个命令，即可创建并启动配置中引用的所有服务。

Compose中两个重要概念： 
- 服务 (service)：一个应用的容器，实际上可以包括若干运行相同镜像的容器实例。 
- 项目 (project)：由一组关联的应用容器组成的一个完整业务单元，在 docker-compose.yml文件中定义。

## **安装**
Compose支持三平台Windows、Mac、Linux，安装方式各有不同。我这里使用的是Linux系统，其他系统安装方法 可以参考官方文档和开源GitHub链接： 
- Docker Compose官方文档链接：https://docs.docker.com/compose
- Docker Compose GitHub链接：https://github.com/docker/compose 
  
Linux上有两种安装方法，Compose项目是用Python写的，可以使用Python-pip安装，也可以通过GitHub下载二进 制文件进行安装。 

### **通过Python-pip安装**
1、安装Python-pip
``` shell
yum install -y epel-release 
yum install -y python-pip
```

2、安装docker-compose
``` shell
pip install docker-compose
```

3、验证是否安装
``` shell
docker-compose version
```

4、卸载
``` shell
pip uninstall docker-compose
```

### **通过GitHub链接下载安装**
非ROOT用户记得加sudo 

1、通过GitHub获取下载链接，以往版本地址：https://github.com/docker/compose/releases
``` shell
curl -L "https://github.com/docker/compose/releases/download/1.26.0-rc3/docker-compose-Darwin-x86_64" -o /usr/local/bin/docker-compose
```
注:
- 若下载较慢， 或下载后不可用， 可直接去github上下载后放到指定目录
- Linux系统请下载docker-compose-Linux-x86_64， 不要下错哦

2、给二进制下载文件可执行的权限
``` shell
chmod +x /usr/local/bin/docker-compose
```

3、可能没有启动程序，设置软连接，比如:
``` shell
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

4、验证是否安装
``` shell
docker-compose version
```

5、卸载

如果是二进制包方式安装的，删除二进制文件即可。
``` shell
rm /usr/local/bin/docker-compose
```
