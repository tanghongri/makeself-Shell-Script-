#!/bin/sh
DIR_PATH=$(dirname $(readlink -f "$0"))

CONFIG_FILE=/etc/Config.conf

#增加或修改目标文件一行
#参数：关键词无重复、整行内容、目标内容
function AddOrModifyFileLine {
	KeyWord=$1
    Line=$2
    File=$3
    tempstr=$(grep "$KeyWord" $File  2>/dev/null)
    if [ "$tempstr" = "" ]
	then
        echo "$Line" >>$File
	else
		sed -i "s#^$KeyWord.*#$Line#g" $File
    fi
}


if test ! -f $CONFIG_FILE
then
	echo "file not exit:$CONFIG_FILE"
	exit -1
fi



PACK_NAME=$(grep PACK_NAME $DIR_PATH/pack.conf |cut -d= -f2|sed 's/^ *\| *$//g')
TAR_DIR=$(grep TAR_DIR $DIR_PATH/pack.conf |cut -d= -f2|sed 's/^ *\| *$//g')
EX_PACK_LIST=$(grep EX_PACK_LIST $CONFIG_FILE |cut -d= -f2|sed 's/^ *\| *$//g')

IS_EXIST=$(echo $EX_PACK_LIST | grep $PACK_NAME )


#包位置
mkdir -p /usr/expack
cp -f $DIR_PATH/source.zip /usr/expack/$PACK_NAME.zip

if test "x$IS_EXIST" = "x"
then
	EX_PACK_LIST=$(echo "$EX_PACK_LIST $PACK_NAME")
	AddOrModifyFileLine "EX_PACK_LIST"  "EX_PACK_LIST=$EX_PACK_LIST" "$CONFIG_FILE"
fi

AddOrModifyFileLine "TAR_DIR_${PACK_NAME}"  "TAR_DIR_${PACK_NAME}=$TAR_DIR" "$CONFIG_FILE"

if test ! -f /etc/tools/pack/expack.sh
then
	mkdir -p /etc/tools/pack
	cp $DIR_PATH/expack.sh /etc/tools/pack/expack.sh
	chmod +x /etc/tools/pack/expack.sh
fi

/etc/tools/pack/expack.sh $PACK_NAME
