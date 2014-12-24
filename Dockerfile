# FRO phusion/baseimage:0.9.15



FROM ubuntu:14.04

MAINTAINER m.maatkamp@gmail.com version: 0.1

# ---
# crosstool-NG
#  see https://github.com/marcelmaatkamp/crosstool-NG

RUN apt-get update && apt-get dist-upgrade -y
RUN apt-get install -y git autoconf build-essential gperf bison flex texinfo libtool libncurses5-dev wget gawk libc6-dev python-serial libexpat-dev unzip libtool

RUN mkdir /home/swuser
RUN groupadd -r swuser -g 433 
RUN useradd -u 431 -r -g swuser -d /home/swuser -s /sbin/nologin -c "Docker image user" swuser 
RUN chown -R swuser:swuser /home/swuser
RUN adduser swuser sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN mkdir /opt/Espressif
RUN chown -R swuser:swuser /opt/Espressif
WORKDIR /opt/Espressif
USER swuser

RUN git clone -b lx106 git://github.com/jcmvbkbc/crosstool-NG.git 

WORKDIR /opt/Espressif/crosstool-NG
RUN ./bootstrap && ./configure --prefix=`pwd` && make && sudo make install
RUN ./ct-ng xtensa-lx106-elf
RUN ./ct-ng build
ENV PATH .:/opt/Espressif/crosstool-NG/builds/xtensa-lx106-elf/bin:/opt/Espressif/esptool-ck:$PATH

WORKDIR /opt/Espressif
RUN mkdir ESP8266_SDK
RUN wget -O esp_iot_sdk_v0.9.3_14_11_21.zip https://github.com/esp8266/esp8266-wiki/raw/master/sdk/esp_iot_sdk_v0.9.3_14_11_21.zip
RUN wget -O esp_iot_sdk_v0.9.3_14_11_21_patch1.zip https://github.com/esp8266/esp8266-wiki/raw/master/sdk/esp_iot_sdk_v0.9.3_14_11_21_patch1.zip
RUN unzip esp_iot_sdk_v0.9.3_14_11_21.zip
RUN unzip -o esp_iot_sdk_v0.9.3_14_11_21_patch1.zip
RUN for i in `ls esp_iot_sdk_v0.9.3`; do  echo $i;  mv esp_iot_sdk_v0.9.3/$i ESP8266_SDK/; done
RUN sudo rm -rf esp_iot_sdk_v0.9.3
RUN mv License ESP8266_SDK/
RUN rm esp_iot_sdk_v0.9.3_14_11_21.zip esp_iot_sdk_v0.9.3_14_11_21_patch1.zip 

WORKDIR /opt/Espressif/ESP8266_SDK
RUN sed -i -e 's/xt-ar/xtensa-lx106-elf-ar/' -e 's/xt-xcc/xtensa-lx106-elf-gcc/' -e 's/xt-objcopy/xtensa-lx106-elf-objcopy/' Makefile
RUN mv examples/IoT_Demo .

RUN wget -O lib/libc.a https://github.com/esp8266/esp8266-wiki/raw/master/libs/libc.a
RUN wget -O lib/libhal.a https://github.com/esp8266/esp8266-wiki/raw/master/libs/libhal.a
RUN wget -O include.tgz https://github.com/esp8266/esp8266-wiki/raw/master/include.tgz
RUN tar -xvzf include.tgz

WORKDIR /opt/Espressif
# RUN wget -O esptool_0.0.2-1_i386.deb https://github.com/esp8266/esp8266-wiki/raw/master/deb/esptool_0.0.2-1_i386.deb
# RUN sudo dpkg -i esptool_0.0.2-1_i386.deb
RUN git clone https://github.com/tommie/esptool-ck.git
RUN cd esptool-ck && make && sudo cp esptool /usr/bin

RUN git clone https://github.com/themadinventor/esptool esptool-py

RUN sudo ln -s $PWD/esptool-py/esptool.py crosstool-NG/builds/xtensa-lx106-elf/bin/

