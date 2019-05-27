#!/bin/bash

#脚本绝对路径
SHELL_FOLDER=$(dirname "$0")

#获取系统信息
. /etc/lsb-release
OS=$DISTRIB_ID                              #eg. Ubuntu
OS_RELEASE=$DISTRIB_RELEASE                 #eg. 16.04
OS_CODENAME=$DISTRIB_CODENAME               #eg. xenial
OS_DESCRIPTION=$DISTRIB_DESCRIPTION         #eg. Ubuntu 16.04.6 LTS
OS_ARCH=""
if [ -n $(uname -a | grep x86_64) ];then
    OS_ARCH=x86_64
elif [ -n $(uname -a | grep ppc64le) ];then
    OS_ARCH=ppc64le
else
    echo "cuda仅支持x86_64和ppc64le"
fi

#判断是否有gcc
if [ -s /usr/bin/gccc ] && [ -s /usr/bin/make ]
then
        echo "安装cuda..."
        URL=""
        KEY="http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/7fa2af80.pub"
        case "$OS" in
            "Ubuntu" )
                if [ "$OS_ARCH" == "ppc64le" ];then
                    if [ "OS_RELEASE" == "18.04"];then
                        URL="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/ppc64el/cuda-repo-ubuntu1804_10.0.130-1_ppc64el.deb"
                    else
                        echo "ppc64le只支持18.04"
                        exit
                    fi
                fi
                
                case "$OS_RELEASE" in
                    "18.04")
                        URL="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.0.130-1_amd64.deb"
                    ;;
                    "16.04")
                        URL="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_10.0.130-1_amd64.deb"
                    ;;
                    "14.04")
                        URL="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-repo-ubuntu1404_10.0.130-1_amd64.deb"
                    ;;
                    * )
                        echo "ubuntu 支持18.04\16.04\14.04"
                        exit
                    esac
            ;;
            * )
                echo "该脚本暂支持ubuntu"
                exit
            esac

        wget $URL -O "/tmp/cuda.deb"
        if [ -s "/tmp/cuda.deb" ];then
            web_size=$(curl -L --head $URL | grep content-length | awk '{print $2}' | tr -cd "[0-9]")
            file_size=$(ls -l /tmp/cuda.deb | awk '{print $5}')
            if [ "0169$file_size" == "$web_size" ];then
                dpkg -i /tmp/cuda.deb
                apt-key adv --fetch-keys $KEY
                apt update
                apt install cuda
            else
                echo "下载失败，检查网络重试"
                exit
        else
            echo "下载失败，检查网络重试"
            exit
        fi
        if ! [ -e /usr/local/cuda-10.0 ];then
            echo "cuda 安装失败"
            exit
        fi
        echo "cuda安装完毕"
else
        apt install make gcc
        if ! [ -s /usr/bin/gccc ] && ! [ -s /usr/bin/make ];then
                echo "安装gcc make失败，检查网络重试"
                exit
        fi
fi

python3=/usr/bin/python3.
#判断python版本是否是3.5版
if [ -s $python3"6" ]
then
        echo "python3.6"
elif [ -s $python3"5" ]
then
        if [ -s /usr/bin/pip3 ];then
            apt install python3-pip -y
            pip3 install opencv-python
            pip3 install https://download.pytorch.org/whl/cu100/torch-1.1.0-cp35-cp35m-linux_x86_64.whl
            pip3 install https://download.pytorch.org/whl/cu100/torchvision-0.3.0-cp35-cp35m-linux_x86_64.whl
            pip3 install cupy-cuda100
            if [ -n "$(pip3 list|grep opencv)" ] && [ -n "$(pip3 list|grep torch)" ] && [ -n "$(pip3 list|grep torchvision)" ];then
                echo "安装成功"
            else
                echo "安装失败"
            fi
fi
