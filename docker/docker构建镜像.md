# **Docker构建镜像**
### Docker构建镜像两种方式：
- 更新镜像：使用 docker commit 命令 
- 构建镜像：使用 docker build 命令，需要创建Dockerﬁle文件 
  
## **一、更新镜像**
- 先使用基础镜像创建一个容器，然后对容器内容进行更改，然后使用 docker commit 命令提交为一个新的镜像（以 tomcat为例）。

### 1、根据基础镜像，创建容器
``` shell
docker run --name xxx -p 80:8080 -d 镜像名
```

### 2、修改容器内容
``` shell
docker exec -it xxx /bin/bash 
# 进入修改容器修改
exit # 保存退出
```

### 3、提交为新镜像
``` shell
docker commit -m="描述消息" -a="作者" 容器ID或容器名 镜像名:TAG
```

### 4、使用新镜像运行容器
docker run --name xxx -p 8080:8080 -d 镜像库/镜像名:版本

## **二、使用Dockerﬁle构建镜像**
以spring-boot项目为例

### 1、准备
- 把你的springboot项目打包成可执行jar包
- 把jar包上传到Linux服务器

### 2、构建
- 在jar包路径下创建Dockerﬁle文件 vi Dockerfile
``` shell
# 指定基础镜像，本地没有会从dockerHub pull下来 
FROM openjdk:8-jre
#作者 
MAINTAINER xxx
# 构建传入参数 
ARG JAR_FILE
# 把可执行jar包复制到基础镜像的根目录下 
# ${JAR_FILE}使用上面ARG的值
ADD ${JAR_FILE} /${JAR_FILE} 
# 镜像要暴露的端口，如要使用端口，在执行docker run命令时使用-p生效 
EXPOSE 80 
# 在镜像运行为容器后执行的命令 
ENTRYPOINT ["java","-jar","/${JAR_FILE}.jar"]
```

- 使用 docker build 命令构建镜像，基本语法
``` shell
docker build -t xxx/xxx:v1 . 
# -f指定Dockerfile文件的路径 
# -t指定镜像名字和TAG 
# .指当前目录，这里实际上需要一个上下文路径

```

### 3、运行
运行的spring-boot镜像
``` shell
docker run --name xxx -p 80:80 -d 镜像名:TAG
```
