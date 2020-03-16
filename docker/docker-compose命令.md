# **Docker Compose模板文件常用指令**
## docker-compose.yml文件官方文档： https://docs.docker.com/compose/compose-file/

## **image**
指定镜像名称或者镜像id，如果该镜像在本地不存在，Compose会尝试pull下来。

示例：
``` yaml
image: mysql:5.7
```

## **build**
指定Dockerﬁle文件的路径。可以是一个路径，例如： 
``` yaml
version: "3.7"
services:
  webapp:
    build: ./dir
```

也可以是一个对象，用以指定Dockerﬁle和参数，例如：
``` yaml
version: "3.7"
services:
  webapp:
    build:
      context: ./dir
      dockerfile: Dockerfile-alternate
      args:
        buildno: 1
```

如果你指定image和build，那么Compose将使用指定的webapp和可选的tag命名构建的image：
``` yaml
build: ./dir
image: webapp:tag
```

## **command**


## **links**


## **external_links**


## **ports**


## **expose**


## **volumes**


## **volumes_from**


## **environment**


## **env_ﬁle**


## **extends**


## **net**


## **dns**


## **dns_search**