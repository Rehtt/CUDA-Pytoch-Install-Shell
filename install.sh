#!/bin/bash

if ! [ -r /root ];then
    echo "需要root权限执行该脚本"
    exit
fi
apt update
apt upgrade -y
#脚本绝对路径
SHELL_FOLDER=$(dirname "$0")

#获取系统信息
. /etc/lsb-release
OS=$DISTRIB_ID                              #eg. Ubuntu
OS_RELEASE=$DISTRIB_RELEASE                 #eg. 16.04
OS_CODENAME=$DISTRIB_CODENAME               #eg. xenial
OS_DESCRIPTION=$DISTRIB_DESCRIPTION         #eg. Ubuntu 16.04.6 LTS
OS_ARCH=""
if [ -n "$(uname -a | grep x86_64)" ] ;then
    OS_ARCH=x86_64
elif [ -n "$(uname -a | grep ppc64le)" ] ;then
    OS_ARCH=ppc64le
else
    echo "cuda仅支持x86_64和ppc64le"
fi

#判断是否有gcc make
if ! [ -s /usr/bin/gcc ] && ! [ -s /usr/bin/make ]
then
    apt install make gcc -y
    if ! [ -s /usr/bin/gccc ] && ! [ -s /usr/bin/make ];then
            echo "安装gcc make失败，检查网络重试"
            exit
    fi
fi

#cuda
if ! [ -s /usr/local/cuda-10.0 ];then
    echo "安装cuda..."
    URL=""
    KEY="/var/cuda-repo-<version>/7fa2af80.pub"
    case "$OS" in
        "Ubuntu" )
            if [ "$OS_ARCH" == "ppc64le" ] ;then
                if [ "OS_RELEASE" == "18.04"] ;then
                    URL="https://developer.nvidia.com/compute/cuda/10.0/Prod/local_installers/cuda-repo-ubuntu1804-10-0-local-10.0.130-410.48_1.0-1_ppc64el"
                else
                    echo "ppc64le只支持18.04"
                    exit
                fi
            fi
            
            case "$OS_RELEASE" in
                "18.04")
                    URL="https://developer.nvidia.com/compute/cuda/10.0/Prod/local_installers/cuda_10.0.130_410.48_linux"
                ;;
                "16.04")
                    URL="https://developer.nvidia.com/compute/cuda/10.0/Prod/local_installers/cuda_10.0.130_410.48_linux"
                ;;
                "14.04")
                    URL="https://developer.nvidia.com/compute/cuda/10.0/Prod/local_installers/cuda_10.0.130_410.48_linux"
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
    
    if ! [ -s /tmp/cuda.run ];then
        wget $URL -O "/tmp/cuda.run"
    fi
    web_size=$(curl -L --head $URL | grep content-length | awk '{print $2}' | tr -cd "[0-9]")
    file_size=$(ls -l /tmp/cuda.run | awk '{print $5}')
    if [ "0169$file_size" == "$web_size" ];then
        chmod +x /tmp/cuda.run
        bash /tmp/cuda.run
    else
        rm /tmp/cuda.run
        echo "下载失败，检查网络重试"
    fi

    if ! [ -s /usr/local/cuda-10.0 ];then
        echo "cuda 安装失败"
        exit
    fi
    echo "cuda安装完毕"
fi

#检查python3是否安装
if ! [ -s /usr/bin/python3 ] && ! [ -s /usr/bin/pip3 ];then
    apt install python3 -y
    apt install python3-pip -y
fi
#python3.x版本
v=0
if [ -n "$(python3 -V|grep 3.5)" ];then
    v=35
elif [ -n "$(python3 -V|grep 3.6)" ];then
    v=36
elif [ -n "$(python3 -V|grep 3.7)" ];then
    v=37
fi
#安装必要的文件
apt install libsm-dev -y
apt install libxrender-dev -y
# apt install libcublas9.1 -y
pip_install(){
    pip_yuan="https://pypi.tuna.tsinghua.edu.cn/simple"
    pip3 install -i $pip_yuan $1
    if [ -z "$(pip3 list|grep $name)" ]
    then
        echo "${name}安装失败"
        echo "是否重试？ [Y/n]"
        read r
        if [ "$r" == "Y" ] || [ "$r" == "y" ] || [ -z "$r" ]
        then
            pip_install $name
        else
            exit
        fi
    fi
}
pip3 install https://download.pytorch.org/whl/cu100/torch-1.1.0-cp${v}-cp${v}m-linux_x86_64.whl
pip3 install https://download.pytorch.org/whl/cu100/torchvision-0.3.0-cp${v}-cp${v}m-linux_x86_64.whl
pip_name=(opencv-python cupy-cuda100 scikit-image torchnet)
for name in ${pip_name[*]}
do
    pip_install $name
done

ldconfig /usr/local/cuda-10.0/lib64/
