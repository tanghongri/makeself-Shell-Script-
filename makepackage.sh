#!/bin/sh
#脚本路径
DIR_PATH=$(dirname $(readlink -f "$0"))
#制作脚本版本
MP_VERSION=1.0.0.1

###################安装相关设置###################
#安装文件沐浴露
SOURCEDIR=""
#目标包名称
PACKGENAME=""
#临时文件路径
TEMPFILE="$DIR_PATH/Temp.dat"
#安装包启动脚本名称
INSTALLNAME="install.sh"

###################脚本头相关设置###################
#安装参数
INSTALL_ARGS=""
#解包脚本位置
HEADER="$DIR_PATH/header.sh"
#HEADER脚本行数
SKIP=0

###################文件相关设置###################
#许可协议
LICENSE=""
#文件数量
FILECOUNT=1
#文件大小，多个中间用空格隔开
FILESIZES=""
#空间大小（K），多个中间用空格隔开
USIZES=""
#md5列表，多个中间用空格隔开
MD5S=""

###################压缩设置###################
#压缩等级
COMPRESS_LEVEL=9
#压缩和解压缩命令
GZIP_CMD="gzip -c$COMPRESS_LEVEL"
GUNZIP_CMD="gzip -cd"
TAR_ARGS="cf"

###################帮助信息###################
Help()
{
  	echo "使用: $0"
    echo "参数配置: \$1 安装文件目录,\$2 目标包名"
    echo "可选参数可以下列参数组合:"
    echo "    --help|-h        : 帮助信息"
    echo "    --license|-l     : 软件许可协议(默认当前目录LICENSE.txt)"
	echo "    --install|-i     : 启动安装脚本名称(默认install.sh)"
	echo "    --args|-a	       : 添加执行参数"
    exit -1
}
###################处理可选参数###################
while true
do
	case "$1" in
	--help|-h)
	Help
		;;
	--license|-l)
		LICENSE=$(cat $2)
		if ! shift 2; then Help; exit 2; fi
		;;
	--install|-i)
		INSTALLNAME=$2
        if ! shift 2; then Help; exit 2; fi
        ;;
	--args|-a)
		INSTALL_ARGS=$2
        if ! shift 2; then Help; exit 2; fi
        ;;
	-*)
	echo "未知参数 : $1"
		Help
		;;
   	*)
		break
		;;
    esac
done
###################参数判断###################
if test $# -lt 2
then
	Help	
fi
	
#安装包资源文件夹
if test -d "$1"
then
	SOURCEDIR="$1"
else
	echo "Error:资源文件夹 $1 不存在." >&2
	exit -1
fi

#目标包名称
PACKGENAME=$2

#LICENSE
if test "$LICENSE" = ""
then
	if test -f "$DIR_PATH/LICENSE.txt"
	then
		LICENSE=$(cat "$DIR_PATH/LICENSE.txt")
	else
		echo "WARNING: $DIR_PATH/LICENSE.txt不存在." >&2
	fi
fi

#查找md5sum
MD5_PATH=`exec <&- 2>&-; command -v md5sum || which md5sum || type md5sum`
if test ! -x "$MD5_PATH"
then  		
    echo "MD5: 未找到 md5sum 命令"
	exit 1
fi

#计算HEADER脚本行数
if test -f "$HEADER"
then
	TARNAME="$TEMPFILE"
	. "$HEADER"
	SKIP=`cat "$TEMPFILE" |wc -l`
	rm -f "$TEMPFILE"
	echo "Header 文件 $SKIP 行" >&2
else
	echo "打开 header 文件失败: $HEADER" >&2
	exit 2
fi
#
if test -f "$PACKGENAME"
then
   	echo "WARNING: 覆盖已存在包: $PACKGENAME" >&2
fi

MD5_CODE=00000000000000000000000000000000
##########################################################################处理安装包
	USIZE=`du -ks "$SOURCEDIR" | awk '{print $1}'`
	echo "安装文件: $SOURCEDIR $USIZE KB"
	echo "开始压缩文件 $SOURCEDIR"
	exec 3<> "$TEMPFILE"
	(cd "$SOURCEDIR" && ( tar -$TAR_ARGS - . | eval "$GZIP_CMD" >&3 ) ) || { echo "Aborting:找到临时文件: $TEMPFILE"; exec 3>&-; rm -f "$TEMPFILE"; exit 3; }
	exec 3>&- # try to close the archive
	#计算文件大小
	FSIZE=`wc -c "$TEMPFILE" | awk '{printf $1}'`
	#计算md5
	MD5_CODE=`eval "$MD5_PATH $TEMPFILE" | awk '{printf $1}'`
	echo "$SOURCEDIR MD5: $MD5_CODE"	
	USIZES=$USIZE
	FILESIZES=$FSIZE;
	MD5S=$MD5_CODE	
	
#生成HEADER脚本
TARNAME="$PACKGENAME"
. "$HEADER"
#复制一份方便查看问题
cp -f $TARNAME $DIR_PATH/InstallTemp.sh
#连接文件

echo "复制 $SOURCEDIR"
cat "$TEMPFILE" >> "$TARNAME"

chmod +x "$TARNAME"
rm -f "$TEMPFILE"
echo "安装包制作成功:$TARNAME"


