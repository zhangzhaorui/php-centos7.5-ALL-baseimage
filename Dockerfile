#基础镜像版本采用CentOS7.5
FROM 172.18.130.36/library/centos:7.5.1804
#描述image制作人
MAINTAINER ZhangNianshen "nianshenlovelily@gmail.com"
#调整时区为东八区
RUN cp usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#创建标准文件夹
RUN mkdir -p /opt/shell /tools /application /log
#创建www-data用户
RUN useradd  www-data -u 66  -s /sbin/nologin
#备份centos默认官方源
RUN mv /etc/yum.repos.d/* /root/
#更换yum源为国内阿里源
COPY CentOS7-Base-aliyuan.repo /etc/yum.repos.d/
#安装epel源，清除并重建yum缓存，执行update
RUN yum clean all && \
    yum makecache && \
    yum -y install epel-release && \
    yum -y update 
#安装基础依赖
RUN yum -y install nodejs curl lrzsz net-tools telnet mlocate sshpass wget  sysstat ntp  tar psmisc vim bind-utils unzip gcc gcc-c++ python-setuptools python-devel automake bison flex git libboost1.55 libevent-dev libssl-dev libtool make pkg-config
#安装nginx-1.14.0
RUN yum -y install http://nginx.org/packages/rhel/7/x86_64/RPMS/nginx-1.14.0-1.el7_4.ngx.x86_64.rpm
#安装nodejs
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash && \
    source /root/.bashrc && \
    #nvm ls-remote && \
    nvm install v9.10.1 && \
    echo "export PATH=$GRADLE_HOME/bin:$PATH:/root/.nvm/versions/node/v9.10.1/bin" >> /etc/profile && \
    source /etc/profile && \
    node -v
#安装gulp
RUN npm install gulp -g
#安装yarn
RUN curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo && \
    yum -y install yarn
#安装php及其扩展插件
#RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
RUN rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm  && \
    yum -y remove php-common-5.4.16 && \
    yum -y install php70w php70w-cli  php70w-pear php70w-fpm php70w-mysqlnd php70w-gd php70w-mcrypt php70w-xml php70w-mbstring php70w-bcmath php70w-pecl-imagick-devel php70w-devel php70w-pecl-redis php70w-opcache php70w-soap
#编译安装php-zookeeper插件
RUN cd /tools/ && \
    wget https://mirrors.tuna.tsinghua.edu.cn/apache/zookeeper/stable/zookeeper-3.4.12.tar.gz && \
    tar zxvf zookeeper-3.4.12.tar.gz -C /application/ && \
    cd /application/zookeeper-3.4.12/src/c && \
    ./configure --prefix=/usr/local/zookeeperlib && \
    make -j8 && \
    make install
#编译安装zk扩展
RUN cd /tools/ && \
    wget https://github.com/php-zookeeper/php-zookeeper/archive/v0.5.0.zip && \
    unzip v0.5.0.zip -d /application/ && \
    cd /application/php-zookeeper-0.5.0 && \
    phpize && \
    ./configure --with-libzookeeper-dir=/usr/local/zookeeperlib && \
    make -j8 && \
    make install
#编译安装Thrift
RUN cd /tools/ && \
    wget http://mirrors.hust.edu.cn/apache/thrift/0.11.0/thrift-0.11.0.tar.gz && \
    tar -zxvf thrift-0.11.0.tar.gz -C /application/ && \
    cd /application/thrift-0.11.0 && \
    ./configure --with-cpp --with-boost --with-python --without-csharp --with-java --without-erlang --without-perl --with-php --without-php_extension --without-ruby --without-haskell  --without-go --without-nodejs && \
    make -j8 && \
    make -j8 install && \
    ln -s /usr/local/bin/thrift /usr/bin/thrift
#编译安装ghostscript
COPY ./ghostscript-9.22-linux-x86_64.tgz  /tools 
RUN  tar xf /tools/ghostscript-9.22-linux-x86_64.tgz -C /application/ && \
     cd /application/ghostscript-9.22-linux-x86_64 && \ 
     mv /usr/bin/gs /root/g-sbackup && \
     cp  gs-922-linux-x86_64 /usr/bin/gs
#安装composer
RUN yum -y install composer supervisor
RUN mv  /etc/supervisord.conf /etc/supervisord.confbak && \
    sed -i 's/listen = 127.0.0.1:9000/listen = 0.0.0.0:9000/' /etc/php-fpm.d/www.conf && \
    sed -i 's/listen.allowed_clients = 127.0.0.1/;listen.allowed_clients = 127.0.0.1/' /etc/php-fpm.d/www.conf
RUN echo '*               -       nofile          102400 ' >>/etc/security/limits.conf  && \
    echo '*               -       nproc          102400 ' >>/etc/security/limits.conf   && \
    echo '*               -       core          unlimited ' >>/etc/security/limits.conf
#将zookeeper.so引入php.ini
RUN sed -i '850 aextension = "zookeeper.so"'  /etc/php.ini
#修改supervisor配置文件
COPY supervisord.conf /etc/
#暴露端口
EXPOSE 9000 80
#启动php
CMD ["/sbin/php-fpm"]
