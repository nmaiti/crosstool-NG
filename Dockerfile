FROM phusion/baseimage:0.9.15

MAINTAINER m.maatkamp@gmail.com version: 0.1

# ---
# crosstool-NG
#  see https://github.com/marcelmaatkamp/crosstool-NG

RUN apt-get update && apt-get dist-upgrade -y
RUN apt-get install -y git autoconf build-essential gperf bison flex texinfo libtool libncurses5-dev wget gawk libc6-dev python-serial libexpat-dev

RUN mkdir /home/swuser
RUN groupadd -r swuser -g 433 && useradd -u 431 -r -g swuser -d /home/swuser -s /sbin/nologin -c "Docker image user" swuser && chown -R swuser:swuser /home/swuser
RUN chown -R swuser /home/swuser

RUN mkdir /opt/Espressif
RUN chown -R swuser /opt/Espressif
WORKDIR /opt/Espressif
USER swuser
RUN git clone -b lx106 git://github.com/jcmvbkbc/crosstool-NG.git 

WORKDIR /opt/Espressif/crosstool-NG
RUN ./bootstrap && ./configure --prefix=`pwd` && make && make install
RUN ./ct-ng xtensa-lx106-elf
RUN ./ct-ng build
ENV PATH=$PWD/builds/xtensa-lx106-elf/bin:$PATH
