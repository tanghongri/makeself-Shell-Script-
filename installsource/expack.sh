#!/bin/sh
DIR_PATH=$(dirname $(readlink -f "$0"))

if test $# -lt 1
then
	echo "请输入需要安装的包名(不含.zip): packname"
	exit -1
fi


PACK_DIR="/usr/expack"


if test ! -f /usr/expack/$1.zip
then
	echo "file not exist:/usr/expack/$1.zip"
	exit -1
fi

TAR_DIR=$(grep TAR_DIR_${1} /etc/PathConfig.conf |cut -d= -f2|sed 's/^ *\| *$//g')


unzip -o /usr/expack/$1.zip -d $TAR_DIR
