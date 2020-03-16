# **Dockerfile常用命令**
## 官方文档：https://docs.docker.com/engine/reference/builder/

## **FROM**
FROM指令是重要的一个并且必须为Dockerﬁle文件开篇的第一个非注释行，用于为镜像文件构建过程指定基础镜 像，后续的指令运行于此基础镜像提供的运行环境

这个基础镜像可以是任何可用镜像，默认情况下docker build会从本地仓库找指定的镜像文件，如果不存在就会从 Docker Hub上拉取

语法：
``` shell
FROM <image> 
FROM <image>:<tag> 
FROM <image>@<digest>
```

## **MAINTAINER(depreacted)**
Dockerﬁle的制作者提供的本人详细信息

Dockerﬁle不限制MAINTAINER出现的位置，但是推荐放到FROM指令之后

语法：
``` shell
MAINTAINER <name>
```
name可以是任何文本信息，一般用作者名称或者邮箱

## **LABEL**
给镜像指定各种元数据

语法：
``` shell
LABEL <key>=<value> <key>=<value> <key>=<value>...
```
一个Dockerﬁle可以写多个LABEL，但是不推荐这么做，Dockerﬁle每一条指令都会生成一层镜像，如果LABEL太长可 以使用\符号换行。构建的镜像会继承基础镜像的LABEL，并且会去掉重复的，但如果值不同，则后面的值会覆盖前 面的值。

## **COPY**
用于从宿主机复制文件到创建的新镜像文件

语法：
``` shell
COPY <src>...<dest> 
COPY ["<src>",..."<dest>"] 
# <src>：要复制的源文件或者目录，可以使用通配符 
# <dest>：目标路径，即正在创建的image的文件系统路径；建议<dest>使用绝对路径，否则COPY指令则以WORKDIR为 其起始路径
```
注意：如果你的路径中有空白字符，通常会使用第二种格式

规则：
- <src> 必须是build上下文中的路径，不能是其父目录中的文件 
- 如果 <src> 是目录，则其内部文件或子目录会被递归复制，但 <src> 目录自身不会被复制 
- 如果指定了多个 <src> ，或在 <src> 中使用了通配符，则 <dest> 必须是一个目录，则必须以/符号结尾 
- 如果 <dest> 不存在，将会被自动创建，包括其父目录路径

## **ADD**
基本用法和COPY指令一样，ADD支持使用TAR文件和URL路径

语法：
``` shell
ADD <src>...<dest> 
ADD ["<src>",..."<dest>"]
```

规则：
- 和COPY规则相同 
- 如果 <src> 为URL并且 <dest> 没有以/结尾，则 <src> 指定的文件将被下载到 <dest> 
- 如果 <src> 是一个本地系统上压缩格式的tar文件，它会展开成一个目录；但是通过URL获取的tar文件不会自动 展开 
- 如果 <src> 有多个，直接或间接使用了通配符指定多个资源，则 <dest> 必须是目录并且以/结尾

## **WORKDIR**
用于为Dockerﬁle中所有的RUN、CMD、ENTRYPOINT、COPY和ADD指定设定工作目录，只会影响当前WORKDIR 之后的指令。

语法：
``` shell
WORKDIR <dirpath>
```
在Dockerﬁle文件中，WORKDIR可以出现多次，路径可以是相对路径，但是它是相对于前一个WORKDIR指令指定的 路径

另外，WORKDIR可以是ENV指定定义的变量


## **VOLUME**
用来创建挂载点，可以挂载宿主机上的卷或者其他容器上的卷

语法：
``` shell
VOLUME <mountpoint> 
VOLUME ["<mountpoint>"]
```
不能指定宿主机当中的目录，宿主机挂载的目录是自动生成的

## **EXPOSE**
用于给容器打开指定要监听的端口以实现和外部通信

语法：
``` shell
EXPOSE <port>[/<protocol>] [<port>[/<protocol>]...]
```
<protocol> 用于指定传输层协议，可以是TCP或者UDP，默认是TCP协议

