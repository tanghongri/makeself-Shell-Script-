#!/bin/sh
#制作脚本版本
MP_VERSION=1.0.0.0
#HEADER脚本行数
SKIP=0
#解包脚本位置
HEADER="$(dirname $0)/header.sh"
#安装包文件名称
FILENAME=""
#目标包名称
TARNAME=""
#校验程序名称
CHECKNAME="Check"
#安装脚本名称
INSTALLNAME="Install.sh"
#临时文件路径
TEMPFILE="$(dirname $0)/Temp$$"
#许可协议
LICENSE=""
#文件大小，多个中间用空格隔开
FILESIZES=""
#空间大小（K），多个中间用空格隔开
USIZES=""
#md5列表，多个中间用空格隔开
MD5S=""

###################帮助信息###################
Help()
{
  	echo "使用: $0"
    	echo "参数配置: \$1 当前目录下安装包名称，\$2 目标包名称"
    	echo "可选参数可以下列参数组合:"
    	echo "    --help | -h        : 帮助信息"
    	echo "    --license|-l       : 软件许可协议(默认LICENSE.txt)"
    	echo "Do not forget to give a fully qualified startup script name"
    	echo "(i.e. with a ./ prefix if inside the archive)."
    	exit 1
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
#安装包名称
if test -f "$1"
then
	FILENAME="$1"
else
	echo "文件 $1 不存在." >&2
	exit 3
fi
#目标包名称
TARNAME=$2
#LICENSE
if test "$LICENSE" = ""
then
	if test -f "LICENSE.txt"
	then
		LICENSE=$(cat "LICENSE.txt")
	else
		echo "WARNING: LICENSE.txt不存在." >&2
	fi
fi
#校验程序
if test ! -f "$CHECKNAME"
then
    	echo "校验程序 $CHECKNAME 不存在." >&2
   	exit 4
fi
#查找md5sum
MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
if test ! -x "$MD5_PATH"; then  		
    	echo "MD5: 未找到 md5sum 命令"
	exit 5		
fi

#计算HEADER脚本行数
if test -f "$HEADER"; then
        OLDTARNAME="$TARNAME"
        TARNAME="$TEMPFILE"
	SKIP=0
       	. "$HEADER"
        SKIP=`cat "$TEMPFILE" |wc -l`
	rm -f "$TEMPFILE"
    	echo "Header 文件 $SKIP 行" >&2
        TARNAME="$OLDTARNAME"
else
    	echo "打开 header 文件失败: $HEADER" >&2
    	exit 6
fi

#
if test -f "$TARNAME"; then
	echo "$TARNAME 包已存在是否覆盖？y/n "
      	read yn
     	if test x"$yn" = xn; then
        	exit 7
        	break;
     	elif test x"$yn" = xy; then
        	break;
      	fi
   	echo "WARNING: 覆盖已存在包: $TARNAME" >&2
fi

MD5_CODE=00000000000000000000000000000000
##########################################################################处理校验程序
#空间
USIZE=`du -ks "$CHECKNAME" | awk '{print $1}'`
USIZES=$USIZE

#计算文件大小
FSIZE=`cat "$CHECKNAME" | wc -c | tr -d " "`
FILESIZES=$FSIZE;

#计算md5
MD5_CODE=`cat "$CHECKNAME" | eval "$MD5_PATH" | cut -b-32`
echo "$CHECKNAME MD5: $MD5_CODE"
MD5S=$MD5_CODE
##########################################################################处理安装包
#空间
USIZE=`du -ks "$FILENAME" | awk '{print $1}'`
USIZES=`expr $USIZES + $USIZE`

#计算文件大小
FSIZE=`cat "$FILENAME" | wc -c | tr -d " "`
FILESIZES="$FILESIZES $FSIZE"
#计算md5
MD5_CODE=`cat "$FILENAME" | eval "$MD5_PATH" | cut -b-32`
echo "$FILENAME MD5: $MD5_CODE"
MD5S="$MD5S $MD5_CODE"


#生成HEADER脚本
. "$HEADER"
#复制一份方便查看问题
#cp $TARNAME Temp.sh
#连接文件
cat "$CHECKNAME" >> "$TARNAME"
cat "$FILENAME" >> "$TARNAME"

chmod +x "$TARNAME"

echo "安装包： \"$TARNAME\" 制作成功."


