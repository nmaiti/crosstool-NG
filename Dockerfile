# FROM phusion/baseimage:0.9.15

FROM ubuntu:14.04

MAINTAINER m.maatkamp@gmail.com version: 0.1

# ---
# crosstool-NG
#  see https://github.com/marcelmaatkamp/crosstool-NG

RUN apt-get update && apt-get dist-upgrade -y
RUN apt-get install -y git autoconf build-essential gperf bison flex texinfo libtool libncurses5-dev wget gawk libc6-dev python-serial libexpat-dev unzip

RUN mkdir /home/swuser
RUN groupadd -r swuser -g 433 
RUN useradd -u 431 -r -g swuser -d /home/swuser -s /sbin/nologin -c "Docker image user" swuser 
RUN chown -R swuser:swuser /home/swuser
RUN adduser swuser sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN mkdir /opt/Espressif
RUN chown -R swuser /opt/Espressif
WORKDIR /opt/Espressif
USER swuser

RUN git clone -b lx106 git://github.com/jcmvbkbc/crosstool-NG.git 

WORKDIR /opt/Espressif/crosstool-NG
RUN ./bootstrap && ./configure --prefix=`pwd` && make && sudo make install
RUN ./ct-ng xtensa-lx106-elf
RUN ./ct-ng build
ENV PATH $PWD/builds/xtensa-lx106-elf/bin:$PATH

WORKDIR /opt/Espressif
RUN mkdir ESP8266_SDK
RUN wget -O esp_iot_sdk_v0.9.3_14_11_21.zip https://github.com/esp8266/esp8266-wiki/raw/master/sdk/esp_iot_sdk_v0.9.3_14_11_21.zip
RUN wget -O esp_iot_sdk_v0.9.3_14_11_21_patch1.zip https://github.com/esp8266/esp8266-wiki/raw/master/sdk/esp_iot_sdk_v0.9.3_14_11_21_patch1.zip
RUN unzip esp_iot_sdk_v0.9.3_14_11_21.zip
RUN unzip -o esp_iot_sdk_v0.9.3_14_11_21_patch1.zip
RUN mv esp_iot_sdk_v0.9.3 ESP8266_SDK
RUN mv License ESP8266_SDK/
RUN rm esp_iot_sdk_v0.9.3_14_11_21.zip esp_iot_sdk_v0.9.3_14_11_21_patch1.zip 

WORKDIR /opt/Espressif/ESP8266_SDK/esp_iot_sdk_v0.9.3
RUN sed -i -e 's/xt-ar/xtensa-lx106-elf-ar/' -e 's/xt-xcc/xtensa-lx106-elf-gcc/' -e 's/xt-objcopy/xtensa-lx106-elf-objcopy/' Makefile
RUN mv examples/IoT_Demo .

RUN wget -O lib/libc.a https://github.com/esp8266/esp8266-wiki/raw/master/libs/libc.a
RUN wget -O lib/libhal.a https://github.com/esp8266/esp8266-wiki/raw/master/libs/libhal.a
RUN wget -O include.tgz https://github.com/esp8266/esp8266-wiki/raw/master/include.tgz
RUN tar -xvzf include.tgz

WORKDIR /opt/Espressif
# RUN wget -O esptool_0.0.2-1_i386.deb https://github.com/esp8266/esp8266-wiki/raw/master/deb/esptool_0.0.2-1_i386.deb
# RUN dpkg -i esptool_0.0.2-1_i386.deb
RUN git clone https://github.com/tommie/esptool-ck.git
RUN cd esptool-ck && make 

RUN git clone https://github.com/themadinventor/esptool esptool-py

RUN ln -s $PWD/esptool-py/esptool.py crosstool-NG/builds/xtensa-lx106-elf/bin/
RUN apt-get install -y libtool

ENV PATH $PATH:/opt/Espressif/crosstool-NG/builds/xtensa-lx106-elf/bin
ENV CPATH $CPATH:/opt/Espressif/ESP8266_SDK/esp_iot_sdk_v0.9.3/include/
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/opt/Espressif/esp_iot_sdk_v0.9.2/lib

# Examples:
#  https://github.com/esp8266/esp8266-wiki/wiki/Building

WORKDIR /opt/Espressif/ESP8266_SDK/esp_iot_sdk_v0.9.3
RUN ln -s /opt/Espressif/ESP8266_SDK/esp_iot_sdk_v0.9.3/ld /opt/Espressif/ESP8266_SDK/ld
RUN make 

WORKDIR /opt/Espressif
RUN git clone https://github.com/esp8266/source-code-examples.git
RUN ln -s /opt/Espressif/ESP8266_SDK/esp_iot_sdk_v0.9.3/ld  /opt/Espressif/source-code-examples/ld
RUN cd source-code-examples/blinky && make