EXPOSE可以一次性指定多个端口，例如： EXPOSE 80/tcp 80/udp

## **ENV**
用来给镜像定义所需要的环境变量，并且可以被Dockerﬁle文件中位于其后的其他指令(如ENV、ADD、COPY等)所调 用，调用格式：$variable_name或者${variable_name}

语法：
``` shell
ENV <key> <value> 
ENV <key>=<value>...
```
第一种格式中， <key> 之后的所有内容都会被视为 <value> 的组成部分，所以一次只能设置一个变量

第二种格式可以一次设置多个变量，如果 <value> 当中有空格可以使用\进行转义或者对 <value> 加引号进行标识； 另外\也可以用来续行 

## **ARG**
用法同ENV

语法：
``` shell
ARG <name>[=<default value>]
```
指定一个变量，可以在docker build创建镜像的时候，使用--build-arg <varname>=<value> 来指定参数

## **RUN**
用来指定docker build过程中运行指定的命令

语法：
``` shell
RUN <command> 
RUN ["<executable>","<param1>","<param2>"]
```
第一种格式里面的参数一般是一个shell命令，以 /bin/sh -c 来运行它

第二种格式中的参数是一个JSON格式的数组，当中 <executable> 是要运行的命令，后面是传递给命令的选项或者 参数；但是这种格式不会用 /bin/sh -c 来发起，所以常见的shell操作像变量替换和通配符替换不会进行；如果你运 行的命令依赖shell特性，可以替换成类型以下的格式
``` shell
RUN ["/bin/bash","-c","<executable>","<param1>"]
```

## **CMD**
容器启动时运行的命令

语法：
``` shell
CMD <command> 
CMD ["<executable>","<param1>","<param2>"] 
CMD ["<param1>","<param2>"
```
前两种语法和RUN相同 

第三种语法用于为ENTRYPOINT指令提供默认参数

RUN和CMD区别： 
- RUN指令运行于镜像文件构建过程中，CMD则运行于基于Dockerﬁle构建出的新镜像文件启动为一个容器的时候 
- CMD指令的主要目的在于给启动的容器指定默认要运行的程序，且在运行结束后，容器也将终止；不过，CMD 命令可以被docker run的命令行选项给覆盖 
- Dockerﬁle中可以存在多个CMD指令，但是只有后一个会生效

## **ENTRYPOINT**
类似于CMD指令功能，用于给容器指定默认运行程序

语法：
``` shell
ENTRYPOINT<command> 
ENTRYPOINT["<executable>","<param1>","<param2>"]
```
和CMD不同的是ENTRYPOINT启动的程序不会被docker run命令指定的参数所覆盖，而且，这些命令行参数会被当 做参数传递给ENTRYPOINT指定的程序(但是，docker run命令的--entrypoint参数可以覆盖ENTRYPOINT)

docker run命令传入的参数会覆盖CMD指令的内容并且附加到ENTRYPOINT命令后作为其参数使用 

同样，Dockerﬁle中可以存在多个ENTRYPOINT指令，但是只有后一个会生效

Dockerﬁle中如果既有CMD又有ENTRYPOINT，并且CMD是一个完整可执行命令，那么谁在后谁生效

## **ONBUILD**
用来在Dockerﬁle中定义一个触发器

语法：
``` shell
ONBUILD <instruction>
```
Dockerﬁle用来构建镜像文件，镜像文件也可以当成是基础镜像被另外一个Dockerﬁle用作FROM指令的参数

在后面这个Dockerﬁle中的FROM指令在构建过程中被执行的时候，会触发基础镜像里面的ONBUILD指令 

ONBUILD不能自我嵌套，ONBUILD不会触发FROM和MAINTAINER指令

在ONBUILD指令中使用ADD和COPY要小心，因为新构建过程中的上下文在缺少指定的源文件的时候会失败
