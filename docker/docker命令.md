# **docker命令**
输入 docker 可以查看Docker的命令用法，输入 docker COMMAND --help 查看指定命令详细用法。

## **镜像常用操作**
### 查找镜像：
``` shell
docker search 关键词
# 搜索docker hub网站镜像的详细信息
```

### 下载镜像：
``` shell
docker pull 镜像名:TAG
# Tag表示版本，有些镜像的版本显示latest，为最新版本
```

### 查看镜像：
``` shell
docker images
# 查看本地所有镜像
```

### 删除镜像：
``` shell
docker rmi -f 镜像ID或者镜像名:TAG
# 删除指定本地镜像
# -f 表示强制删除
```

### 获取元信息：
``` shell
docker inspect 镜像ID或者镜像名:TAG
# 获取镜像的元信息，详细信息
```

## **容器常用操作**
### 运行：
``` shell
docker run --name 容器名 -i -t -p 主机端口:容器端口 -d -v 主机目录:容器目录:ro 镜像ID或镜像名:TAG
# --name 指定容器名，可自定义，不指定自动命名
# -i 以交互模式运行容器
# -t 分配一个伪终端，即命令行，通常-it组合来使用
# -p 指定映射端口，讲主机端口映射到容器内的端口
# -d 后台运行容器
# -v 指定挂载主机目录到容器目录，默认为rw读写模式，ro表示只读
```

### 容器列表：
``` shell
docker ps -a -q
# docker ps查看正在运行的容器
# -a 查看所有容器（运行中、未运行）
# -q 只查看容器的ID
```

### 启动容器：
``` shell
docker start 容器ID或容器名
```

### 停止容器：
``` shell
docker stop 容器ID或容器名
```

### 删除容器：
``` shell
docker rm -f 容器ID或容器名
# -f 表示强制删除
```

### 查看日志：
``` shell
docker logs 容器ID或容器名
```

### 进入正在运行容器：
``` shell
docker exec -it 容器ID或者容器名 /bin/bash
# 进入正在运行的容器并且开启交互模式终端
# /bin/bash是固有写法，作用是因为docker后台必须运行一个进程，否则容器就会退出，在这里表示启动容器后启动
bash。
# 也可以用docker exec在运行中的容器执行命令
```

### 拷贝文件：
``` shell
docker cp 主机文件路径 容器ID或容器名:容器路径 #主机中文件拷贝到容器中
docker cp 容器ID或容器名:容器路径 主机文件路径 #容器中文件拷贝到主机中
```

### 获取容器元信息：
``` shell
docker inspect 容器ID或容器名
```