ENV CPATH /opt/Espressif/ESP8266_SDK/include
ENV LD_LIBRARY_PATH /opt/Espressif/ESP8266_SDK/lib
RUN export 

# Examples:
#  https://github.com/esp8266/esp8266-wiki/wiki/Building

WORKDIR /opt/Espressif/ESP8266_SDK
RUN make 

WORKDIR /opt/Espressif
RUN git clone https://github.com/esp8266/source-code-examples.git
RUN ln -s /opt/Espressif/ESP8266_SDK/esp_iot_sdk_v0.9.3/ld  /opt/Espressif/source-code-examples/ld
RUN cd source-code-examples/blinky && make

WORKDIR /opt/Espressif/ESP8266_SDK
RUN wget -O at_v0.20_14_11_28.zip https://github.com/esp8266/esp8266-wiki/raw/master/sdk/at_v0.20_14_11_28.zip
RUN unzip at_v0.20_14_11_28.zip && rm -rf at_v0.20_14_11_28.zip
RUN cd at_v0.20_on_SDKv0.9.3 && for i in `ls at`; do mv at/$i .; done && make 

WORKDIR /opt/Espressif/ESP8266_SDK/IoT_Demo
RUN make
WORKDIR /opt/Espressif/ESP8266_SDK/IoT_Demo/.output/eagle/debug/image
RUN esptool -eo eagle.app.v6.out -bo eagle.app.v6.flash.bin -bs .text -bs .data -bs .rodata -bc -ec
RUN xtensa-lx106-elf-objcopy --only-section .irom0.text -O binary eagle.app.v6.out eagle.app.v6.irom0text.bin
RUN cp eagle.app.v6.flash.bin ../../../../../bin/
RUN cp eagle.app.v6.irom0text.bin ../../../../../bin/

WORKDIR /opt/Espressif/crosstool-NG/builds/xtensa-lx106-elf/bin
RUN for i in `ls`; do  filename=`echo $i|sed -e 's/xtensa-lx106-elf-//'`; sudo ln -s xtensa-lx106-elf-$filename /opt/Espressif/crosstool-NG/builds/xtensa-lx106-elf/bin/xt-$filename; done
RUN sudo ln -s /opt/Espressif/crosstool-NG/builds/xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc /opt/Espressif/crosstool-NG/builds/xtensa-lx106-elf/bin/xt-xcc

WORKDIR /opt/Espressif
RUN git clone https://github.com/nodemcu/nodemcu-firmware.git
WORKDIR /opt/Espressif/nodemcu-firmware
RUN cat /opt/Espressif/ESP8266_SDK/include/sys/fcntl.h | sed -e 's/#include <xtensa\/simcall-fcntl.h>/\/\/ #include <xtensa\/simcall-fcntl.h>/g' > /opt/Espressif/ESP8266_SDK/include/sys/fcntl.h.bak
RUN mv /opt/Espressif/ESP8266_SDK/include/sys/fcntl.h.bak /opt/Espressif/ESP8266_SDK/include/sys/fcntl.h
RUN cat /opt/Espressif/ESP8266_SDK/include/machine/setjmp.h | sed -e 's/#if __XTENSA_WINDOWED_ABI__/#ifdef __XTENSA_WINDOWED_ABI__/g' > /opt/Espressif/ESP8266_SDK/include/machine/setjmp.h.bak && sudo mv /opt/Espressif/ESP8266_SDK/include/machine/setjmp.h.bak /opt/Espressif/ESP8266_SDK/include/machine/setjmp.h
RUN cat /opt/Espressif/nodemcu-firmware/app/Makefile | sed -e 's/-L..\/lib/-L..\/lib -L\/opt\/Espressif\/ESP8266_SDK\/lib/g' >  /opt/Espressif/nodemcu-firmware/app/Makefile.bak && mv /opt/Espressif/nodemcu-firmware/app/Makefile.bak /opt/Espressif/nodemcu-firmware/app/Makefile
RUN make

WORKDIR /opt/Espressif
