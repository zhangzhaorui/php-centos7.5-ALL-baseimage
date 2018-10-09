## php的Base版镜像
* 这个是针对php环境的基础image，打入image中的内容可以看Dockerfile
* 真正的php应用程序，需要FROM此image
* 通过supervisor管理的php，具体的program的supervisor配置文件在真正的php program image中，不再此镜像中
* php program需要的env文件不在此镜像中
* Dockerfile中有对每一步的操作的解释，可以继续完善
* 请勿调整dockerfile中各个语句顺序，有从上到下顺序依赖
* 无cache情况下重新build需要30分钟左右，过慢，镜像过大。后期优化，可以将所需公网资源拉取到本地，通过copy或者add添加到image中
* yum过程太慢，需要一个本地yum源
* 此image中的各个组件的update需要重新build镜像
